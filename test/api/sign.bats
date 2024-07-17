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
    assert_output '06b4c6f4caf4234be9dedc6983412aaf5'
}
