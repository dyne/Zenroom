load ../bats_setup
load ../bats_zencode
SUBDOC=fsp

@test "Create secret key" {
    cat <<EOF | zexe keygen.zen
Scenario fsp
Given nothing
When I create the fsp key
Then print the keyring
EOF
    save_output 'SSkey.json'
    assert_output '{"keyring":{"fsp":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA="}}'
}

@test "Create fsp ciphertext" {
    cat << EOF | save_asset encode_message.data
{
    "message": "bring me a coffe, please. Maybe two"
}
EOF
	cat << EOF | zexe encode_message.zen SSkey.json encode_message.data
	Scenario fsp
	Given I have a 'keyring'
    and I have a 'string' named 'message'
	When I create the random 'nonce'
	and I create the fsp ciphertext of 'message'
	Then print the 'fsp ciphertext'
EOF
	save_output 'message_ciphertext.json'
	assert_output '{"fsp_ciphertext":{"k":"Lp377tyx75tXJECe1sHwnLyFxmZs6L56Ru0P+JlCbDvlexIFHtkE9SP8HaW4qLV5+tDbffmj2+EBHf7o9vNOglghjA==","n":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA=","p":"Tjzt63HUDZUmT4SiThGobLyFxmZs6L56Ru0P+MGgxZGHCXtPHroI0tnrZENeQyDoQp4Q9nr9OnZunsprcwJm8J0xww=="}}'
}


@test "Create fsp cleartext and response (using cache)" {
	cat << EOF | zexe decode_message.zen SSkey.json message_ciphertext.json
	Scenario fsp
	Given I have a 'keyring'
	and I have a 'fsp ciphertext'
	When I create the fsp cleartext of 'fsp ciphertext'
	and I set 'response' to 'this is my response' as 'string'
	and I create the fsp response with 'response'
	Then print the 'fsp cleartext' as 'string'
	and print the 'fsp response'
	and print the 'fsp ciphertext'
EOF
	save_output 'message_and_response.json'
	assert_output '{"fsp_ciphertext":{"k":"Lp377tyx75tXJECe1sHwnLyFxmZs6L56Ru0P+JlCbDvlexIFHtkE9SP8HaW4qLV5+tDbffmj2+EBHf7o9vNOglghjA==","n":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA=","p":"Tjzt63HUDZUmT4SiThGobLyFxmZs6L56Ru0P+MGgxZGHCXtPHroI0tnrZENeQyDoQp4Q9nr9OnZunsprcwJm8J0xww=="},"fsp_cleartext":"bring me a coffe, please. Maybe two","fsp_response":"Lp377tyx75tXJECe1sHwnLyFxmZs6L56Ru0P+JlCbDvlexIheZplt/mKRCBpx+8nGtYJ6UD1Okwtx9h4bxNzv4c1yQ=="}'
}

@test "Create a fsp response from ciphertext" {
	cat << EOF | zexe encode_response.zen SSkey.json message_ciphertext.json
	Scenario fsp
	Given I have a 'keyring'
	and I have a 'fsp ciphertext'
	When I set 'response' to 'this is my response' as 'string'
	and I create the fsp response of 'fsp ciphertext' with 'response'
	Then print the 'fsp response'
EOF
	save_output 'message_response.json'
	assert_output '{"fsp_response":"Lp377tyx75tXJECe1sHwnLyFxmZs6L56Ru0P+JlCbDvlexIheZplt/mKRCBpx+8nGtYJ6UD1Okwtx9h4bxNzv4c1yQ=="}'
}

@test "Decrypt a tainted ciphertext (fail)" {
	cat << EOF | save_asset tainted_ciphertext.json
{
    "fsp_ciphertext":{
        "k":"Qp377tyx75tXJECe1sHwnLyFxmZs6L56Ru0P+JlCbDvlexIFHtkE9SP8HaW4qLV5+tDbffmj2+EBHf7o9vNOglghjA==",
        "n":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA=",
        "p":"Ajzt63HUDZUmT4SiThGobLyFxmZs6L56Ru0P+MGgxZGHCXtPHroI0tnrZENeQyDoQp4Q9nr9OnZunsprcwJm8J0xww=="
    }
}
EOF
	cat << EOF | save_asset encode_response.zen
	Scenario fsp
	Given I have a 'keyring'
	and I have a 'fsp ciphertext'
	When I set 'response' to 'tainted love' as 'string'
	and I create the fsp response of 'fsp ciphertext' with 'response'
	Then print the 'fsp response'
	and print the 'fsp ciphertext'
EOF
	run $ZENROOM_EXECUTABLE -z -k SSkey.json -a tainted_ciphertext.json encode_response.zen
    assert_line --partial "Invalid authentication of fsp ciphertext"
}

@test "Create a fsp cleartext from response to ciphertext" {
	cat << EOF | zexe decode_response.zen SSkey.json message_and_response.json
	Scenario fsp
	Given I have a 'keyring'
	and I have a 'fsp ciphertext'
	and I have a 'fsp response'
	When I create the fsp cleartext of response 'fsp response' to 'fsp ciphertext'
	Then print the 'fsp cleartext' as 'string'
EOF
	save_output 'cleartext_response.json'
	assert_output '{"fsp_cleartext":"this_is_my_response"}'
}

@test "Decrypt a tainted response (fail)" {
    cat << EOF | save_asset tainted_response.json
{
    "fsp_response":"fn9SRJuGgu4eeVxWnn80aOoRRt2SzVOa+yBIttEQf7DlexIheZplt/mKRCAxJUaNGtYJ6UD1Okwtx9h4bxNzv4c1yQ==",
    "fsp_ciphertext": {
        "k":"Lp377tyx75tXJECe1sHwnLyFxmZs6L56Ru0P+JlCbDvlexIFHtkE9SP8HaW4qLV5+tDbffmj2+EBHf7o9vNOglghjA==",
        "n":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA=",
        "p":"Ft5EQTbjYOBvEphqBq9smOoRRt2SzVOa+yBIttEQf7CHCXtPHroI0tnrZENeQyDoQp4Q9nr9OnZunsprcwJm8J0xww=="
    }
}
EOF
	cat << EOF | save_asset decode_response.zen
	Scenario fsp
	Given I have a 'keyring'
	and I have a 'fsp ciphertext'
	and I have a 'fsp response'
	When I create the fsp cleartext of response 'fsp response' to 'fsp ciphertext'
	Then print the 'fsp cleartext' as 'string'
EOF
    run $ZENROOM_EXECUTABLE -z -k SSkey.json -a tainted_response.json decode_response.zen
	assert_line --partial 'Invalid authentication of fsp response'
}

#TODO: check that both responses from previous tests are the same
