#!/usr/bin/env zsh

set -e
set -u
set -o pipefail
# set -x
# https://coderwall.com/p/fkfaqq/safer-bash-scripts-with-set-euxo-pipefail


alias zenroom="${1:-../../src/zenroom}"
echo "============================================"
echo "TEST A-SYMMETRIC SIGNATURE (ECDSA)"
echo "============================================"

# alice sign
zenroom -z DSA01.zen -k alice.keys | tee alice_signs_to_bob.json

# bob verify
zenroom -z DSA02.zen -k alice.pub -a alice_signs_to_bob.json

