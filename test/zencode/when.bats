load ../bats_setup
load ../bats_zencode
SUBDOC=when


@test "When I copy '' to ''" {
cat <<EOF >copy_data.data
{
    "my_hex": "0011FFFF",
    "my_bool": false
}
EOF
cat <<EOF | zexe copy_data.zen copy_data.data
Given I have a 'hex' named 'my hex'
Given I have a 'boolean' named 'my_bool'

When I copy 'my hex' to 'dest'
When I copy 'my bool' to 'bool_dest'

Then print 'my hex'
Then print 'dest'
Then print 'my_bool'
Then print 'bool_dest'
EOF
    save_output 'copy_data.out'
    assert_output '{"bool_dest":false,"dest":"0011ffff","my_bool":false,"my_hex":"0011ffff"}'
}

@test "When I append the string" {
	  cat << EOF | zexe append_string.zen
Given nothing
When I set 'my_prefix' to 'did:dyne:' as 'string'
and I append the string 'sandbox:' to 'my_prefix'
Then print 'my prefix'
EOF
	save_output strappend.json
	assert_output '{"my_prefix":"did:dyne:sandbox:"}'
}

@test "When I append the encoded string of" {
	cat <<EOF | save_asset pub_did.json
	{
	  "hex_path": "did:dyne:sandbox:",
	  "base58_path": "did:dyne:sandbox:",
	  "base64_path": "did:dyne:sandbox:",
	  "eddsa_public_key": "8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ",
	}
EOF
	cat <<EOF | zexe append_encoded_to.zen pub_did.json
Scenario eddsa
Given I have a 'string' named 'hex_path'
and I have a 'string' named 'base58_path'
and I have a 'string' named 'base64_path'
and I have a 'eddsa public key'
When I append the 'hex' of 'eddsa_public_key' to 'hex_path'
and I append the 'base58' of 'eddsa_public_key' to 'base58_path'
and I append the 'base64' of 'eddsa_public_key' to 'base64_path'
Then print the 'hex_path'
and print the 'base58 path'
and print the 'base64 path'
EOF
	save_output did.json
	assert_output '{"base58_path":"did:dyne:sandbox:8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ","base64_path":"did:dyne:sandbox:bjbiQ5ryoK1I7akMK2wkTcQCLj7FS1sy7fYY2peqnxo=","hex_path":"did:dyne:sandbox:6e36e2439af2a0ad48eda90c2b6c244dc4022e3ec54b5b32edf618da97aa9f1a"}'
}

@test "When I create the string encoding of" {
	cat <<EOF | save_asset eddsa.json
{"eddsa_public_key": "8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ"}
EOF
	cat << EOF | zexe create_string_encoding.zen eddsa.json
Scenario eddsa
Given I have a 'eddsa public key'
When I create the 'hex' string of 'eddsa public key'
Then print the 'hex'
EOF
	save_output create_string.encoding.json
	assert_output '{"hex":"6e36e2439af2a0ad48eda90c2b6c244dc4022e3ec54b5b32edf618da97aa9f1a"}'
}

@test "When I pickup from path ''" {
    cat <<EOF | save_asset stringnum.json
{
	"api": "http://3.68.108.18/api/v1/blocks/latest",
	"path": "blocks/",
	"latest": {
		"result": {
			"height": 102,
			"male": false
		}
	}

}
EOF
    cat <<EOF | zexe append_number_try.zen stringnum.json
Given I have a 'string dictionary' named 'latest'

and I have a 'string' named 'path'

When I pickup from path 'latest.result.height'
and I append 'height' to 'path'

When I pickup from path 'latest.result.male'

Then print the 'male'
Then print the 'path'
EOF
    save_output 'append_number_try.out'
    assert_output '{"male":false,"path":"blocks/102"}'

}

