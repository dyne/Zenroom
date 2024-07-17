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
    STR448='abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'
    STR896='abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu'
}

save() {
    >&3 echo " 💾 $1"
    export output=`cat $ZTMP/$1`
}
@test "SIGN API :: Compile tests" {
    LDADD="-L$R/meson -lzenroom"
    CFLAGS="$CFLAGS -I$R/src"
    cc ${CFLAGS} -ggdb -o sign_keygen   $T/sign_keygen.c ${LDADD}
    cc ${CFLAGS} -ggdb -o sign_pubgen   $T/sign_pubgen.c ${LDADD}
}

@test "SIGN API :: eddsa keygen" {
    LD_LIBRARY_PATH=$R/meson ./sign_keygen eddsa > eddsa_sk
    save eddsa_sk
}
@test "SIGN API :: eddsa keygen with external seed" {
    LD_LIBRARY_PATH=$R/meson ./sign_keygen eddsa \
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000 \
  > eddsa_sk_seed
    save eddsa_sk_seed
    assert_output '06b4c6f4caf4234be9dedc6983412aaf50773e788e144e3e2cd09b56f21f744d'
}

@test "SIGN API :: eddsa pubgen" {
    LD_LIBRARY_PATH=$R/meson ./sign_pubgen eddsa `cat eddsa_sk_seed` > eddsa_pk
    save eddsa_pk
    assert_output 'e78735703bf56140a00a6f867ca926fa0945e8b5752325e6593ea680d55d41bc'
}
