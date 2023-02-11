module main
// import time
import os
import tfchain4

const testpath = os.dir(@FILE) + '/example_data'


fn do() ! {
	mut tfchain:=tfchain4.new(secret:'')!
	mut last:=0
	for i in 0 .. 1000 {
		mut user := tfchain4.user_new()
		user.id = 0
		user.name = "aname"
		user.email = ["kk@iiid.com"]
		user.matrix = ["user1","user2"]
		user.signatures= [u32(55),u32(33)]
		tfchain.save(user)!
		if int(i)==last*1000{
			println(i)
			last+=1
		}
		// println(user)
		// println(user.dumps())
		// user2:=tfchain4.user_load(user.dumps())!
		// println(user2)
	}
	println("end")
	// mut user2:=tfchain.get_user(20)!
	// println(user2)
}	

fn main() {
	do() or { panic(err) }
}
