#!/usr/bin/env bash

# https://github.com/DP-3T/documents

# use executable in current directory
Z=../../src/zenroom
D=.

if test -r ./zenroom-linux-amd64; then
	Z=./zenroom-linux-amd64
	D=./out-dp3t
elif test -r ./zenroom-osx.command; then
	Z=./zenroom-osx.command;
	D=./out-dp3t
elif test -r ./src/zenroom; then
	Z=./src/zenroom
	D=./out-dp3t
elif test -r ../../src/zenroom; then
	Z=../../src/zenroom
	D=./out-dp3t
fi

if ! test -r $Z; then
	echo "Zenroom executable not found"
	echo "download yours from https://files.dyne.org/zenroom/nightly/"
	exit 1
fi

alias zenroom=$Z
chmod +x $Z

echo "Zenroom executable: $Z"
mkdir -p $D
echo "destination dir: $D"

cat <<EOF | $Z -z | tee $D/SK1.json
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given nothing
When I create the random object of '256' bits
and I rename the 'random object' to 'secret day key'
Then print the 'secret day key'
EOF


cat <<EOF | $Z -z -a $D/SK1.json | tee $D/SK2.json
scenario 'dp3t': Decentralized Privacy-Preserving Proximity Tracing
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given I have a 'secret day key'
When I renew the secret day key to a new day
Then print the 'secret day key'
EOF

cat <<EOF | tee $D/moments.json
{ "moments": "8" }
EOF

cat <<EOF | $Z -z -k $D/SK2.json | tee $D/EphID_2.json
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


# now generate a test with 40.000 infected SK
cat <<EOF | $Z -c memmanager=sys -z > $D/SK_infected_40k.json
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given nothing
When I create the array of '20000' random objects of '256' bits
and I rename the 'array' to 'list of infected'
Then print the 'list of infected'
EOF

# extract a few random infected ephemeral ids to simulate proximity
cat <<EOF | $Z -c memmanager=sys,debug=1 -z -a $D/SK_infected_40k.json | tee $D/EphID_infected.json
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
cat <<EOF | time $Z -c memmanager=sys,debug=1 -z -a $D/SK_infected_40k.json -k $D/EphID_infected.json
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
# cat <<EOF | $Z -c memmanager=sys -z -a $D/SK_infected_40k.json -k $D/EphID_2.json
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
