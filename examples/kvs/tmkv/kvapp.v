module tmkv

import log

import crypto.md5
import encoding.base64
import json
import math
import net.http
import time

[heap]
pub struct KVApp {
mut:
	logger &log.Logger = unsafe { nil }
	db map[string]string
	snapshot Snapshot
	chunks []string
	last_height u64
	snapshot_interval u32
	chunk_size u32
	max_characters_per_chunk u32
	tendermint_address string
}

pub fn new_kvapp(tendermint_address string, snapshot_interval u32, chunk_size u32, mut logger &log.Logger) KVApp {
	logger.info("Snapshot interval: ${snapshot_interval}")
	logger.info("Chunk size: ${chunk_size}")
	logger.info("Maximum characters per chunk: ${(chunk_size * 8_000) / 8}")
	return KVApp {
		snapshot_interval: snapshot_interval
		chunk_size: chunk_size
		logger: unsafe { logger }
		// chunk size in MB  divided by 8 bits per character
		max_characters_per_chunk: (chunk_size * 8_000_000) / 8
		tendermint_address: tendermint_address
	}
}

pub fn (mut a KVApp) restore_db_from_chunk(chunk string) ! {
	restored_db_chunk := json.decode(map[string]string, chunk)!
	for k, v in restored_db_chunk {
		a.db[k] = v
	}
}

pub fn (mut a KVApp) take_snapshot(height u64, db map[string]string) {
	if db.len == 0 {
		a.logger.info("Database empty, no need to make snapshot")
		return
	}
	hash := md5.hexhash(json.encode(db))
	if hash == a.snapshot.hash {
		a.logger.info("Database has not changed since last snapshot, reusing snapshot")
		a.snapshot.height = height
		a.snapshot.metadata = "${time.now()} | reusing old snapshot"
		return
	}

	a.logger.info("Taking a snapshot")
	// find the item that has the most amount of characters
	mut item_with_most_characters := 0
	for key, val in db {
		if item_with_most_characters < key.len + val.len {
			item_with_most_characters = key.len + val.len
		}
	}

	// create the chunks
	mut chunks := []string {}
	mut chunk := map[string]string{}
	// each chunk can have at most a.max_characters_per_chunk characters but if that value is smaller
	// than the largest item in the db use the largest item as size of the chunk
	max_characters_per_chunk :=  math.max(item_with_most_characters + 6, int(a.max_characters_per_chunk))
	mut characters_left := max_characters_per_chunk
	for key, val in db {
		if characters_left > (key.len + val.len + 6) {
			// still room left in the chunk 
			characters_left -= key.len + val.len + 6
		} else {
			// no more room left in the chunk: create a new one
			a.logger.info("New chunk: ${json.encode(chunk)}")
			chunks.insert(0, json.encode(chunk))
			chunk = map[string]string{}
			characters_left = max_characters_per_chunk
		}
		chunk[key] = val
	}
	if chunk.len > 0 {
		chunks.insert(0, json.encode(chunk))
	}

	// Create the snapshot
	a.chunks = chunks
	a.snapshot = Snapshot{
		height: height
		format: snapshot_version
		chunks: u32(chunks.len)
		hash: hash
		metadata: "${time.now()} | taking snapshot of ${db.len} items"
	}
	a.logger.debug("Chunks: ${a.chunks}")
	a.logger.debug("Snapshot: ${a.snapshot}")
}

pub fn (mut a KVApp) info(req RequestInfo) ?ResponseInfo {
	return ResponseInfo{}
}

pub fn (mut a KVApp) init_chain(req RequestInitChain) ?ResponseInitChain {
	return ResponseInitChain{}
}

pub fn (mut a KVApp) begin_block(req RequestBeginBlock) ?ResponseBeginBlock {
	return ResponseBeginBlock{}
}

pub fn (mut a KVApp) end_block(req RequestEndBlock) ?ResponseEndBlock {
	a.last_height = req.height
	return ResponseEndBlock{}
}

pub fn (mut a KVApp) set_option(req RequestSetOption) ?ResponseSetOption {
	return ResponseSetOption{}
}

