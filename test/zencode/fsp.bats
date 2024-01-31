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
	When I create the random 'fsp nonce'
	and I create the fsp ciphertext of 'message'
	Then print the 'fsp ciphertext'
EOF
	save_output 'message_ciphertext.json'
	assert_output '{"fsp_ciphertext":{"k":"MLFZQ9dstaNe8xpbVemUCP+t10brKz816VKaHlO7MW3GY6cZNNfVx5k8hDfSw76denOm8/meGfYngrq24HWHzllXs64z4WThkGJD6QVV4T9rBoZK6VgayMh28GdYPwbdWAFPsPJYpLpUXE0HURsar4ded50A/0Y3RT+y0nUV9I3GJT2mtCZuj/F3XNy7gEEyK4eUlJDtch2USxa3szwDJBnOSI7scDzlY7wlHM9oqxKDVT3dQ/0kMYegRvJlZXNBmQlf7BRNEkSzJSMOsDkP0KY3h8y8qhXMh49lY2G4iMJ2BWk3QKetaOwToJmtSA4MewXLJ1qENxZR2w/9XsptvQ==","n":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA=","p":"NJqJPHzOmR7LOeMIK4q5aHctjrE1Suwgbs96Ni8qGyzi2QJbfzHZGffR7KFONBV5J1jpj9Z4pUNEcO6vYUIt7OsYJhK+UWB/LHvOlPw64DAsjuyHVp/+s2tqfGqZl0HBIQQI8DDYy4Pvs/YYELj6s39F7XK3NEbMNnPiO+APXlB1it7L+otDfZ/jnQUlzUKOjq84f0hvWcthX1Z/9dX1/+zDW1zmYgw8hwKHviTmBFRcinifpsgfc9uJvXn8AFodzRTF/Z5pqPyPeE1fX3Un3b9ZE1PVl3+/i9GQLvv6eksFMRSDMdTMKGu2uzjLvzX4jIfyPZSvl60w6p94bl4vxQ=="}}'
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
	assert_output '{"fsp_ciphertext":{"k":"MLFZQ9dstaNe8xpbVemUCP+t10brKz816VKaHlO7MW3GY6cZNNfVx5k8hDfSw76denOm8/meGfYngrq24HWHzllXs64z4WThkGJD6QVV4T9rBoZK6VgayMh28GdYPwbdWAFPsPJYpLpUXE0HURsar4ded50A/0Y3RT+y0nUV9I3GJT2mtCZuj/F3XNy7gEEyK4eUlJDtch2USxa3szwDJBnOSI7scDzlY7wlHM9oqxKDVT3dQ/0kMYegRvJlZXNBmQlf7BRNEkSzJSMOsDkP0KY3h8y8qhXMh49lY2G4iMJ2BWk3QKetaOwToJmtSA4MewXLJ1qENxZR2w/9XsptvQ==","n":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA=","p":"NJqJPHzOmR7LOeMIK4q5aHctjrE1Suwgbs96Ni8qGyzi2QJbfzHZGffR7KFONBV5J1jpj9Z4pUNEcO6vYUIt7OsYJhK+UWB/LHvOlPw64DAsjuyHVp/+s2tqfGqZl0HBIQQI8DDYy4Pvs/YYELj6s39F7XK3NEbMNnPiO+APXlB1it7L+otDfZ/jnQUlzUKOjq84f0hvWcthX1Z/9dX1/+zDW1zmYgw8hwKHviTmBFRcinifpsgfc9uJvXn8AFodzRTF/Z5pqPyPeE1fX3Un3b9ZE1PVl3+/i9GQLvv6eksFMRSDMdTMKGu2uzjLvzX4jIfyPZSvl60w6p94bl4vxQ=="},"fsp_cleartext":"bring me a coffe, please. Maybe two","fsp_response":"92beYOHeqomEE+T3zASlwX04mLt3GflMVnbJMT6bNZPlAEF3KIFnxgBhnakDRcw7f2kKLFlu3a+SXFEWEz4a8qiZmK0N4kjHUlyjg0p6jprKDbYgglvVis/xcQtzFARK/FPL8vzsgelEWQuRbUCCYyAGzwX43uaeToWN7BPuCcontRj08eLniqGRwV6kVHPBEbOEvVbLiGd7qPOvwPvzdHfCJZL8xNHsb2PW8KM1kqxZjo8hLfoFgdgQSuv02Ak33upeu1LdfZFS6wcJV2UjDbCqbs1JpeSMgZWBik41UwA2rc60snPo97+JQ84A3EhO4pGZYL9AgPfmosyZnNz2+Q=="}'
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
	assert_output '{"fsp_response":"92beYOHeqomEE+T3zASlwX04mLt3GflMVnbJMT6bNZPlAEF3KIFnxgBhnakDRcw7f2kKLFlu3a+SXFEWEz4a8qiZmK0N4kjHUlyjg0p6jprKDbYgglvVis/xcQtzFARK/FPL8vzsgelEWQuRbUCCYyAGzwX43uaeToWN7BPuCcontRj08eLniqGRwV6kVHPBEbOEvVbLiGd7qPOvwPvzdHfCJZL8xNHsb2PW8KM1kqxZjo8hLfoFgdgQSuv02Ak33upeu1LdfZFS6wcJV2UjDbCqbs1JpeSMgZWBik41UwA2rc60snPo97+JQ84A3EhO4pGZYL9AgPfmosyZnNz2+Q=="}'
}

