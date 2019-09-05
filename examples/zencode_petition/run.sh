#!/bin/bash

set -e
set -u
set -o pipefail
# set -x
# https://coderwall.com/p/fkfaqq/safer-bash-scripts-with-set-euxo-pipefail

pfx=.

zenroom                                                            -z $pfx/01-CITIZEN-credential-keygen.zencode              > keypair.keys
zenroom -k keypair.keys                                            -z $pfx/02-CITIZEN-credential-request.zencode             > blind_signature.req
zenroom                                                            -z $pfx/03-CREDENTIAL_ISSUER-keygen.zencode               > ci_keypair.keys
zenroom -k ci_keypair.keys                                         -z $pfx/04-CREDENTIAL_ISSUER-publish-verifier.zencode     > ci_verify_keypair.keys
zenroom -k ci_keypair.keys            -a blind_signature.req       -z $pfx/05-CREDENTIAL_ISSUER-credential-sign.zencode      > ci_signed_credential.json
zenroom -k keypair.keys               -a ci_signed_credential.json -z $pfx/06-CITIZEN-aggregate-credential-signature.zencode > credential.json
zenroom -k credential.json            -a ci_verify_keypair.keys    -z $pfx/07-CITIZEN-prove-credential.zencode               > blindproof_credential.json
zenroom -k blindproof_credential.json -a ci_verify_keypair.keys    -z $pfx/08-VERIFIER-verify-credential.zencode
zenroom -k credential.json            -a ci_verify_keypair.keys    -z $pfx/09-CITIZEN-create-petition.zencode                > petition_request.json
zenroom -k ci_verify_keypair.keys     -a petition_request.json     -z $pfx/10-VERIFIER-approve-petition.zencode              > petition.json
zenroom                               -a petition.json             -z $pfx/51-LEDGER-validate-petition.zencode              > petition_validation.json
zenroom -k credential.json            -a ci_verify_keypair.keys    -z $pfx/11-CITIZEN-sign-petition.zencode                  > petition_signature.json
zenroom -k petition.json              -a petition_signature.json   -z $pfx/12-LEDGER-add-signed-petition.zencode             > petition-increase.json
zenroom -k credential.json            -a petition-increase.json    -z $pfx/13-CITIZEN-tally-petition.zencode                 > tally.json
zenroom -k tally.json                 -a petition-increase.json    -z $pfx/14-CITIZEN-count-petition.zencode

return $?
