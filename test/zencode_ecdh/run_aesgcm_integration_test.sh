#!/usr/bin/env zsh

set -e
set -u
set -o pipefail
# set -x
# https://coderwall.com/p/fkfaqq/safer-bash-scripts-with-set-euxo-pipefail


alias zenroom="${1:-../../src/zenroom}"
echo "============================================"
echo "TEST A-SYMMETRIC ENCRYPTION (ECDH + AES-GCM)"
echo "============================================"


zenroom -z AES01.zen | tee alice.keys

zenroom -z AES02.zen -k alice.keys | tee alice.pub

zenroom -z AES03.zen | tee bob.keys

zenroom -z AES04.zen -k bob.keys | tee bob.pub

zenroom -z AES05.zen -k alice.keys -a bob.pub | tee alice_to_bob.json

zenroom -z AES06.zen -k bob.keys -a alice.pub | tee bob.keyring

zenroom -z AES07.zen -k bob.keyring -a alice_to_bob.json
