load ../bats_setup
load ../bats_zencode
SUBDOC=given

@test "Given nothing" {
    cat <<EOF | zexe nothing.zen
rule check version 1.0.0
Given nothing
When I create the random object of '256' bits
Then print the 'random object'
EOF
    save_output "nothing.json"
    assert_output '{"random_object":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA="}'
}

@test "Given nothing with something in input" {
    cat <<EOF | save_asset fail_nothing.data
{"a": 1}
EOF
cat <<EOF | save_asset fail_nothing.zen 
rule check version 1.0.0
	 Given nothing
	 When I create the random object of '256' bits
	 Then print the 'random object'
EOF
    run $ZENROOM_EXECUTABLE -z fail_nothing.zen -a fail_nothing.data
    assert_failure
}
@test "Given I have a '' named ''" {
    echo '{ "anykey": "anyvalue" }' | save_asset 'have_anyvalue.data'
    cat <<EOF | zexe have_anyvalue.zen have_anyvalue.data
rule check version 1.0.0
rule input encoding string
rule output encoding string
	 Given I have a 'string' named 'anykey'
	 Then print the 'anykey'
EOF
    save_output "have_anyvalue.json"
    assert_output '{"anykey":"anyvalue"}'
}

@test "Given I have a 'hex' named '' and print string" {
    echo '{ "anykey": "616e7976616c7565" }' | save_asset have_anyhex.data
    cat <<EOF | zexe have_anyhex.zen have_anyhex.data
rule check version 1.0.0
	 Given I have a 'hex' named 'anykey'
	 Then print the 'anykey' as 'string'
EOF

    save_output "have_anyhex.json"
    assert_output '{"anykey":"anyvalue"}'
}

@test "Given I have a 'number' named '' inside ''" {
    cat <<EOF | save_asset 'have_heterogeneous.data'
{
	"myObject":{
		"myNumber":1000,
		"myString":"Hello World!",
		"myArray":[
			"String1",
			"String2",
			"String3"
		]
	}
}
EOF

    cat <<EOF | zexe have_number.zen have_heterogeneous.data
rule check version 1.0.0
	 Given I have a 'number' named 'myNumber' inside 'myObject'
	 Then print the 'myNumber'
EOF

    save_output have_number.json
    assert_output '{"myNumber":1000}'

}

@test "Given I have a valid '' named ''" {
    cat <<EOF | zexe have_valid_arrays.zen have_heterogeneous.data
Given I have a valid 'string array' named 'myArray' in 'myObject'
Given I have a valid 'string' named 'myString' in 'myObject'
Given I have a valid 'number' named 'myNumber' in 'myObject'
When I randomize the 'myArray' array
Then print all data
EOF
    save_output have_valid_arrays.json
    assert_output '{"myArray":["String1","String2","String3"],"myNumber":1000,"myString":"Hello World!"}'
}

@test "Given I have my 'keyring'" {
    cat <<EOF | save_asset have_my.data
{"Andrea":{
      "keyring":{
	 "ecdh":"IIiTD89L6/sbIvaUc5jAVR88ySigaBXppS5GLUjm7Dv2OLKbNIVdiZ48jpLGskKVDPpukKe4R0A="
      },
   },
   "stuff": {
    "robba":"1000",
	"quantity":1000,
    "peppe":[
	"peppe2",
	"peppe3",
	"peppe4"
	]
	},

	"Bobbino":{
      "keyring":{
	 "ecdh":"IIiTD89L6/sbIvaUc5jAVR88ySigaBXppS5GLUjm7Dv2OLKbNIVdiZ48jpLGskKVDPpukKe4R0A="
				},
    "robbaB":"1000",
    "peppeB":[
	"peppe2B",
	"peppe3B",
	"peppe4B"
	]
	}
 }
EOF

    cat <<EOF | zexe have_my.zen have_my.data
rule check version 1.0.0
scenario 'ecdh'
	 Given I am 'Andrea'
	 and I have my 'keyring'
	 Then print the 'keyring'
EOF
    save_output 'have_my.json'
        assert_output '{"keyring":{"ecdh":"IIiTD89L6/sbIvaUc5jAVR88ySigaBXppS5GLUjm7Dv2OLKbNIVdiZ48jpLGskKVDPpukKe4R0A="}}'


}
@test "Given I have my valid 'keyring'" {
    cat <<EOF | zexe have_my_valid.zen have_my.data
rule check version 1.0.0
scenario 'ecdh'
	 Given I am 'Andrea'
	 and I have my valid 'keyring'
	 Then print the 'keyring'
EOF
    save_output have_my_valid.json
    assert_output '{"keyring":{"ecdh":"IIiTD89L6/sbIvaUc5jAVR88ySigaBXppS5GLUjm7Dv2OLKbNIVdiZ48jpLGskKVDPpukKe4R0A="}}'
}
@test "Given my 'keyring' is valid" {
    cat <<EOF | zexe is_valid.zen have_my.data
rule check version 1.0.0
scenario 'ecdh'
	 Given I am 'Andrea'
	 and my 'keyring' is valid
	 Then print all data
    # keyring is not printed
EOF
    save_output is_valid.json
    assert_output '[]'
}

