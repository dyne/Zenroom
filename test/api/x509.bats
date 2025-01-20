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

@test "X509 AMCL LIB :: Compile test" {
      AMCL="${R}/lib/milagro-crypto-c/build/lib"
    LDADD="${AMCL}/libamcl_core.a ${AMCL}/libamcl_x509.a"
    LDADD="$LDADD ${AMCL}/libamcl_rsa_2048.a ${AMCL}/libamcl_rsa_4096.a"
    CFLAGS="$CFLAGS -I$R/src -I$R/lib/milagro-crypto-c/include"
    CFLAGS="$CFLAGS -I$R/lib/milagro-crypto-c/build/include" 
    gcc -c $T/testx509.c $CFLAGS
    gcc ${CFLAGS} -ggdb -o x509 testx509.o ${LDADD}
}

@test "X509 AMCL LIB :: Run test" {
      LD_LIBRARY_PATH=$R ./x509 > test_x509
      save test_x509

}