@test "Decrypt a tainted ciphertext (fail)" {
	cat << EOF | save_asset tainted_ciphertext.json
{"fsp_ciphertext":{"k":"PLFZQ9dstaNe8xpbVemUCP+t10brKz816VKaHlO7MW3GY6cZNNfVx5k8hDfSw76denOm8/meGfYngrq24HWHzllXs64z4WThkGJD6QVV4T9rBoZK6VgayMh28GdYPwbdWAFPsPJYpLpUXE0HURsar4ded50A/0Y3RT+y0nUV9I3GJT2mtCZuj/F3XNy7gEEyK4eUlJDtch2USxa3szwDJBnOSI7scDzlY7wlHM9oqxKDVT3dQ/0kMYegRvJlZXNBmQlf7BRNEkSzJSMOsDkP0KY3h8y8qhXMh49lY2G4iMJ2BWk3QKetaOwToJmtSA4MewXLJ1qENxZR2w/9XsptvQ==","n":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA=","p":"NJqJPHzOmR7LOeMIK4q5aHctjrE1Suwgbs96Ni8qGyzi2QJbfzHZGffR7KFONBV5J1jpj9Z4pUNEcO6vYUIt7OsYJhK+UWB/LHvOlPw64DAsjuyHVp/+s2tqfGqZl0HBIQQI8DDYy4Pvs/YYELj6s39F7XK3NEbMNnPiO+APXlB1it7L+otDfZ/jnQUlzUKOjq84f0hvWcthX1Z/9dX1/+zDW1zmYgw8hwKHviTmBFRcinifpsgfc9uJvXn8AFodzRTF/Z5pqPyPeE1fX3Un3b9ZE1PVl3+/i9GQLvv6eksFMRSDMdTMKGu2uzjLvzX4jIfyPZSvl60w6p94bl4vxQ=="}}
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
{"fsp_ciphertext":{"k":"MLFZQ9dstaNe8xpbVemUCP+t10brKz816VKaHlO7MW3GY6cZNNfVx5k8hDfSw76denOm8/meGfYngrq24HWHzllXs64z4WThkGJD6QVV4T9rBoZK6VgayMh28GdYPwbdWAFPsPJYpLpUXE0HURsar4ded50A/0Y3RT+y0nUV9I3GJT2mtCZuj/F3XNy7gEEyK4eUlJDtch2USxa3szwDJBnOSI7scDzlY7wlHM9oqxKDVT3dQ/0kMYegRvJlZXNBmQlf7BRNEkSzJSMOsDkP0KY3h8y8qhXMh49lY2G4iMJ2BWk3QKetaOwToJmtSA4MewXLJ1qENxZR2w/9XsptvQ==","n":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA=","p":"NJqJPHzOmR7LOeMIK4q5aHctjrE1Suwgbs96Ni8qGyzi2QJbfzHZGffR7KFONBV5J1jpj9Z4pUNEcO6vYUIt7OsYJhK+UWB/LHvOlPw64DAsjuyHVp/+s2tqfGqZl0HBIQQI8DDYy4Pvs/YYELj6s39F7XK3NEbMNnPiO+APXlB1it7L+otDfZ/jnQUlzUKOjq84f0hvWcthX1Z/9dX1/+zDW1zmYgw8hwKHviTmBFRcinifpsgfc9uJvXn8AFodzRTF/Z5pqPyPeE1fX3Un3b9ZE1PVl3+/i9GQLvv6eksFMRSDMdTMKGu2uzjLvzX4jIfyPZSvl60w6p94bl4vxQ=="},"fsp_response":"Z2beYOHeqomEE+T3zASlwX04mLt3GflMVnbJMT6bNZPlAEF3KIFnxgBhnakDRcw7f2kKLFlu3a+SXFEWEz4a8qiZmK0N4kjHUlyjg0p6jprKDbYgglvVis/xcQtzFARK/FPL8vzsgelEWQuRbUCCYyAGzwX43uaeToWN7BPuCcontRj08eLniqGRwV6kVHPBEbOEvVbLiGd7qPOvwPvzdHfCJZL8xNHsb2PW8KM1kqxZjo8hLfoFgdgQSuv02Ak33upeu1LdfZFS6wcJV2UjDbCqbs1JpeSMgZWBik41UwA2rc60snPo97+JQ84A3EhO4pGZYL9AgPfmosyZnNz2+w=="}
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
