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
    # vectors
    STR448='6162636462636465636465666465666765666768666768696768696A68696A6B696A6B6C6A6B6C6D6B6C6D6E6C6D6E6F6D6E6F706E6F7071'
    STR896='61626364656667686263646566676869636465666768696A6465666768696A6B65666768696A6B6C666768696A6B6C6D6768696A6B6C6D6E68696A6B6C6D6E6F696A6B6C6D6E6F706A6B6C6D6E6F70716B6C6D6E6F7071726C6D6E6F707172736D6E6F70717273746E6F707172737475'
}

save() {
    >&3 echo " 💾 $1"
    export output=`cat $ZTMP/$1`
}

run_exec() {
    binary="$1"
    shift
    unset LD_PRELOAD
    if strings "$R/libzenroom.so" | grep -q "__asan_init"; then
         export LD_PRELOAD=$(cc -print-file-name=libasan.so)
    fi
    LD_LIBRARY_PATH=$R LD_PRELOAD=$LD_PRELOAD "./$binary" "$@"
}

@test "SIGN API :: Compile tests" {
    LDADD="-L$R -lzenroom"
    CFLAGS="$CFLAGS -I$R/src"
    cc ${CFLAGS} -ggdb -o sign_keygen   $T/sign_keygen.c ${LDADD}
    cc ${CFLAGS} -ggdb -o sign_pubgen   $T/sign_pubgen.c ${LDADD}
    cc ${CFLAGS} -ggdb -o sign_create   $T/sign_create.c ${LDADD}
    cc ${CFLAGS} -ggdb -o sign_verify   $T/sign_verify.c ${LDADD}
}

@test "SIGN API :: eddsa keygen" {
    run_exec sign_keygen eddsa > eddsa_sk
    save eddsa_sk
}
@test "SIGN API :: eddsa keygen with external seed" {
    run_exec sign_keygen eddsa \
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000 \
  > eddsa_sk_seed
    save eddsa_sk_seed
    assert_output '06b4c6f4caf4234be9dedc6983412aaf50773e788e144e3e2cd09b56f21f744d'
}

@test "SIGN API :: eddsa pubgen" {
    run_exec sign_pubgen eddsa `cat eddsa_sk_seed` > eddsa_pk
    save eddsa_pk
    assert_output 'e78735703bf56140a00a6f867ca926fa0945e8b5752325e6593ea680d55d41bc'
}

@test "SIGN API :: eddsa create" {
    run_exec sign_create eddsa `cat eddsa_sk_seed` "$STR448" > eddsa_signature
    save eddsa_signature
    assert_output 'b2efa19f6c51a929e4155a8ee1df57abeef8e1b9556366551f9e1ec3ea2476b6c3bbcb93e8a23d5cfffa50f968cb84aa5e1e06bf1b884509ae35603b20999a01'
}

@test "SIGN API :: eddsa verify OK" {
    run_exec sign_verify eddsa `cat eddsa_pk` "$STR448" `cat eddsa_signature` > eddsa_verification
    save eddsa_verification
    assert_output '1'
}

@test "SIGN API :: eddsa verify ERR msg" {
    run_exec sign_verify eddsa `cat eddsa_pk` "$STR896" `cat eddsa_signature`> eddsa_verification
    save eddsa_verification
    assert_output '0'
}

@test "SIGN API :: eddsa verify ERR sig" {
    run_exec sign_verify eddsa `cat eddsa_pk` "$STR448" "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"> eddsa_verification
    save eddsa_verification
    assert_output '0'
}
