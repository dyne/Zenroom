load ../bats_setup
load ../bats_zencode
SUBDOC=rules

@test "Rule output unsorted" {
    cat << EOF | save_asset rule_input_unsorted.data
{ "reverse_order": { "c": 3, "b": 2, "a": 1 } }
EOF
	>&3 cat rule_input_unsorted.data
	cat <<EOF | zexe rule_input_unsorted.zen rule_input_unsorted.data
rule output sorting false

Given I have a 'string dictionary' named 'reverse order'
and debug
Then print all data
EOF

	save_output rule_input_unsorted.out
	assert_output '{"reverse_order":{"c":3,"b":2,"a":1}}'
}


# --- version --- #
@test "Rule check version" {
    cat <<EOF | zexe check_version.zen
Rule check version 2.0.0

Given nothing
When I create the random 'random'
Then print the data
EOF
}

@test "Rule check version fails" {
    cat <<EOF | save_asset check_version_fail.zen
Rule check version abc

Given nothing
When I create the random 'random'
Then print the data
EOF
    run $ZENROOM_EXECUTABLE -z check_version_fail.zen
    assert_line --partial 'Could not extract version number(s) from "abc"'
}

# --- output --- #
@test "Rule output encoding" {
    cat <<EOF | zexe output_encoding.zen
Rule output encoding base58
Scenario 'ecdh': pk

Given I have nothing
When I create the ecdh key
and I create the ecdh public key
Then print the 'ecdh public key'
EOF
    save_output base58_output.json
    assert_output '{"ecdh_public_key":"Prv7EbvuXevABNJytdsoXPqjJFJxnuiHVk3QqcuWHtn7yzEQHkctuEgezzjG9tCCNriD4HsmFNnFPFDcGfMs3kmR"}'
}

# @test "Rule output encoding fails" {
#     cat <<EOF | save_asset output_encoding_fail.zen
# Rule output encoding base123
# Scenario 'ecdh': pk

# Given I have nothing
# When I create the ecdh key
# and I create the ecdh public key
# Then print the 'ecdh public key'
# EOF
#     run $ZENROOM_EXECUTABLE -z output_encoding_fail.zen
#     assert_line --partial 'Invalid output conversion: base123'
# }

@test "Rule output format" {
    cat <<EOF | zexe output_format.zen
Rule output format JSON
Scenario 'ecdh': pk

Given I have nothing
When I create the ecdh key
and I create the ecdh public key
Then print the 'ecdh public key'
EOF
    save_output json_output.json
    assert_output '{"ecdh_public_key":"BHdrWMNBRclVO1I1/iEaYjfEi5C0eEvG2GZgsCNq87qy8feZ74JEvnKK9FC07ThhJ8s4ON2ZQcLJ+8HpWMfKPww="}'
}

@test "Rule output format fails" {
    cat <<EOF | save_asset output_format_fail.zen
Rule output format not_a_format
Scenario 'ecdh': pk

Given I have nothing
When I create the ecdh key
and I create the ecdh public key
Then print the 'ecdh public key'
EOF
    run $ZENROOM_EXECUTABLE -z output_format_fail.zen
    assert_line --partial 'Conversion format not supported: not_a_format'
}

@test "Rule output versioning" {
    cat <<EOF | zexe  output_versioning.zen
Rule output versioning
Scenario 'ecdh': key

Given I have nothing
When I create the ecdh key
and I create the ecdh public key
Then print the 'ecdh public key'
EOF
}

# --- input --- #
@test "Rule input encoding" {
    cat <<EOF | zexe input_encoding.zen base58_output.json
Rule input encoding base58
Scenario 'ecdh': public key

Given I have a 'ecdh public key'
Then print the data
EOF
    save_output input_encoding_output.json
    assert_output '{"ecdh_public_key":"BHdrWMNBRclVO1I1/iEaYjfEi5C0eEvG2GZgsCNq87qy8feZ74JEvnKK9FC07ThhJ8s4ON2ZQcLJ+8HpWMfKPww="}'
}