pub fn (mut a KVApp) commit(req RequestCommit) ?ResponseCommit {
	if a.last_height % a.snapshot_interval == 0 {
		spawn a.take_snapshot(a.last_height, a.db.clone())
	}
	return ResponseCommit{
		data: ""
	}
}

pub fn (mut a KVApp) list_snapshots(req RequestListSnapshots) ?ResponseListSnapshots {
	return ResponseListSnapshots{
		snapshots: [a.snapshot]
	}
}

pub fn (mut a KVApp) offer_snapshot(req RequestOfferSnapshot) ?ResponseOfferSnapshot {
	mut result := 0
	if req.snapshot.height <= a.last_height && req.snapshot.chunks == 0 && req.snapshot.hash != ""{
		result = 3
	} else if req.snapshot.format != snapshot_version {
		result = 4
	} else {
		result = 1
	}
	return ResponseOfferSnapshot{
		result: result
	}
}

pub fn (mut a KVApp) load_snapshot_chunk(req RequestLoadSnapshotChunk) ?ResponseLoadSnapshotChunk {
	return ResponseLoadSnapshotChunk{
		chunk: a.chunks[req.chunk]
	}
}

pub fn (mut a KVApp) apply_snapshot_chunk(req RequestApplySnapshotChunk) ?ResponseApplySnapshotChunk {
	mut result := 1
	a.logger.info("Restoring db from chunk with id ${req.index}")
	a.restore_db_from_chunk(req.chunk) or {
		a.logger.error("failed restoring chunk ${req.chunk}: $err")
		result = 2
	}
	return ResponseApplySnapshotChunk{
		result: result
		refetch_chunks: []u32{}
		reject_senders: []string{}
	}
}

pub fn (mut a KVApp) is_valid(tx string) int {
	if tx == "" {
		return 2
	}

	parts := tx.split("=")
	if parts.len != 2 {
		return 1
	}

	key := parts.first()

	if key in a.db {
		return 2
	}

	return 0
}

pub fn (mut a KVApp) check_tx(req RequestCheckTx) ?ResponseCheckTx {
	tx := base64.decode_str(req.tx)
	code := a.is_valid(tx)
	return ResponseCheckTx{
		code: code,
		gas_wanted: 1
	}
}

pub fn (mut a KVApp) deliver_tx(req RequestDeliverTx) ?ResponseDeliverTx {
	tx := base64.decode_str(req.tx)
	code := a.is_valid(tx)
	if code != 0 {
		return ResponseDeliverTx {
			code: code,
			log: "key already exists"
		}
	}

	tx_parts := tx.split("=")
	key := tx_parts.first()
	value := tx_parts.last()

	a.db[key] = value
	return ResponseDeliverTx{
		code: 0
	}
}

pub fn (mut a KVApp) query(req RequestQuery) ?ResponseQuery {
	mut resp := ResponseQuery{}

	resp.key = req.data
	query_key := base64.decode_str(resp.key)

	value := a.get_value(query_key) or {
		resp.log = "key does not exist"
		return resp
	}

	resp.value = base64.encode_str(value)
	resp.log = "key exists"
	return resp
}

pub fn (mut a KVApp) get_value(key string) ?string {
	if key in a.db {
		return a.db[key]
	}
	return none
}

struct JsonRpcError {
	data string
}

struct JsonRpcResult {
	check_tx ResponseCheckTx
	deliver_tx ResponseDeliverTx
}

struct TmResponse {
	jsonrpc string
	id int
	error JsonRpcError
	result JsonRpcResult
}

pub fn (mut a KVApp) set_value(key string, value string) ! {
	url := "${a.tendermint_address}/broadcast_tx_sync?tx=\"${key}=${value}\""

	response := http.get(url) or {
		return error("Http request failed: $url with error $err")
	}

	mut tm_response := json.decode(TmResponse, response.body) or {
		return error("Failed decoding to TmResponse: $err")
	}

	if tm_response.error.data != "" {
		return error(tm_response.error.data)
	}

	if tm_response.result.check_tx.code == 2 || tm_response.result.deliver_tx.code != 0 {
		return error("Key ${key} already exists.")
	}
}