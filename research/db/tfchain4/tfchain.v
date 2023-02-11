module tfchain4
// import freeflowuniverse.crystallib.pathlib
import freeflowuniverse.crystallib.zdb
import encoding.binary
import crypto.md5


pub struct ZDBArgs{
pub mut:
	socket_path string = '~/.zdb/socket'
	secret string = '1234'
	namespace string = 'default'
}

pub struct TFChain{
pub mut:
	zdb zdb.ZDB
mut:
	prevhash []u8
	previd u32
}



pub fn new(zdbargs ZDBArgs)! TFChain{
	mut zdb := zdb.get(zdbargs.socket_path, zdbargs.secret, zdbargs.namespace)!	

	mut tfchain := TFChain{
		zdb:zdb
	}
	nsinfo := zdb.nsinfo(zdbargs.namespace)!
	if true || nsinfo["entries"].int() == 0{
		//this was the first startup
		tfchain.prevhash = md5.sum("START") //just to have the first one
		tfchain.data_set(.start,0,"START")! //this is the first record
	}	

	return tfchain
	
}


//if key is 0 then will create an increment and new object will be added to db
fn (mut tfchain TFChain) data_set(objtype ObjType, key u32,data string) !u32{
	mut key2:=""
	if key == 0{
		key2=""
	}else{
		key2=key.str()
	}
	objtype_u16 := u16(objtype)
	mut b:=[]u8{}
	binary.little_endian_put_u32(mut b, objtype_u16)

	panic("S")
	datanew:=b.str()+tfchain.prevhash+data
	newhash := md5.hexhash(datanew) //should probably go to binary form

	// datatostor=+newhash+
	
	// println(nsinfo["entries"].int())
	panic("Ss")

	key3:= tfchain.zdb.set(key2,data)!
	u:=binary.little_endian_u64(key3.bytes())	
	println(u)
	panic('sd')
	// .trim_right("0")
	return u32(1)
}

//if key is 0 then will create an increment and new object will be added to db
fn (mut tfchain TFChain) data_get(key u32) !string{
	mut key2:=""
	if key == 0{
		return error("cannot get data for key 0")
	}else{
		key2=key.str()
	}
	data:= tfchain.zdb.get(key2)!	
	return data
}