@test "Rule input encoding fails" {
    cat <<EOF | save_asset input_encoding_fail.zen
Rule input encoding base123
Scenario 'ecdh': public key

Given I have a 'ecdh public key'
Then print the data
EOF
    run $ZENROOM_EXECUTABLE -z -a base58_output.json input_encoding_fail.zen
    assert_line --partial 'Input encoding not found: base123'
}

@test "Rule input format" {
    cat <<EOF | zexe input_format.zen base58_output.json
Rule input format json
Rule input encoding base58
Scenario 'ecdh': public key

Given I have a 'ecdh public key'
Then print the data
EOF
    save_output input_format_output.json
    assert_output '{"ecdh_public_key":"BHdrWMNBRclVO1I1/iEaYjfEi5C0eEvG2GZgsCNq87qy8feZ74JEvnKK9FC07ThhJ8s4ON2ZQcLJ+8HpWMfKPww="}'
}

@test "Rule input format fails" {
    cat <<EOF | save_asset input_format_fail.zen
Rule input format not_a_format
Rule input encoding base58
Scenario 'ecdh': public key

Given I have a 'ecdh public key'
Then print the data
EOF
    run $ZENROOM_EXECUTABLE -z -a base58_output.json input_format_fail.zen
    assert_line --partial 'Conversion format not supported: not_a_format'
}

@test "Rule input untagged" {
    cat <<EOF | zexe  input_untagged.zen base58_output.json
Rule input untagged
Rule input encoding base58
Scenario 'ecdh': public key

Given I have a 'ecdh public key'
Then print the data
EOF
}

# --- unknown ignore --- #
@test "Rule unknown ignore" {
    cat <<EOF | zexe unknown_ignore.zen
Rule unknown ignore

Given a statement that does not exist
and what about this one?
Given nothing
When I write string 'test passed' in 'result'
Then print the data
Then another statement that does not exist
and maybe another one
EOF
    save_output unknown_ignore_output.json
    assert_output '{"result":"test_passed"}'
    run $ZENROOM_EXECUTABLE -z $TMP/unknown_ignore.zen
    assert_line --partial 'Zencode line 3 pattern ignored: Given a statement that does not exist'
    assert_line --partial 'Zencode line 4 pattern ignored: and what about this one?'
    assert_line --partial 'Zencode line 8 pattern ignored: Then another statement that does not exist'
    assert_line --partial 'Zencode line 9 pattern ignored: and maybe another one'
}

@test "Rule unknown ignore fails" {
    cat <<EOF | save_asset unknown_ignore_fails.zen
Rule unknown ignore

Given nothing
When I test the rule with a statement that does not exist
When I write string 'test passed' in 'result'
Then print the data
EOF
    run $ZENROOM_EXECUTABLE -z unknown_ignore_fails.zen
    assert_line --partial 'Zencode line 4 found invalid statement out of given or then phase: When I test the rule with a statement that does not exist'
}

@test "Rule unknown ignore fails in given" {
    cat <<EOF | save_asset unknown_ignore_fails_given.zen
Rule unknown ignore

Given nothing
Given I test the rule with a statement that does not exist
When I write string 'test passed' in 'result'
Then print the data
EOF
    run $ZENROOM_EXECUTABLE -z unknown_ignore_fails_given.zen
    assert_line --partial 'Zencode line 4 found invalid statement after a valid one in the given phase: Given I test the rule with a statement that does not exist'
}

@test "Rule unknown ignore fails in then" {
    cat <<EOF | save_asset unknown_ignore_fails_then.zen
Rule unknown ignore

Given nothing
When I write string 'test passed' in 'result'
Then I use a statement that does not exists
Then print the data
EOF
    run $ZENROOM_EXECUTABLE -z unknown_ignore_fails_then.zen
    assert_line --partial 'Zencode line 6 found valid statement after an invalid one in the then phase: Then print the data'
}

