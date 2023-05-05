load ../bats_setup
load ../bats_zencode
SUBDOC=bbs

@test "Create the proof of some messages" {
    cat << EOF | save_asset proof_data.json
{
	"The_Authority": {
		"bbs_issuer_public_key":"qv+YMnglevxF+p1E0VbEVNcW+xolDf7RMtZbIAkzH2GMYjwU76FiRfUMyS5gM0BRCH8a6SZpuJaQ9f65LpFWj5Wo4obRELAR6ayZI/2HEjj1fRKVOVdxMx/27e5D5MzG"
    },
	"bbs_credential": "lEkvgDGkVaTcHJTGHwcrBnT8f4Mt4V8o0cop6wv1/gF2+O5WtN7G7UmLY9dLWLfBPg9o3Ll/maB5xo1d1U2BPprltwmu/1kp+1TBq9K85A4rLzWAWyjs5NAUmlhbSRfjDFHxrLj8C4hgMT/MMNGk2Q==",
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
    cat <<EOF | zexe create_proof.zen proof_data.json
Scenario bbs
Given I have a 'bbs issuer public key' inside 'The Authority'
Given I have a 'bbs credential'
Given I have a 'bbs messages'
Given I have a 'integer array' named 'bbs disclosed indexes'
When I create the random object of '256' bits 
When I rename the 'random_object' to 'bbs presentation header'
When I create the bbs disclosed messages
When I create the bbs proof using 'sha256'
Then print the 'bbs proof'
Then print the 'bbs issuer public key'
Then print the 'bbs disclosed messages'
Then print the 'bbs disclosed indexes'
Then print the 'bbs presentation header'
Then print the 'bbs credential'
EOF
    save_output verify_proof_data.json
}

@test "Verify the proof of some messages" {

    cat <<EOF | zexe verify_proof.zen verify_proof_data.json
Scenario bbs
Given I have a 'bbs issuer public key'
and I have a 'bbs proof'
and I have a 'bbs presentation header'
and I have a 'integer array' named 'bbs disclosed indexes'
and I have a 'bbs disclosed messages'
When I verify the bbs proof using 'sha256'
Then print the string  'bbs zkp verification successful'
EOF
    save_output verify_proof_bbs.json
    assert_output '{"output":["bbs_zkp_verification_successful"]}'
}
