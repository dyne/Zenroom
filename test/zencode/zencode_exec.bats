load ../bats_setup
load ../bats_zencode

@test "Execute zencode-exec with all stdin inputs" {

	# empty conf
	echo > zencode_exec_stdin

	cat <<EOF | base64 -w0 >> zencode_exec_stdin
rule check version 3.0.0
Scenario 'ecdh': Bob verifies the signature from Alice
# Here we load the pubkey we'll verify the signature against
Given I have a 'public key' from 'Alice'
# Here we load the objects to be verified
Given I have a 'string' named 'myMessage'
Given I have a 'string array' named 'myStringArray'

# Here we load the objects's signatures
Given I have a 'signature' named 'myStringArray.signature'
Given I have a 'signature' named 'myMessage.signature'

# Here we perform the verifications
When I verify the 'myMessage' has a ecdh signature in 'myMessage.signature' by 'Alice'
When I verify the 'myStringArray' has a ecdh signature in 'myStringArray.signature' by 'Alice'

# Here we print out the result: if the verifications succeeded, a string will be printed out
# if the verifications failed, Zenroom will throw an error
Then print the string 'Zenroom certifies that signatures are all correct!'
Then print the 'myMessage'

EOF
	echo >> zencode_exec_stdin
	cat <<EOF | base64 -w0 >> zencode_exec_stdin
{
	"Alice": {
		"public_key": "BBCQg21VcjsmfTmNsg+I+8m1Cm0neaYONTqRnXUjsJLPa8075IYH+a9w2wRO7rFM1cKmv19Igd7ntDZcUvLq3xI="
	}
}
EOF
	echo >> zencode_exec_stdin

	cat <<EOF | base64 -w0 >> zencode_exec_stdin
{
	"myMessage": "Dear Bob, your name is too short, goodbye - Alice.",
	"myMessage.signature": {
		"r": "vWerszPubruWexUib69c7IU8Dxy1iisUmMGC7h7arDw=",
		"s": "nSjxT+JAP56HMRJjrLwwB6kP+mluYySeZcG8JPBGcpY="
	},
	"myStringArray": [
		"Hello World! This is my string array, element [0]",
		"Hello World! This is my string array, element [1]",
		"Hello World! This is my string array, element [2]"
	],
	"myStringArray.signature": {
		"r": "B8qrQqYSWaTf5Q16mBCjY1tfsD4Cf6ZSMJTHCCV8Chg=",
		"s": "S1/Syca6+XozVr5P9fQ6/AkQ+fJTMfwc063sbKmZ5B4="
	}
}
EOF
	echo >> zencode_exec_stdin

	cat zencode_exec_stdin | ${TR}/zencode-exec > $TMP/out
	save_output verified.json
	assert_output '{"myMessage":"Dear Bob, your name is too short, goodbye - Alice.","output":["Zenroom_certifies_that_signatures_are_all_correct!"]}'
}

@test "Check heap dump in zencode-exec is compact (base64)" {

	echo "rngseed=hex:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" > zencode_exec_stdin

	cat <<EOF | base64 -w0 >> zencode_exec_stdin
Given nothing
When I create the random object of '256' bits
and debug
Then print the 'random object'

EOF
	echo >> zencode_exec_stdin

	echo >> zencode_exec_stdin # keys
	echo >> zencode_exec_stdin # data

	echo > $TMP/out
	cat zencode_exec_stdin | ${TR}/zencode-exec 2>>full.json 1>>full.json

	awk '/HEAP:/ {print $4}' full.json | sed 's/",//' | base64 -d > $TMP/out
    save_output heap.json
	assert_output '{"CODEC":{"random_object":{"encoding":"def","name":"random_object","zentype":"e"}},"GIVEN_data":[],"GIVEN_keys":[],"THEN":[],"WHEN":{"random_object":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA="}}'
	>&3 echo
	awk '/TRACE:/ {print $4}' full.json | sed 's/",//' | base64 -d > $TMP/out
	save_output trace.json
	assert_output '["Given nothing","When I create the random object of '"'"'256'"'"' bits","and debug"]'
}
