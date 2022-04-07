# shared functions among test scripts in zencode_reflow
# use with: source shared_lib.sh

generate_issuer() {
## ISSUER creation
cat <<EOF | zexe issuer_keygen.zen  | save reflow issuer_keypair.json
Scenario credential
Given I am 'The Authority'
when I create the issuer key
Then print my 'keyring'
EOF

cat <<EOF | zexe issuer_verifier.zen -k issuer_keypair.json  | save reflow issuer_verifier.json
Scenario credential: publish verifier
Given that I am known as 'The Authority'
Given I have my 'keyring'
When I create the issuer public key
Then print my 'issuer public key'
EOF
##
}

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
Then print my 'credential request'
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
then print my 'credentials'
and print my 'keyring'
EOF
	##
echo "OK $1"
}

## TODO:
# 1. generate parent dictionaries, sign them
# 2. generate a child dictionary from parents (identity sum)
# 3. sign the child dictionary and the parents
# 4. verify the child dictionary and the parents
