load ../bats_setup
load ../bats_zencode
SUBDOC=bbs

@test "Create the shake proof of some messages" {
    cat << EOF | save_asset shake_proof_data.json
{
	"The_Authority": {
		"bbs_public_key":"qv+YMnglevxF+p1E0VbEVNcW+xolDf7RMtZbIAkzH2GMYjwU76FiRfUMyS5gM0BRCH8a6SZpuJaQ9f65LpFWj5Wo4obRELAR6ayZI/2HEjj1fRKVOVdxMx/27e5D5MzG"
    },
	"bbs_credential": "lk060h1D5YTRdoEop3hWk4K00C0GJOflQNr2CUfPp0wfNSDM9ith6AM0FHfA0KgibS+QKFoHms1ChZU29RHVFvZMZqcnueHCUUTARfpChJIP36Cf+aqn0wiVMomg9p/mv1iBqWwjOmejEIxW25Iu+Q==",
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
Given I have a 'bbs public key' inside 'The Authority'
Given I have a 'bbs credential'
Given I have a 'string array' named 'bbs messages'
Given I have a 'integer array' named 'bbs disclosed indexes'
When I create the random object of '256' bits 
When I rename the 'random_object' to 'bbs presentation header'
When I create the bbs disclosed messages
When I create the bbs proof using 'shake256'
Then print the 'bbs proof'
Then print the 'bbs public key'
Then print the 'bbs disclosed messages'
Then print the 'bbs disclosed indexes'
Then print the 'bbs presentation header'
Then print the 'bbs credential'
EOF
    save_output verify_shake_proof_data.json
}

@test "Verify the shake proof of some messages" {

    cat <<EOF | zexe verify_shake_proof.zen verify_shake_proof_data.json
Scenario bbs
Given I have a 'bbs public key'
and I have a 'bbs proof'
and I have a 'base64' named 'bbs presentation header'
and I have a 'integer array' named 'bbs disclosed indexes'
and I have a 'string array' named 'bbs disclosed messages'
When I verify the bbs proof using 'shake256'
Then print the string 'bbs shake zkp verification successful'
EOF
    save_output verify_shake_proof_bbs.json
    assert_output '{"output":["bbs_shake_zkp_verification_successful"]}'
}

@test "Create shake proof of some messages (explicit statement)" {
    cat << EOF | save_asset shake_proof2_data.json
{
	"The_Authority": {
		"bbs_public_key":"qv+YMnglevxF+p1E0VbEVNcW+xolDf7RMtZbIAkzH2GMYjwU76FiRfUMyS5gM0BRCH8a6SZpuJaQ9f65LpFWj5Wo4obRELAR6ayZI/2HEjj1fRKVOVdxMx/27e5D5MzG"
    },
	"bbs_credential": "lk060h1D5YTRdoEop3hWk4K00C0GJOflQNr2CUfPp0wfNSDM9ith6AM0FHfA0KgibS+QKFoHms1ChZU29RHVFvZMZqcnueHCUUTARfpChJIP36Cf+aqn0wiVMomg9p/mv1iBqWwjOmejEIxW25Iu+Q==",
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
    cat <<EOF | zexe create_shake_proof2.zen shake_proof2_data.json
Scenario bbs
Given I have a 'bbs public key' inside 'The Authority'
Given I have a 'bbs credential'
Given I have a 'string array' named 'bbs messages'
Given I have a 'number array' named 'bbs disclosed indexes'
When I create the random object of '256' bits 
When I rename the 'random_object' to 'bbs presentation header'
When I create the bbs disclosed messages
When I create the bbs proof of the signature 'bbs credential' of the messages 'bbs messages' using 'shake256' with public key 'bbs public key' presentation header 'bbs presentation header' and disclosed indexes 'bbs disclosed indexes'
Then print the 'bbs proof'
Then print the 'bbs public key'
Then print the 'bbs disclosed messages'
Then print the 'bbs disclosed indexes'
Then print the 'bbs presentation header'
Then print the 'bbs credential'
EOF
    save_output verify_shake_proof2_data.json
}

@test "Verify shake proof of some messages (explicit statement)" {

    cat <<EOF | zexe verify_shake_proof2.zen verify_shake_proof2_data.json
Scenario bbs
Given I have a 'bbs public key'
and I have a 'bbs proof'
and I have a 'base64' named 'bbs presentation header'
and I have a 'number array' named 'bbs disclosed indexes'
and I have a 'string array' named 'bbs disclosed messages'
When I verify the bbs proof using 'shake256' with public key 'bbs public key' presentation header 'bbs presentation header' disclosed messages 'bbs disclosed messages' and disclosed indexes 'bbs disclosed indexes'
Then print the string  'bbs zkp verification successful'
EOF
    save_output verify_shake_proof2_bbs.json
    assert_output '{"output":["bbs_zkp_verification_successful"]}'
}
