#!/usr/bin/env bash

# https://github.com/DP-3T/documents

####################
# common script init
if ! test -r ../utils.sh; then
        echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################
set -e
out='../../docs/examples/zencode_cookbook/reflow'
mkdir -p ${out}
rm ${out}/*

cat <<EOF | zexe dp3t_keygen.zen | save dp3t SK1.json
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given nothing
When I create the random object of '256' bits
and I rename the 'random object' to 'secret day key'
Then print the 'secret day key'
EOF


cat <<EOF | zexe dp3t_keyderiv.zen -a SK1.json | save dp3t SK2.json
scenario 'dp3t': Decentralized Privacy-Preserving Proximity Tracing
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given I have an 'hex' named 'secret day key'
# TODO: if the key is found in HEAP then parse secret day key as octet in default encoding
When I renew the secret day key to a new day
Then print the 'secret day key'
EOF

cat <<EOF | zexe dp3t_ephidgen.zen -k SK2.json | save dp3t EphID_2.json
scenario 'dp3t': Decentralized Privacy-Preserving Proximity Tracing
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given I have an 'hex' named 'secret day key'
When I write string 'Broadcast key' in 'broadcast key'
and I write number '180' in 'epoch'
and I create the ephemeral ids for today
and I randomize the 'ephemeral ids' array
Then print the 'ephemeral ids'
EOF


# now generate a test with 20.000 infected SK
cat <<EOF | zexe dp3t_testgen.zen | save dp3t SK_infected_20k.json
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given nothing
When I create the array of '200' random objects of '256' bits
and I rename the 'array' to 'list of infected'
and debug
Then print the 'list of infected'
EOF

# extract a few random infected ephemeral ids to simulate proximity
cat <<EOF | zexe dp3t_testextract.zen -a SK_infected_20k.json | save dp3t EphID_infected.json
scenario 'dp3t'
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given I have an 'hex array' named 'list of infected'
When I pick the random object in 'list of infected'
and I rename the 'random object' to 'secret day key'
and I write number '180' in 'epoch'
and I write string 'Broadcast key' in 'broadcast key'
and I create the ephemeral ids for today
# and the 'secret day key' is found in 'list of infected'
Then print the 'ephemeral ids'
EOF

# given a list of infected and a list of ephemeral ids 
cat <<EOF | zexe dp3t_checkinfected.zen -a SK_infected_20k.json -k EphID_infected.json | save dp3t SK_proximity.json
scenario 'dp3t'
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given I have a 'hex array' named 'list of infected'
and I have a 'hex array' named 'ephemeral ids'
When I write number '180' in 'epoch'
and I write string 'Broadcast key' in 'broadcast key'
and I create the proximity tracing of infected ids
and debug
Then print the 'proximity tracing'
EOF

# given a list of infected and a list of ephemeral ids 
# cat <<EOF | zexe -c memmanager=sys -z -a $D/SK_infected_20k.json -k $D/EphID_2.json
# scenario 'dp3t'
# rule check version 1.0.0
# rule input encoding hex
# rule output encoding hex
# Given I have a valid array in 'list of infected'
# and I have a valid array in 'ephemeral ids'
# When I write number '8' in 'moments'
# and I write string 'Broadcast key' in 'broadcast key'
# and I create the proximity tracing of infected ids
# Then print the 'proximity tracing'
# EOF
