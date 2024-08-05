load ../bats_setup
load ../bats_zencode
SUBDOC=rsa

@test "Generate asymmetric keys for Alice and Bob" {

# RNG gathering for RSA takes too long, so we hard-code keys

#     cat <<EOF | rngzexe alice_rsa_keygen.zen
# Scenario rsa
# Given I am known as 'Alice'
# When I create the keyring
# and I create the rsa key
# Then print my 'keyring'
# EOF
    echo '{"Alice":{"keyring":{"rsa":"4f2d/behINr5MK2Qtz6cuqoFzENRYrqz+1pswBaG8H3FpAV07prGsvzWgSrzaymNPE235efQlFmMw6Q92JgtnTpRlf1MdkH/JiuB7f17rkT6UKrUJHSlxN+DKqxON4nSnGKI8nrfvmhspmxrwGD984JhPEukH+uMC+q5nEAmI3/wmY/zBAS3xfIZnCLvxebjJHcxsw3y7s9v+FPBboBFB0du1HYxHQy1yxNgL0s0Y/PXhJhvjEh1QB62J8rinXYjzpRf/tRikmkw098PMvSmRQzI32dQYGZLXYVo1udnUvzERCRxogWJC7Un4g5P1/jX505HborkBk0L8yRXrs19h6EgJobvnyKVfzYF7fF8wj9b7KaQWUrZyygR1R0v7jSe6TPMILvos2hDkBFne9jgCD0kEyOBFwosTTOsPxvSDpB4Ov2hYJ56xSBsb6Lz7Hwjq0qe9IAB/+/vbMlNpbzlZ6E0otFZEtYFm9+Xg7DTgf6fw9gGXv4prFFw1KMkQ/8PibnFFf0JnAhKhz1Z+16RyZiCzrCv6KlDZksm2qbwUX2cqljIzA1TsgqEu/avBWf82e4vOd3PJvPUULgp1HQIfYWC6Q8QiK7IJ1ySRrwKVZGS0g8rOB0KAwNb7s83GB0lVyPlpYm7BSQMoH1djb90kvwLwPkeGKNCsQmCaBidYSdjniF7yutbCUuZOpk1PYNnATWnEfGZPMXDwdt4XTXEYxyxLbqax11ZXvzLWXyNu3ZHo9axoJsgGc1kHE0q4gIRcbivDkYbRwJK+BjBKODRNBTHZFY5b7X277PpJqUf9EADsae+g42HaI6kWdyxo8+t/MYSByHk9Db6tdB14Q0uzuHnPz4XgmDj/9FsMzZQnXN5CpW84SQ6QvSPmZQFusMy7zkarLL/pC+qwfK/Rj5k5QMWrv9U7kfJKQCQz+1PDdnA4UTjlwmQko/0hTo08wUsIPOXDvquU8lbA0jwmnbAbS2zAAGbMydzIrre+gIWKNo7WxU/1Dep02K2HkoMgwaXZtusXKWptB01iVo9rNSU+HeJWkd6CTOB4oGHx8sqSMNNYfikyPBjX2MKHGIwiKF0APv/j8G/4ImpexwxaWQuUgG+vtz/XgxHvUwb9C29QP5QQiG5OeKM7TGuA9AixrS39AwzCGvRf3kzKYiC1CYhrVd2YXinuZ8G1zKtO7xSAAh+Rm5PfCpfRle1f+/qbVOqG0ceBWM2pp9VNRKHsNxnWUXi5SzCPpu4Y8iaaX8Pd3PN96SET1oHps5Z/UcOzkgBQXLxruFCMDmsDwd+Slpah8Tvfil79+XFSKaui+/C4BBPUaYvh/4w6PN6nK1VaOxVTLuAJEgXOFnBxK1QIK6PLzm2of+3v1p3EpqOwW6SrLrIoFrnkL0NsCnAZZ8Y+S4GCZSHkoBe1OlVoW1OG2CW2/gX4boXbsWmKn1Z4OxVRAGJBWINA0QdxoQSaCKaddnDaE8yvhNZqaF44hdldEWcR9zoA1KIZzDEh34pgWxx5nA0pDRzdZ7HmpRsawqahHEFIk574CX2q2m9pk5MiiPzu+veFK6ekeZFbtVS+cP+6CdxbvzgcTtptLEJaN5sR/yZmIt0G3R72Lynvtx/NHmJ6fyf2IFJEdC9qCsUx09OhAW7OQgJv9xJGfgKrztU2xVDam/x0oYCfs5/RE0bW8CqgwVlyurmau7l76B6cSJ/bT0="}}}' > $TMP/out
    save_output alice_rsa_keys.json


    cat << EOF | zexe alice_rsa_pubkey.zen alice_rsa_keys.json
Scenario rsa
Given I am known as 'Alice'
Given I have my 'keyring'
When I create the rsa public key
Then print my 'rsa public key'
EOF
    save_output alice_rsa_pubkey.json

# RNG gathering for RSA takes too long, so we hard-code keys
#     cat <<EOF | rngzexe bob_rsa_keygen.zen
# Scenario rsa
# Given I am known as 'Bob'
# When I create the keyring
# and I create the rsa key
# Then print my 'keyring'
# EOF
    echo '{"Bob":{"keyring":{"rsa":"zAqNWdMu1MHcfBUDBU3pFdIY1o6GEG0K+nYiC8Nxi1nmL1jNb+pg/qq9E6JxH3aL6n+jBFQEbuBXRwND7nH2Df3CrIHi8Jn7Xx9gix+ZvGDjxxs1IRq1fg8LdCTT0Q2r2KYHuIuk+clWxF5S7YkKcWiR7+P+3aSO0Zo8pucA1cnWTLbltVtPUVdgdVhXaEIOMLhiNRrjj2BUg7wjRFxxM99UE/gb+Uaq2m4om6mOR/5kYh98pgOKKkyyqy/WcuOrfPP0VOVW82R0eGyO/EgBjMiK3LOD70nWjwFRn1/xYCe37vi8Hykr0xWY8zA+ByNcTnBRndbBvthcA/ZLvqMiX/8MbPD6axQ2DlU5Zd1ccPhYL5gHQTxF0V68idecMfHCB4c4RXCJ3KQusmLyg0MEglmAI8WVcxkIloIMCdTJzSj5XOaXljJg1uuKVxGoKybWIHUlMIUqUURqnOpv8se5lSXoH3V0S5QkjFeGgn45wYdJhMUCsVr/iWjm+W9B+GFlz9rv+1sxRajoZ/9yMREF473ZBWmt1Ubqkk6k8x/z22wTX/SBWeTeaQzriHiOP64Vx+O3KmOsezjIzUz2jRDRecQh14AYxhx/qQJ9NEKFn/etCbKoeJDttE03Q0UTS3IiEyxjdKAzJyWa4nrMlmpzfze90Tq8ig9PpsXyQLKnd4s31dNkd0PjeMFrOxy+gNl93SZq4EmTiSNt8pHSgkM6DPnOjxB4xbyRNAvVqagnIfubyh3D+3HTHZUEm8IlKA5bOcviBREjIiAFocJ7j8Q0JpduTuW1D2gG/Pr3Z3SHSqRx/s0yFRSqPgx+ZAlxcwTmj+UPrmZ6JKPoe7qJOcGivz7jc1Fc1YXZDn4Y3nncz+auMma9fYQ0Ifo+qmdEN7/KoByT8ltFVa8/YtG99yI2VUkHCPLFQ0a12JM0AT0/50lwQhnkeXXX2O9+XMasBtBVxDMrvfwmqSALtiKt6EVXOMc+n9Zq+ItDki9urQ7sSSLjXB0ZgkE2hmJ3uxhzLJUlfcJnuU8RG48n9BfwRX0+awY4uZLiNNEMUtVOdpUa/2U4BxHVE4+2zvIDncyMsq/3giAwA04UycQ1SnybIGQ9GDYU+9LFCaQ8dTnqgtdUJ7svl/O1gAQEvGKBawu2P4sfouhZErY8ShjXZpT5pTnfVlEG+YnBX+hene4+EgEKcyQboI3yd93MxmOKXCe3T/iCemsXQyum3Wfuqn6lLx00FY9cIhjh9XtBe1BsI12owrMUtBDuAuXagH5q1MdBeYiArRguxYfxr7223XZVHXP8E8kr3f86K+Q5olVcgyPncKiioaGMsS1n4SAFCp30kRrQIPEkyPyMas5Qoow4IJ94z6Ro+cpS4QSFV1j23n9WfSaZm1EhMZFHZPH6u+3B9fAd33kabEkAbcIIBZFWsv2okcYMNvfCiz2yFH7ZajgJM0ONbbDp3bsJV7NAR8YHren4z4tDXHqzZsM7vZ80vEwi7f+zVqrRKUiuP0ogaevHdto5+ekCCarPSpoSw/sbIcqzmASTBxgRwORtg/9FxKXrz2btcM56UO6rRiQ/k1yP4ZeoRkyBUXwV9IZ2WjlYHTBXKgOv+S1K1x9VIqt91rpUjIl5TRwPs4GHBFcZXRzjgA0K73Dn9Y4inGnQhkICbCWnC1YfWheEXVy7vjJxiwjj8cIpp6X8lyTfrPJ87NmD3xA="}}}' > $TMP/out
    save_output bob_rsa_keys.json

    cat << EOF | zexe bob_rsa_pubkey.zen bob_rsa_keys.json
Scenario rsa
Given I am known as 'Bob'
Given I have my 'keyring'
When I create the rsa public key
Then print my 'rsa public key'
EOF
    save_output bob_rsa_pubkey.json
}

