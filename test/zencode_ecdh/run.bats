load ../bats_setup
load ../bats_zencode
SUBDOC=ecdh

# teardown() { rm -rf $TMP }

@test "Zenroom executable is installed" {
    zenroom="$(which zenroom)"
    assert_file_executable "$zenroom"
}

@test "Generate a random password" {
    cat <<EOF | zexe SYM01.zen
Scenario ecdh: Generate a random password
Given nothing
When I create the random 'password'
Then print the 'password'
EOF
#    output=`cat $TMP/out`
    save_output secret.json
    assert_output '{"password":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA="}'
}

@test "Encrypt a message with the password" {
    cat <<EOF | zexe SYM02.zen
Scenario ecdh: Encrypt a message with the password
Given nothing
# only inline input, no KEYS or DATA passed
When I write string 'my secret word' in 'password'
and I write string 'a very short but very confidential message' in 'whisper'
and I write string 'for your eyes only' in 'header'
# header is implicitly used when encrypt
and I encrypt the secret message 'whisper' with 'password'
# anything introduced by 'the' becomes a new variable
Then print the 'secret message'
EOF
    save_output cipher_message.json
}


@test "Decrypt the message with the password" {
    cat <<EOF | zexe SYM03.zen cipher_message.json
Scenario ecdh: Decrypt the message with the password
Given I have a 'secret message'
When I write string 'my secret word' in 'password'
and I decrypt the text of 'secret message' with 'password'
Then print the 'text' as 'string'
and print the 'header' from 'secret message' as 'string'
EOF
     save_output clear_message.json
}
