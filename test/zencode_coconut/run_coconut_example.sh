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
zenroom -z $pfx/CRED01.zen | tee keypair.keys

# -credential-request
zenroom -k keypair.keys -z $pfx/CRED02.zen | tee blind_signature.req

# _ISSUER-keygen
zenroom -z $pfx/CRED03.zen | tee ci_keypair.keys

# _ISSUER-publish-verifier
zenroom -k ci_keypair.keys -z $pfx/CRED04.zen |tee ci_verify_keypair.keys

# _ISSUER-credential-sign
zenroom -k ci_keypair.keys -a blind_signature.req -z $pfx/CRED05.zen | tee ci_signed_credential.json


# -aggregate-credential-signature
# this generates sigma (AggCred(σ1, . . . , σt) → (σ):) 
zenroom -k keypair.keys -a ci_signed_credential.json -z $pfx/CRED06.zen | tee credential.json

# -prove-credential
# this generates theta (❖ ProveCred(vk, m, φ0) → (Θ, φ0):
zenroom -k credential.json -a ci_verify_keypair.keys -z $pfx/CRED07.zen | tee blindproof_credential.json

# -VERIFIER-verify-credential
# returns a boolean VerifyCred(vk, Θ, φ0) 
zenroom -k blindproof_credential.json -a ci_verify_keypair.keys -z $pfx/CRED08.zen
