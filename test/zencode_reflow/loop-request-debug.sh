#!/usr/bin/env bash

######
# Setup output color aliases
#
# echo "${red}red text ${green}green text${reset}"
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
reset=`tput sgr0`



#### SETUP OUTPUT FOLDER and cleaning
# ${out}/credentialParticipantKeygen.zen
# out='../../docs/examples/zencode_cookbook'
# out='./files'
out='/run/shm/loop-request'


mkdir -p ${out}
rm -f ${out}/*
rm -f ${out}/zenroom-test-summary.txt

## ISSUER creation
cat <<EOF | zenroom -z  > ${out}/issuer_key.json
Scenario credential
Given I am 'The Authority'
when I create the issuer key
Then print my 'keyring'
EOF

cat <<EOF | zenroom -z -k ${out}/issuer_key.json  > ${out}/issuer_public_key.json
Scenario credential: publish verifier
Given that I am known as 'The Authority'
and I have my 'keyring'
When I create the issuer public key
Then print my 'issuer public key'
EOF
##


name=Alice
    ## PARTICIPANT
	cat <<EOF | zenroom -z > ${out}/keypair_${name}.json
Scenario reflow
Scenario credential
Given I am '${name}'
When I create the BLS key
and I create the credential key
Then print my 'keyring'
EOF

# 	cat <<EOF | zenroom
#  ${out}/pubkey_${name}.zen -k ${out}/keypair_${name}.json  > ${out}/public_key_${name}.json
# Scenario reflow
# Given I am '${name}'
# and I have my 'keyring'
# When I create the BLS public key
# Then print my 'bls public key'
# EOF

cat << EOF > credential_request.zen
Scenario credential
Given I am '${name}'
and I have my 'keyring'
When I create the credential request
Then print my 'credential request'
EOF

while true; do
 gdb -x .gdbinit --args ../../src/zenroom -cdebug=3 -z credential_request.zen -k ${out}/keypair_${name}.json 
done

