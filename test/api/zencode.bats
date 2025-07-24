# setup paths for BATS test units
setup() {
    bats_require_minimum_version 1.5.0
    T="$BATS_TEST_DIRNAME"
    TR=`cd "$T"/.. && pwd`
    R=`cd "$TR"/.. && pwd`
    TMP="$BATS_TEST_TMPDIR"
    load "$TR"/test_helper/bats-support/load
    load "$TR"/test_helper/bats-assert/load
    load "$TR"/test_helper/bats-file/load
    ZTMP="$BATS_FILE_TMPDIR"
    cd $ZTMP
}

save() {
    >&3 echo " 💾 $1"
    export output=`cat $ZTMP/$1`
}

@test "ZENCODE API :: Compile tests" {
    LDADD="-L$R -lzenroom"
    CFLAGS="$CFLAGS -I$R/src"
    if strings "$R/libzenroom.so" | grep -q "__asan_init"; then
        LDADD="${LDADD} -fsanitize=address,undefined"
        CFLAGS="${CFLAGS} -fsanitize=address,undefined"
    fi
    cc ${CFLAGS} -ggdb -o zencode_exec $T/zencode.c ${LDADD}
    cc ${CFLAGS} -ggdb -o zencode_exec_tobuf $T/zencode_to_buf.c ${LDADD}
    cc ${CFLAGS} -ggdb -o zenroom_exec $T/zenroom.c ${LDADD}
    cc ${CFLAGS} -ggdb -o zenroom_exec_tobuf $T/zenroom_to_buf.c ${LDADD}
}

@test "ZENCODE API :: zencode_exec 100 times with conf" {
    script="$(cat <<EOF
Given nothing
Then print the string 'Hello World'
EOF
)"
    LD_LIBRARY_PATH=$R ./zencode_exec "$script" "debug=2,logfmt=json" "" "" "" "" "100"> iteration_zencode
}

@test "ZENCODE API :: zencode_exec only conf keys and data" {
    script="$(cat <<EOF
Given nothing
Then print the string 'Hello World'
EOF
)"
    LD_LIBRARY_PATH=$R ./zencode_exec "$script" "" "" "" > simple_zencode
    save simple_zencode
    assert_output '{"output":["Hello_World"]}'
}

@test "ZENCODE API :: zencode_exec all inputs " {
    script="$(cat <<EOF
Given I have a 'string' named 'data'
Given I have a 'string' named 'keys'
Given I have a 'string' named 'extra'
Then print the data
EOF
)"
    data='{"data":"data"}'
    keys='{"keys":"keys"}'
    extra='{"extra":"extra"}'
    LD_LIBRARY_PATH=$R ./zencode_exec "$script" "" "$keys" "$data" "$extra"> extra_zencode
    save extra_zencode
    assert_output '{"data":"data","extra":"extra","keys":"keys"}'
}

@test "ZENCODE API :: zencode_exec_tobuf only conf keys and data" {
    script="$(cat <<EOF
Given nothing
Then print the string 'Hello World'
EOF
)"
    LD_LIBRARY_PATH=$R ./zencode_exec_tobuf "$script" "" "" ""> simple_zencode_tobuf
    save simple_zencode_tobuf
    assert_output '{"output":["Hello_World"]}'
}

@test "ZENCODE API :: zencode_exec_tobuf all inputs " {
    script="$(cat <<EOF
Given I have a 'string' named 'data'
Given I have a 'string' named 'keys'
Given I have a 'string' named 'extra'
Then print the data
EOF
)"
    data='{"data":"data"}'
    keys='{"keys":"keys"}'
    extra='{"extra":"extra"}'
    LD_LIBRARY_PATH=$R ./zencode_exec_tobuf "$script" "" "$keys" "$data" "$extra"> extra_zencode_tobuf
    save extra_zencode_tobuf
    assert_output '{"data":"data","extra":"extra","keys":"keys"}'
}

@test "ZENCODE API :: zenroom_exec all inputs " {
    script="print(DATA..KEYS..EXTRA..CONTEXT)"
    data='USING '
    keys='ALL '
    extra='ZENROOM '
    context='INPUTS'
    LD_LIBRARY_PATH=$R ./zenroom_exec "$script" "" "$keys" "$data" "$extra" "$context"> extra_context_zenroom
    save extra_context_zenroom
    assert_output 'USING ALL ZENROOM INPUTS'
}

@test "ZENCODE API :: zenroom_exec_tobuf all inputs " {
    script="print(DATA..KEYS..EXTRA..CONTEXT)"
    data='USING '
    keys='ALL '
    extra='ZENROOM '
    context='INPUTS'
    LD_LIBRARY_PATH=$R ./zenroom_exec_tobuf "$script" "" "$keys" "$data" "$extra" "$context"> extra_context_zenroom_tobuf
    save extra_context_zenroom_tobuf
    assert_output 'USING ALL ZENROOM INPUTS'
}
