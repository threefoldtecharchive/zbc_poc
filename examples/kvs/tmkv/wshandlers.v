module tmkv

import json

// a handler function which takes payload request
// as a string, and returns a response string
// encoding/decoding should be done with structs in the app itself
// or in a helper proxy app
pub interface WsHandler {
mut:
	app &KVApp

	handle(string) !string
}

pub struct InfoHandler {
mut:
	app &KVApp
}

pub fn (mut h InfoHandler) handle(payload string) !string {
	req := json.decode(RequestInfo, payload) or {
		return error("failed decoding to RequestInfo: $err")
	}
	resp := h.app.info(req) or {
		return error("info failed: $err, req: $req")
	}
	return json.encode(resp as ResponseInfo)
}

pub struct InitChainHandler {
mut:
	app &KVApp
}

pub fn (mut h InitChainHandler) handle(payload string) !string {
	req := json.decode(RequestInitChain, payload) or {
		return error("failed decoding to RequestInitChain: $err")
	}
	resp := h.app.init_chain(req) or {
		return error("init_chain failed: $err, req: $req")
	}

	return json.encode(resp as ResponseInitChain)
}

pub struct BeginBlockHandler {
mut:
	app &KVApp
}

pub fn (mut h BeginBlockHandler) handle(payload string) !string {
	req := json.decode(RequestBeginBlock, payload) or {
		return error("failed decoding to RequestBeginBlock: $err")
	}
	resp := h.app.begin_block(req) or {
		return error("begin_block failed: $err, req: $req")
	}

	return json.encode(resp as ResponseBeginBlock)
}

pub struct EndBlockHandler {
mut:
	app &KVApp
}

pub fn (mut h EndBlockHandler) handle(payload string) !string {
	req := json.decode(RequestEndBlock, payload) or {
		return error("failed decoding to RequestEndBlock: $err")
	}
	resp := h.app.end_block(req) or {
		return error("end_block failed: $err, req: $req")
	}

	return json.encode(resp as ResponseEndBlock)
}

pub struct SetOptionHandler {
mut:
	app &KVApp
}

pub fn (mut h SetOptionHandler) handle(payload string) !string {
	req := json.decode(RequestSetOption, payload) or {
		return error("failed decoding to RequestSetOption: $err")
	}
	resp := h.app.set_option(req) or {
		return error("set_option failed: $err, req: $req")
	}

	return json.encode(resp as ResponseSetOption)
}

pub struct CommitHandler {
mut:
	app &KVApp
}

pub fn (mut h CommitHandler) handle(payload string) !string {
	req := json.decode(RequestCommit, payload) or {
		return error("failed decoding to RequestCommit: $err")
	}
	resp := h.app.commit(req) or {
		return error("commit failed: $err, req: $req")
	}

	return json.encode(resp as ResponseCommit)
}

pub struct CheckTxHandler {
mut:
	app &KVApp
}

pub fn (mut h CheckTxHandler) handle(payload string) !string {
	req := json.decode(RequestCheckTx, payload) or {
		return error("failed decoding to RequestCheckTx: $err")
	}
	resp := h.app.check_tx(req) or {
		return error("checkTx failed: $err, req: $req")
	}

	return json.encode(resp as ResponseCheckTx)
}

pub struct DeliverTxHandler {
mut:
	app &KVApp
}

pub fn (mut h DeliverTxHandler) handle(payload string) !string {
	req := json.decode(RequestDeliverTx, payload) or {
		return error("failed decoding to RequestDeliverTx: $err")
	}
	resp := h.app.deliver_tx(req) or {
		return error("deliver_tx failed: $err, req: $req")
	}

	return json.encode(resp as ResponseDeliverTx)
}

pub struct QueryHandler {
mut:
	app &KVApp
}

pub fn (mut h QueryHandler) handle(payload string) !string {
	req := json.decode(RequestQuery, payload) or {
		return error("failed decoding to RequestQuery: $err")
	}
	resp := h.app.query(req) or {
		return error("query failed: $err, req: $req")
	}

	return json.encode(resp as ResponseQuery)
}

pub struct ListSnapshotsHandler {
mut:
	app &KVApp
}

pub fn (mut h ListSnapshotsHandler) handle(payload string) !string {
	req := json.decode(RequestListSnapshots, payload) or {
		return error("failed decoding to RequestListSnapshots: $err")
	}
	resp := h.app.list_snapshots(req) or {
		return error("list snapshots failed: $err, req: $req")
	}

	return json.encode(resp as ResponseListSnapshots)
}

pub struct OfferSnapshotHandler {
mut:
	app &KVApp
}

pub fn (mut h OfferSnapshotHandler) handle(payload string) !string {
	req := json.decode(RequestOfferSnapshot, payload) or {
		return error("failed decoding to RequestOfferSnapshot: $err")
	}
	resp := h.app.offer_snapshot(req) or {
		return error("offer snapshot failed: $err, req: $req")
	}

	return json.encode(resp as ResponseOfferSnapshot)
}

pub struct LoadSnapshotChunkHandler {
mut:
	app &KVApp
}

pub fn (mut h LoadSnapshotChunkHandler) handle(payload string) !string {
	req := json.decode(RequestLoadSnapshotChunk, payload) or {
		return error("failed decoding to RequestLoadSnapshotChunk: $err")
	}
	resp := h.app.load_snapshot_chunk(req) or {
		return error("load snapshot chunk failed: $err, req: $req")
	}

	return json.encode(resp as ResponseLoadSnapshotChunk)
}

pub struct ApplySnapshotChunkHandler {
mut:
	app &KVApp
}

pub fn (mut h ApplySnapshotChunkHandler) handle(payload string) !string {
	req := json.decode(RequestApplySnapshotChunk, payload) or {
		return error("failed decoding to RequestApplySnapshotChunk: $err")
	}
	resp := h.app.apply_snapshot_chunk(req) or {
		return error("apply snapshot chunk failed: $err, req: $req")
	}

	return json.encode(resp as ResponseApplySnapshotChunk)
}