#!/usr/bin/env bash

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

# sideload='../../src/lua/zencode_reflow.lua'

out='../../docs/examples/zencode_cookbook/reflow'
mkdir -p ${out}
rm ${out}/*

## ISSUER
cat <<EOF | zexe ${out}/issuer_keygen.zen | tee ${out}/issuer_keypair.json
Scenario credential
Given I am 'The Authority'
when I create the issuer key
Then print my 'keys'
EOF


cat <<EOF | zexe ${out}/issuer_verifier.zen -a ${out}/issuer_keypair.json | tee ${out}/issuer_verifier.json
Scenario credential: publish verifier
Given that I am known as 'The Authority'
and I have my 'keys'
When I create the issuer public key
Then print my 'issuer public key'
EOF

generate_participant() {
    local name=$1
    ## PARTICIPANT
	cat <<EOF | zexe ${out}/keygen_${1}.zen | tee ${out}/keypair_${1}.json
Scenario reflow
Scenario credential
Given I am '${1}'
When I create the BLS key
and I create the credential key
Then print my 'keys'
EOF

	cat <<EOF | zexe ${out}/pubkey_${1}.zen -k ${out}/keypair_${1}.json | tee ${out}/public_key_${1}.json
Scenario reflow
Given I am '${1}'
and I have my 'keys'
When I create the BLS public key
Then print my 'bls public key'
EOF

	cat <<EOF | zexe ${out}/request_${1}.zen -k ${out}/keypair_${1}.json | tee ${out}/request_${1}.json
Scenario credential
Given I am '${1}'
and I have my 'keys'
When I create the credential request
Then print my 'credential request'
EOF
	##

	## ISSUER SIGNS
	cat <<EOF | zexe ${out}/issuer_sign_${1}.zen -k ${out}/issuer_keypair.json -a ${out}/request_${1}.json | tee ${out}/issuer_signature_${1}.json
Scenario credential
Given I am 'The Authority'
and I have my 'keys'
and I have a 'credential request' inside '${1}'
when I create the credential signature
and I create the issuer public key
Then print the 'credential signature'
and print the 'issuer public key'
EOF
	##

	## PARTICIPANT AGGREGATES SIGNED CREDENTIAL
	cat <<EOF | zexe ${out}/aggr_cred_${1}.zen -k ${out}/keypair_${1}.json -a ${out}/issuer_signature_${1}.json | tee ${out}/verified_credential_${1}.json
Scenario credential
Given I am '${1}'
and I have my 'keys'
and I have a 'credential signature'
when I create the credentials
then print my 'credentials'
and print my 'keys'
EOF
	##

}

# generate  signed credentials
generate_participant "Alice"
generate_participant "Bob"
generate_participant "Carl"

# join the verifiers of signed credentials
# json_join ${out}/verifier_Alice.json ${out}/verifier_Bob.json ${out}/verifier_Carl.json > ${out}/public_keys.json
# echo "{\"public_keys\": `cat ${out}/public_keys.json` }" > ${out}/public_key_array.json

echo "${yellow} =========================== merging public keys ===================${reset}" 

jq -s 'reduce .[] as $item ({}; . * $item)' . ${out}/public_key_* | tee ${out}/public_keys.json

echo "${yellow} =========================== writing public keys array ===================${reset}"

echo "{\"public_keys\": `cat ${out}/public_keys.json` }" | tee ${out}/public_key_array.json

# make a uid using the current timestamp
#echo "{\"today\": \"`date +'%s'`\"}" > ${out}/uid.json

cat <<EOF > ${out}/uid.json
{
   "Sale":{
      "Buyer":"Alice",
      "Seller":"Bob",
	  "Witness":"Carl",
      "Good":"Cow",
      "Price":100,
      "Currency":"EUR",
      "Timestamp":1422779638,
      "Text":"Bob sells the cow to Alice, cause the cow grew too big and Carl, Bob's roomie, was complaining"
   }
}
EOF



# anyone can start a seal

# CREATE Reflow seal
cat <<EOF | zexe ${out}/seal_start.zen -k ${out}/uid.json -a ${out}/public_key_array.json | tee ${out}/reflow_seal.json
Scenario reflow
Given I have a 'bls public key array' named 'public keys'
and I have a 'string dictionary' named 'Sale'
When I aggregate the bls public key from array 'public keys'
and I rename the 'bls public key' to 'reflow public key'
and I create the reflow identity of 'Sale'
and I create the reflow seal with identity 'reflow identity'
Then print the 'reflow seal'
EOF
#

cp -v ${out}/reflow_seal.json ${out}/reflow_seal_empty.json

# anyone can require a verified credential to be able to sign, chosing
# the right issuer verifier for it
json_join ${out}/issuer_verifier.json ${out}/reflow_seal.json > ${out}/credential_to_sign.json


# PARTICIPANT SIGNS (function)
function participant_sign() {
	local name=$1
	cat <<EOF | zexe ${out}/sign_seal.zen -a ${out}/credential_to_sign.json -k ${out}/verified_credential_$name.json | tee ${out}/signature_$name.json
Scenario reflow
Scenario credential
Given I am '$name'
and I have my 'credentials'
and I have my 'keys'
and I have a 'reflow seal'
and I have a 'issuer public key' from 'The Authority'
When I create the reflow signature
Then print the 'reflow signature'
EOF
}

participant_sign 'Alice'
participant_sign 'Bob'
participant_sign 'Carl'

function collect_sign() {
	local name=$1
	local tmp_msig=`mktemp`
	local tmp_sig=`mktemp`
	cp -v ${out}/reflow_seal.json $tmp_msig
#	json_join ${out}/issuer_verifier.json ${out}/signature_$name.json > $tmp_sig
	jq -s '.[0] * .[1]' ${out}/issuer_verifier.json ${out}/signature_$name.json > ${out}/issuer_verifier_signature_$name.json
	cat << EOF | zexe ${out}/collect_sign.zen -a $tmp_msig -k ${out}/issuer_verifier_signature_$name.json | tee ${out}/reflow_seal.json
Scenario reflow
Scenario credential
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
	rm -f $tmp_msig
}

# COLLECT UNIQUE SIGNATURES
collect_sign 'Alice'
collect_sign 'Bob'
collect_sign 'Carl'


# VERIFY SIGNATURE
cat << EOF | zexe ${out}/verify_sign.zen -a ${out}/reflow_seal.json | jq .
Scenario reflow
Given I have a 'reflow seal'
When I verify the reflow seal is valid
Then print the string 'SUCCESS'
and print the 'reflow seal'
EOF


cat << EOF | zexe ${out}/verify_identity.zen -a ${out}/reflow_seal.json -k ${out}/uid.json  | jq .
Scenario 'reflow' : Verify the identity in the seal 
Given I have a 'reflow seal'
Given I have a 'string dictionary' named 'Sale'
When I create the reflow identity of 'Sale'
When I rename the 'reflow identity' to 'SaleIdentity'
When I verify 'SaleIdentity' is equal to 'identity' in 'reflow seal'
Then print the string 'The reflow identity in the seal is verified'
EOF
