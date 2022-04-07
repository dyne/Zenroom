#!/usr/bin/env bash

DEBUG=1
####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh

Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

set -e

cat <<EOF >generate-key-seed.keys
{
	"seed": "pNivlLFjZesFAqSG3qDobmrhKeWkGtPuUBeJ3FmkAWQ="
}
EOF

cat <<EOF | debug generate-key-seed.zen -k generate-key-seed.keys
Rule check version 2.0.0
Scenario 'ecdh': Create the key
Scenario 'ethereum': Create key
Scenario 'reflow': Create the key
Scenario 'schnorr': Create the key

# Loading the seed
Given I have a 'string' named 'seed'

# Creating the keypair from the seed
When I create the keypair with secret key 'seed'

# this needs to be implemented
When I create the ecdh key with secret key 'seed'
When I create the ethereum key with secret key 'seed'
When I create the reflow key with secret key 'seed'
When I create the schnorr key with secret key 'seed'
When I create the bitcoin key with secret key 'seed'


Then print the 'keys'
Then print the 'keypair'
EOF
