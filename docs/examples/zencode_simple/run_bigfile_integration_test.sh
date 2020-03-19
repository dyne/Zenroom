#!/bin/sh
export TIME='\t%E real,\t%U user,\t%S sys,\t%K amem,\t%M mmem'

#zsh
# TIMEFMT='%J   %U  user %S system %P cpu %*E total'$'\n'\
# 	   'avg shared (code):         %X KB'$'\n'\
# 	   'avg unshared (data/stack): %D KB'$'\n'\
# 	   'total (sum):               %K KB'$'\n'\
# 	   'max memory:                %M MB'$'\n'\
# 	   'page faults from disk:     %F'$'\n'\
# 	   'other page faults:         %R'


verbose=1

if [ "$1" = "" ]; then
	z="../../src/zenroom"
else z="$1"; fi

# chose among profiling tools
zenroom() {	
	if command -v perf; then
		# perf stat -B $z $*
		perf record $z $*
		# perf report
	else
		time $z $*
	fi
}

echo
echo "========================================"
echo "ZENCODE SIMPLE ENCRYPTION, BIGFILE test"
echo
command -v zenroom
# create_file returns:
# [
#   { base64: "...base64..." }
#   { bob: { public: "u64:...ecdh public key" } }
# ]
create_file() {
	out=test_"$1"KiB.json
	dd if=/dev/urandom bs=1024 count="$1" 2>/dev/null \
		| base64 -w0 | tr -d '=' | tr '/+' '_-' \
		| jq -Rsj '. | { message: . }' | jq -s . - bob.pub \
										  > test_"$1"KiB.json
	echo "$out"
}

encrypt() {
	in=`create_file $1`
	scenario="Alice encrypts a $1KiB file for Bob"
	echo $scenario
	cat <<EOF | zenroom -c memmanager=\"sys\" -z -d$verbose -k alice.keys -a $in \
		> alice_to_bob.json
Scenario 'simple': $scenario
rule input untagged
Given that I am known as 'Alice'
and I have my valid 'keypair'
and I have a valid 'public key' from 'Bob'
and I have a 'message'
When I encrypt the message for 'Bob'
Then print the 'secret message'
EOF
}

encrypt 4    # 4K
encrypt 10
# encrypt 500  # .5M
#encrypt 1000  # 1M
# encrypt 1500  # 1.5M
