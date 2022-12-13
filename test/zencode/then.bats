load ../bats_setup
load ../bats_zencode
SUBDOC=then

@test "Print data" {
    cat <<EOF | save_asset dictionary.json
{ "dictionary": {
   "first": {
    "v1": 1,
    "v2": 2,
    "vs": "hello"
    },
   "second": {
    "v3": 3,
    "v4": 4,
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
    assert_output '{"dictionary":{"first":{"v1":1,"v2":2,"vs":"hello"},"second":{"v3":3,"v4":4,"vs":"world"}}}'
}

@test "Print my data" {
    cat <<EOF | zexe print_my_data.zen dictionary.json
Given I am known as 'Alice'
Given I have the 'string dictionary' named 'dictionary'
Then print my data
EOF
    save_output 'print_my_data.out'
    assert_output '{"Alice":{"dictionary":{"first":{"v1":1,"v2":2,"vs":"hello"},"second":{"v3":3,"v4":4,"vs":"world"}}}}'

}

@test "Print data from" {
    cat <<EOF | zexe print_data_from.zen dictionary.json
Given I have the 'string dictionary' named 'dictionary'
Then print data from 'dictionary'
Then print the 'dictionary'
EOF
    save_output 'print_data_from.out'
    assert_output '{"dictionary":{"first":{"v1":1,"v2":2,"vs":"hello"},"second":{"v3":3,"v4":4,"vs":"world"}},"first":{"v1":1,"v2":2,"vs":"hello"},"second":{"v3":3,"v4":4,"vs":"world"}}'
}

@test "Print data from as" {
    cat <<EOF | zexe print_data_from_as.zen dictionary.json
Given I have the 'string dictionary' named 'dictionary'
Then print data from 'dictionary' as 'base58'
Then print the 'dictionary'
EOF
    save_output 'print_data_from_as.out'
    assert_output '{"dictionary":{"first":{"v1":1,"v2":2,"vs":"hello"},"second":{"v3":3,"v4":4,"vs":"world"}},"first":{"v1":1,"v2":2,"vs":"Cn8eVZg"},"second":{"v3":3,"v4":4,"vs":"EUYUqQf"}}'
}

@test "Then print '' from ''" {
    cat <<EOF | zexe print_data2.zen dictionary.json
Given I have the 'string dictionary' named 'dictionary'
Then print 'second' from 'dictionary'
EOF
    save_output 'print_data2.out'
    assert_output '{"second":{"v3":3,"v4":4,"vs":"world"}}'
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
    assert_output '{"storage_contract":"1b620ca5172a8d6a64798fca2ee690066f7a7816"}'

}


@test "tests for encoding on print (2)" {
    cat <<EOF | save_asset read_and_print_tx.json
{
	"tx": {
		"nonce": "0",
		"to": "1b620cA5172A8D6A64798FcA2ee690066F7A7816",
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
    assert_output '{"to":"1b620ca5172a8d6a64798fca2ee690066f7a7816","tx":{"gas_limit":"300000","gas_price":"100000000000","nonce":"0","to":"1b620ca5172a8d6a64798fca2ee690066f7a7816","value":"0"}}'

}

@test "Print my name" {
    cat <<EOF | zexe print_my_name.zen
Given I am known as 'Alice'
Then print my name in 'identity'
EOF
    save_output 'print_my_name.out'
    assert_output '{"identity":"Alice"}'
}
