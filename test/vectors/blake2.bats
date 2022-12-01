load ../bats_setup

@test "Blake2b: hash vectors" {
	${ZENROOM_EXECUTABLE} -a $T/blake2b_vectors.json $T/blake2b_vectors.lua
}
