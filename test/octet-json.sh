#!/usr/bin/env zsh

tstr="[*] Zenroom - crypto language restricted execution environment DECODE-0.4"
zenroom=$1
valgrind=$2

function grind() {
	if [[ "$valgrind" = "" ]]; then
		$zenroom $*
	else
		valgrind --max-stackframe=2064480 $zenroom $*
	fi
	return $?
}

echo "= test octets and keyring saves in json DATA"
cat <<EOF > /tmp/zenroom_temp_check.lua
-- ecdh = require'ecdh'
-- octet = require'octet'
ecc = ecdh.new()
right = octet.new()
right:string("$tstr")
ecc:keygen()
pk = ecc:public()
assert(ecc:checkpub(pk))
-- json = require'json'
dump = json.encode({teststr="$tstr",
                    pubkey=pk:base64(),
	                test64=right:base64(),
					testhex=right:hex(),
					testhash=ecc:hash(right):base64()})
print(dump)
EOF

grind -d \
	/tmp/zenroom_temp_check.lua  > /tmp/octet.json || return 1


echo "== generated DATA structure in /tmp/octet.json"
echo "== checking import/export and hashes"

cat <<EOF > /tmp/zenroom_temp_check.lua
-- json = require'json'
-- octet = require'octet'
test = json.decode(DATA)
assert(test.teststr == "$tstr")
-- ecdh = require'ecdh'
ecc = ecdh.new()
left = octet.new()
left:string("$tstr")
right = octet.new()
right:base64(test.test64)
assert(left == right)
right:string(test.teststr)
assert(left == right)
right:hex(test.testhex)
assert(left == right)
assert(ecc:hash(left):base64() == test.testhash)
assert(ecc:hash(right):base64() == test.testhash)
print "== check the pubkey"
left:base64(test.pubkey)
assert(ecc:checkpub(left))
EOF

grind -d \
	-a /tmp/octet.json /tmp/zenroom_temp_check.lua \
	|| return 1

echo "= OK"
