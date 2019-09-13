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
zenroom -k credentials.json -a verifier.json -z $pfx/create_petition.zen | tee petition_request.json

# -VERIFIER-approve-petition
zenroom -k verifier.json -a petition_request.json -z $pfx/approve_petition.zen | tee petition.json

# -CITIZEN-sign-petition
zenroom -k credentials.json -a verifier.json -z $pfx/sign_petition.zen | tee petition_signature.json

# -LEDGER-add-signed-petition
zenroom -k petition.json -a petition_signature.json -z $pfx/aggregate_petition_signature.zen | tee petition-increase.json

# -CITIZEN-tally-petition
zenroom -k credentials.json -a petition-increase.json -z $pfx/tally_petition.zen | tee tally.json

# 14-CITIZEN-count-petition
zenroom -k tally.json -a petition-increase.json -z $pfx/count_petition.zen