# @test "check that secret key doesn't changes on pubkey generation" {
#     cat << EOF | zexe keygen_immutable_rsa.zen
# Scenario rsa
# Given I am known as 'Carl'
# When I create the rsa key
# and I copy the 'rsa' from 'keyring' to 'rsa before'
# and I create the rsa public key
# and I copy the 'rsa' from 'keyring' to 'rsa after'
# and I verify 'rsa before' is equal to 'rsa after'
# Then print 'rsa before' as 'hex'
# and print 'rsa after' as 'hex'
# EOF
# }

@test "Alice signs a message" {
    cat <<EOF | zexe sign_rsa_from_alice.zen alice_rsa_keys.json
Rule check version 4.32.6
Scenario rsa
Given that I am known as 'Alice'
and I have my 'keyring'
When I write string 'This is my authenticated message.' in 'message'
and I create the rsa signature of 'message'
Then print the 'message'
and print the 'rsa signature'
EOF
    save_output sign_rsa_alice_output.json
}


@test "Verify a message signed by Alice" {
    cat <<EOF | zexe join_sign_rsa_pubkey.zen sign_rsa_alice_output.json alice_rsa_pubkey.json
Scenario rsa
Given I have a 'rsa public key' in 'Alice'
and I have a 'rsa signature'
and I have a 'string' named 'message'
Then print the 'rsa signature'
and print the 'rsa public key'
and print the 'message'
EOF
    save_output sign_rsa_pubkey.json

    cat <<EOF | zexe verify_rsa_from_alice.zen sign_rsa_alice_output.json alice_rsa_pubkey.json
Rule check version 4.32.6
Scenario rsa
Given I have a 'rsa public key' in 'Alice'
and I have a 'rsa signature'
and I have a 'string' named 'message'
When I verify the 'message' has a rsa signature in 'rsa signature' by 'Alice'
Then print the string 'Signature is valid'
and print the 'message'
EOF
    save_output verify_rsa_alice_signature.json
    assert_output '{"message":"This_is_my_authenticated_message.","output":["Signature_is_valid"]}'
}

