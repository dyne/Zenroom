load ../bats_setup
load ../bats_zencode
SUBDOC=cookbook_intro

@test "create ecdh keyring" {
    cat <<EOF | zexe alice_keygen.zen
Scenario 'ecdh': Create the keyring
Given that I am known as 'Alice'
When I create the ecdh key
Then print my keyring
EOF
    save_output alice_keyring.json
}

@test "random array generation" {
    cat <<EOF | zexe randomArrayGeneration.zen
Given nothing
When I create the array of '16' random objects of '32' bits
Then print all data
EOF
    save_output myFirstRandomArray.json
}

@test "random array rename" {
    cat <<EOF | zexe randomArrayRename.zen
Given nothing
When I create the array of '16' random objects of '32' bits
And I rename the 'array' to 'myArray'
Then print all data
EOF
}

@test "multiple random array" {
    cat <<EOF | zexe randomArrayMultiple.zen
Given nothing
When I create the array of '2' random objects of '8' bits
And I rename the 'array' to 'myTinyArray'
And I create the array of '4' random objects of '32' bits
And I rename the 'array' to 'myAverageArray'
And I create the array of '8' random objects of '128' bits
And I rename the 'array' to 'myBigFatArray'
Then print all data 
EOF
    save_output myArrays.json
}
