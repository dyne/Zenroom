load ../bats_setup
load ../bats_zencode

SUBDOC=zkp

Participants=10

users=""
for i in $(seq $Participants)
do
  users+=" Participant_${i}"
done

## ISSUER creation

@test "Issuer keygen" {
  cat <<EOF | zexe issuer_keygen.zen
Scenario credential
Given I am 'The Authority'
when I create the issuer key
Then print my 'keyring'
EOF
  save_output 'issuer_key.json'

}

@test "Issuer public key" {
  cat <<EOF | zexe issuer_public_key.zen issuer_key.json
Scenario credential: publish verifier
Given that I am known as 'The Authority'
and I have my 'keyring'
When I create the issuer public key
Then print my 'issuer public key'
EOF
  save_output "credentialIssuerpublic_key.json"
}

generate_participant() {
    local name=$1
    ## PARTICIPANT
    cat <<EOF | zexe keygen_${1}.zen
Scenario multidarkroom
Scenario credential
Given I am '${1}'
When I create the credential key
Then print my 'keyring'
EOF
    save_output "keypair_${1}.json"
    rm $TMP/out

    cat <<EOF | zexe request_${1}.zen keypair_${1}.json
Scenario credential
Given I am '${1}'
and I have my 'keyring'
When I create the credential request
Then print my 'credential request'
EOF
    save_output "request_${1}.json"
    rm $TMP/out
	##

    ## ISSUER SIGNS
    cat <<EOF | zexe issuer_sign_${1}.zen issuer_key.json request_${1}.json
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
    ##

    ## PARTICIPANT AGGREGATES SIGNED CREDENTIAL
    cat <<EOF | zexe aggr_cred_${1}.zen keypair_${1}.json issuer_signature_${1}.json
Scenario credential
Given I am '${1}'
and I have my 'keyring'
and I have a 'credential signature'
when I create the credentials
then print my 'credentials'
and print my 'keyring'
EOF
    save_output "verified_credential_${1}.json"
    rm $TMP/out
}


@test "Generate n signed credentials" {
    for user in ${users[@]}
    do
        echo  "now generating the participant: "  ${user}
        generate_participant ${user}
    done
}
