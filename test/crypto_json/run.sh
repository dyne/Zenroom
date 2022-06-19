#!/usr/bin/env zsh

tstr="Zenroom test"
zenroom=../../src/zenroom
if [ ! -r ${zenroom} ]; then zenroom="../../meson/zenroom"; fi
. ../utils.sh

arg=$1

run_zenroom_on_cortexm_qemu(){
	qemu_zenroom_run "$*"
	cat ./outlog
}

function grind() {
	if [[ "$arg" == "valgrind" ]]; then
		valgrind --max-stackframe=2064480 $zenroom $*
	else
		if [[ "$arg" == "cortexm" ]]; then
			run_zenroom_on_cortexm_qemu $*
		else
			$zenroom $*
		fi
	fi
	return $?
}

print "= test octets and keyring saves in json DATA"
cat <<EOF > /tmp/zenroom_temp_check.lua
ecc = ECDH.keygen()
right = str("$tstr")
pk = ecc.public
dump = JSON.encode({teststr="$tstr",
                    pubkey=base64(pk),
	                test64=base64(right),
 					testhex=hex(right),
					testhash=base64(sha512(right))})
print(dump)
EOF

grind \
	/tmp/zenroom_temp_check.lua > /tmp/octet.json || return 1


echo "== generated DATA structure in /tmp/octet.json"
echo "== checking import/export and hashes"

cat <<EOF > /tmp/zenroom_temp_check.lua
test = JSON.decode(DATA)
assert(test.teststr == "$tstr")
left = O.from_str("$tstr")
right = base64(test.test64)
assert(left == right)
right = O.from_str(test.teststr)
assert(left == right)
right = O.from_hex(test.testhex)
assert(left == right)
assert(base64(sha512(left))  == test.testhash)
assert(base64(sha512(right)) == test.testhash)
print("== check the pubkey")
left = base64(test.pubkey)
assert(ECDH.pubcheck(left))
EOF

grind \
	-a /tmp/octet.json /tmp/zenroom_temp_check.lua \
	|| return 1

echo "= OK"