@test "When I create the '' cast of strings in ''" {
    cat <<EOF | save_asset string-mpack.json
{
"newblock": {
	"newblock-mpack": "haZudW1iZXLHAAAACk1IZ3hNV0psTnepdGltZXN0YW1wxwAAAA5NSGcyTWpkaVlUa3dPQapwYXJlbnRIYXNoxwAAAFhNSGd6TUdJell6YzBOR0k0WkRsaVlqTXdZak00TURRMllXWTFPRGhpWVRsbFpEWTRaamRsTjJaalpEa3pOV0U0WXpRNE5UWmlPR0ZoWXpBek5HVTBOak5opGhhc2jHAAAAWE1IZzVZekF3WW1ZeU9ESmpObVk1WTJGaE1XRTVaamM0Tmpaak1UaGxNbVpsWkRneVpUWTVNREkzTlRWaE16a3hNMlkxT0RKbFpXSXhaV1psT0dZM05EbGqqYmxvY2tjaGFpboSkdHlwZccAAAALWlhSb1pYSmxkVzCkaHR0cMcAAAAgYUhSMGNEb3ZMemM0TGpRM0xqTTRMakl5TXpvNE5UUTGid3PHAAAAHmQzTTZMeTgzT0M0ME55NHpPQzR5TWpNNk9EVTBOZ6RuYW1lxwAAAAtabUZpWTJoaGFXNA==",
	"txid": "dd445fed8ab124ab0c38720db060b730ddcf4c3fe71b3668eacf9505cd17da8f"
	},
	"version": "2.0",
	"id": "20cfe258df01bf6c634b6b79329b20ef7f5bdf69e6c319b06adb44ac9a4b6c67"
}
EOF

    cat <<EOF | zexe base64-string-cast.zen string-mpack.json
Given I have a 'string dictionary' named 'newblock'
When I pickup from path 'newblock.newblock-mpack'
When I create the 'base64' cast of strings in 'newblock-mpack'
and I create the 'contents' decoded from mpack 'base64'
Then print the 'contents' as 'string'
EOF
    save_output 'base64-string-cast.out'
    assert_output '{"contents":{"blockchain":{"http":"http://78.47.38.223:8545","name":"fabchain","type":"ethereum","ws":"ws://78.47.38.223:8546"},"hash":"0x9c00bf282c6f9caa1a9f7866c18e2fed82e6902755a3913f582eeb1efe8f749c","number":"0x11be7","parentHash":"0x30b3c744b8d9bb30b38046af588ba9ed68f7e7fcd935a8c4856b8aac034e463a","timestamp":"0x627ba908"}}'
}

