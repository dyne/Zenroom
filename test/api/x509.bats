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
    # CFLAGS="$CFLAGS -fsanitize=address -fsanitize=undefined -fsanitize=float-divide-by-zero -fsanitize=float-cast-overflow -fsanitize=leak"
    if strings "$R/libzenroom.so" | grep -q "__asan_init"; then
        LDADD="${LDADD} -fsanitize=address,undefined"
        CFLAGS="${CFLAGS} -fsanitize=address,undefined"
    fi
    cc ${CFLAGS} -ggdb -o x509 $T/testx509.c ${LDADD}
    cc ${CFLAGS} -ggdb -o x509_didroom $T/x509_didroom.c ${LDADD}
    cc ${CFLAGS} -ggdb -o x509_postquantum $T/x509_postquantum.c ${LDADD}

}

@test "X509 AMCL LIB :: Run test for RSA" {
      LD_LIBRARY_PATH=$R ./x509 > test_x509
      save test_x509
      # >&3 cat test_x509
}

@test "X509 Zenroom LIB :: Run test for P256 Didroom" {
      LD_LIBRARY_PATH=$R ./x509_didroom > test_x509_didroom
      save test_x509_didroom
      # >&3 cat test_x509_didroom
}

@test "X509 Zenroom LIB :: Run test for Post-Quantum X509" {
      LD_LIBRARY_PATH=$R ./x509_postquantum > test_x509_postquantum
      save test_x509_postquantum
      # >&3 cat test_x509_postquantum
}
