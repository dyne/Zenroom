load ../bats_setup
load ../bats_zencode
SUBDOC=parser

@test "Create credetianl key" {
    cat <<EOF | zexe array_32_256.zen
rule check version 2.0.0
Scenario credential: credential keygen
Given that I am known as 'Alice'
When I create the credential key
Then print my 'keyring'
EOF
}

@test "Create issuer key" {
    cat <<EOF | zexe array_32_256.zen
rule check version 1.0.0
Scenario credential: issuer keygen
Given that I am known as 'MadHatter'
When I create the issuer key
Then print my 'keyring'
EOF
}

@test "rule unknow ignore" {
    cat <<EOF | zexe array_32_256.zen
rule check version 1.0.0
rule unknown ignore
Scenario credential: issuer keygen
Given that I am known as 'MadHatter'
When I create the issuer key
and I don't know what I am doing
Then print my 'keyring'
EOF
}

@test "Zencode pattern not found: 0YOUI4qhIeXmIpyK" {
    cat <<EOF > $TMP/error1.zen
rule check version 1.0.0
Scenario credential: issuer keygen
Given that I am known as 'MadHatter'
0YOUI4qhIeXmIpyK
Then print 'Success' 'OK'
EOF
    run $ZENROOM_EXECUTABLE -z $TMP/error1.zen
    assert_failure
}


@test "Zencode pattern not found: and 0YOUI4qhIeXmIpyK" {
    cat <<EOF > $TMP/error2.zen
rule check version 1.0.0
Scenario credential: issuer keygen
Given that I am known as 'MadHatter'
and 0YOUI4qhIeXmIpyK
Then print 'Success' 'OK'
EOF
    run $ZENROOM_EXECUTABLE -z $TMP/error2.zen
    assert_failure
}


@test "Zencode pattern not found: this should fail or 'rule unknown ignore'" {
    cat <<EOF > $TMP/error3.zen
rule check version 1.0.0
Scenario credential: issuer keygen
Given that I am known as 'MadHatter'
When I create the issuer keypair
and this should fail or 'rule unknown ignore'
Then print my 'issuer keypair'
EOF
    run $ZENROOM_EXECUTABLE -z $TMP/error3.zen
    assert_failure
}