@test "Count chars" {
    cat <<EOF | save_asset graphql.json
{"graphql":"bXV0YXRpb24gewogIGNyZWF0ZUVjb25vbWljRXZlbnQoCiAgICBldmVudDogewogICAgICBhY3Rpb246ICJwcm9kdWNlIgogICAgICBwcm92aWRlcjogIjAxRldOMTJYWDdUSlgxQUZGNUtBNFdQTk45IiAjIGJvYgogICAgICByZWNlaXZlcjogIjAxRldOMTJYWDdUSlgxQUZGNUtBNFdQTk45IiAjIGJvYgogICAgICBvdXRwdXRPZjogIjAxRldOMTM2U1BETUtXV0YyM1NXUVpSTTVGIiAjIGhhcnZlc3RpbmcgYXBwbGVzIHByb2Nlc3MKICAgICAgcmVzb3VyY2VDb25mb3Jtc1RvOiAiMDFGV04xMzZZNFpaN0s5RjMxNEhRN01LUkciICMgYXBwbGUKICAgICAgcmVzb3VyY2VRdWFudGl0eTogewogICAgICAgIGhhc051bWVyaWNhbFZhbHVlOiA1MAogICAgICAgIGhhc1VuaXQ6ICIwMUZXTjEzNlM1VlBDQ1IzQjNUR1lEWUVZOSIgIyBraWxvZ3JhbQogICAgICB9CiAgICAgIGF0TG9jYXRpb246ICIwMUZXTjEzNlpBUFE1RU5CRjNGWjc5OTM1RCIgIyBib2IncyBmYXJtCiAgICAgIGhhc1BvaW50SW5UaW1lOiAiMjAyMi0wMS0wMlQwMzowNDowNVoiCiAgICB9CiAgICBuZXdJbnZlbnRvcmllZFJlc291cmNlOiB7CiAgICAgIG5hbWU6ICJib2IncyBhcHBsZXMiCiAgICAgIG5vdGU6ICJib2IncyBkZWxpc2ggYXBwbGVzIgogICAgICB0cmFja2luZ0lkZW50aWZpZXI6ICJsb3QgMTIzIgogICAgICBjdXJyZW50TG9jYXRpb246ICIwMUZXTjEzNlpBUFE1RU5CRjNGWjc5OTM1RCIgIyBib2IncyBmYXJtCiAgICAgIHN0YWdlOiAiMDFGV04xMzZYMTgzRE00M0NUV1hFU05XQUIiICMgZnJlc2gKICAgIH0KICApIHsKICAgIGVjb25vbWljRXZlbnQgewogICAgICBpZAogICAgICBhY3Rpb24ge2lkfQogICAgICBwcm92aWRlciB7aWR9CiAgICAgIHJlY2VpdmVyIHtpZH0KICAgICAgb3V0cHV0T2Yge2lkfQogICAgICByZXNvdXJjZUNvbmZvcm1zVG8ge2lkfQogICAgICByZXNvdXJjZVF1YW50aXR5IHsKICAgICAgICBoYXNOdW1lcmljYWxWYWx1ZQogICAgICAgIGhhc1VuaXQge2lkfQogICAgICB9CiAgICAgIGF0TG9jYXRpb24ge2lkfQogICAgICBoYXNQb2ludEluVGltZQogICAgfQogICAgZWNvbm9taWNSZXNvdXJjZSB7ICMgdGhpcyBpcyB0aGUgbmV3bHktY3JlYXRlZCByZXNvdXJjZQogICAgICBpZAogICAgICBuYW1lCiAgICAgIG5vdGUKICAgICAgdHJhY2tpbmdJZGVudGlmaWVyCiAgICAgIHN0YWdlIHtpZH0KICAgICAgY3VycmVudExvY2F0aW9uIHtpZH0KICAgICAgY29uZm9ybXNUbyB7aWR9CiAgICAgIHByaW1hcnlBY2NvdW50YWJsZSB7aWR9CiAgICAgIGN1c3RvZGlhbiB7aWR9CiAgICAgIGFjY291bnRpbmdRdWFudGl0eSB7CiAgICAgICAgaGFzTnVtZXJpY2FsVmFsdWUKICAgICAgICBoYXNVbml0IHtpZH0KICAgICAgfQogICAgICBvbmhhbmRRdWFudGl0eSB7CiAgICAgICAgaGFzTnVtZXJpY2FsVmFsdWUKICAgICAgICBoYXNVbml0IHtpZH0KICAgICAgfQogICAgfQogIH0KfQo=","schnorr_signature":"CL7LFfLAIgE7e3U2KroR8q18EZ3KMCxaXpwE7MH+ZIpvIhAxIHrO9eZhRO6LQ9GAEtwdXnW04Q89O1eFo4C2JeFI/11i9rc7MjB3PIdBtUk="}
EOF

    cat <<EOF | zexe countchar.zen graphql.json
Given I have a 'base64' named 'graphql'
When I create the count of char '{' found in 'graphql'
and I rename 'count' to 'open'
and I create the count of char '}' found in 'graphql'
and I remove 'count'
and I remove 'open'
When I create the count of char '(' found in 'graphql'
and I rename 'count' to 'open'
and I create the count of char ')' found in 'graphql'
and I remove 'count'
and I remove 'open'
When I create the count of char '[' found in 'graphql'
and I rename 'count' to 'open'
and I create the count of char ']' found in 'graphql'
and I verify 'count' is equal to 'open'
Then print the string 'OK'
and print 'graphql' as 'string'
EOF
    save_output 'countchar.out'
}

