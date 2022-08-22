load ../bats_setup
load ../bats_zencode
SUBDOC=reflow

@test "Issuer keygen" {
    cat <<EOF | zexe issuer_keygen.zen
Scenario credential
Given I am 'The Authority'
when I create the issuer key
Then print my 'keyring'
EOF

    save_output "reflow issuer_keypair.json"
    assert_output '{"The_Authority":{"keyring":{"issuer":{"x":"CKGied4Ww03qmsUM/vnOMDodgwPp9Fc3QJuiFcBGQ/k=","y":"abYTJShT0ZBKU+ZwJlEIPNinT6TFU+unaKMEZ+u3kbs="}}}}'
}


@test "Issuer verifier" {
    cat <<EOF | zexe issuer_verifier.zen issuer_keypair.json
Scenario credential: publish verifier
Given that I am known as 'The Authority'
and I have my 'keyring'
When I create the issuer public key
Then print my 'issuer public key'
EOF
    save_output "issuer_verifier.json"
    assert_output '{"The_Authority":{"issuer_public_key":{"alpha":"FQLFrpXEvILgyDetXpxBMqtUPJ55HV9o36PREpT2ZZJyW61JHR0If125DDeKc25vCb/w/jkGPRZnOvRle1gzDr0fzI58Wg++Ww3Cs0Qi+QdVf6iuQSrRqHzze01kncefEpoi3iDckIWu21ugjTd73/9FxQEqWkN8o2etBxA73RDnOgHgo7SjVH4JDbYgLLMbElPy2XNFsDfzYEnH5YDR4QTmCrz0oYmTc2tfYVeQ5P18rW0NE4fnukt0xAievljS","beta":"EMp/xmfX9qvgxmXPYmqFitcWUK0t6Cv6ASbZ0Vy4cm2WIo78nIKwdCj1e7BXdv5vEi2sPwaqdXtCYHV9ttYBI2dSqF260Ct/ywSpV6N+3jfhKj5UWsPNexn/jdccdLLzEZWhuKqenEzwkiRtnyGTNa/cQcKKMlpKRTaO2iTYiLIB8p5wwC3/647IbKh3kxHEGU67/vD6TujUrq4RJjul6uUbLE3LZa+oTwgkG+mmQNHBjny7G9zvGMRsWCiDQ/9I"}}}'
}

generate_participant() {
    local name=$1
    ## PARTICIPANT
	cat <<EOF | zexe keygen_${1}.zen
Scenario reflow
Given I am '${1}'
When I create the reflow key
and I create the credential key
Then print my 'keyring'
EOF
    save_output "keypair_${1}.json"
    rm $TMP/out

	cat <<EOF | zexe pubkey_${1}.zen keypair_${1}.json
Scenario reflow
Given I am '${1}'
and I have my 'keyring'
When I create the reflow public key
Then print my 'reflow public key'
EOF
    save_output "public_key_${1}.json"
    rm $TMP/out

	cat <<EOF | zexe request_${1}.zen keypair_${1}.json
Scenario credential
Given I am '${1}'
and I have my 'keyring'
When I create the credential request
Then print my 'credential request' as 'credential request'
EOF
    save_output "request_${1}.json"
    rm $TMP/out

	## ISSUER SIGNS
	cat <<EOF | zexe issuer_sign_${1}.zen issuer_keypair.json request_${1}.json
Scenario credential
Given I am 'The Authority'
and I have my 'keyring'
and I have a 'credential request' inside '${1}'
when I create the credential signature
and I create the issuer public key
Then print the 'credential signature'
and print the 'issuer public key'
EOF
    save_output "issuer_signature_${1}.json"
    rm $TMP/out

	## PARTICIPANT AGGREGATES SIGNED CREDENTIAL
	cat <<EOF | zexe aggr_cred_${1}.zen keypair_${1}.json issuer_signature_${1}.json
Scenario credential
Given I am '${1}'
and I have my 'keyring'
and I have a 'credential signature'
when I create the credentials
then print 'credentials'
and print 'keyring'
EOF
    save_output "verified_credential_${1}.json"
    rm $TMP/out
}

@test "CREATE Reflow seal" {
    generate_participant "Alice"
    generate_participant "Bob"
    generate_participant "Carl"
}

