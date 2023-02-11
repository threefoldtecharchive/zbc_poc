module main

import flag
import log
import os
import tmkv


fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('Tendermint Key-Value app written in V')
	fp.limit_free_args(0, 0)!
	fp.description('This is a abci app written in V that communicates with tendermint using a websocket.')
	fp.skip_executable()
	ws_port := fp.int('wsport', 0, 8880, 'port to run the websocket server on, default is 8880')
	t_port := fp.int('tport', 0, 26657, 'port to send http requests to tendermint, default is 26657')
	snapshot_interval := fp.int('snapshot', 0, 5000, 'the interval at which snapshots will be taken')
	chunk_size := fp.int('chunksize', 0, 10, 'the chunk size in MB for snapshots (maximum 10 MB)')
	debug_log := fp.bool('debug', 0, false, 'log debug messages too')
	_ := fp.finalize() or {
		eprintln(err)
		println(fp.usage())
		return
	}
	if ws_port < 0 || t_port < 0 || snapshot_interval < 0 || chunk_size < 0 {
		eprintln("should be a positive value")
		println(fp.usage())
		return 
	}
	if chunk_size == 0 || chunk_size > 10 {
		eprintln("chunksize should be more than 1 MB and less than 10 MB")
		println(fp.usage())
		return 
	}
	
	log_level := match debug_log {
		true { log.Level.debug }
		else { log.Level.info }
	}
	mut logger := log.Logger(&log.Log{ level: log_level})
	tendermint_address := "http://127.0.0.1:${t_port}"
	mut app := tmkv.new_kvapp(tendermint_address, u32(snapshot_interval), u32(chunk_size), mut &logger)
	
	mut ws_handlers := map[string]&tmkv.WsHandler{}
	ws_handlers["info"] = &tmkv.InfoHandler{app: &app}
	ws_handlers["initchain"] = &tmkv.InitChainHandler{app: &app}
	ws_handlers["beginblock"] = &tmkv.BeginBlockHandler{app: &app}
	ws_handlers["endblock"] = &tmkv.EndBlockHandler{app: &app}
	ws_handlers["setoption"] = &tmkv.SetOptionHandler{app: &app}
	ws_handlers["commit"] = &tmkv.CommitHandler{app: &app}
	ws_handlers["checktx"] = &tmkv.CheckTxHandler{app: &app}
	ws_handlers["delivertx"] = &tmkv.DeliverTxHandler{app: &app}
	ws_handlers["query"] = &tmkv.QueryHandler{app: &app}
	ws_handlers["listsnapshots"] = &tmkv.ListSnapshotsHandler{app: &app}
	ws_handlers["offersnameshot"] = &tmkv.OfferSnapshotHandler{app: &app}
	ws_handlers["loadsnapshotchunk"] = &tmkv.LoadSnapshotChunkHandler{app: &app}
	ws_handlers["applysnapshotchunk"] = &tmkv.ApplySnapshotChunkHandler{app: &app}

	mut tmwsserver := tmkv.new_tmwsserver(ws_port, ws_handlers, &logger) or { panic(err) }

	t_tmwsserver := spawn tmwsserver.run()

	mut restapi_handlers := map[string]&tmkv.RestApiHandler{}
	restapi_handlers["get"] = &tmkv.GetHandler{app: &app}
	restapi_handlers["set"] = &tmkv.SetHandler{app: &app}
	mut tmkvrestapi := tmkv.new_tmkvrestapi(8080, restapi_handlers, &logger)

	t_tmkvrestapi := spawn tmkvrestapi.listen_and_serve()

	t_tmwsserver.wait() or { panic(err) }
	t_tmkvrestapi.wait()
}