@test "Fail verification on a different message" {
    cat <<EOF > wrong_rsa_message.zen
Rule check version 4.32.6
Scenario rsa
Given I have a 'rsa public key'
and I have a 'rsa signature'
When I write string 'This is the wrong message.' in 'message'
and I verify the 'message' has a rsa signature in 'rsa signature' by 'Alice'
Then print the string 'Signature is valid'
and print the 'message'
EOF
    run $ZENROOM_EXECUTABLE -z -a sign_rsa_pubkey.json wrong_rsa_message.zen
    assert_line --partial 'The rsa signature by Alice is not authentic'
}

@test "Fail verification on a different public key" {
    cat <<EOF | rngzexe create_rsa_wrong_pubkey.zen sign_rsa_alice_output.json
Scenario rsa
Given I have a 'rsa signature'
and I have a 'string' named 'message'
When I create the rsa key
and I create the rsa public key
Then print the 'rsa signature'
and print the 'rsa public key'
and print the 'message'
EOF
    save_output wrong_rsa_pubkey.json
    cat <<EOF > wrong_rsa_pubkey.zen
Rule check version 4.32.6
Scenario rsa
Given I have a 'rsa public key'
and I have a 'rsa signature'
and I have a 'string' named 'message'
When I verify the 'message' has a rsa signature in 'rsa signature' by 'Alice'
Then print the string 'Signature is valid'
and print the 'message'
EOF
    run $ZENROOM_EXECUTABLE -z -a wrong_rsa_pubkey.json wrong_rsa_pubkey.zen
    assert_line --partial 'The rsa signature by Alice is not authentic'
}

@test "Alice signs a big file" {
    cat <<EOF | $ZENROOM_EXECUTABLE -z > bigfile_rsa.json
Rule check version 4.32.6
Given Nothing
When I create the random object of '1000000' bytes
and I rename 'random object' to 'bigfile'
Then print the 'bigfile' as 'base64'
EOF

    cat <<EOF | zexe sign_rsa_bigfile.zen alice_rsa_keys.json bigfile_rsa.json
Rule check version 4.32.6
Scenario rsa
Given that I am known as 'Alice'
and I have my 'keyring'
and I have a 'base64' named 'bigfile'
When I create the rsa signature of 'bigfile'
Then print the 'rsa signature'
EOF
    save_output sign_rsa_bigfile_keyring.json
}

@test "Verify a big file signed by Alice" {
    cat <<EOF | zexe join_sign_pubkey.zen sign_rsa_bigfile_keyring.json alice_rsa_pubkey.json
Scenario rsa
Given I have a 'rsa public key' in 'Alice'
and I have a 'rsa signature'
Then print the 'rsa signature'
and print the 'rsa public key'
EOF
    save_output sign_rsa_pubkey_big.json

    cat <<EOF | zexe verify_rsa_from_alice_big.zen sign_rsa_pubkey_big.json bigfile_rsa.json
Rule check version 4.32.6
Scenario rsa
Given I have a 'rsa public key'
and I have a 'rsa signature'
and I have a 'base64' named 'bigfile'
When I verify the 'bigfile' has a rsa signature in 'rsa signature' by 'Alice'
Then print the string 'Bigfile Signature is valid'
EOF
    save_output verify_rsa_alice_signature_big.json
    assert_output '{"output":["Bigfile_Signature_is_valid"]}'
}
