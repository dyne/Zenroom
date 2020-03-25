#!/usr/bin/env zsh


set -e
set -u
set -o pipefail

exe=${1:-zenroom}


echo "TEST RNGSEED READ/WRITE"
zmodload zsh/system
cat <<EOF | ${exe} | sysread run1
print(RNGSEED:hex() .. ";" .. O.random(256):hex())
EOF
seed1=`print $run1 | cut -d';' -f 1`
rand1=`print $run1 | cut -d';' -f 2`
cat <<EOF | ${exe} -c rngseed=hex:$seed1 | sysread run2
print(RNGSEED:hex() .. ";" .. O.random(256):hex())
EOF
seed2=`print $run2 | cut -d';' -f 1`
rand2=`print $run2 | cut -d';' -f 2`

[[ "$seed1" != "$seed2" ]] && return 1

[[ "$rand1" != "$rand2" ]] && return 1

seed="619007c2ae1cf73f188d142f168a127d29fb59291713394f703ca8501e31548015de3f89ef6ca10043e0f7fa2bf7c1525634065cbe5fb14f7c8aa652d726334e633537ec5b15b399897f8389230d9cc06d2143bf58ed0a3f6407daeb339ab099630a898ba4d3bcf13b896c1f5d4620da7117cb647a9ae0e46b046d17a50f190000e87d250d08e38ed1843d70a12ad5a4d00bb91d3d5109b8c1d77c4e83861ab6de8297bbc4ad68481305f0c4b32860f41afc74937e10b0e4b911d97b9b6435fd7a00ae2dd3ff7721021acfbab2146bc0c6ad796969ed0451b8913f1e4813ab9e25506e199a69dcea7856bf2003dae16db2f9ca95a765dd52cf2d919200b1501f"
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
