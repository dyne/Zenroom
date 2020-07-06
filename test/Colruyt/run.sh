#!/usr/bin/env bash

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################


cat <<EOF | tee words.zen | $Z -z > words.json
Given nothing
When I write string 'the' in 'words'
and I append string 'quick' to 'words'
and I append string 'brown' to 'words'
and I append string 'fox' to 'words'
and I append string 'jumps' to 'words'
and I append string 'over' to 'words'
and I append string 'the' to 'words'
and I append string 'lazy' to 'words'
and I append string 'dog' to 'words'
Then print 'words' as 'string'
EOF

cat <<EOF | tee seedgen.zen | $Z -z -k words.json > masterseed.json
Given I have a 'string' named 'words'
When I create the hash of 'words' using 'sha512'
Then print 'hash' as 'hex'
EOF

# take the hex in masterseed.json
masterseed=`cat masterseed.json | cut -d\" -f4`
echo "masterseed: $masterseed"

# use the hex in the conf directive rngseed of zenroom
# concatenate the masterseed 4 times to reach 256 byte length:  rngseed=hex:${masterseed}${masterseed}${masterseed}${masterseed}
cat <<EOF | tee mainIDgen.zen | $Z -c "rngseed=hex:${masterseed}${masterseed}${masterseed}${masterseed}" | tee randomseed.json -z > mainID.json
Scenario simple
Given nothing
When I create the keypair
Then print the 'keypair' as 'base64'
EOF

cat mainID.json
