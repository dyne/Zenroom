load ../bats_setup
load ../bats_zencode
SUBDOC=given

@test "Given nothing" {
    cat <<EOF | zexe nothing.zen
rule check version 1.0.0
Given nothing
When I create the random of '256' bits
Then print the 'random'
EOF
    save_output "nothing.json"
    assert_output '{"random":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA="}'
}

@test "Given nothing with something in input" {
    cat <<EOF | save_asset fail_nothing.data
{"a": 1}
EOF
cat <<EOF | save_asset fail_nothing.zen 
rule check version 1.0.0
	 Given nothing
	 When I create the random of '256' bits
	 Then print the 'random'
EOF
    run $ZENROOM_EXECUTABLE -z -a fail_nothing.data fail_nothing.zen
    assert_line --partial 'Undesired data passed as input'
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
    assert_output '{"myArray":["String1","String3","String2"],"myNumber":1000,"myString":"Hello World!"}'
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

@test "Given I have a '' in path ''" {
    cat << EOF | save_asset given_in_path.data
{
    "my_dict": {
        "result": {
            "my_string_array": [
                "hello",
                "world"
            ],
            "my_number_array": [
                1,
                2,
                3
            ],
            "my_hex": "0123",
            "my_base64": "W8ZFMccV+jErS2wLP3nn6jH46WgNp8vzzfzuFMxmWtA=",
            "my_base58": "6nLf3J6QhF94jE6A6BNVcHEyjBXdS1H1YqGBfaWgTULv"
        }
    }
}
EOF

    cat << EOF | zexe given_in_path.zen given_in_path.data
Given I have a 'string array' in path 'my_dict.result.my_string_array'
and I have a 'number array' in path 'my_dict.result.my_number_array'
and I have a 'hex' in path 'my_dict.result.my_hex'
and I have a 'base64' in path 'my_dict.result.my_base64'
and I have a 'base58' in path 'my_dict.result.my_base58'

Then print the data
EOF
    save_output 'given_in_path.json'
    assert_output '{"my_base58":"6nLf3J6QhF94jE6A6BNVcHEyjBXdS1H1YqGBfaWgTULv","my_base64":"W8ZFMccV+jErS2wLP3nn6jH46WgNp8vzzfzuFMxmWtA=","my_hex":"0123","my_number_array":[1,2,3],"my_string_array":["hello","world"]}'
}

@test "Given I have a '' in path '' (fail)" {
    cat << EOF | save_asset given_in_path_fail_not_found.zen
Given I have a 'string array' in path 'my_dict.result.not_my_string_array'

Then print the data
EOF
    run $ZENROOM_EXECUTABLE -z -a given_in_path.data given_in_path_fail_not_found.zen
    assert_line --partial 'Key not_my_string_array not found in result'

    cat << EOF | save_asset given_in_path_fail_not_a_table.zen
Given I have a 'string array' in path 'my_dict.result.my_hex.not_existing_element'

Then print the data
EOF
    run $ZENROOM_EXECUTABLE -z -a given_in_path.data given_in_path_fail_not_a_table.zen
    assert_line --partial 'Object is not a table: my_hex'
}

@test "Read hex with 0x prefix" {
    cat << eof | save_asset hex_0x_prefix.data
{
  "0xprefix": "0x7d6df85bDBCe99151c813fd1DDE6BC007c523C27"
}
eof
    cat <<EOF | zexe hex_0x_prefix.zen hex_0x_prefix.data
Scenario ethereum

Given I have a 'hex' named '0xprefix'
Given I rename '0xprefix' to 'myhex'
Given I have a 'ethereum address' named '0xprefix'

Then print data
EOF
    save_output "hex_0x_prefix.out"
    assert_output '{"0xprefix":"0x7d6df85bDBCe99151c813fd1DDE6BC007c523C27","myhex":"7d6df85bdbce99151c813fd1dde6bc007c523c27"}'
}

@test "Load a wrong formatted time fails" {
    cat << EOF | save_asset fail_wrong_time.data
{
	"num": {
		"key_1": "1.2",
		"key_2": "100"
	}
}
EOF
    cat <<EOF | save_asset fail_wrong_time.zen fail_wrong_time.data
Given I have a 'time dictionary' named 'num'

then print the data
EOF
    run $ZENROOM_EXECUTABLE -a fail_wrong_time.data -z fail_wrong_time.zen
    assert_line --partial 'Could not read unix timestamp 1.2'
}

@test "Load tables with wrong data type fails" {
    cat << EOF | save_asset fail_table_wrong_dt.data
{
	"dict": {
        "hello": "world"
    },
    "array": [
        "hello",
        "world"
    ],
    "ecdh_pks": [
        "BLOYXryyAI7rPuyNbI0/1CfLFd7H/NbX+osqyQHjPR9BPK1lYSPOixZQWvFK+rkkJ+aJbYp6kii2Y3+fZ5vl2MA=",
        "BKRCtsZf8PxlIO5C/rQ8brFimDMgITrqKGiD/9YMdrdeIThLoN7Zm6oAQcVGBYso6aWQmkY70I3Dg2GRAv2gCog="
    ]
}
EOF
    cat <<EOF | save_asset fail_table_wrong_dt_1.zen
Given I have a 'string dictionary' named 'array'
Then print the data
EOF
    cat <<EOF | save_asset fail_table_wrong_dt_2.zen
Given I have a 'string array' named 'dict'
Then print the data
EOF
    cat <<EOF | save_asset fail_table_wrong_dt_3.zen
Scenario ecdh
Given I have a 'ecdh public key dictionary' named 'ecdh pks'
Then print the data
EOF
    run $ZENROOM_EXECUTABLE -a fail_table_wrong_dt.data -z fail_table_wrong_dt_1.zen
    assert_line --partial 'Incorrect data type, expected dictionary for array'
    run $ZENROOM_EXECUTABLE -a fail_table_wrong_dt.data -z fail_table_wrong_dt_2.zen
    assert_line --partial 'Incorrect data type, expected array for dict'
    run $ZENROOM_EXECUTABLE -a fail_table_wrong_dt.data -z fail_table_wrong_dt_3.zen
    assert_line --partial 'Incorrect data type, expected dictionary for ecdh_pks'
}


@test "Given I have a '' in path '' with arrays" {
    cat << EOF | save_asset given_in_path_array.data
{
    "my_dict": {
        "result": {
            "my_string_array": [
                "hello",
                "world"
            ],
            "my_number_array": [
                1,
                2,
                3
            ]
        }
    },
    "my_array": [
        {
            "1": "hello"
        },
        [
            "one",
            {
                "hi": "world"
            }
        ]
    ]
}
EOF

    cat << EOF | zexe given_in_path_array.zen given_in_path_array.data
Given I have a 'number' in path 'my_dict.result.my_number_array.1'
and I rename '1' to 'my_number_array_1'
Given I have a 'string' in path 'my_dict.result.my_string_array.2'
and I rename '2' to 'my_string_array_2'
Given I have a 'string' in path 'my_array.1.1'
and I rename '1' to 'my_array_1_1'
Given I have a 'string' in path 'my_array.2.1'
and I rename '1' to 'my_array_2_1'
Given I have a 'string' in path 'my_array.2.2.hi'
and I rename 'hi' to 'my_array_2_2_hi'

Then print the data
EOF
    save_output 'given_in_path.json'
    assert_output '{"my_array_1_1":"hello","my_array_2_1":"one","my_array_2_2_hi":"world","my_number_array_1":1,"my_string_array_2":"world"}'
}


@test "Given to decode partials with string prefix and suffix in other variable" {
	  cat << EOF | save_asset prefix_from_varibale.json
{
    "token": "BEARER eyJhbGciOiJFUzI1NiJ9.eyJzdWIiOiI2ZGEyY2IyNDk3MjMzN2ZhYTU1NDA2ZDYwYmZkYmU1MDM4NDk1ODc5IiwiaWF0IjoxNzA5ODkyNDI3LCJpc3MiOiJodHRwczovL2F1dGh6LXNlcnZlcjEuemVuc3dhcm0uZm9ya2JvbWIuZXU6MzEwMCIsImF1ZCI6ImRpZDpkeW5lOnNhbmRib3guc2lnbnJvb206UFREdnZRbjFpV1FpVnhrZnNEblVpZDhGYmllS2JIcTQ2UXM4YzlDWng2NyIsImV4cCI6MTcwOTg5NjAyN30.OReIXP6ZjSL8iHyno1nDwWw32SqlG3HIoFqoBpIb1OwuvOgUbGmdCNgfJToq7dT8kG2gsgIJYr40BcnNJDVX_Q",
    "prefix": "BEARER ",
    "suffix": " eyJhbGciOiJFUzI1NiJ9.eyJzdWIiOiI2ZGEyY2IyNDk3MjMzN2ZhYTU1NDA2ZDYwYmZkYmU1MDM4NDk1ODc5IiwiaWF0IjoxNzA5ODkyNDI3LCJpc3MiOiJodHRwczovL2F1dGh6LXNlcnZlcjEuemVuc3dhcm0uZm9ya2JvbWIuZXU6MzEwMCIsImF1ZCI6ImRpZDpkeW5lOnNhbmRib3guc2lnbnJvb206UFREdnZRbjFpV1FpVnhrZnNEblVpZDhGYmllS2JIcTQ2UXM4YzlDWng2NyIsImV4cCI6MTcwOTg5NjAyN30.OReIXP6ZjSL8iHyno1nDwWw32SqlG3HIoFqoBpIb1OwuvOgUbGmdCNgfJToq7dT8kG2gsgIJYr40BcnNJDVX_Q"
 }
EOF
    cat << EOF | zexe prefix_from_varibale.zen prefix_from_varibale.json
Scenario 'w3c': token
Given I have a 'string' part of 'token' before string suffix 'suffix'
and I rename 'token' to 'bearer'
Given I have a 'json web token' part of 'token' after string prefix 'prefix'
When I pickup a 'string dictionary' from path 'token.payload'
Then print the 'payload'
Then print the 'bearer'
EOF
    save_output 'prefix_from_varibale.json'
    assert_output '{"bearer":"BEARER","payload":{"aud":"did:dyne:sandbox.signroom:PTDvvQn1iWQiVxkfsDnUid8FbieKbHq46Qs8c9CZx67","exp":1709896027,"iat":1709892427,"iss":"https://authz-server1.zenswarm.forkbomb.eu:3100","sub":"6da2cb24972337faa55406d60bfdbe5038495879"}}'
}

@test "Given to accept uuid encoding" {
    cat <<EOF | save_asset given_uuid.data.json
{
    "data1": "urn:uuid:550e8400-e29b-41d4-a716-446655440000",
    "data2": "VQ6EAOKbQdSnFkRmVUQAAA=="
}
EOF
    cat <<EOF | zexe given_uuid.zen given_uuid.data.json
Given I have a 'uuid' named 'data1'
Given I have a 'base64' named 'data2'
Then print the 'data2' as 'uuid'
EOF
    save_output given_uuid.out.json
    assert_output '{"data2":"550e8400-e29b-41d4-a716-446655440000"}'
} 

@test "Given custom dictionary" {
    test_data='{"custom":{"encoded":"AhVCQPry2svggZcn5H","name":"Alice","nested":{"code":"nested code","crypto":{"iv":"696e697469616c697a6174696f6e20766563746f72","key":"c2VjcmV0IGtleQ=="}},"secret":"onion canoe strategy minor rookie route extend cause lunar cheap drive near illness pill medal save toss athlete pattern avocado east excuse impose insect"}}'
    echo "$test_data" | save_asset 'custom_dictionary.json'
    cat <<EOF | zexe custom_dictionary.zen custom_dictionary.json
    Given I have a 'dictionary' named 'custom'
    and I decode dictionary path 'custom.encoded' as 'base58'
    and I decode dictionary path 'custom.secret' as 'mnemonic'
    and I decode dictionary path 'custom.nested.crypto.iv' as 'hex'
    and I decode dictionary path 'custom.nested.crypto.key' as 'base64'
    Then print 'custom'
EOF
    save_output 'custom_dictionary_result.json'
    assert_output "$test_data"
}

@test "Given path before prefix or after suffix" {
      cat << EOF | save_asset 'w3c_credential.json'
{
  "document": {
    "@context": [
      "https://www.w3.org/ns/credentials/v2",
      "https://www.w3.org/ns/credentials/examples/v2"
    ],
    "credentialSubject": {
      "alumniOf": "The School of Examples",
      "id": "did:example:abcdefgh"
    },
    "description": "A minimum viable example of an Alumni Credential.",
    "id": "urn:uuid:58172aac-d8ba-11ed-83dd-0b3aef56cc33",
    "issuer": "https://vc.example/issuers/5678",
    "name": "Alumni Credential",
    "proof": {
      "created": "2023-02-24T23:36:38Z",
      "cryptosuite": "eddsa-rdfc-2022",
      "proofPurpose": "assertionMethod",
      "proofValue": "z2YwC8z3ap7yx1nZYCg4L3j3ApHsF8kgPdSb5xoS1VR7vPG3F561B52hYnQF9iseabecm3ijx4K1FBTQsCZahKZme",
      "type": "DataIntegrityProof",
      "verificationMethod": "did:key:z6MkrJVnaZkeFzdQyMZu1cgjg7k1pZZ6pvBQ7XJPt4swbTQ2#z6MkrJVnaZkeFzdQyMZu1cgjg7k1pZZ6pvBQ7XJPt4swbTQ2"
    },
    "type": [
      "VerifiableCredential",
      "AlumniCredential"
    ],
    "validFrom": "2023-01-01T00:00:00Z"
  }
}
EOF
    cat <<EOF | zexe path_before_prefix.zen w3c_credential.json
    Given I have a 'base58' part of path 'document.proof.proofValue' after string prefix 'z'
    Then print 'proofValue' as 'base64'
EOF
    save_output 'path_before_prefix.json'
    assert_output '{"proofValue":"TY5TwtWz8qeJF1PrFsqZMyW9sNPPxb4Qk9ChhCb174V4ytwP1LX03Q0c4K79FasSC3qJTQ6wlP/aTmVTzR7VDQ=="}'
}

