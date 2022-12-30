module tfchain4
// import freeflowuniverse.crystallib.pathlib
import freeflowuniverse.crystallib.zdb


pub fn (mut tfchain TFChain) save (o Object)!{
	mut data:=""
	match o {
		User {
			data=o.dumps()
			key:=tfchain.data_set(.user,o.id,data)!
		}
		else {
			panic("cannot find the type")
		}
	}	

}


pub fn (mut tfchain TFChain) get_user (id u32)! User{
	data:=tfchain.data_get(id)!
	obj:=user_load(data)!
	return obj
}