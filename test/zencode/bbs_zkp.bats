load ../bats_setup
load ../bats_zencode
SUBDOC=bbs

@test "Create the sha proof of some messages" {
    cat << EOF | save_asset proof_data.json
{
	"The_Authority": {
		"bbs_public_key":"qv+YMnglevxF+p1E0VbEVNcW+xolDf7RMtZbIAkzH2GMYjwU76FiRfUMyS5gM0BRCH8a6SZpuJaQ9f65LpFWj5Wo4obRELAR6ayZI/2HEjj1fRKVOVdxMx/27e5D5MzG"
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
Given I have a 'bbs public key' inside 'The Authority'
Given I have a 'bbs credential'
Given I have a 'string array' named 'bbs messages'
Given I have a 'number array' named 'bbs disclosed indexes'
When I create the random object of '256' bits 
When I rename the 'random_object' to 'bbs presentation header'
When I create the bbs disclosed messages
When I create the bbs proof using 'sha256'
Then print the 'bbs proof'
Then print the 'bbs public key'
Then print the 'bbs disclosed messages'
Then print the 'bbs disclosed indexes'
Then print the 'bbs presentation header'
Then print the 'bbs credential'
EOF
    save_output verify_proof_data.json
}

@test "Verify the sha proof of some messages" {

    cat <<EOF | zexe verify_proof.zen verify_proof_data.json
Scenario bbs
Given I have a 'bbs public key'
and I have a 'bbs proof'
and I have a 'base64' named 'bbs presentation header'
and I have a 'number array' named 'bbs disclosed indexes'
and I have a 'string array' named 'bbs disclosed messages'
When I verify the bbs proof using 'sha256'
Then print the string  'bbs zkp verification successful'
EOF
    save_output verify_proof_bbs.json
    assert_output '{"output":["bbs_zkp_verification_successful"]}'
}

@test "Create sha proof of some messages (explicit statement)" {
    cat << EOF | save_asset proof2_data.json
{
	"The_Authority": {
		"bbs_public_key":"qv+YMnglevxF+p1E0VbEVNcW+xolDf7RMtZbIAkzH2GMYjwU76FiRfUMyS5gM0BRCH8a6SZpuJaQ9f65LpFWj5Wo4obRELAR6ayZI/2HEjj1fRKVOVdxMx/27e5D5MzG"
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
    cat <<EOF | zexe create_proof2.zen proof2_data.json
Scenario bbs
Given I have a 'bbs public key' inside 'The Authority'
Given I have a 'bbs credential'
Given I have a 'string array' named 'bbs messages'
Given I have a 'number array' named 'bbs disclosed indexes'
When I create the random object of '256' bits 
When I rename the 'random_object' to 'bbs presentation header'
When I create the bbs disclosed messages
When I create the bbs proof of the signature 'bbs credential' of the messages 'bbs messages' using 'sha256' with public key 'bbs public key' presentation header 'bbs presentation header' and disclosed indexes 'bbs disclosed indexes'
Then print the 'bbs proof'
Then print the 'bbs public key'
Then print the 'bbs disclosed messages'
Then print the 'bbs disclosed indexes'
Then print the 'bbs presentation header'
Then print the 'bbs credential'
EOF
    save_output verify_proof2_data.json
}

@test "Verify sha proof of some messages (explicit statement)" {

    cat <<EOF | zexe verify_proof2.zen verify_proof2_data.json
Scenario bbs
Given I have a 'bbs public key'
and I have a 'bbs proof'
and I have a 'base64' named 'bbs presentation header'
and I have a 'number array' named 'bbs disclosed indexes'
and I have a 'string array' named 'bbs disclosed messages'
When I verify the bbs proof using 'sha256' with public key 'bbs public key' presentation header 'bbs presentation header' disclosed messages 'bbs disclosed messages' and disclosed indexes 'bbs disclosed indexes'
Then print the string  'bbs zkp verification successful'
EOF
    save_output verify_proof2_bbs.json
    assert_output '{"output":["bbs_zkp_verification_successful"]}'
}

@test "DOCS: create issuer keys" {
    cat <<EOF | zexe issuer_keys_docs.zen
Scenario 'bbs': authority generates its keys

Given I am 'The Authority'

When I create the bbs key
When I create the bbs public key

Then print my 'bbs public key'
Then print my 'keyring'

EOF
    save_output issuer_keys_output_docs.json
}

@test "DOCS: create credential example" {
    cat << EOF | save_asset data_credential_docs.json
{
    "The_Authority": {
        "bbs_public_key": "o+JuJ0zDfbRzXkXsgBZ9t2YvM+OGOFWqByaQeYxplqUU/2SNEYTcP5QQh1mSN9xxDyNW/s6Lm/fR8D6c7kfbdRwSPcx+xb0iemsNxhwFtVqo/KrAtpsOaBugtUh8P0xY",
        "keyring": {
            "bbs": "MXuDMAavZ9URy0VSwIxQwl9gCTXL1ePQfyWpHQCL9Wk="
        }
    },
    "bbs_messages": [
		"above 18",
		"italian",
		"professor"
	],
	"hash_name": "sha256"
}
EOF
    cat <<EOF | zexe create_credential_docs.zen data_credential_docs.json
Scenario 'bbs': authority generates the private credential

Given I am 'The Authority'
and I have my 'keyring'

Given I have a 'string array' named 'bbs messages'

# The hash function used to generate the signature, to create the proof and to verify it   
# must be the same in all the three cases.
Given I have a 'string' named 'hash name'

# The private credential is generated by signing the messages.
When I create the bbs signature of 'bbs messages' using 'hash name'
When I rename the 'bbs signature' to 'bbs credential'

Then print the 'bbs messages'
Then print the 'bbs credential'
Then print the 'hash name'
EOF
    save_output output_credential_docs.json
}

@test "DOCS: create proof example" {
    cat << EOF | save_asset proof_data_docs.json
{
	"The_Authority": {
		"bbs_public_key": "o+JuJ0zDfbRzXkXsgBZ9t2YvM+OGOFWqByaQeYxplqUU/2SNEYTcP5QQh1mSN9xxDyNW/s6Lm/fR8D6c7kfbdRwSPcx+xb0iemsNxhwFtVqo/KrAtpsOaBugtUh8P0xY"
	},
    "bbs_credential": "mM+sPY0BNTri66IFR/G9HgSvJuzhf1fz36twKO4RnQXQyKYv2afPYa0J7fKpGC2KSdUb4M9lC59iLXS5n6Cutgc8pE21NRyvaV/Pp3mOnOxSw8ScbPbpuQuPVqUkPK16V+hlWMKRVc7+njxQZUt1oA==",
	"bbs_messages": [
		"above 18",
		"italian",
		"professor"
	],
	"hash_name": "sha256",
	"bbs_disclosed_indexes": [
		1,
		3
	]
}
EOF
    cat <<EOF | zexe create_proof_docs.zen proof_data_docs.json
Scenario 'bbs': participant generates the bbs proof

Given I have a 'bbs public key' inside 'The Authority'
Given I have a 'bbs credential'
Given I have a 'string array' named 'bbs messages'
# This is the same hash function used by the Authority to sign the messages.
Given I have a 'string' named 'hash name'

Given I have a 'number array' named 'bbs disclosed indexes'

When I create the random object of '256' bits 
When I rename the 'random_object' to 'bbs presentation header'

When I create the bbs disclosed messages

# The SAME hash function must be used in BOTH the creation and the verification. 
When I create the bbs proof of the signature 'bbs credential' of the messages 'bbs messages' using 'hash name' with public key 'bbs public key' presentation header 'bbs presentation header' and disclosed indexes 'bbs disclosed indexes'
When I rename the 'bbs proof' to 'bbs proof verbose'
When I create the bbs proof using 'hash name'

Then print the 'bbs proof verbose'
Then print the 'bbs proof'
Then print the 'bbs public key'
Then print the 'bbs disclosed messages'
Then print the 'bbs disclosed indexes'
Then print the 'bbs presentation header'
Then print the 'bbs credential'
Then print the 'hash name'
EOF
    save_output created_proof_docs.json
}


@test "DOCS: verify proof example" {
    cat << EOF | save_asset proved_signature_docs.json
{
    "The_Authority": {
        "bbs_public_key": "o+JuJ0zDfbRzXkXsgBZ9t2YvM+OGOFWqByaQeYxplqUU/2SNEYTcP5QQh1mSN9xxDyNW/s6Lm/fR8D6c7kfbdRwSPcx+xb0iemsNxhwFtVqo/KrAtpsOaBugtUh8P0xY"
    },

	"bbs_disclosed_indexes": [
		1,
		3
	],
	"bbs_disclosed_messages": [
		"above 18",
		"professor"
	],
	"bbs_presentation_header": "4rAHPkKy0JmKDC4klGayzHvSqqDxMWyJ61SvkmiAHjU=",
	"bbs_proof": "hjaff22+6VybKCyVBA6EQCndmPA3G/EGADBSe2jJys50GX9RKM87U0PRd+JlJDQemBpb1r0R4cvWRIFWJdFV01PGEH+prkmhkS5fTgbNsU4wnLayrjAVALr74FWzTbf1luwfzk2rRABZ+5xzEuP/pf6qkwRmYFZpcYJzaWODyRV6dSinfYAbFOmHD42xfPGbTYtEFznPdlo0vlgUM6YQYH360yx1P1iybdlbJCoPUdZdA/DCtK/mjEJ+PuMJ1nXQmGoWJ7hfB2mD9pcHSNmFH0zzMmjJ1q98kK2EeaMcqVsY2iHiDoqrTxyaka8QLvzMCvtN34bvg0fO7o8pzVfJLqWa6zQRJgwel2WtgbEcjAJfFmkOoa9O0aancWOPOAiMlDwFtSIU9tvchDDPEUVVjHBZyETlsEwm/JTmVGOMZtMUuxrlJy4RvF0aqNSpRqKX",
	"hash_name": "sha256"
}
EOF
    cat <<EOF | zexe verify_proof_docs.zen proved_signature_docs.json
Scenario bbs: verify a bbs proof

# We load al the necessary objects one at a time
Given I have a 'bbs public key' in 'The Authority'
and I have a 'bbs proof'
and I have a 'base64' named 'bbs presentation header'
Given I have a 'number array' named 'bbs disclosed indexes'
and I have a 'string array' named 'bbs disclosed messages'

# The SAME hash function must be used in BOTH the creation and the verification.
When I verify the bbs proof using 'sha256' with public key 'bbs public key' presentation header 'bbs presentation header' disclosed messages 'bbs disclosed messages' and disclosed indexes 'bbs disclosed indexes'
When I verify the bbs proof using 'sha256'

# The print is executed only if the verification was successful
Then print the string  'bbs zkp verification successful'
EOF
    save_output verified_proof_docs.json
}
