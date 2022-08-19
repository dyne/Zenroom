load ../bats_setup
SUBDOC=sha_nist


@test "NIST SHA256" {
    target=`echo ${BATS_TEST_NAME} | cut -d_ -f3`
    echo "$target" > "$target"
    ${ZENROOM_EXECUTABLE} -a $T/${target}ShortMsg.rsp -k $target $T/check_rsp.lua
    ${ZENROOM_EXECUTABLE} -a $T/${target}LongMsg.rsp  -k $target $T/check_rsp.lua
}

@test "NIST SHA512" {
    target=`echo ${BATS_TEST_NAME} | cut -d_ -f3`
    echo "$target" > "$target"
    ${ZENROOM_EXECUTABLE} -a $T/${target}ShortMsg.rsp -k $target $T/check_rsp.lua
    ${ZENROOM_EXECUTABLE} -a $T/${target}LongMsg.rsp  -k $target $T/check_rsp.lua
}

@test "NIST SHA3 256" {
    target=`echo ${BATS_TEST_NAME} | cut -d_ -f3,4`
    echo "$target" > "$target"
    ${ZENROOM_EXECUTABLE} -a $T/${target}ShortMsg.rsp -k $target $T/check_rsp.lua
    ${ZENROOM_EXECUTABLE} -a $T/${target}LongMsg.rsp  -k $target $T/check_rsp.lua
}

@test "NIST SHA3 512" {
    target=`echo ${BATS_TEST_NAME} | cut -d_ -f3,4`
    echo "$target" > "$target"
    ${ZENROOM_EXECUTABLE} -a $T/${target}ShortMsg.rsp -k $target $T/check_rsp.lua
    ${ZENROOM_EXECUTABLE} -a $T/${target}LongMsg.rsp  -k $target $T/check_rsp.lua
}
