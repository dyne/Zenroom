load ../bats_setup
load ../bats_zencode
SUBDOC=rules

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
    run $ZENROOM_EXECUTABLE -z $BATS_SUITE_TMPDIR/check_version_fail.zen
    assert_failure
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

@test "Rule output encoding fails" {
    cat <<EOF | save_asset output_encoding_fail.zen
Rule output encoding base123
Scenario 'ecdh': pk

Given I have nothing
When I create the ecdh key
and I create the ecdh public key
Then print the 'ecdh public key'
EOF
    run $ZENROOM_EXECUTABLE -z $BATS_SUITE_TMPDIR/output_encoding_fail.zen
    assert_failure
}

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
    run $ZENROOM_EXECUTABLE -z $BATS_SUITE_TMPDIR/output_format_fail.zen
    assert_failure
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
    run $ZENROOM_EXECUTABLE -z -a $BATS_SUITE_TMPDIR/base58_output.json $BATS_SUITE_TMPDIR/input_encoding_fail.zen
    assert_failure
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
    run $ZENROOM_EXECUTABLE -z -a $BATS_SUITE_TMPDIR/base58_output.json $BATS_SUITE_TMPDIR/input_format_fail.zen
    assert_failure
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
    cat <<EOF | zexe  unknown_ignore.zen
Rule unknown ignore

Given nothing
When I test the rule with a statement that does not exist
When I write string 'test passed' in 'result'
Then print the data
EOF
    save_output unknown_ignore_output.json
    assert_output '{"result":"test_passed"}'
}

# --- collision ignore --- #
@test "collision ignore" {
    cat <<EOF | save_asset collision.keys 
{"test": "collision_keys"}
EOF
    cat <<EOF | save_asset collision.json
{"test": "collision_data"}
EOF
    cat <<EOF | zexe collision_ignore.zen collision.keys collision.json
Rule collision ignore

Given I have a 'string' named 'test'
When I write string 'test passed' in 'result'
Then print the 'result'
EOF
    save_output collision_ignore_output.json
    assert_output '{"result":"test_passed"}'
}

# --- caller restroom-mw --- #
@test "caller restroom-mw" {
    cat <<EOF | zexe caller_restroom-mw.zen collision.keys  collision.json
Rule caller restroom-mw

Given I have a 'string' named 'test'
When I test the rule with a statement that does not exist
and I also have a collision in data and keys
When I write string 'test passed' in 'result'
Then print the 'result'
EOF
    save_output caller_restroom-mw_output.json
    assert_output '{"result":"test_passed"}'
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
    run $ZENROOM_EXECUTABLE -z $BATS_SUITE_TMPDIR/set_fail.zen
    assert_failure
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
    run $ZENROOM_EXECUTABLE -z $BATS_SUITE_TMPDIR/rule_invalid.zen
    assert_failure
}
