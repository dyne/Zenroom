load ../bats_setup
load ../bats_zencode
SUBDOC=then

@test "Print data" {
    cat <<EOF | save_asset dictionary.json
{ "dictionary": {
   "first": {
    "v1": 123,
    "v2": 234,
    "vs": "hello"
    },
   "second": {
    "v3": 345,
    "v4": 456,
    "vs": "world"
    }
  }
}
EOF
    cat <<EOF | zexe print_data.zen dictionary.json
Given I have the 'string dictionary' named 'dictionary'
Then print all data
EOF
    save_output 'print_data.out'
    assert_output '{"dictionary":{"first":{"v1":123,"v2":234,"vs":"hello"},"second":{"v3":345,"v4":456,"vs":"world"}}}'
}

@test "Print my data" {
    cat <<EOF | zexe print_my_data.zen dictionary.json
Given I am known as 'Alice'
Given I have the 'string dictionary' named 'dictionary'
Then print my data
EOF
    save_output 'print_my_data.out'
    assert_output '{"Alice":{"dictionary":{"first":{"v1":123,"v2":234,"vs":"hello"},"second":{"v3":345,"v4":456,"vs":"world"}}}}'
}

@test "Print data from" {
    cat <<EOF | zexe print_data_from.zen dictionary.json
Given I have the 'string dictionary' named 'dictionary'
Then print data from 'dictionary'
Then print the 'dictionary'
EOF
    save_output 'print_data_from.out'
    assert_output '{"dictionary":{"first":{"v1":123,"v2":234,"vs":"hello"},"second":{"v3":345,"v4":456,"vs":"world"}},"first":{"v1":123,"v2":234,"vs":"hello"},"second":{"v3":345,"v4":456,"vs":"world"}}'
}

@test "Print data from as" {
    cat <<EOF | zexe print_data_from_as.zen dictionary.json
Given I have the 'string dictionary' named 'dictionary'
Then print data from 'dictionary' as 'base58'
Then print the 'dictionary'
EOF
    save_output 'print_data_from_as.out'
    assert_output '{"dictionary":{"first":{"v1":123,"v2":234,"vs":"hello"},"second":{"v3":345,"v4":456,"vs":"world"}},"first":{"v1":123,"v2":234,"vs":"Cn8eVZg"},"second":{"v3":345,"v4":456,"vs":"EUYUqQf"}}'
}

@test "Then print '' from ''" {
    cat <<EOF | zexe print_data2.zen dictionary.json
Given I have the 'string dictionary' named 'dictionary'
Then print 'second' from 'dictionary'
EOF
    save_output 'print_data2.out'
    assert_output '{"second":{"v3":345,"v4":456,"vs":"world"}}'
}

@test "tests for encoding on print" {
    cat <<EOF | save_asset coding_export.data
{
	"storage_contract": "1b620cA5172A8D6A64798FcA2ee690066F7A7816"
}
EOF

    cat <<EOF | zexe coding_export.zen coding_export.data
Scenario ethereum
Given I have a 'ethereum address' named 'storage contract'
Then print 'storage contract'
EOF
    save_output 'coding_export.out'
    assert_output '{"storage_contract":"0x1b620cA5172A8D6A64798FcA2ee690066F7A7816"}'

}


@test "tests for encoding on print (2)" {
    cat <<EOF | save_asset read_and_print_tx.json
{
	"tx": {
		"nonce": "0",
		"to": "0x1b620cA5172A8D6A64798FcA2ee690066F7A7816",
		"gas price": "100000000000",
		"gas limit": "300000",
		"value": "0"
	}
}
EOF
    cat <<EOF | zexe read_and_print_tx.zen read_and_print_tx.json
Scenario ethereum
Given I have a 'ethereum transaction' named 'tx'
Then print 'to' from 'tx'
Then print data
EOF
    save_output 'read_and_print_tx.out'
    assert_output '{"to":"0x1b620cA5172A8D6A64798FcA2ee690066F7A7816","tx":{"gas_limit":"300000","gas_price":"100000000000","nonce":"0","to":"0x1b620cA5172A8D6A64798FcA2ee690066F7A7816","value":"0"}}'

}

@test "Print my name" {
    cat <<EOF | zexe print_my_name.zen
Given I am known as 'Alice'
Then print my name in 'identity'
EOF
    save_output 'print_my_name.out'
    assert_output '{"identity":"Alice"}'
}


@test "Print '' as '' in ''" {
    cat <<EOF | save_asset print_as_in.data
{
    "string": "hello"
}
EOF
    cat <<EOF | zexe print_as_in.zen print_as_in.data
Given I have a 'string'

When I create the 'hex dictionary' named 'hex_data'

Then print the 'string' as 'hex' in 'hex_data'
# one more statement for trigger heapguard check
and print the 'string'
EOF
    save_output 'print_as_in.out'
    assert_output '{"hex_data":["68656c6c6f"],"string":"hello"}'
}

