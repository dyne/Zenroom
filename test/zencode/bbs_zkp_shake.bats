load ../bats_setup
load ../bats_zencode
SUBDOC=bbs

@test "Create the shake proof of some messages" {
    cat << EOF | save_asset shake_proof_data.json
{
	"bbs_messages": [
		"above 18",
		"italian",
		"professor"
	],
	"bbs_disclosed_indexes": [
		1,
		3
	]
}
EOF
    cat <<EOF | zexe create_shake_proof.zen shake_proof_data.json
Scenario bbs
# Given I have a 'bbs public key' inside 'The Authority'
# Given I have a 'bbs credential'
Given I have a 'string array' named 'bbs messages'
Given I have a 'number array' named 'bbs disclosed indexes'
When I create the bbs shake key
and I create the bbs shake public key
When I create the random object of '256' bits
When I rename the 'random_object' to 'bbs presentation header'
When I create the bbs shake signature of 'bbs messages'
and I rename 'bbs shake signature' to 'bbs shake credential'
When I create the bbs disclosed messages
When I create the bbs shake proof
Then print the 'bbs shake proof'
Then print the 'bbs shake public key'
Then print the 'bbs disclosed messages'
Then print the 'bbs disclosed indexes'
Then print the 'bbs presentation header'
Then print the 'bbs shake credential'
EOF
    save_output verify_shake_proof_data.json
    >&3 cat  verify_shake_proof_data.json
}

@test "Verify the shake proof of some messages" {

    cat <<EOF | zexe verify_shake_proof.zen verify_shake_proof_data.json
Scenario bbs
Given I have a 'bbs shake public key'
and I have a 'bbs shake proof'
and I have a 'base64' named 'bbs presentation header'
and I have a 'integer array' named 'bbs disclosed indexes'
and I have a 'string array' named 'bbs disclosed messages'
When I verify the bbs shake proof
Then print the string 'bbs shake zkp verification successful'
EOF
    save_output verify_shake_proof_bbs.json
    assert_output '{"output":["bbs_shake_zkp_verification_successful"]}'
}

@test "Create shake proof of some messages (explicit statement)" {
    cat << EOF | save_asset some_shake_proof_data.json
{
	"bbs_messages": [
		"above 18",
		"italian",
		"professor"
	],
}
EOF
    cat <<EOF | zexe create_shake_proof2.zen verify_shake_proof_data.json some_shake_proof_data.json
Scenario bbs
Given I have a 'bbs shake public key'
Given I have a 'bbs shake credential'
Given I have a 'string array' named 'bbs messages'
Given I have a 'number array' named 'bbs disclosed indexes'
When I create the random object of '256' bits 
When I rename the 'random_object' to 'bbs presentation header'
When I create the bbs disclosed messages
When I create the bbs shake proof of the signature 'bbs shake credential' of the messages 'bbs messages' with public key 'bbs shake public key' presentation header 'bbs presentation header' and disclosed indexes 'bbs disclosed indexes'
Then print the 'bbs shake proof'
Then print the 'bbs shake public key'
Then print the 'bbs disclosed messages'
Then print the 'bbs disclosed indexes'
Then print the 'bbs presentation header'
Then print the 'bbs shake credential'
EOF
    save_output verify_shake_proof2_data.json
}

@test "Verify shake proof of some messages (explicit statement)" {

    cat <<EOF | zexe verify_shake_proof2.zen verify_shake_proof_data.json some_shake_proof_data.json
Scenario bbs
Given I have a 'bbs shake public key'
and I have a 'bbs shake proof'
and I have a 'base64' named 'bbs presentation header'
and I have a 'number array' named 'bbs disclosed indexes'
and I have a 'string array' named 'bbs disclosed messages'
When I verify the bbs shake proof with public key 'bbs shake public key' presentation header 'bbs presentation header' disclosed messages 'bbs disclosed messages' and disclosed indexes 'bbs disclosed indexes'
Then print the string  'bbs shake zkp verification successful'
EOF
    save_output verify_shake_proof2_bbs.json
    assert_output '{"output":["bbs_shake_zkp_verification_successful"]}'
}
