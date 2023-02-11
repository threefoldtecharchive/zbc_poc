package pkg

import (
	"context"
	"encoding/json"

	"github.com/pkg/errors"
	abcitypes "github.com/tendermint/tendermint/abci/types"
	"nhooyr.io/websocket"
)

type Request struct {
}

type KvApp struct {
	client *websocket.Conn
}

type RequestMessage struct {
	Command string `json:"handler"`
	Request string `json:"request"`
}

type ResponseMessage struct {
	Error    string `json:"error"`
	Response string `json:"response"`
}

func NewKvApp(conn *websocket.Conn) *KvApp {
	return &KvApp{
		client: conn,
	}
}

func (app *KvApp) call(funcName string, req interface{}, resp interface{}) error {
	bytes, err := json.Marshal(req)
	if err != nil {
		return errors.Wrap(err, "failed to serialize request")
	}
	request := RequestMessage{
		Command: funcName,
		Request: string(bytes),
	}

	bytes, err = json.Marshal(request)
	if err != nil {
		return errors.Wrap(err, "failed to serialize request message")
	}
	err = app.client.Write(context.Background(), websocket.MessageBinary, bytes)
	if err != nil {
		return errors.Wrap(err, "failed to send message to server")
	}

	_, bytes, err = app.client.Read(context.Background())
	if err != nil {
		return errors.Wrap(err, "failed to read message from server")
	}

	response := ResponseMessage{
		Error:    "",
		Response: "",
	}
	err = json.Unmarshal(bytes, &response)
	if err != nil {
		return errors.Wrap(err, "failed to unserialize response message")
	}

	err = json.Unmarshal([]byte(response.Response), &resp)
	if err != nil {
		return errors.Wrap(err, "failed to unserialize response")
	}

	return nil
}

func (app *KvApp) Info(req abcitypes.RequestInfo) abcitypes.ResponseInfo {
	resp := abcitypes.ResponseInfo{}
	app.call("info", req, &resp)
	return resp
}

func (app *KvApp) InitChain(req abcitypes.RequestInitChain) abcitypes.ResponseInitChain {
	resp := abcitypes.ResponseInitChain{}
	app.call("initchain", req, &resp)
	return resp
}

func (app *KvApp) EndBlock(req abcitypes.RequestEndBlock) abcitypes.ResponseEndBlock {
	resp := abcitypes.ResponseEndBlock{}
	app.call("endblock", req, &resp)
	return resp
}

func (app *KvApp) ListSnapshots(req abcitypes.RequestListSnapshots) abcitypes.ResponseListSnapshots {
	resp := abcitypes.ResponseListSnapshots{}
	app.call("listsnapshots", req, &resp)
	return resp
}

func (app *KvApp) OfferSnapshot(req abcitypes.RequestOfferSnapshot) abcitypes.ResponseOfferSnapshot {
	resp := abcitypes.ResponseOfferSnapshot{}
	app.call("offersnameshot", req, &resp)
	return resp
}

func (app *KvApp) LoadSnapshotChunk(req abcitypes.RequestLoadSnapshotChunk) abcitypes.ResponseLoadSnapshotChunk {
	resp := abcitypes.ResponseLoadSnapshotChunk{}
	app.call("loadsnapshotchunk", req, &resp)
	return resp
}

func (app *KvApp) ApplySnapshotChunk(req abcitypes.RequestApplySnapshotChunk) abcitypes.ResponseApplySnapshotChunk {
	resp := abcitypes.ResponseApplySnapshotChunk{}
	app.call("applysnapshotchunk", req, &resp)
	return resp
}

func (app *KvApp) SetOption(req abcitypes.RequestSetOption) abcitypes.ResponseSetOption {
	resp := abcitypes.ResponseSetOption{}
	app.call("setoption", req, &resp)
	return resp
}

func (app *KvApp) CheckTx(req abcitypes.RequestCheckTx) abcitypes.ResponseCheckTx {
	resp := abcitypes.ResponseCheckTx{Code: 0, GasWanted: 1}
	app.call("checktx", req, &resp)
	return resp
}

func (app *KvApp) DeliverTx(req abcitypes.RequestDeliverTx) abcitypes.ResponseDeliverTx {
	resp := abcitypes.ResponseDeliverTx{Code: 0}
	app.call("delivertx", req, &resp)
	return resp
}

func (app *KvApp) Commit() abcitypes.ResponseCommit {
	req := Request{}
	resp := abcitypes.ResponseCommit{Data: []byte{}}
	app.call("commit", req, &resp)
	return resp
}

func (app *KvApp) Query(req abcitypes.RequestQuery) (resp abcitypes.ResponseQuery) {
	app.call("query", req, &resp)
	return
}

func (app *KvApp) BeginBlock(req abcitypes.RequestBeginBlock) abcitypes.ResponseBeginBlock {
	resp := abcitypes.ResponseBeginBlock{}
	app.call("beginblock", req, &resp)
	return resp
}
