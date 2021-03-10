#!/usr/bin/env bash

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

sideload='../../src/lua/zencode_multidarkroom.lua'

## ISSUER
cat <<EOF | zexe issuer_keygen.zen | tee issuer_keypair.json
Scenario credential
Given I am 'The Authority'
when I create the issuer key
Then print my 'keys'
EOF

cat <<EOF | zexe issuer_verifier.zen -a issuer_keypair.json | tee issuer_verifier.json
Scenario credential: publish verifier
Given that I am known as 'The Authority'
and I have my 'keys'
When I create the issuer public key
Then print my 'issuer public key'
EOF

generate_participant() {
    local name=$1
    ## PARTICIPANT
	cat <<EOF | zexe keygen_${1}.zen | tee keypair_${1}.json
Scenario multidarkroom
Scenario credential
Given I am '${1}'
When I create the BLS key
and I create the credential key
Then print my 'keys'
EOF

	cat <<EOF | zexe pubkey_${1}.zen -k keypair_${1}.json | tee verifier_${1}.json
Scenario multidarkroom
Given I am '${1}'
and I have my 'keys'
When I create the BLS public key
Then print my 'bls public key'
EOF

	cat <<EOF | zexe request_${1}.zen -k keypair_${1}.json | tee request_${1}.json
Scenario credential
Given I am '${1}'
and I have my 'keys'
When I create the credential request
Then print my 'credential request'
EOF
	##

	## ISSUER SIGNS
	cat <<EOF | zexe issuer_sign_${1}.zen -k issuer_keypair.json -a request_${1}.json | tee issuer_signature_${1}.json
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
	cat <<EOF | zexe aggr_cred_${1}.zen -k keypair_${1}.json -a issuer_signature_${1}.json | tee verified_credential_${1}.json
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

# generate two signed credentials
generate_participant "Alice"
generate_participant "Bob"

# join the verifiers of signed credentials
json_join verifier_Alice.json verifier_Bob.json > public_keys.json
echo "{\"public_keys\": `cat public_keys.json` }" > public_key_array.json
# make a uid using the current timestamp
echo "{\"today\": \"`date +'%s'`\"}" > uid.json

# anyone can start a session

# SIGNING SESSION
cat <<EOF | debug session_start.zen -k uid.json -a public_key_array.json > multidarkroom_session.json
Scenario multidarkroom
Given I have a 'bls public key array' named 'public keys'
and I have a 'string' named 'today'
When I aggregate the bls public key from array 'public keys'
and I rename the 'bls public key' to 'multidarkroom public key'
and I create the multidarkroom session with uid 'today'
Then print the 'multidarkroom session'
EOF
#

# anyone can require a verified credential to be able to sign, chosing
# the right issuer verifier for it
json_join issuer_verifier.json multidarkroom_session.json > credential_to_sign.json


# PARTICIPANT SIGNS (function)
function participant_sign() {
	local name=$1
	cat <<EOF | zexe sign_session.zen -a credential_to_sign.json -k verified_credential_$name.json | tee signature_$name.json
Scenario multidarkroom
Scenario credential
Given I am '$name'
and I have my 'credentials'
and I have my 'keys'
and I have a 'multidarkroom session'
and I have a 'issuer public key' from 'The Authority'
When I create the multidarkroom signature
Then print the 'multidarkroom signature'
EOF
}

participant_sign 'Alice'
participant_sign 'Bob'

function collect_sign() {
	local name=$1
	local tmp_msig=`mktemp`
	local tmp_sig=`mktemp`
	cp -v multidarkroom_session.json $tmp_msig
	json_join issuer_verifier.json signature_$name.json > $tmp_sig
	cat << EOF | zexe collect_sign.zen -a $tmp_msig -k $tmp_sig | tee multidarkroom_session.json
Scenario multidarkroom
Scenario credential
Given I have a 'multidarkroom session'
and I have a 'issuer public key' in 'The Authority'
and I have a 'multidarkroom signature'
When I aggregate all the issuer public keys
and I verify the multidarkroom signature credential
and I check the multidarkroom signature fingerprint is new
and I add the multidarkroom fingerprint to the multidarkroom session
and I add the multidarkroom signature to the multidarkroom session
Then print the 'multidarkroom session'
EOF
	rm -f $tmp_msig $tmp_sig
}

# COLLECT UNIQUE SIGNATURES
collect_sign 'Alice'
collect_sign 'Bob'

# VERIFY SIGNATURE
cat << EOF | zexe verify_sign.zen -a multidarkroom_session.json | jq .
Scenario multidarkroom
Given I have a 'multidarkroom session'
When I verify the multidarkroom session is valid
Then print 'SUCCESS'
and print the 'multidarkroom session'
EOF

