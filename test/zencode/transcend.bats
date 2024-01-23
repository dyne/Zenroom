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
	cat << EOF | zexe encode_message.zen SSkey.json
	Scenario transcend
	Given I have a 'keyring'
	When I create the random object of '128' bytes
	and I create the random 'nonce'
	and I create the transcend ciphertext of 'random object'
	Then print the 'transcend ciphertext'
EOF
	save_output 'message_ciphertext.json'
	assert_output '{"transcend_ciphertext":{"k":"buP/70PZzmgxGQd41Hv8C591AgvEm/0C8XvWkwdOUjnk5nekfTy84h1wZ+HNRSZBLSHFW45Tl51+cm3VF4UUmFWFUCmQp/xkHUfZruoMtaIEt5swMbCPC00IlnO0P9qXkUmjtdzdkP7gLZAQ3Am4n1VQwGgLnEDImeDQ0F9OgBmz2Y/PSV6SMzi+V2T0cTsAai89NFbwdC02k4Q9nUzUhA==","n":"DR92VSF2l3Az1K1+LyWO13Jk1eBPmuhhPT2NbpxGgsk=","p":"4eR8k+ggV9/KWIHOmmc2WeRei2clhPqfdi5LBFoM3+K5PrfGQq3fPGPLQe3ugveeysf6yXwSNOScjv6YRTRzuAKnKMQxXQZ4sVEyz+ue+lq4Ml1WXVgxcQvlmYstfbasdDKxlKVH9UkZp9Qw7Sz+EjvuoPIUAAnb2V5X2lUug8mELzVS3LdMGpwA2WcMe68MNhZTWiV5f2DWfCboNW0PTg=="}}'

}


@test "Create transcend cleartext and response (using cache)" {
	cat << EOF | zexe decode_message.zen SSkey.json message_ciphertext.json
	Scenario transcend
	Given I have a 'keyring'
	and I have a 'base64 dictionary' named 'transcend ciphertext'
	When I create the transcend cleartext of 'transcend ciphertext'
	and I create the random 'response'
	and I create the transcend response with 'response'
	Then print the 'transcend cleartext'
	and print the 'transcend response'
	and print the 'transcend ciphertext'
EOF
	save_output 'message_and_response.json'
	assert_output '{"transcend_ciphertext":{"k":"buP/70PZzmgxGQd41Hv8C591AgvEm/0C8XvWkwdOUjnk5nekfTy84h1wZ+HNRSZBLSHFW45Tl51+cm3VF4UUmFWFUCmQp/xkHUfZruoMtaIEt5swMbCPC00IlnO0P9qXkUmjtdzdkP7gLZAQ3Am4n1VQwGgLnEDImeDQ0F9OgBmz2Y/PSV6SMzi+V2T0cTsAai89NFbwdC02k4Q9nUzUhA==","n":"DR92VSF2l3Az1K1+LyWO13Jk1eBPmuhhPT2NbpxGgsk=","p":"4eR8k+ggV9/KWIHOmmc2WeRei2clhPqfdi5LBFoM3+K5PrfGQq3fPGPLQe3ugveeysf6yXwSNOScjv6YRTRzuAKnKMQxXQZ4sVEyz+ue+lq4Ml1WXVgxcQvlmYstfbasdDKxlKVH9UkZp9Qw7Sz+EjvuoPIUAAnb2V5X2lUug8mELzVS3LdMGpwA2WcMe68MNhZTWiV5f2DWfCboNW0PTg=="},"transcend_cleartext":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyBXInjtofr6HKwW62EBkk/4vIXGZmzovnpG7Q/4mUJsO+V7EiF5mmW3+YpEIDElRo1uvmCaH5xJE0C+hwoKYAPQHw5oLUCNZFaBkZy0+6GEjy5du448E+Ms3dIvuzRnWQM=","transcend_response":"nFOfpFkgFdBlWbVhVikBfxXJV0KSssWfmmSVZwyTECDk5nekfTy84h1wZ+HNRSZBLSHFW45Tl51+cm3VF4UUmFWFUCmQp/xkHUfZruoMtaIEt5swMbCPC00IlnO0P9qXkUmjtdzdkP7gLZAQ3Am4n1VQwGgLnEDImeDQ0F9OgBnG+Z0do6tLkmMqY9/UHfpc/63XRusrPzXpUpoeU7sxbQ=="}'
}

