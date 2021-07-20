#!/usr/bin/env bash

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

# sideload='../../src/lua/zencode_reflow.lua'

## ISSUER
cat <<EOF | zexe issuer_keygen.zen | save reflow issuer_keypair.json
Scenario credential
Given I am 'The Authority'
when I create the issuer key
Then print my 'keys'
EOF


cat <<EOF | zexe issuer_verifier.zen -a issuer_keypair.json | save reflow issuer_verifier.json
Scenario credential: publish verifier
Given that I am known as 'The Authority'
and I have my 'keys'
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
Then print my 'keys'
EOF

	cat <<EOF | zexe pubkey_${1}.zen -k keypair_${1}.json | save reflow public_key_${1}.json
Scenario reflow
Given I am '${1}'
and I have my 'keys'
When I create the reflow public key
Then print my 'reflow public key'
EOF

	cat <<EOF | zexe request_${1}.zen -k keypair_${1}.json | save reflow request_${1}.json
Scenario credential
Given I am '${1}'
and I have my 'keys'
When I create the credential request
Then print my 'credential request'
EOF
	##

	## ISSUER SIGNS
	cat <<EOF | zexe issuer_sign_${1}.zen -k issuer_keypair.json -a request_${1}.json | save reflow issuer_signature_${1}.json
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
	cat <<EOF | debug aggr_cred_${1}.zen -k keypair_${1}.json -a issuer_signature_${1}.json | save reflow verified_credential_${1}.json
Scenario credential
Given I am '${1}'
and I have my 'keys'
and I have a 'credential signature'
when I create the credentials
then print 'credentials'
and print 'keys'
EOF
	##
echo "OK $1"
}

# generate  signed credentials
generate_participant "Alice"

echo "# join the verifiers of signed credentials"
json_join public_key_Alice.json > public_keys.json
echo "{\"public_keys\": `cat public_keys.json` }" > public_key_array.json

cat <<EOF > Example.json
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
cat <<EOF | zexe seal_start.zen -k Example.json -a public_key_array.json | save reflow reflow_seal.json
Scenario reflow
Given I have a 'reflow public key array' named 'public keys'
and I have a 'string dictionary' named 'Sale'
When I aggregate the reflow public key from array 'public keys'
and I create the reflow identity of 'Sale'
and I create the reflow seal with identity 'reflow identity'
Then print the 'reflow seal'
EOF
#

cat << EOF | zexe verify_identity.zen -a reflow_seal.json -k Example.json | jq .
Scenario 'reflow' : Verify the identity in the seal 
Given I have a 'reflow seal'
Given I have a 'string dictionary' named 'Sale'
When I create the reflow identity of 'Sale'
When I rename the 'reflow identity' to 'SaleIdentity'
Then print all data
EOF
