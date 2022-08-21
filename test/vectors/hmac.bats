load ../bats_setup

@test "NIST HMAC 256" {
    target=`echo ${BATS_TEST_NAME} | cut -d_ -f4`
    echo "SHA$target" > "$target"
    >&3 echo "$BATS_TEST_NAME"
    ${ZENROOM_EXECUTABLE} -a $T/HMAC_$target.rsp -k $target $T/check_hmac.lua
}

@test "NIST HMAC 512" {
    target=`echo ${BATS_TEST_NAME} | cut -d_ -f4`
    echo "SHA$target" > "$target"
    >&3 echo "$BATS_TEST_NAME"
    ${ZENROOM_EXECUTABLE} -a $T/HMAC_$target.rsp -k $target $T/check_hmac.lua
}
