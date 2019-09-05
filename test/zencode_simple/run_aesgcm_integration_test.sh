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

return 0

# TODO: multiple recipients zencode

# join in array: [ { alice = { public = "..." } }, { bob = { public = "..." } } ]
jq -s '.' *.pub > recipients.pub

scenario="Alice encrypts a message for Bob"
echo $scenario
cat <<EOF | zenroom -z -d$verbose -k alice.keys -a recipients.pub | tee alice_to_bob.json
Scenario 'simple': $scenario
Given that I am known as 'Alice'
and I create a table 'recipients'
and I have inside 'Bob' a valid 'public key'
and I add it to 'recipients'
When I write 'This is my secret message to you' in 'draft'
and I encrypt the 'draft' for all 'recipients' as 'secret message'
Then print the 'secret message'
EOF
