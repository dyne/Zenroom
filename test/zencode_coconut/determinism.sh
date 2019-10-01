#!/bin/zsh

# test deterministic results across computations of petition contracts
# with same random seed - requires json-sort-cli from npm

pfx=.
seed="0c0ccdb5d2e702eab5472932409ad64c0c0ccdb5d2e702eab5472932409ad64c0c0ccdb5d2e702eab5472932409ad64c0c0ccdb5d2e702eab5472932409ad64c0c0ccdb5d2e702eab5472932409ad64c0c0ccdb5d2e702eab5472932409ad64c"

zenroom                                                            -z $pfx/credential_keygen.zen		             > keypair.keys
zenroom -k keypair.keys                                            -z $pfx/create_request.zen			             > blind_signature.req
zenroom                                                            -z $pfx/issuer_keygen.zen			             > ci_keypair.keys
zenroom -k ci_keypair.keys                                         -z $pfx/publish_verifier.zen				     > ci_verify_keypair.keys
zenroom -k ci_keypair.keys            -a blind_signature.req       -z $pfx/issuer_sign.zen				     > ci_signed_credential.json
zenroom -k keypair.keys               -a ci_signed_credential.json -z $pfx/aggregate_signature.zen			     > credential.json
zenroom -k credential.json            -a ci_verify_keypair.keys    -z $pfx/create_proof.zen	   	                     > blindproof_credential.json
zenroom -k blindproof_credential.json -a ci_verify_keypair.keys    -z $pfx/verify_proof.zen
zenroom -S $seed -k credential.json            -a ci_verify_keypair.keys    -z $pfx/create_petition.zen            	     > petition_request.json
zenroom -S $seed -k credential.json            -a ci_verify_keypair.keys    -z $pfx/create_petition.zen         	     > petition_request2.json
zenroom -S $seed -k credential.json            -a ci_verify_keypair.keys    -z $pfx/create_petition.zen              	     > petition_request3.json

zenroom -k ci_verify_keypair.keys     -a petition_request.json     -z $pfx/approve_petition.zen			             > petition.json

zenroom -S $seed -k credential.json            -a ci_verify_keypair.keys    -z $pfx/sign_petition.zen 	                     > petition_signature.json
zenroom -S $seed -k credential.json            -a ci_verify_keypair.keys    -z $pfx/sign_petition.zen        	             > petition_signature2.json
zenroom -S $seed -k credential.json            -a ci_verify_keypair.keys    -z $pfx/sign_petition.zen              	     > petition_signature3.json

zenroom -S $seed -k petition.json              -a petition_signature.json   -z $pfx/aggregate_petition_signature.zen            > petition_increase.json
zenroom -S $seed -k petition.json              -a petition_signature.json   -z $pfx/aggregate_petition_signature.zen            > petition_increase2.json
zenroom -S $seed -k petition.json              -a petition_signature.json   -z $pfx/aggregate_petition_signature.zen           > petition_increase3.json

zenroom -k credential.json            -a petition_increase.json    -z $pfx/tally_petition.zen			              > tally.json
zenroom -k tally.json                 -a petition_increase.json    -z $pfx/count_petition.zen

req=(petition_request.json petition_request2.json petition_request3.json)
sig=(petition_signature.json petition_signature2.json petition_signature3.json)
inc=(petition_increase.json petition_increase2.json petition_increase3.json)

for i in $req; do
	#jsonsort $i
	sha512sum $i
done
for i in $sig; do
	#jsonsort $i
	sha512sum $i
done
for i in $inc; do
	#jsonsort $i
	sha512sum $i
done
