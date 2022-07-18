#!/usr/bin/env bash

RNGSEED='random'


####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

# sideload='../../src/lua/zencode_reflow.lua'

echo -e "${yellow} ======================================================" 
echo -e "${yellow} ======================================================" 
echo -e "${yellow} ======================================================" 
echo -e "${yellow} =============== Clean Up =========================" 
echo -e "${yellow} ======================================================" 
echo -e "${yellow} ======================================================" 
echo -e "${yellow} ======================================================${reset}" 

rm -f *.json
rm -f *.zen


## ISSUER
cat <<EOF | zexe issuer_keygen.zen | save reflow issuer_keypair.json
Scenario credential
Given I am 'The Authority'
when I create the issuer key
Then print my 'keyring'
EOF


cat <<EOF | zexe issuer_verifier.zen -a issuer_keypair.json | save reflow issuer_verifier.json
Scenario credential: publish verifier
Given that I am known as 'The Authority'
and I have my 'keyring'
When I create the issuer public key
Then print my 'issuer public key'
EOF

generate_participant() {
    local name=$1
    ## PARTICIPANT
	cat <<EOF | zexe keygen_${1}.zen | save reflow keypair_${1}.json
Scenario reflow
Given I am '${1}'
When I create the reflow key
and I create the credential key
Then print my 'keyring'
EOF

	cat <<EOF | zexe pubkey_${1}.zen -k keypair_${1}.json | save reflow public_key_${1}.json
Scenario reflow
Given I am '${1}'
and I have my 'keyring'
When I create the reflow public key
Then print my 'reflow public key'
EOF

	cat <<EOF | zexe request_${1}.zen -k keypair_${1}.json | save reflow request_${1}.json
Scenario credential
Given I am '${1}'
and I have my 'keyring'
When I create the credential request
Then print my 'credential request' as 'credential request'
EOF
	##

	## ISSUER SIGNS
	cat <<EOF | zexe issuer_sign_${1}.zen -k issuer_keypair.json -a request_${1}.json | save reflow issuer_signature_${1}.json
Scenario credential
Given I am 'The Authority'
and I have my 'keyring'
and I have a 'credential request' inside '${1}'
when I create the credential signature
and I create the issuer public key
Then print the 'credential signature'
and print the 'issuer public key'
EOF
	##

	## PARTICIPANT AGGREGATES SIGNED CREDENTIAL
	cat <<EOF | zexe aggr_cred_${1}.zen -k keypair_${1}.json -a issuer_signature_${1}.json | save reflow verified_credential_${1}.json
Scenario credential
Given I am '${1}'
and I have my 'keyring'
and I have a 'credential signature'
when I create the credentials
then print 'credentials'
and print 'keyring'
EOF
	##
echo "OK $1"
}

# generate  signed credentials
generate_participant "Alice"
generate_participant "Bob"
generate_participant "Carl"

echo "# join the verifiers of signed credentials"
json_join public_key_Alice.json public_key_Bob.json public_key_Carl.json > public_keys.json
echo "{\"public_keys\": `cat public_keys.json` }" > public_key_array.json

cat public_key_array.json | save reflow public_key_array.json

cat <<EOF | save reflow uid.json
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



echo "# anyone can start a seal"

# CREATE Reflow seal
cat <<EOF | zexe seal_start.zen -k uid.json -a public_key_array.json | save reflow reflow_seal.json
Scenario reflow
Given I have a 'reflow public key array' named 'public keys'
and I have a 'string dictionary' named 'Sale'
When I aggregate the reflow public key from array 'public keys'
and I create the reflow identity of 'Sale'
and I create the reflow seal with identity 'reflow identity'
Then print the 'reflow seal'
EOF
#

cp -v reflow_seal.json reflow_seal_empty.json
cat reflow_seal_empty.json | save reflow reflow_seal_empty.json


# anyone can require a verified credential to be able to sign, chosing
# the right issuer verifier for it
json_join issuer_verifier.json reflow_seal.json | save reflow credential_to_sign.json


# PARTICIPANT SIGNS (function)
function participant_sign() {
	local name=$1
	cat <<EOF | zexe sign_seal.zen -a credential_to_sign.json -k verified_credential_$name.json | save reflow signature_$name.json
Scenario reflow
Given I am '$name'
and I have the 'credentials'
and I have the 'keyring'
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
	cp -v reflow_seal.json $tmp_msig
#	json_join issuer_verifier.json signature_$name.json > $tmp_sig
	jq -s '.[0] * .[1]' issuer_verifier.json signature_$name.json | save reflow issuer_verifier_signature_$name.json
	cat << EOF | zexe collect_sign.zen -a $tmp_msig -k issuer_verifier_signature_$name.json | save reflow reflow_seal.json
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
	rm -f $tmp_msig
}

# COLLECT UNIQUE SIGNATURES
collect_sign 'Alice'
collect_sign 'Bob'
collect_sign 'Carl'


# VERIFY SIGNATURE
cat << EOF | zexe verify_sign.zen -a reflow_seal.json | jq .
Scenario reflow
Given I have a 'reflow seal'
When I verify the reflow seal is valid
Then print the string 'SUCCESS'
and print the 'reflow seal'
EOF

cat << EOF | zexe verify_identity.zen -a reflow_seal.json -k uid.json
Scenario 'reflow' : Verify the identity in the seal 
Given I have a 'reflow seal'
Given I have a 'string dictionary' named 'Sale'
When I create the reflow identity of 'Sale'
When I rename the 'reflow identity' to 'SaleIdentity'
When I verify 'SaleIdentity' is equal to 'identity' in 'reflow seal'
Then print the string 'The reflow identity in the seal is verified'
EOF

for i in *.zen; do cat $i | save reflow $i 2>/dev/null; done