# --- set --- #
@test "set" {
    cat << EOF | zexe set_hash.zen
Rule output encoding hex
Rule set hash sha512

Given nothing
When I create the random 'source'
and I create the hash of 'source'
Then print 'hash'
EOF
    save_output set_hash.json
    assert_output '{"hash":"fafe7ced778593ce8735d6d0d8d0c04a6333a832fe95901e0fb4e74644c4e4ebfe44dac8e9c3c5a3533bc66bca3d0b6cd0b154e0f2ef305b316a822f9e36667d"}'
}

@test "set fails" {
    cat << EOF | save_asset set_fail.zen
Rule output encoding hex
Rule set hash sha123

Given nothing
When I create the random 'source'
and I create the hash of 'source'
Then print 'hash'
EOF
    run $ZENROOM_EXECUTABLE -z set_fail.zen
    assert_line '[!]  Hash algorithm not known: sha123'
}

# --- Rule invalid --- #
@test "Rule does not exist" {
    cat << EOF | save_asset rule_invalid.zen
Rule that does not exists

Given nothing
When I create the random 'source'
and I create the hash of 'source'
Then print 'hash'
EOF
    run $ZENROOM_EXECUTABLE -z rule_invalid.zen
    assert_line --partial 'Rule invalid: Rule that does not exists'
}

# --- Rule number strict --- #
@test "Rule input number strict" {
    cat << EOF | save_asset rule_input_number_strict.data
{
    "num": 1978468946
}
EOF
    cat << EOF | zexe rule_input_number_strict_with_float.zen rule_input_number_strict.data
Rule input number strict

Given I have a 'float' named 'num'
and I rename 'num' to 'float_num'
Given I have a 'time' named 'num'
and I rename 'num' to 'time_num'

Then print the data
EOF
    save_output 'rule_input_number_strict.out'
    assert_output '{"float_num":1.978469e+09,"time_num":1978468946}'
}

@test "Rule input number strict with dictionaries" {
    cat << EOF | save_asset rule_input_number_strict_dictionaries.data
{
    "string_dict_with_number": {
        "string": "hello",
        "num": 1978468946,
        "bool": true
    }
}
EOF
    cat << EOF | zexe rule_input_number_strict_dictionaries.zen rule_input_number_strict_dictionaries.data
Rule input number strict

Given I have a 'string dictionary' named 'string_dict_with_number'
Then print the data
EOF
    save_output rule_input_number_strict_dictionaries.out
    assert_output '{"string_dict_with_number":{"bool":true,"num":1.978469e+09,"string":"hello"}}'

    cat << EOF | zexe not_rule_input_number_strict_dictionaries.zen rule_input_number_strict_dictionaries.data
Given I have a 'string dictionary' named 'string_dict_with_number'
Then print the data
EOF
    save_output not_rule_input_number_strict_dictionaries.out
    assert_output '{"string_dict_with_number":{"bool":true,"num":1978468946,"string":"hello"}}'
}


# --- Rule path separator --- #
@test "Rule path separator" {
    cat << EOF | save_asset rule_path_separator.data
{
    "my_dict": {
        "my_array": [
            [
                {
                    "hello": "world"
                },
                {
                    "world": "hello"
                }
            ]
        ]
    }
}
EOF
    cat << EOF | zexe rule_path_separator.zen rule_path_separator.data
Rule path separator -

Given I have a 'string dictionary' named 'my_dict'
Given I have a 'string' in path 'my_dict-my_array-1-2-world'

When I pickup from path 'my_dict-my_array-1-1-hello'

Then print the 'world'
Then print the 'hello'
EOF
    save_output 'rule_path_separator.out'
    assert_output '{"hello":"world","world":"hello"}'
}

@test "Rule path separator longer than one char fails" {
    cat << EOF | save_asset rule_path_separator_fail.zen
Rule path separator --

Given I have a 'string' in path 'my_dict--my_array--1--2--world'

Then print the data
EOF
    run $ZENROOM_EXECUTABLE -z -a rule_path_separator.data rule_path_separator_fail.zen
    assert_line --partial 'Rule invalid: Rule path separator --'
}
