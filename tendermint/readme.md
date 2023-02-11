# Vlang - Tendermint keyvalue store PoC

In this section of the repository you will find a PoC of a [tendermint](https://tendermint.com/) keyvalue store. This is keyvalue store is written in V and uses tendermint for replication of the data, it is thus an [ABCI application](https://docs.tendermint.com/v0.34/tutorials/go-built-in.html#). 

## Setup

- Install V: https://github.com/vlang/v/blob/master/README.md#installing-v-from-source
- Install tendermint v0.34.0: https://github.com/tendermint/tendermint/blob/main/docs/introduction/install.md

## Under the hood

The tendermint keyvalue store is made of two executables: one written in V and one in Go. The executable written in go will start a webserver, implements the [ABCI methods and types](https://github.com/tendermint/tendermint/blob/v0.34.x/spec/abci/abci.md), keeps a databse in memory and decides when to take a snapshot of that database. The executable written in Go will connect to that webserver, start a tendermint node and delegate the communication between tendermint and the V app through the websocket. 

## Running the tendermint keyvalue store:

Open 2 terminal windows, in the first you should execute the v app:

```
cd ~/code/github/threefoldtech/zbc_poc/examples/kvs
v run main.v --chunksize=10 --snapshot=5000
```
it will build and run the V executable. The argument *chunksize* defines the chunksize in MB when splitting the database data in chunks for snapshots. The argument *snapshot* is the amount of blocks to wait before taking a snapshot.

In the second window:

```
mkdir -p ~/consensus
cd ~/consensus
tendermint init
go build
/tm_ws -config ~/.tendermint/config/config.toml
```
which will build and run the go executable. At this point tendermint should start creating blocks and consensus should happen.

## Getting and setting keys

The V app also implements a REST API that allows you to get and set keys to the key value store.

Open your favorite browser and type in the following url:

```
http://localhost:8080/get?thisisakey
```

As we have nothing in our database yet you should get the following output:
```
{
    "code":1,
    "status":"FAILURE",
    "log":"The key thisisakey does not exist.",
    "result":{}}
```

A successful get would have resulted in the following output:
```
{
    "code":0,
    "status":"SUCCESS",
    "log":"",
    "result":{
        "thisisakey":"thisisavalue"
    }
}
```

That requires us to execute the following set request:
```
http://localhost:8080/set?thisisakey=thisisavalue
```

Which results in the following output:
```
{
    "code":0,
    "status":"SUCCESS",
    "log":"",
    "result":{
        "thisisakey":"thisisavalue"
    }
}
```

## Further improvements

Everything can be improved, here are some of the starting points:
- Only a single node was used to test the functionality, we should test using multiple nodes. The nodes should properly replicate the transactions (we should also test if the lack of transaction ordering across nodes is no issue: https://docs.tendermint.com/v0.34/tendermint-core/mempool.html).
- The generation of snapshots was tested but using those snapshots to populate the db on startup was not tested as it requires a multi-node setup. 
- Performance tests across mutliple nodes (more nodes equals more communication between nodes)
- The app was not tested on threadsafety. Possible tests: setting a key via the REST API while it is being set through another node.
- We should test taking a snapshot while someone is setting a key via the REST API