@test "Given I have a '' named '' inside ''" {
    cat <<EOF | zexe have_inside_a.zen have_my.data
rule check version 1.0.0
scenario 'ecdh'
	 Given I have a 'number' named 'robba' inside 'stuff'
	 Then print the 'robba'
EOF
    save_output 'have_inside_a.json'
    assert_output '{"robba":1000}'
}

# ambiguity explained:
@test "Given I have a 'keyring' inside ''" {
    cat <<EOF | zexe have_a_keyring_inside.zen have_my.data
rule check version 1.0.0
scenario 'ecdh'
	 Given I have a 'keyring' inside 'Bobbino'
	 Then print the 'keyring'
EOF
    save_output 'have_a_keyring_inside.json'
    assert_output '{"keyring":{"ecdh":"IIiTD89L6/sbIvaUc5jAVR88ySigaBXppS5GLUjm7Dv2OLKbNIVdiZ48jpLGskKVDPpukKe4R0A="}}'

}
# TODO: rename in Given I have inside 'Bobbino' a 'keypair'
# diverso da Given I have a 'keypair' inside 'Bobbino'
# also same statements with valid
# also from (maybe move to scenario ecdh)
@test "Given I have a valid '' from ''" {
    skip "TODO: look at keyring print"
    cat <<EOF | zexe have_valid.zen have_my.data
rule check version 1.0.0
scenario 'ecdh'
	 Given I have a valid 'keyring' from 'Andrea'
#	 when schema
	 Then print all data
EOF
    save_output have_valid.json
    assert_output ''
}

@test "Given I have a '_ array' named '' inside ''" {
    cat <<EOF | zexe have_a_implicit_array.zen have_my.data
rule check version 1.0.0
scenario 'ecdh'
	 Given I have a 'string array' named 'peppe' inside 'stuff'
	 Then print the 'peppe'
EOF
    save_output have_a_implicit_array.json
    assert_output '{"peppe":["peppe2","peppe3","peppe4"]}'
}

@test "Given I have a valid '_ array' named '' inside ''" {
    cat <<EOF | zexe have_a_implicit_array.zen have_my.data
rule check version 1.0.0
scenario 'ecdh'
	 Given I have a valid 'string array' named 'peppe' inside 'stuff'
	 Then print the 'peppe'
EOF
 save_output 'have_a_implicit_array.json'
 assert_output '{"peppe":["peppe2","peppe3","peppe4"]}'
}

@test "Given I have a valid 'number' named '' inside ''" {
    cat <<EOF | zexe have_a_implicit_array.zen have_my.data
rule check version 1.0.0
scenario 'ecdh'
	 Given I have a valid 'number' named 'quantity' inside 'stuff'
	 Then print the 'quantity'
EOF
    save_output 'have_a_implicit_array.json'
    assert_output '{"quantity":1000}'
}

@test "Given I have a '' named by ''" {
    cat <<EOF | save_asset named_by.data
{
	"friend": "Bob",
	"Bob": "Gnignigni"
}
EOF

    cat <<EOF | zexe named_by.zen named_by.data

# Given I have a 'string' named 'friend'
Given I have a 'string' named by 'friend'

Then print all data

EOF
    save_output 'named_by.json'
    assert_output '{"Bob":"Gnignigni"}'
}

@test "Given that I have a '' named by '' inside ''" {
    cat <<EOF | save_asset named_by_inside.data
{
	"Sender": "Alice",
	"Alice": {
		"keyring": {
			"ecdh": "2mZDRS1rE4jT5EuozwZfbS+GLE7ogBfgWOr30wXoe3g="
		}
	},
	"Friends": {
		"Bob": "BJX5HFLhTxd+QeCcywWP4i7QXufoI83j/VvzoaTlfHjJBJeEIhCIUQHIm+paH/aJWHSnAQC0Mea0IiYb7z4Z4bk=",
		"Jenna": "BNRzlJ4csYlWgycGGiK/wgoEw3OizCdx9MWg06rxUBTP5rP9qPASOW5KY8YgmNjW5k7lLpboboHrsApWsvgkMN4="
	},
	"Recipient": "Bob",
	"Message": "Hi, Bob!"
}
EOF

    cat <<EOF | zexe named_by_inside.zen named_by_inside.data
Scenario 'ecdh':
Given my name is in a 'string' named 'Sender'
Given that I have my 'keyring'
Given I have a 'string' named 'Recipient'
Given I have a 'string' named 'Message'

# below the statement needed
Given that I have a 'public key' named by 'Recipient' inside 'Friends'

When I rename the object named by 'Recipient' to 'SecretRecipient'
When I encrypt the secret message of 'Message' for 'SecretRecipient'
When I rename the 'secret message' to 'SecretMessage'

Then print the 'SecretMessage'
Then print the 'SecretRecipient'
EOF
    save_output 'named_by_inside.json'
    assert_output '{"SecretMessage":{"checksum":"vf30ItXU0amG1/iQ+EtuuQ==","header":"RGVmYXVsdEhlYWRlcg==","iv":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA=","text":"jZQbM8f45hY="},"SecretRecipient":"BJX5HFLhTxd+QeCcywWP4i7QXufoI83j/VvzoaTlfHjJBJeEIhCIUQHIm+paH/aJWHSnAQC0Mea0IiYb7z4Z4bk="}'
}

