module tfchain4

type Object = User | UserSignature

enum ObjType{
	start
	user
	usersignature
}

enum SignCategory{
	admin //change who is in a SignGroup, can change name, pubkey and state of account, has money & sign rights
	asset //can manage an asset (destroy, create value)
	money //send money from account wallets
	sign //sign with this account 
	db //have right on db action
	custom //is a custom right
}

struct SignGroup{
pub mut:
	id u32
	signatures []u32  //links to UserSignature
	signature_min u8
	category SignCategory
	customright string //e.g. a group of people together administer a VM, string could be 'vm.10'
}


//can only be changed by the account owner itself, id can never be changed
//if multisig the admin's of the accountgroup can change the account state & pubkey & name (only admins)
struct Account{
pub mut:
	id u32
	name string
	pubkey string
	state AccountState
	signers []SignGroup //if empty then the account itself is admin
	wallets []Wallet
}

enum AccountState{
	active
	nonactive
}

enum AssetType{
	money
	nft
}


struct Asset{
pub mut:
	id u32
	name string  //
	description string
	owners []u32 //link to owners, administer the money, create/destroy, an owner is an Account, can be multisig
	dbkey string //the key in keyvalue stor
	max_instances u32   // e.g. I have 1 million tokens (when an nft the owners can no longer change the nr of instances)
	max_fractional u32 //e.g. can do 1/1000 of 1 part, in case of 1 million tokens, we would have 1,000,000,000 parts to deal with
}


struct Wallet{
pub mut:
	asset u32 //link to type of asset
	value u32	//is the max nr of tokens
	faction u32 //is the subpart e.g. I have 1 of 1000
	lasttransaction u32 //link to the last transaction, history can be built up
}

// struct DB{
// 	kvs map[string]Record //default key value stor, normally . notation inside e.g. vmachine.10 
// }

enum RecordState{
	ok
	deleted
}

struct Record{
	data []u8 //bytestring
	owners []u32 //who can modify, they all have admin rights, links to accounts
	state RecordState
}

