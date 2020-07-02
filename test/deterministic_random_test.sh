#!/usr/bin/env zsh


set -e
set -u
set -o pipefail

exe=${1:-zenroom}


echo "TEST RNGSEED READ/WRITE"
zmodload zsh/system
cat <<EOF | ${exe} | sysread run1
print(RNGSEED:hex() .. ";" .. O.random(64):hex())
EOF
seed1=`print $run1 | cut -d';' -f 1`
rand1=`print $run1 | cut -d';' -f 2`
cat <<EOF | ${exe} -c "rngseed=hex:$seed1" | sysread run2
print(RNGSEED:hex() .. ";" .. O.random(64):hex())
EOF
seed2=`print $run2 | cut -d';' -f 1`
rand2=`print $run2 | cut -d';' -f 2`

[[ "$seed1" != "$seed2" ]] && return 1

[[ "$rand1" != "$rand2" ]] && return 1

seed="74eeeab870a394175fae808dd5dd3b047f3ee2d6a8d01e14bff94271565625e98a63babe8dd6cbea6fedf3e19de4bc80314b861599522e44409fdd20f7cd6cfc"

dtmode=`mktemp`
cat <<EOF > $dtmode
print("RNGSEED: ".. RNGSEED:hex())
print("Checks for deterministic operations")

first = O.random(16)
second = O.random(16)

-- subsequent executions lead to different results
assert( first ~= second )
I.print({ first = first })
I.print({ second = second })

-- new initialization doesn't resets from first
third = O.random(16)
assert( first ~= third )
I.print({ third = third })

i = INT.random()
I.print({big_random = i})

-- ECDH
ecdh = ECDH.keygen()
I.print({ ecdh_keys = { sec = ecdh.private,
						pub = ecdh.public } })
ecdh2 = ECDH.keygen()
I.print({ ecdh_keys = { sec = ecdh2.private,
						pub = ecdh2.public } })
assert(ecdh2.private ~= ecdh.private)
assert(ecdh2.public ~= ecdh.public)
c, d = ECDH.sign(ecdh.private, "Hello World!")
I.print({ ecdh_sign = { c = c, d = d } })
-- will check if same on next execution
EOF

first=`${exe} -c rngseed=hex:$seed $dtmode`
second=`${exe} -c rngseed=hex:$seed $dtmode`
# echo "$first"

if [[ "$first" == "$second" ]]; then
	echo
	echo "====================="
	echo "Deterministic mode OK"
	echo "====================="
	echo
else
	echo
	echo "Error in deterministic mode"
	echo
	echo "$first" > /tmp/first
	echo "$second" > /tmp/second
	diff /tmp/first /tmp/second
	echo
	rm $dtmode
	return 1
fi

first=`${exe}  $dtmode`
second=`${exe} $dtmode`


if ! [[ "$first" == "$second" ]]; then
	echo
	echo "======================="
	echo "Undeterministic mode OK"
	echo "======================="
	echo
else
	echo
	echo "Error in undeterministic mode"
	echo
	# echo "$first" > /tmp/first
	# echo "$second" > /tmp/second
	echo "$first"
	diff /tmp/first /tmp/second
	echo
	rm $dtmode
	return 1
fi

rm $dtmode
return 0
