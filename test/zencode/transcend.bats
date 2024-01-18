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
	assert_output '{"transcend_ciphertext":{"k":"cEFesPf7cmzbs30YDi/4V591AgvEm/0C8XvWkwdOUjnk5nekfTy84h1wZ+HNRSZBLSHFW45Tl51+cm3VF4UUmFWFUCmQp/xkHUfZruoMtaIEt5swMbCPC00IlnO0P9qXkUmjtdzdkP7gLZAQ3Am4n1VQwGgLnEDImeDQ0F9OgBmtey6Q/XwuN9IULQQuJT9cai89NFbwdC02k4Q9nUzUhA==","n":"DR92VSF2l3Az1K1+LyWO13Jk1eBPmuhhPT2NbpxGgsk=","p":"8Isvkbst2a0CoxJYhMrKGeRei2clhPqfdi5LBFoM3+K5PrfGQq3fPGPLQe3ugveeysf6yXwSNOScjv6YRTRzuAKnKMQxXQZ4sVEyz+ue+lq4Ml1WXVgxcQvlmYstfbasdDKxlKVH9UkZp9Qw7Sz+EjvuoPIUAAnb2V5X2lUug8mELzVS3LdMGpwA2WcMe68MNhZTWiV5f2DWfCboNW0PTg=="}}'
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
	assert_output '{"transcend_ciphertext":{"k":"cEFesPf7cmzbs30YDi/4V591AgvEm/0C8XvWkwdOUjnk5nekfTy84h1wZ+HNRSZBLSHFW45Tl51+cm3VF4UUmFWFUCmQp/xkHUfZruoMtaIEt5swMbCPC00IlnO0P9qXkUmjtdzdkP7gLZAQ3Am4n1VQwGgLnEDImeDQ0F9OgBmtey6Q/XwuN9IULQQuJT9cai89NFbwdC02k4Q9nUzUhA==","n":"DR92VSF2l3Az1K1+LyWO13Jk1eBPmuhhPT2NbpxGgsk=","p":"8Isvkbst2a0CoxJYhMrKGeRei2clhPqfdi5LBFoM3+K5PrfGQq3fPGPLQe3ugveeysf6yXwSNOScjv6YRTRzuAKnKMQxXQZ4sVEyz+ue+lq4Ml1WXVgxcQvlmYstfbasdDKxlKVH9UkZp9Qw7Sz+EjvuoPIUAAnb2V5X2lUug8mELzVS3LdMGpwA2WcMe68MNhZTWiV5f2DWfCboNW0PTg=="},"transcend_cleartext":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyBXInjtofr6HKwW62EBkk/4vIXGZmzovnpG7Q/4mUJsO+V7EiF5mmW3+YpEIDElRo1uvmCaH5xJE0C+hwoKYAPQ6UasczRKmme8SOUwelXq2y5du448E+Ms3dIvuzRnWQM=","transcend_response":"BVieo98xOGThUgd1lZAKldeUPPfUGI8+DoNmh0pBGtPk5nekfTy84h1wZ+HNRSZBLSHFW45Tl51+cm3VF4UUmFWFUCmQp/xkHUfZruoMtaIEt5swMbCPC00IlnO0P9qXkUmjtdzdkP7gLZAQ3Am4n1VQwGgLnEDImeDQ0F9OgBkwsVlD12y1o17zGltV6ZQI/63XRusrPzXpUpoeU7sxbQ=="}'
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
	assert_output '{"transcend_response":"BVieo98xOGThUgd1lZAKldeUPPfUGI8+DoNmh0pBGtPk5nekfTy84h1wZ+HNRSZBLSHFW45Tl51+cm3VF4UUmFWFUCmQp/xkHUfZruoMtaIEt5swMbCPC00IlnO0P9qXkUmjtdzdkP7gLZAQ3Am4n1VQwGgLnEDImeDQ0F9OgBkwsVlD12y1o17zGltV6ZQI/63XRusrPzXpUpoeU7sxbQ=="}'
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

#TODO: check that both responses from previous tests are the same
