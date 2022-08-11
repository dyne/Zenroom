load ../bats_setup

setup_file() {

    run1=`echo "print(RNGSEED:hex() .. ';' .. O.random(64):hex())" | Z -`
    export seed1=`echo $run1 | cut -d';' -f 1`

    run2=`echo "print(RNGSEED:hex() .. ';' .. O.random(64):hex())" | Z - -c "rngseed=hex:$seed1"`
    export seed2=`echo $run2 | cut -d';' -f 1`

    export seed="74eeeab870a394175fae808dd5dd3b047f3ee2d6a8d01e14bff94271565625e98a63babe8dd6cbea6fedf3e19de4bc80314b861599522e44409fdd20f7cd6cfc"

}

@test "Check that test seeds are different" {

    assert_equal "$seed1" "$seed2"

    assert_not_equal $seed $seed1
    assert_not_equal $seed $seed2

    cat <<EOF > determinism.lua
print("RNGSEED:".. RNGSEED:hex())
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
I.print({ ecdh_keys = { sec = ecdh.private, pub = ecdh.public } })
ecdh2 = ECDH.keygen()
I.print({ ecdh_keys = { sec = ecdh2.private, pub = ecdh2.public } })
assert(ecdh2.private ~= ecdh.private)
assert(ecdh2.public ~= ecdh.public)
c, d = ECDH.sign(ecdh.private, "Hello World!")
I.print({ ecdh_sign = { c = c, d = d } })
-- will check if same on next execution
EOF

}

@test "Check same results with same seed" {
    first=`Z  determinism.lua -c rngseed=hex:$seed1`
    second=`Z determinism.lua -c rngseed=hex:$seed2`
    assert_equal "$first" "$second"
}

@test "Check different results with random seeds" {
    first=`Z determinism.lua`
    second=`Z determinism.lua`
    assert_not_equal "$first" "$second"
}

@test "Check different results with different seeds" {
    first=`Z  determinism.lua -c rngseed=hex:$seed1`
    second=`Z determinism.lua -c rngseed=hex:$seed`
    assert_not_equal "$first" "$second"
}