@test "Create a transcend response from ciphertext" {
	cat << EOF | zexe encode_response.zen SSkey.json message_ciphertext.json
	Scenario transcend
	Given I have a 'keyring'
	and I have a 'base64 dictionary' named 'transcend ciphertext'
	When I create the random 'response'
	and I create the transcend response of 'transcend ciphertext' with 'response'
	Then print the 'transcend response'
EOF
	save_output 'message_response.json'
	assert_output '{"transcend_response":"nFOfpFkgFdBlWbVhVikBfxXJV0KSssWfmmSVZwyTECDk5nekfTy84h1wZ+HNRSZBLSHFW45Tl51+cm3VF4UUmFWFUCmQp/xkHUfZruoMtaIEt5swMbCPC00IlnO0P9qXkUmjtdzdkP7gLZAQ3Am4n1VQwGgLnEDImeDQ0F9OgBnG+Z0do6tLkmMqY9/UHfpc/63XRusrPzXpUpoeU7sxbQ=="}'
}

@test "Create a false transcend response from tainted ciphertext" {
	echo '{"transcend_ciphertext":{"k":"cEFesPf7cmzbs30YDi/4V591AgvEm/0C8XvWkwdOUjnk5nekfTy84h1wZ+HNRSZBLSHFW45Tl51+cm3VF4UUmFWFUCmQp/xkHUfZruoMtaIEt5swMbCPC00IlnO0P9qXkUmjtdzdkP7gLZAQ3Am4n1VQwGgLnEDImeDQ0F9OgBmtey6Q/XwuN9IULQQuJT9cai89NFbwdC02k4Q9nUzUhA==","n":"0J2vZQ==","p":"8Isvkbst2a0CoxJYhMrKGeRei2clhPqfdi5LBFoM3+K5PrfGQq3fPGPLQe3ugveeysf6yXwSNOScjv6YRTRzuAKnKMQxXQZ4sVEyz+ue+lq4Ml1WXVgxcQvlmYstfbasdDKxlKVH9UkZp9Qw7Sz+EjvuoPIUAAnb2V5X2lUug8mELzVS3LdMGpwA2WcMe68MNhZTWiV5f2DWfCboNW0PTg=="}}' > tainted_ciphertext.json
	cat << EOF | zexe encode_response.zen SSkey.json tainted_ciphertext.json
	Scenario transcend
	Given I have a 'keyring'
	and I have a 'base64 dictionary' named 'transcend ciphertext'
	When I set 'response' to 'tainted love' as 'string'
	and I create the transcend response of 'transcend ciphertext' with 'response'
	Then print the 'transcend response'
	and print the 'transcend ciphertext'
EOF
	save_output 'tainted_response.json'
	assert_output '{"transcend_ciphertext":{"k":"cEFesPf7cmzbs30YDi/4V591AgvEm/0C8XvWkwdOUjnk5nekfTy84h1wZ+HNRSZBLSHFW45Tl51+cm3VF4UUmFWFUCmQp/xkHUfZruoMtaIEt5swMbCPC00IlnO0P9qXkUmjtdzdkP7gLZAQ3Am4n1VQwGgLnEDImeDQ0F9OgBmtey6Q/XwuN9IULQQuJT9cai89NFbwdC02k4Q9nUzUhA==","n":"0J2vZQ==","p":"8Isvkbst2a0CoxJYhMrKGeRei2clhPqfdi5LBFoM3+K5PrfGQq3fPGPLQe3ugveeysf6yXwSNOScjv6YRTRzuAKnKMQxXQZ4sVEyz+ue+lq4Ml1WXVgxcQvlmYstfbasdDKxlKVH9UkZp9Qw7Sz+EjvuoPIUAAnb2V5X2lUug8mELzVS3LdMGpwA2WcMe68MNhZTWiV5f2DWfCboNW0PTg=="},"transcend_response":"zonSH3eyWk9OtXFNDczSxRY9NYj7byXQRwyqZ0lOcXrk5nekfTy84h1wZ+HNRSZBLSHFW45Tl51+cm3VF4UUmFWFUCmQp/xkHUfZruoMtaIEt5swMbCPC00IlnO0P9qXkUmjtdzdkP7gLZAQ3Am4n1VQwGgLnEDImeDQ0F9OgBmtey6Q/XwuN9IULQQuJT9cai89NCKRHUNC9uBiBFmpYQ=="}'
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
	assert_output '{"transcend_cleartext":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAXdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA="}'
}

@test "Create a false transcend cleartext from tainted response to ciphertext" {
	cat << EOF | zexe decode_response.zen SSkey.json tainted_response.json
	Scenario transcend
	Given I have a 'keyring'
	and I have a 'base64 dictionary' named 'transcend ciphertext'
	and I have a 'base64' named 'transcend response'
	When I create the transcend cleartext of response 'transcend response' to 'transcend ciphertext'
	Then print the 'transcend cleartext' as 'string'
EOF
	save_output 'cleartext_response.json'
	assert_output '{"transcend_cleartext":"\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000tainted_love"}'
}

#TODO: check that both responses from previous tests are the same