@test "Generate seal" {
    echo "# join the verifiers of signed credentials" >&3
    json_join $BATS_SUITE_TMPDIR/public_key_Alice.json $BATS_SUITE_TMPDIR/public_key_Bob.json $BATS_SUITE_TMPDIR/public_key_Carl.json | save_asset public_keys.json
    echo "{\"public_keys\": `cat $BATS_SUITE_TMPDIR/public_keys.json` }" | save_asset public_key_array.json

    cat <<EOF | save_asset uid.json
{
   "Sale":{
      "Buyer":"Alice",
      "Seller":"Bob",
	  "Witness":"Carl",
      "Good":"Cow",
      "Price":100,
      "Currency":"EUR",
      "Timestamp":"1422779638",
      "Text":"Bob sells the cow to Alice, cause the cow grew too big and Carl, Bob's roomie, was complaining"
   }
}
EOF

    echo "# anyone can start a seal" >&3

    cat <<EOF | zexe seal_start.zen uid.json public_key_array.json
Scenario reflow
Given I have a 'reflow public key array' named 'public keys'
and I have a 'string dictionary' named 'Sale'
When I aggregate the reflow public key from array 'public keys'
and I create the reflow identity of 'Sale'
and I create the reflow seal with identity 'reflow identity'
Then print the 'reflow seal'
EOF
    save_output "reflow_seal.json"


    cat $BATS_SUITE_TMPDIR/reflow_seal.json | save_asset reflow_seal_empty.json

    # anyone can require a verified credential to be able to sign, chosing
    # the right issuer verifier for it
    json_join $BATS_SUITE_TMPDIR/issuer_verifier.json $BATS_SUITE_TMPDIR/reflow_seal.json | save_asset credential_to_sign.json
}

# PARTICIPANT SIGNS (function)
function participant_sign() {
	local name=$1
	cat <<EOF | zexe sign_seal.zen credential_to_sign.json verified_credential_$name.json
Scenario reflow
Given I am '$name'
and I have the 'credentials'
and I have the 'keyring'
and I have a 'reflow seal'
and I have a 'issuer public key' from 'The Authority'
When I create the reflow signature
Then print the 'reflow signature'
EOF
    save_output "signature_$name.json"
}

@test "Partecipants sign" {
    participant_sign 'Alice'
    participant_sign 'Bob'
    participant_sign 'Carl'
}

function collect_sign() {
	local name=$1
	local tmp_msig=$1_msig.json
	local tmp_sig=$1_sig.json
	cat $BATS_SUITE_TMPDIR/reflow_seal.json | save_asset $tmp_msig
#	json_join issuer_verifier.json signature_$name.json > $tmp_sig
	jq -s '.[0] * .[1]' $BATS_SUITE_TMPDIR/issuer_verifier.json $BATS_SUITE_TMPDIR/signature_$name.json | save_asset issuer_verifier_signature_$name.json
	cat << EOF | zexe collect_sign.zen $tmp_msig issuer_verifier_signature_$name.json
Scenario reflow
Given I have a 'reflow seal'
and I have a 'issuer public key' in 'The Authority'
and I have a 'reflow signature'
When I aggregate all the issuer public keys
and I verify the reflow signature credential
and I check the reflow signature fingerprint is new
and I add the reflow fingerprint to the reflow seal
and I add the reflow signature to the reflow seal
Then print the 'reflow seal'
EOF
    save_output reflow_seal.json
	rm -f $tmp_msig
}


@test "COLLECT UNIQUE SIGNATURES" {
    collect_sign 'Alice'
    collect_sign 'Bob'
    collect_sign 'Carl'
}

@test "VERIFY SIGNATURE" {
    cat << EOF | zexe verify_sign.zen reflow_seal.json
Scenario reflow
Given I have a 'reflow seal'
When I verify the reflow seal is valid
Then print the string 'SUCCESS'
and print the 'reflow seal'
EOF
}

@test "VERIFY IDENTITY" {
    cat << EOF | zexe verify_identity.zen reflow_seal.json uid.json
Scenario 'reflow' : Verify the identity in the seal
Given I have a 'reflow seal'
Given I have a 'string dictionary' named 'Sale'
When I create the reflow identity of 'Sale'
When I rename the 'reflow identity' to 'SaleIdentity'
When I verify 'SaleIdentity' is equal to 'identity' in 'reflow seal'
Then print the string 'The reflow identity in the seal is verified'
EOF


}
