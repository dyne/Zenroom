#!/usr/bin/env zsh

set -e
set -u
set -o pipefail
# set -x
# https://coderwall.com/p/fkfaqq/safer-bash-scripts-with-set-euxo-pipefail

alias zenroom="${1:-../../src/zenroom}"

pfx=.

echo "###################################"
echo "## PETITION"

# -CITIZEN-create-petition
zenroom -k credential.json -a ci_verify_keypair.keys -z $pfx/PETIT01.zen | tee petition_request.json

# -VERIFIER-approve-petition
zenroom -k ci_verify_keypair.keys -a petition_request.json -z $pfx/PETIT02.zen | tee petition.json

# -CITIZEN-sign-petition
zenroom -k credential.json -a ci_verify_keypair.keys -z $pfx/PETIT03.zen | tee petition_signature.json

# -LEDGER-add-signed-petition
zenroom -k petition.json -a petition_signature.json -z $pfx/PETIT04.zen | tee petition-increase.json

# -CITIZEN-tally-petition
zenroom -k credential.json -a petition-increase.json -z $pfx/PETIT05.zen | tee tally.json

# 14-CITIZEN-count-petition
zenroom -k tally.json -a petition-increase.json -z $pfx/PETIT06.zen

