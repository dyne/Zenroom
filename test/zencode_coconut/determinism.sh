#!/bin/zsh

# test deterministic results across computations of petition contracts
# with same random seed - requires json-sort-cli from npm

pfx=src
seed="0c0ccdb5d2e702eab5472932409ad64c0c0ccdb5d2e702eab5472932409ad64c0c0ccdb5d2e702eab5472932409ad64c0c0ccdb5d2e702eab5472932409ad64c0c0ccdb5d2e702eab5472932409ad64c0c0ccdb5d2e702eab5472932409ad64c"

zenroom                                                            -z $pfx/01-CITIZEN-credential-keygen.zencode              > keypair.keys
zenroom -k keypair.keys                                            -z $pfx/02-CITIZEN-credential-request.zencode             > blind_signature.req
zenroom                                                            -z $pfx/03-CREDENTIAL_ISSUER-keygen.zencode               > ci_keypair.keys
zenroom -k ci_keypair.keys                                         -z $pfx/04-CREDENTIAL_ISSUER-publish-verifier.zencode     > ci_verify_keypair.keys
zenroom -k ci_keypair.keys            -a blind_signature.req       -z $pfx/05-CREDENTIAL_ISSUER-credential-sign.zencode      > ci_signed_credential.json
zenroom -k keypair.keys               -a ci_signed_credential.json -z $pfx/06-CITIZEN-aggregate-credential-signature.zencode > credential.json
zenroom -k credential.json            -a ci_verify_keypair.keys    -z $pfx/07-CITIZEN-prove-credential.zencode               > blindproof_credential.json
zenroom -k blindproof_credential.json -a ci_verify_keypair.keys    -z $pfx/08-VERIFIER-verify-credential.zencode
zenroom -S $seed -k credential.json            -a ci_verify_keypair.keys    -z $pfx/09-CITIZEN-create-petition.zencode                > petition_request.json
zenroom -S $seed -k credential.json            -a ci_verify_keypair.keys    -z $pfx/09-CITIZEN-create-petition.zencode                > petition_request2.json
zenroom -S $seed -k credential.json            -a ci_verify_keypair.keys    -z $pfx/09-CITIZEN-create-petition.zencode                > petition_request3.json

zenroom -k ci_verify_keypair.keys     -a petition_request.json     -z $pfx/10-VERIFIER-approve-petition.zencode              > petition.json

zenroom -S $seed -k credential.json            -a ci_verify_keypair.keys    -z $pfx/11-CITIZEN-sign-petition.zencode                  > petition_signature.json
zenroom -S $seed -k credential.json            -a ci_verify_keypair.keys    -z $pfx/11-CITIZEN-sign-petition.zencode                  > petition_signature2.json
zenroom -S $seed -k credential.json            -a ci_verify_keypair.keys    -z $pfx/11-CITIZEN-sign-petition.zencode                  > petition_signature3.json

zenroom -S $seed -k petition.json              -a petition_signature.json   -z $pfx/12-LEDGER-add-signed-petition.zencode             > petition_increase.json
zenroom -S $seed -k petition.json              -a petition_signature.json   -z $pfx/12-LEDGER-add-signed-petition.zencode             > petition_increase2.json
zenroom -S $seed -k petition.json              -a petition_signature.json   -z $pfx/12-LEDGER-add-signed-petition.zencode             > petition_increase3.json

zenroom -k credential.json            -a petition_increase.json    -z $pfx/13-CITIZEN-tally-petition.zencode                 > tally.json
zenroom -k tally.json                 -a petition_increase.json    -z $pfx/14-CITIZEN-count-petition.zencode

req=(petition_request.json petition_request2.json petition_request3.json)
sig=(petition_signature.json petition_signature2.json petition_signature3.json)
inc=(petition_increase.json petition_increase2.json petition_increase3.json)

for i in $req; do
	jsonsort $i
	sha512sum $i
done
for i in $sig; do
	jsonsort $i
	sha512sum $i
done
for i in $inc; do
	jsonsort $i
	sha512sum $i
done
