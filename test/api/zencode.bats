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
    cc ${CFLAGS} -ggdb -o zencode_exec $T/zencode.c ${LDADD}
}

@test "ZENCODE API :: zencode_exec only conf keys and data" {
    script="$(cat <<EOF
Given nothing
Then print the string 'Hello World'
EOF
)"
    LD_LIBRARY_PATH=$R ./zencode_exec "$script" "" "" ""> simple_zencode
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
    LD_LIBRARY_PATH=$R ./zencode_exec "$script" "" "$data" "$keys" "$extra"> extra_zencode
    save extra_zencode
    assert_output '{"data":"data","extra":"extra","keys":"keys"}'
}
