module tfchain4
import freeflowuniverse.crystallib.resp
pub struct User{
pub mut:
	id u32
	name string
	email []string
	matrix []string
	signatures []u32
}

pub fn (obj User) dumps() string{
	mut b := resp.builder_new()
	b.add(resp.r_u32(obj.id))
	b.add(resp.r_string(obj.name))
	b.add(resp.r_list_string(obj.email))
	b.add(resp.r_list_string(obj.matrix))
	b.add(resp.r_list_u32(obj.signatures))
	return b.data.bytestr()
}

pub fn user_new() User{
	return User{}
}

pub fn user_load(data string) !User{
	items :=resp.decode(data.bytes())!
	mut u:=User{
		id:items[0].u32()
		name:items[1].strget()
		email:items[2].strlist()
		matrix:items[3].strlist()
		signatures:items[4].u32list()
	}	
	// println(items[2])
	return u
}


//////////////////////////////

pub struct UserSignature{
pub mut:
	id u32
	userid u32 //link to the user
	pubkey string //as used for encryption & signing
}

pub fn (obj UserSignature) dumps() string{
	mut b := resp.builder_new()
	b.add(resp.r_u32(obj.id))
	b.add(resp.r_u32(obj.userid))
	b.add(resp.r_string(obj.pubkey))
	return b.data.bytestr()
}