@test "Print positive big in different encodings" {
    cat <<EOF | save_asset print_big_encoded.data
    {
        "big": "197846894637981748973289437329874387498372948739827"
    }
EOF
    cat <<EOF | zexe print_big_encoded.zen print_big_encoded.data
Given I have a 'integer' named 'big'

When I copy 'big' to 'big_to_hex'
When I copy 'big' to 'big_to_base58'
When I copy 'big' to 'big_to_base64'
When I copy 'big' to 'big_to_binary'
When I copy 'big' to 'big_to_url64'
When I copy 'big' to 'big_to_integer'

Then print the 'big'
Then print the 'big_to_hex' as 'hex'
Then print the 'big_to_base64' as 'base64'
Then print the 'big_to_base58' as 'base58'
Then print the 'big_to_binary' as 'binary'
Then print the 'big_to_url64' as 'url64'
Then print the 'big_to_integer' as 'integer'
EOF
    save_output 'print_big_encoded.out'
    assert_output '{"big":"197846894637981748973289437329874387498372948739827","big_to_base58":"9KooCfQvDTBguALVSgdqpefnm5AF4","big_to_base64":"h19RloyzHhv5in7MpWTUWB8qrsbz","big_to_binary":"100001110101111101010001100101101000110010110011000111100001101111111001100010100111111011001100101001010110010011010100010110000001111100101010101011101100011011110011","big_to_hex":"875f51968cb31e1bf98a7ecca564d4581f2aaec6f3","big_to_integer":"197846894637981748973289437329874387498372948739827","big_to_url64":"h19RloyzHhv5in7MpWTUWB8qrsbz"}'
}

@test "Print negative big in different encodings fails" {
    cat <<EOF | save_asset print_big_encoded_fail.data
    {
        "negative_big": "-197846894637981748973289437329874387498372948739827"
    }
EOF
    cat <<EOF | save_asset print_big_encoded_fail.zen
    Given I have a 'integer' named 'negative big'
    Then print the 'negative big' as 'hex'
EOF
    run $ZENROOM_EXECUTABLE -z -a print_big_encoded_fail.data print_big_encoded_fail.zen
    assert_line --partial 'Negative integers can not be encoded'
}

@test "Print big as float fails" {
    cat <<EOF | save_asset print_big_as_float_fail.data
    {
        "negative_big": "197846894637981748973289437329874387498372948739827"
    }
EOF
    cat <<EOF | save_asset print_big_as_float_fail.zen
    Given I have a 'integer' named 'negative big'
    Then print the 'negative big' as 'float'
EOF
    run $ZENROOM_EXECUTABLE -z -a print_big_as_float_fail.data print_big_as_float_fail.zen
    assert_line --partial 'Encoding not valid for integers'
}

@test "Print float in different encodings" {
    cat <<EOF | save_asset print_float_encoded.data
    {
        "small_float": 155.6234,
        "big_float": 1978468946
    }
EOF
    cat <<EOF | zexe print_float_encoded.zen print_float_encoded.data
Rule input number strict
Given I have a 'float' named 'small_float'
Given I have a 'float' named 'big_float'

When I copy 'small_float' to 'sf_to_hex'
When I copy 'small_float' to 'sf_to_base58'
When I copy 'small_float' to 'sf_to_base64'
When I copy 'small_float' to 'sf_to_binary'
When I copy 'small_float' to 'sf_to_url64'
When I copy 'small_float' to 'sf_to_string'

When I copy 'big_float' to 'bf_to_hex'
When I copy 'big_float' to 'bf_to_base58'
When I copy 'big_float' to 'bf_to_base64'
When I copy 'big_float' to 'bf_to_binary'
When I copy 'big_float' to 'bf_to_url64'
When I copy 'big_float' to 'bf_to_string'

Then print the 'small_float'
Then print the 'sf_to_hex' as 'hex'
Then print the 'sf_to_base64' as 'base64'
Then print the 'sf_to_base58' as 'base58'
Then print the 'sf_to_binary' as 'binary'
Then print the 'sf_to_url64' as 'url64'
Then print the 'sf_to_string' as 'string'

Then print the 'big_float'
Then print the 'bf_to_hex' as 'hex'
Then print the 'bf_to_base64' as 'base64'
Then print the 'bf_to_base58' as 'base58'
Then print the 'bf_to_binary' as 'binary'
Then print the 'bf_to_url64' as 'url64'
Then print the 'bf_to_string' as 'string'
EOF
    save_output 'print_float_encoded.out'
    assert_output '{"bf_to_base58":1.978469e+09,"bf_to_base64":1.978469e+09,"bf_to_binary":1.978469e+09,"bf_to_hex":1.978469e+09,"bf_to_string":1.978469e+09,"bf_to_url64":1.978469e+09,"big_float":1.978469e+09,"sf_to_base58":155.6234,"sf_to_base64":155.6234,"sf_to_binary":155.6234,"sf_to_hex":155.6234,"sf_to_string":155.6234,"sf_to_url64":155.6234,"small_float":155.6234}'
}

@test "print float from base64 fail" {
    cat <<EOF | save_asset float_from_base64_fail.data
    {
        "b64": "CTlQid3NvdizBrYjqIwNLIrHGeFccqHzlQ/jsYovLJA="
    }
EOF
    cat <<EOF | save_asset float_from_base64_fail.zen
    Given I have a 'base64' named 'b64'
    Then print the 'b64' as 'number'
EOF
    run $ZENROOM_EXECUTABLE -z -a float_from_base64_fail.data float_from_base64_fail.zen
    assert_line --partial 'Could not read the float number'
}
