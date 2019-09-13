#!/usr/bin/env zsh

set -e
set -u
set -o pipefail

alias zenroom="${1:-../../src/zenroom}"
pfx=.
echo
echo "=========================================="
echo "= COCONUT INTEGRATION TESTS - CREDENTIALS"
echo "=========================================="
echo
echo "###################################"
echo "## ZERO KNOWLEDGE CREDENTIAL"

# -credential-keygen
zenroom -z $pfx/credential_keygen.zen | tee keypair.keys

# -credential-request
zenroom -k keypair.keys -z $pfx/create_request.zen | tee request.json

# _ISSUER-keygen
zenroom -z $pfx/issuer_keygen.zen | tee issuer_keypair.keys

# _ISSUER-publish-verifier
zenroom -k issuer_keypair.keys -z $pfx/publish_verifier.zen | tee verifier.json

# _ISSUER-credential-sign
zenroom -k issuer_keypair.keys -a request.json -z $pfx/issuer_sign.zen | tee signature.json

# -aggregate-credential-signature
# this generates sigma (AggCred(σ1, . . . , σt) → (σ):) 
zenroom -k keypair.keys -a signature.json -z $pfx/aggregate_signature.zen | tee credentials.json

# -prove-credential
# this generates theta (❖ ProveCred(vk, m, φ0) → (Θ, φ0):
zenroom -k credentials.json -a verifier.json -z $pfx/create_proof.zen | tee proof.json

# -VERIFIER-verify-credential
# returns a boolean VerifyCred(vk, Θ, φ0) 
zenroom -k proof.json -a verifier.json -z $pfx/verify_proof.zen
