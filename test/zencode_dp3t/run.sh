#!/usr/bin/env bash

# https://github.com/DP-3T/documents

RNGSEED=hex:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################


cat <<EOF | tee dp3t_keygen.zen | $Z -z | tee SK1.json
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given nothing
When I create the random object of '256' bits
and I rename the 'random object' to 'secret day key'
Then print the 'secret day key'
EOF


cat <<EOF | tee dp3t_keyderiv.zen | $Z -z -a SK1.json | tee SK2.json
scenario 'dp3t': Decentralized Privacy-Preserving Proximity Tracing
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given I have a 'secret day key'
When I renew the secret day key to a new day
Then print the 'secret day key'
EOF

cat <<EOF | tee dp3t_ephidgen.zen | $Z -z -k SK2.json | tee EphID_2.json
scenario 'dp3t': Decentralized Privacy-Preserving Proximity Tracing
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given I have a 'secret day key'
When I write string 'Broadcast key' in 'broadcast key'
and I write number '180' in 'epoch'
and I create the ephemeral ids for today
and I randomize the 'ephemeral ids' array
Then print the 'ephemeral ids'
EOF


# now generate a test with 20.000 infected SK
cat <<EOF | $Z -z > SK_infected_20k.json
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given nothing
When I create the array of '20000' random objects of '256' bits
and I rename the 'array' to 'list of infected'
Then print the 'list of infected'
EOF

# extract a few random infected ephemeral ids to simulate proximity
cat <<EOF | $Z -z -a SK_infected_20k.json | tee EphID_infected.json
scenario 'dp3t'
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given I have a valid array in 'list of infected'
When I pick the random object in 'list of infected'
and I rename the 'random object' to 'secret day key'
and I write number '180' in 'epoch'
and I write string 'Broadcast key' in 'broadcast key'
and I create the ephemeral ids for today
# and the 'secret day key' is found in 'list of infected'
Then print the 'ephemeral ids'
EOF

# given a list of infected and a list of ephemeral ids 
cat <<EOF | tee dp3t_check.zen | $Z -z -a SK_infected_20k.json -k EphID_infected.json | tee SK_proximity.json
scenario 'dp3t'
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given I have a valid array in 'list of infected'
and I have a valid array in 'ephemeral ids'
When I write number '180' in 'epoch'
and I write string 'Broadcast key' in 'broadcast key'
and I create the proximity tracing of infected ids
Then print the 'proximity tracing'
EOF

# given a list of infected and a list of ephemeral ids 
# cat <<EOF | $Z -c memmanager=sys -z -a $D/SK_infected_20k.json -k $D/EphID_2.json
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
