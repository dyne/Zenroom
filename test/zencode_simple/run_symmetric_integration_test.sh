#!/usr/bin/env zsh

set -e
set -u
set -o pipefail
# set -x
# https://coderwall.com/p/fkfaqq/safer-bash-scripts-with-set-euxo-pipefail

alias zenroom="${1:-../../src/zenroom}"
echo "============================================"
echo "TEST SYMMETRIC ENCRYPTION WITH JSON AND CBOR"
echo "============================================"


echo "=== JSON"

zenroom -z SYM01.zen | tee secret.json

echo "Encrypt a message with the secret"
zenroom -z SYM02.zen -k secret.json | tee cipher_message.json

echo "Decrypt the message with the secret"
zenroom -z SYM03.zen -k secret.json -a cipher_message.json

echo "=== CBOR"

echo "Generate a secret"
zenroom -z SYM04.zen | tee secret.cbor

echo "Encrypt a message with the secret"
zenroom -z SYM05.zen -k secret.cbor -z SYM05.zen | tee cipher_message.cbor

echo "Decrypt the message with the secret"
zenroom -z SYM06.zen -k secret.cbor -a cipher_message.cbor
