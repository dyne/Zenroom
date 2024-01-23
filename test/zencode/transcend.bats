load ../bats_setup
load ../bats_zencode
SUBDOC=transcend

@test "Create secret key" {
    cat <<EOF | zexe keygen.zen
Scenario transcend
Given nothing
When I create the transcend key
Then print the keyring
EOF
    save_output 'SSkey.json'
    assert_output '{"keyring":{"transcend":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA="}}'
}

@test "Create transcend ciphertext" {
    cat << EOF | save_asset encode_message.data
{
    "message": "bring me a coffe, please. Maybe two"
}
EOF
	cat << EOF | zexe encode_message.zen SSkey.json encode_message.data
	Scenario transcend
	Given I have a 'keyring'
    and I have a 'string' named 'message'
	When I create the random 'nonce'
	and I create the transcend ciphertext of 'message'
	Then print the 'transcend ciphertext'
EOF
	save_output 'message_ciphertext.json'
	assert_output '{"transcend_ciphertext":{"k":"Lp377tyx75tXJECe1sHwnLyFxmZs6L56Ru0P+JlCbDvlexIFHtkE9SP8HaW4qLV5+tDbffmj2+EBHf7o9vNOglghjA==","n":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA=","p":"Ft5EQTbjYOBvEphqBq9smOoRRt2SzVOa+yBIttEQf7CHCXtPHroI0tnrZENeQyDoQp4Q9nr9OnZunsprcwJm8J0xww=="}}'
}


@test "Create transcend cleartext and response (using cache)" {
	cat << EOF | zexe decode_message.zen SSkey.json message_ciphertext.json
	Scenario transcend
	Given I have a 'keyring'
	and I have a 'base64 dictionary' named 'transcend ciphertext'
	When I create the transcend cleartext of 'transcend ciphertext'
	and I create the random 'response'
	and I create the transcend response with 'response'
	Then print the 'transcend cleartext' as 'string'
	and print the 'transcend response'
	and print the 'transcend ciphertext'
EOF
	save_output 'message_and_response.json'
	assert_output '{"transcend_ciphertext":{"k":"Lp377tyx75tXJECe1sHwnLyFxmZs6L56Ru0P+JlCbDvlexIFHtkE9SP8HaW4qLV5+tDbffmj2+EBHf7o9vNOglghjA==","n":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA=","p":"Ft5EQTbjYOBvEphqBq9smOoRRt2SzVOa+yBIttEQf7CHCXtPHroI0tnrZENeQyDoQp4Q9nr9OnZunsprcwJm8J0xww=="},"transcend_cleartext":"bring me a coffe, please. Maybe two","transcend_response":"dn9SRJuGgu4eeVxWnn80aOoRRt2SzVOa+yBIttEQf7DlexJ8oVoHiGjpml6KA0quqW+/ffmj2+EBHf7o9vNOglghjA=="}'
}

@test "Create a transcend response from ciphertext" {
	cat << EOF | zexe encode_response.zen SSkey.json message_ciphertext.json
	Scenario transcend
	Given I have a 'keyring'
	and I have a 'base64 dictionary' named 'transcend ciphertext'
	When I set 'response' to 'this is my response' as 'string'
	and I create the transcend response of 'transcend ciphertext' with 'response'
	Then print the 'transcend response'
EOF
	save_output 'message_response.json'
	assert_output '{"transcend_response":"dn9SRJuGgu4eeVxWnn80aOoRRt2SzVOa+yBIttEQf7DlexIheZplt/mKRCAxJUaNGtYJ6UD1Okwtx9h4bxNzv4c1yQ=="}'
}

@test "Decrypt a tainted ciphertext (fail)" {
	cat << EOF | save_asset tainted_ciphertext.json
{
    "transcend_ciphertext":{
        "k":"cEFesPf7cmzbs30YDi/4V591AgvEm/0C8XvWkwdOUjnk5nekfTy84h1wZ+HNRSZBLSHFW45Tl51+cm3VF4UUmFWFUCmQp/xkHUfZruoMtaIEt5swMbCPC00IlnO0P9qXkUmjtdzdkP7gLZAQ3Am4n1VQwGgLnEDImeDQ0F9OgBmtey6Q/XwuN9IULQQuJT9cai89NFbwdC02k4Q9nUzUhA==",
        "n":"0J2vZQ==",
        "p":"8Isvkbst2a0CoxJYhMrKGeRei2clhPqfdi5LBFoM3+K5PrfGQq3fPGPLQe3ugveeysf6yXwSNOScjv6YRTRzuAKnKMQxXQZ4sVEyz+ue+lq4Ml1WXVgxcQvlmYstfbasdDKxlKVH9UkZp9Qw7Sz+EjvuoPIUAAnb2V5X2lUug8mELzVS3LdMGpwA2WcMe68MNhZTWiV5f2DWfCboNW0PTg=="
    }
}
EOF
	cat << EOF | save_asset encode_response.zen
	Scenario transcend
	Given I have a 'keyring'
	and I have a 'base64 dictionary' named 'transcend ciphertext'
	When I set 'response' to 'tainted love' as 'string'
	and I create the transcend response of 'transcend ciphertext' with 'response'
	Then print the 'transcend response'
	and print the 'transcend ciphertext'
EOF
	run $ZENROOM_EXECUTABLE -z -k SSkey.json -a tainted_ciphertext.json encode_response.zen
    assert_line --partial "Invalid authentication of transcend ciphertext"
}

@test "Create a transcend cleartext from response to ciphertext" {
	cat << EOF | zexe decode_response.zen SSkey.json message_and_response.json
	Scenario transcend
	Given I have a 'keyring'
	and I have a 'base64 dictionary' named 'transcend ciphertext'
	and I have a 'base64' named 'transcend response'
	When I create the transcend cleartext of response 'transcend response' to 'transcend ciphertext'
	Then print the 'transcend cleartext'
EOF
	save_output 'cleartext_response.json'
	assert_output '{"transcend_cleartext":"AAAAXdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA="}'
}

@test "Decrypt a tainted response (fail)" {
    cat << EOF | save_asset tainted_response.json
{
    "transcend_response":"fn9SRJuGgu4eeVxWnn80aOoRRt2SzVOa+yBIttEQf7DlexIheZplt/mKRCAxJUaNGtYJ6UD1Okwtx9h4bxNzv4c1yQ==",
    "transcend_ciphertext": {
        "k":"Lp377tyx75tXJECe1sHwnLyFxmZs6L56Ru0P+JlCbDvlexIFHtkE9SP8HaW4qLV5+tDbffmj2+EBHf7o9vNOglghjA==",
        "n":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA=",
        "p":"Ft5EQTbjYOBvEphqBq9smOoRRt2SzVOa+yBIttEQf7CHCXtPHroI0tnrZENeQyDoQp4Q9nr9OnZunsprcwJm8J0xww=="
    }
}
EOF
	cat << EOF | save_asset decode_response.zen
	Scenario transcend
	Given I have a 'keyring'
	and I have a 'base64 dictionary' named 'transcend ciphertext'
	and I have a 'base64' named 'transcend response'
	When I create the transcend cleartext of response 'transcend response' to 'transcend ciphertext'
	Then print the 'transcend cleartext' as 'string'
EOF
    run $ZENROOM_EXECUTABLE -z -k SSkey.json -a tainted_response.json decode_response.zen
	assert_line --partial 'Invalid authentication of transcend response'
}

#TODO: check that both responses from previous tests are the same