@test "Given my name is in a '' named '' inside ''" {
cat <<EOF | save_asset name_named_in.data
{
	"UserData": {
	        "Sender": "Alice in wonderland"
	},
	"Alice in wonderland": {
		"keyring": {
			"ecdh": "2mZDRS1rE4jT5EuozwZfbS+GLE7ogBfgWOr30wXoe3g="
		}
	}
}
EOF

cat <<EOF | zexe name_named_in.zen name_named_in.data
Scenario 'ecdh'
# below the statement needed
Given my name is in a 'string' named 'Sender' inside 'UserData'

Given that I have my 'keyring'
Then print my 'keyring'
EOF
    save_output 'name_named_in.json'
    assert_output '{"Alice_in_wonderland":{"keyring":{"ecdh":"2mZDRS1rE4jT5EuozwZfbS+GLE7ogBfgWOr30wXoe3g="}}}'
}


@test " Given that I have a '' named '' in '', nested dictionary" {
    cat <<EOF | save_asset nested_dictionary_in.data
{
"@context": [
"https://www.w3.org/ns/did/v1",
"https://w3id.org/security/suites/ed25519-2020/v1"
],
"id": "did:example:123456789abcdefghi",
"authentication": [
{
"id": "did:example:123456789abcdefghi#keys-1",
"type": "Ed25519VerificationKey2020",
"controller": "did:example:123456789abcdefghi",
"publicKeyMultibase": "zH3C2AVvLMv6gmMNam3uVAjZpfkcJCwDwnZn6z3wXmqPV"
}
]
}
EOF

    cat <<EOF | zexe nested_dict_in.zen nested_dictionary_in.data
Given that I have a 'string' named 'id' in 'authentication'
Then print all data
EOF
    save_output 'nested_dict_in.json'
    assert_output '{"id":"did:example:123456789abcdefghi#keys-1"}'
}

@test "rename '' to ''" {
    cat <<EOF | save_asset given_rename.data
{
   "eddsa_public_key": "2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK",
   "comment": " è una stringa"
}
EOF

    cat <<EOF | zexe given_rename.zen given_rename.data
Given that I have a 'string' named 'eddsa public key'
Given that I rename 'eddsa_public_key' to 'eddsa string'
Given that I have a 'base58' named 'eddsa public key'
Given I have a 'string' named 'comment'
When I append 'comment' to 'eddsa string'
Then print all data
EOF
    save_output 'given_rename.json'
    assert_output '{"comment":" è una stringa","eddsa_public_key":"2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","eddsa_string":"2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK è una stringa"}'
}

@test "Given to decode partials with string prefix and suffix" {
	  cat << EOF | save_asset string_partials_examples.json
	  { "identity": "did:dyne:sandbox:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK",
	    "pk": "2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK:pk",
	    "sfx_onebyte": "2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK@",
	    "pfx_onebyte": "@2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK",
 }
EOF

	  cat << EOF | zexe decode_prefixed.zen string_partials_examples.json
Given I have a 'base58' part of 'identity' after string prefix 'did:dyne:sandbox:'
Then print the 'identity' as 'hex'
EOF
	  # TODO: check the integrity of the public key i.e verifying a signature
	  save_output 'hex_eddsa.json'
	  assert_output '{"identity":"1bb0515e4fe007600355be41f4d7d93508b3b11b6741b9af51ec295a1b544c40"}'

	  cat << EOF | zexe decode_prefixed.zen string_partials_examples.json
Given I have a 'base58' part of 'pfx_onebyte' after string prefix '@'
Then print the 'pfx_onebyte' as 'hex'
EOF
	  # TODO: check the integrity of the public key i.e verifying a signature
	  save_output 'hex_eddsa.json'
	  assert_output '{"pfx_onebyte":"1bb0515e4fe007600355be41f4d7d93508b3b11b6741b9af51ec295a1b544c40"}'

	  cat << EOF | zexe decode_prefixed.zen string_partials_examples.json
Given I have a 'base58' part of 'pk' before string suffix ':pk'
Then print the 'pk' as 'hex'
EOF
	  # TODO: check the integrity of the public key i.e verifying a signature
	  save_output 'hex_eddsa.json'
	  assert_output '{"pk":"1bb0515e4fe007600355be41f4d7d93508b3b11b6741b9af51ec295a1b544c40"}'

	  cat << EOF | zexe decode_prefixed.zen string_partials_examples.json
Given I have a 'base58' part of 'sfx onebyte' before string suffix '@'
Then print the 'sfx_onebyte' as 'hex'
EOF
	  # TODO: check the integrity of the public key i.e verifying a signature
	  save_output 'hex_eddsa.json'
	  assert_output '{"sfx_onebyte":"1bb0515e4fe007600355be41f4d7d93508b3b11b6741b9af51ec295a1b544c40"}'

}
