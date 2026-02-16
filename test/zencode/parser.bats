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
Then print my 'keyring'
and I don't know what I am doing
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
    assert_line --partial "Invalid Zencode prefix 4: '0YOUI4qhIeXmIpyK'"
}


@test "Zencode line 4 pattern not found: should fail" {
    cat <<EOF > $TMP/error2.zen
rule check version 1.0.0
Scenario credential: issuer keygen
Given that I am known as 'MadHatter'
and 0YOUI4qhIeXmIpyK
Then print 'Success' 'OK'
EOF
    run $ZENROOM_EXECUTABLE -z $TMP/error2.zen
    assert_line --partial 'Zencode line 4 pattern not found (given): and 0YOUI4qhIeXmIpyK'
}


@test "Zencode line 5 pattern not found: should fail" {
    cat <<EOF > $TMP/error3.zen
rule check version 1.0.0
Scenario credential: issuer keygen
Given that I am known as 'MadHatter'
When I create the issuer key
and this should fail or 'rule unknown ignore'
Then print my 'issuer keypair'
EOF
    run $ZENROOM_EXECUTABLE -z $TMP/error3.zen
    assert_line --partial "Zencode line 5 pattern not found (when): and this should fail or 'rule unknown ignore'"
}

@test "Zencode line 10 pattern not found: should fail" {
    cat <<EOF > $TMP/error3.zen

# comment line
rule check version 1.0.0

# empty line above
Scenario credential: issuer keygen
Given that I am known as 'MadHatter'
When I create the issuer key

and this should fail or 'rule unknown ignore'
Then print my 'issuer keypair'
EOF
    run $ZENROOM_EXECUTABLE -z $TMP/error3.zen
    assert_line --partial "Zencode line 10 pattern not found (when): and this should fail or 'rule unknown ignore'"
}

@test "JSON duplicate keys are rejected" {
    cat <<EOF > $TMP/duplicate_keys.zen
rule check version 1.0.0
Scenario credential: issuer keygen
Given I have a 'string dictionary' named 'root'
Then print the 'root'
EOF
    cat <<EOF > $TMP/duplicate_keys.json
{
  "root": {
    "k": 1,
    "k": 2
  }
}
EOF
    run $ZENROOM_EXECUTABLE -z -a $TMP/duplicate_keys.json $TMP/duplicate_keys.zen
    assert_failure
    assert_line --partial "duplicate key 'k'"
}