@test "When I compact ascii strings in ''" {
    cat <<EOF | save_asset loremipsum.json
{"lorem": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n\nSed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?\nAt vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus. Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus asperiores repellat.\n\n"}
EOF

    cat <<EOF | zexe rmchar.zen loremipsum.json
Given I have a 'string' named 'lorem'
When I copy 'lorem' to 'ipsum'

When I remove newlines in 'lorem'
and I remove spaces in 'lorem'

When I compact ascii strings in 'ipsum'
and I verify 'lorem' is equal to 'ipsum'


Then print the string 'OK'
EOF
    save_output 'rmchar.out'
    assert_output '{"output":["OK"]}'
}


@test "create the json escaped string of ''" {
    cat <<EOF | save_asset json_encode.json
{
    "myStringArray": [
      "Hello World! myFirstObject, myFirstArray[0]",
      "Hello World! myFirstObject, myFirstArray[1]",
      "Hello World! myFirstObject, myFirstArray[2]"
    ],
    "myBase64Array": [
      "BPEg2X6/Y+68oolE6ocCPDlLWQZLqdaBV00d/jJ5f0dRNQNBUcIh/JHGgfDotpM4p682MPZ5PKoC3vsjhI88OeE="
    ],
    "myNumberArray" : [
        1,
        2,
        3
    ],
    "myStringDictionary" : {
      "first": "hello",
      "second": "world!"
    },
    "myBase64Dictionary" : {
      "first": "aGVsbG8=",
      "second": "d29ybGQh"
    },
    "myNumberDictionary" : {
      "first": 1,
      "second": 2
    },
    "myMixedDictionary": {
      "string": "hello",
      "number": 1,
      "boolean": true
    }
}
EOF

    cat <<EOF | zexe json_encode.zen json_encode.json
Given I have a 'string array' named 'myStringArray'
Given I have a 'base64 array' named 'myBase64Array'
Given I have a 'number array' named 'myNumberArray'
Given I have a 'string dictionary' named 'myStringDictionary'
Given I have a 'base64 dictionary' named 'myBase64Dictionary'
Given I have a 'number dictionary' named 'myNumberDictionary'
Given I have a 'string dictionary' named 'myMixedDictionary'

When I create the json escaped string of 'myStringArray'
and I rename the 'json escaped string' to 'json.myStringArray'

When I create the json escaped string of 'myBase64Array'
and I rename the 'json escaped string' to 'json.myBase64Array'

When I create the json escaped string of 'myNumberArray'
and I rename the 'json escaped string' to 'json.myNumberArray'

When I create the json escaped string of 'myStringDictionary'
and I rename the 'json escaped string' to 'json.myStringDictionary'

When I create the json escaped string of 'myBase64Dictionary'
and I rename the 'json escaped string' to 'json.myBase64Dictionary'

When I create the json escaped string of 'myNumberDictionary'
and I rename the 'json escaped string' to 'json.myNumberDictionary'

When I create the json escaped string of 'myMixedDictionary'
and I rename the 'json escaped string' to 'json.myMixedDictionary'

Then print the 'json.myStringArray'
Then print the 'json.myBase64Array'
Then print the 'json.myNumberArray'
Then print the 'json.myStringDictionary'
Then print the 'json.myBase64Dictionary'
Then print the 'json.myNumberDictionary'
Then print the 'json.myMixedDictionary'
EOF
    save_output 'json_encode.out'
    assert_output '{"json.myBase64Array":"[\"BPEg2X6/Y+68oolE6ocCPDlLWQZLqdaBV00d/jJ5f0dRNQNBUcIh/JHGgfDotpM4p682MPZ5PKoC3vsjhI88OeE=\"]","json.myBase64Dictionary":"{\"first\":\"aGVsbG8=\",\"second\":\"d29ybGQh\"}","json.myMixedDictionary":"{\"boolean\":true,\"number\":1,\"string\":\"hello\"}","json.myNumberArray":"[1,2,3]","json.myNumberDictionary":"{\"first\":1,\"second\":2}","json.myStringArray":"[\"Hello World! myFirstObject, myFirstArray[0]\",\"Hello World! myFirstObject, myFirstArray[1]\",\"Hello World! myFirstObject, myFirstArray[2]\"]","json.myStringDictionary":"{\"first\":\"hello\",\"second\":\"world!\"}"}'
}

@test "When I create the json unescaped object of ''" {
    cat <<EOF | zexe json_decode.zen json_encode.out
Given I have a 'string' named 'json.myStringArray'
Given I have a 'string' named 'json.myBase64Array'
Given I have a 'string' named 'json.myNumberArray'
Given I have a 'string' named 'json.myStringDictionary'
Given I have a 'string' named 'json.myBase64Dictionary'
Given I have a 'string' named 'json.myNumberDictionary'
Given I have a 'string' named 'json.myMixedDictionary'

When I create the json unescaped object of 'json.myStringArray'
and I rename the 'json unescaped object' to 'myStringArray'

When I create the json unescaped object of 'json.myBase64Array'
and I rename the 'json unescaped object' to 'myBase64Array'

When I create the json unescaped object of 'json.myNumberArray'
and I rename the 'json unescaped object' to 'myNumberArray'

When I create the json unescaped object of 'json.myStringDictionary'
and I rename the 'json unescaped object' to 'myStringDictionary'

When I create the json unescaped object of 'json.myBase64Dictionary'
and I rename the 'json unescaped object' to 'myBase64Dictionary'

When I create the json unescaped object of 'json.myNumberDictionary'
and I rename the 'json unescaped object' to 'myNumberDictionary'

When I create the json unescaped object of 'json.myMixedDictionary'
and I rename the 'json unescaped object' to 'myMixedDictionary'

Then print the 'myStringArray'
Then print the 'myBase64Array'
Then print the 'myNumberArray'
Then print the 'myStringDictionary'
Then print the 'myBase64Dictionary'
Then print the 'myNumberDictionary'
Then print the 'myMixedDictionary'
EOF
    save_output 'json_decode.out'
    assert_output '{"myBase64Array":["BPEg2X6/Y+68oolE6ocCPDlLWQZLqdaBV00d/jJ5f0dRNQNBUcIh/JHGgfDotpM4p682MPZ5PKoC3vsjhI88OeE="],"myBase64Dictionary":{"first":"aGVsbG8=","second":"d29ybGQh"},"myMixedDictionary":{"boolean":true,"number":1,"string":"hello"},"myNumberArray":[1,2,3],"myNumberDictionary":{"first":1,"second":2},"myStringArray":["Hello World! myFirstObject, myFirstArray[0]","Hello World! myFirstObject, myFirstArray[1]","Hello World! myFirstObject, myFirstArray[2]"],"myStringDictionary":{"first":"hello","second":"world!"}}'
}

@test "When create the json unescaped object of '' nested arrays" {
    cat <<EOF | save_asset json_unescaped_nested_arrays.json
{
    "nested_array": "[[\"data_1\",\"data_2\",[\"data_4\"]],[\"data_3\"]]"
}
EOF
    cat <<EOF | zexe json_unescaped_nested_arrays.zen json_unescaped_nested_arrays.json
Given I have a 'string' named 'nested_array'

When I create the json unescaped object of 'nested_array'

Then print the 'json unescaped object'
EOF
    save_output 'json_unescaped_nested_arrays.out'
    assert_output '{"json_unescaped_object":[["data_1","data_2",["data_4"]],["data_3"]]}'
}

@test "When create the json escaped object of '' string fail" {
    cat <<EOF | save_asset json_escaped_of_string.json
{
    "myString": "Hello world!"
}
EOF
    cat <<EOF | save_asset json_escaped_of_string.zen
Given I have a 'string' named 'myString'

When I create the json escaped string of 'myString'

Then print the 'json escaped string'
EOF
    run $ZENROOM_EXECUTABLE -z -a json_escaped_of_string.json json_escaped_of_string.zen
    assert_line --partial 'JSON encode input is not a table'
}

@test "When create the json unescaped object of '' string fail" {
    cat <<EOF | save_asset json_unescaped_of_string.zen
Given I have a 'string' named 'myString'

When I create the json unescaped object of 'myString'

Then print the 'json unescaped object'
EOF
    run $ZENROOM_EXECUTABLE -z -a json_escaped_of_string.json json_unescaped_of_string.zen
    assert_line --partial 'JSON decode input is not a encoded table'
}

@test "cast float into integer" {
    cat <<EOF | save_asset cast_float.json
{"b64": "ITQjFPGiNLU0LC0yQeI=",
 "integer": "123456789123456789123456789"}
EOF

    cat <<EOF | zexe cast_float.zen cast_float.json
Given  have a 'base64' named 'b64'
Given I have a 'integer'
When create the float 'fb64' cast of integer in 'b64'
When create the float 'finteger' cast of integer in 'integer'

Then print data
EOF
    save_output 'cast_float.out'
    assert_output '{"b64":"ITQjFPGiNLU0LC0yQeI=","fb64":6.734502e+32,"finteger":1.234568e+26,"integer":"123456789123456789123456789"}'
}


@test "verify is found" {
    cat <<EOF | save_asset found.json
{
    "str": "hello",
    "integer": "123456789123456789123456789",
    "float": 1234,
    "dict": {
            "str_1": "hello",
            "str_2": "world"
    },
    "array": [
             "hello",
             "world"
    ]
}
EOF

    cat <<EOF | zexe found.zen found.json
Given I  have a 'string' named 'str'
and I have a 'integer'
and I have a 'float'
and I have a 'string dictionary' named 'dict'
and I have a 'string array' named 'array'

When I verify 'str' is found
and I verify 'integer' is found
and I verify 'float' is found
and I verify 'dict' is found
and I verify 'array' is found

Then print the string 'found everything'
EOF
    save_output 'found.out'
    assert_output '{"output":["found_everything"]}'
}

@test "exit with error message" {
    cat <<EOF | save_asset error_message.data.json
{
    "error": "object not found"
}
EOF
    cat <<EOF | save_asset error_message.zen
    Given I have a 'string' named 'error'
    If I verify 'object' is not found
    When I exit with error message 'error'
    EndIf
    Then print the string 'object found'
EOF
    cat <<EOF | save_asset error_message_inline.zen
    Given nothing
    If I verify 'object' is not found
    When I exit with error message 'Object not found'
    EndIf
    Then print the string 'object found'
EOF
    run $ZENROOM_EXECUTABLE -z -a error_message.data.json error_message.zen
    assert_failure
    assert_line '[!] object not found'
    run $ZENROOM_EXECUTABLE -z error_message_inline.zen
    assert_failure
    assert_line '[!] Object not found'
}

@test "json validation" {
    cat <<EOF | save_asset json_validation.data.json
{
    "json_encoded_dict": "{\"first\":\"hello\",\"second\":\"world!\"}",
    "not_json_encoded_dict": "this is not a json"
}
EOF
    cat <<EOF | zexe json_validation.zen json_validation.data.json
Given I have a 'string' named 'json_encoded_dict'
Given I have a 'string' named 'not_json_encoded_dict'

When I verify 'json_encoded_dict' is a json
# equivalently
When I verify 'json_encoded_dict' is a valid json

If I verify 'not_json_encoded_dict' is a json
Then print the string '[!] validte not_json_encoded_dict'
EndIf

Then print the string 'validate json encoded dicr'
EOF
    save_output json_validation.out.json
    assert_output '{"output":["validate_json_encoded_dicr"]}'
}

@test "try to move element from table to existing object" {
    cat <<EOF | save_asset move_from_to_existing_obj.json
{
    "dict_from": {
        "str_3": "!"
    },
    "dict_to": {
            "str_1": "hello",
            "str_2": "world"
    }
}
EOF

    cat <<EOF | save_asset move_from_to_existing_obj.zen
Given I  have a 'string dictionary' named 'dict_from'
and I have a 'string dictionary' named 'dict_to'

When I move 'str_3' from 'dict_from' to 'dict_to'

Then print the 'dict_to'
EOF
    run $ZENROOM_EXECUTABLE -z -a move_from_to_existing_obj.json move_from_to_existing_obj.zen
    assert_line --partial 'Cannot overwrite existing object: dict_to'
    assert_line --partial 'To copy/move element in existing element use:'
    assert_line --partial "When I move/copy '' from '' in ''"
}

@test "move/copy as to" {
    cat <<EOF | save_asset move_from_to_existing_obj.data.json
{
    "base64_string": "aGVsbG8gbXkgZnJpZW5k",
    "ecdh_signature": {
        "r":"d2tYw0FFyVU7UjX+IRpiN8SLkLR4S8bYZmCwI2rzurI=",
        "s":"vUljXtnKkBqle/Ik7y3GfMa1o3wEIi4lRC+b/KmVbaI="
    }
}
EOF
    cat <<EOF | zexe move_copy_as_to.zen move_from_to_existing_obj.data.json
Scenario 'ecdh': sign
Given I have a 'ecdh signature'
and I have a 'base64' named 'base64_string'

When I copy 'base64_string' as 'string' to 'string_from_base64'
When I move 'ecdh signature' as 'ecdh signature' to 'new_ecdh_siganture_with_string_encoding'

Then print the 'string_from_base64'
Then print the 'new_ecdh_siganture_with_string_encoding'
EOF
    save_output move_from_to_existing_obj.out.json
    assert_output '{"new_ecdh_siganture_with_string_encoding":{"r":"d2tYw0FFyVU7UjX+IRpiN8SLkLR4S8bYZmCwI2rzurI=","s":"vUljXtnKkBqle/Ik7y3GfMa1o3wEIi4lRC+b/KmVbaI="},"string_from_base64":"hello my friend"}'
}

@test "move or copy from a dictiopnary and array" {
    cat <<EOF | save_asset copy_move_from_to.data.json
{
    "dict_from": {
        "str_1": "hello",
        "str_2": "world",
        "str_3": "!"
    },
    "array_from": [
        "hello",
        "world",
        "!"
    ],
    "str_pos_for_dict": "str_3",
    "str_pos_for_array": "3",
    "int_pos": "3",
    "float_pos": 3
}
EOF
    cat <<EOF | zexe copy_move_from_to.zen copy_move_from_to.data.json
Given I  have a 'string dictionary' named 'dict_from'
and I have a 'string array' named 'array_from'
and I have a 'integer' named 'int_pos'
and I have a 'string' named 'str_pos_for_array'
and I have a 'string' named 'str_pos_for_dict'
and I have a 'float' named 'float_pos'


When I copy 'str_2' from 'dict_from' to 'string_copied_from_dict'
When I copy 'str_pos_for_dict' from 'dict_from' to 'string_copied_from_dict_with_str_pos'

When I copy '2' from 'array_from' to 'string_copied_from_array'
When I copy 'str_pos_for_array' from 'array_from' to 'string_copied_from_array_with_str_pos'
When I copy 'int_pos' from 'array_from' to 'string_copied_from_array_with_int_pos'
When I copy 'float_pos' from 'array_from' to 'string_copied_from_array_with_float_pos'

When I move 'str_1' from 'dict_from' to 'string_moved_from_dict'
When I move 'str_pos_for_dict' from 'dict_from' to 'string_moved_from_dict_with_str_pos'

When I move 'str_pos_for_array' from 'array_from' to 'string_moved_from_array_with_str_pos'
and I copy 'string_moved_from_array_with_str_pos' in 'array_from'
When I move 'int_pos' from 'array_from' to 'string_moved_from_array_with_int_pos'
and I copy 'string_moved_from_array_with_int_pos' in 'array_from'
When I move 'float_pos' from 'array_from' to 'string_moved_from_array_with_float_pos'
When I move '1' from 'array_from' to 'string_moved_from_array'

Then print the data
EOF
    save_output copy_move_from_to.out.json
    assert_output '{"array_from":["world"],"dict_from":{"str_2":"world"},"float_pos":3,"int_pos":"3","str_pos_for_array":"3","str_pos_for_dict":"str_3","string_copied_from_array":"world","string_copied_from_array_with_float_pos":"!","string_copied_from_array_with_int_pos":"!","string_copied_from_array_with_str_pos":"!","string_copied_from_dict":"world","string_copied_from_dict_with_str_pos":"!","string_moved_from_array":"hello","string_moved_from_array_with_float_pos":"!","string_moved_from_array_with_int_pos":"!","string_moved_from_array_with_str_pos":"!","string_moved_from_dict":"hello","string_moved_from_dict_with_str_pos":"!"}'
}

@test "base32: encoding and decoding" {
    cat <<EOF | save_asset b32_encoding_decoding.data.json
{ 
    "my_b32":"AAI777Y=",
    "my_hex":"0011ffff",
    "my_base64":"ABH//w=="
}
EOF
    cat <<EOF | zexe b32_encoding_decoding.zen b32_encoding_decoding.data.json
Given I have a 'base32' named 'my_b32'
Given I have a 'hex' named 'my_hex'
Given I have a 'base64' named 'my_base64'

When I copy 'my_b32' as 'base64' to 'dest_b32'  
When I copy 'my_hex' as 'base32' to 'dest_hex' 
When I copy 'my_base64' as 'base32' to 'dest_b64'   

Then print 'dest b32'
Then print 'dest b64'
Then print 'dest hex'

EOF
    save_output b32_encoding_decoding.out.json
    assert_output '{"dest_b32":"ABH//w==","dest_b64":"AAI777Y=","dest_hex":"AAI777Y="}'
}

@test "base32crockford: encoding and decoding also with checksum" {
    cat <<EOF | save_asset b32crockford_encoding_decoding.data.json
{ 
    "my_b32_crockford":"ADT74TBECWG78VS0CNQ66VV4CM",
    "my_b32_crockford_cs":"ADT74TBECWG78VS0CNQ66VV4CMS",
    "my_hex":"537472696e6720746f20656e636f6465",
    "my_string":"String to encode"
}
EOF
    cat <<EOF | zexe b32crockford_encoding_decoding.zen b32crockford_encoding_decoding.data.json
Given I have a 'base32crockford' named 'my_b32_crockford'
Given I have a 'base32crockford_cs' named 'my_b32_crockford_cs'
Given I have a 'hex' named 'my_hex'
Given I have a 'string' named 'my_string'

When I copy 'my_b32_crockford' as 'string' to 'dest_string'  
When I copy 'my_b32_crockford_cs' as 'hex' to 'dest_hex'  
When I copy 'my_hex' as 'base32crockford' to 'dest_b32_crockford' 
When I copy 'my_string' as 'base32crockford_cs' to 'dest_b32_crockford_cs'   

Then print 'dest_string'
Then print 'dest_b32_crockford'
Then print 'dest_b32_crockford_cs'
Then print 'dest_hex'
EOF
    save_output b32crockford_encoding_decoding.out.json
    assert_output '{"dest_b32_crockford":"ADT74TBECWG78VS0CNQ66VV4CM","dest_b32_crockford_cs":"ADT74TBECWG78VS0CNQ66VV4CMS","dest_hex":"537472696e6720746f20656e636f6465","dest_string":"String to encode"}'
}
