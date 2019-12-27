#!/usr/bin/env zsh

tstr="Zenroom test"
zenroom=$1
valgrind=$2

function grind() {
	if [[ "$2" != "valgrind" ]]; then
		$zenroom $*
	else
		valgrind --max-stackframe=2064480 $zenroom $*
	fi
	return $?
}

print "= test octets and keyring saves in json DATA"
cat <<EOF > /tmp/zenroom_temp_check.lua
ecc = ECDH.keygen()
right = str("$tstr")
pk = ecc.public
dump = JSON.encode({teststr="$tstr",
                    pubkey=pk:base64(),
	                test64=right:base64(),
 					testhex=right:hex(),
					testhash=sha512(right):base64()})
print(dump)
EOF

grind \
	/tmp/zenroom_temp_check.lua > /tmp/octet.json || return 1


echo "== generated DATA structure in /tmp/octet.json"
echo "== checking import/export and hashes"

cat <<EOF > /tmp/zenroom_temp_check.lua
test = JSON.decode(DATA)
assert(test.teststr == "$tstr")
left = str("$tstr")
right = base64(test.test64)
assert(left == right)
right = str(test.teststr)
assert(left == right)
right = hex(test.testhex)
assert(left == right)
assert(sha512(left):base64() == test.testhash)
assert(sha512(right):base64() == test.testhash)
print "== check the pubkey"
left = base64(test.pubkey)
assert(ECDH.pubcheck(left))
EOF

grind \
	-a /tmp/octet.json /tmp/zenroom_temp_check.lua \
	|| return 1

echo "= OK"
