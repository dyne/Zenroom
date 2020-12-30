#!/usr/bin/env bash

# RNGSEED="hex:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################
# use zexe if you have zenroom in a system-wide path
#
# zexe() {
#	out="$1"
#	shift 1
#	>&2 echo "test: $out"
#	tee "$out" | zenroom -z $*
# }
####################

n=0

let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo " Script $n: Participant creates shared secret  "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "



cat <<EOF  > ../../docs/examples/zencode_cookbook/scenarioSecShare-Secret.json
{
	"32BytesSecret":"myMilkshakeBringsAllTheBoysTo..."
}
EOF



cat <<EOF | debug ../../docs/examples/zencode_cookbook/scenarioSecShare-createSharedSecret.zen -k ../../docs/examples/zencode_cookbook/scenarioSecShare-Secret.json | jq . | tee ../../docs/examples/zencode_cookbook/scenarioSecShare-sharedSecret.json

# Let's define the scenario, we'll need the 'secshare' here
Scenario secshare: create a shared secret

# We'll start from a secret, which can be max 32 bytes in length
Given I have a 'string' named '32BytesSecret'

# Here we are creating the "secret shares", the output will be an array of pairs of numbers
# The quorum represents the minumum amount of secret shares needed to
# rebuild the secret, and it can be configured
When I create the secret shares of '32BytesSecret' with '19' quorum '5'

# Here we rename the output and print it out
and I rename the 'secret shares' to 'mySharedSecret'
Then print the 'mySharedSecret'
EOF

let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo " Script $n: pick 5 random parts "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "




cat <<EOF | debug ../../docs/examples/zencode_cookbook/scenarioSecShare-removeShares.zen -k ../../docs/examples/zencode_cookbook/scenarioSecShare-Secret.json -a ../../docs/examples/zencode_cookbook/scenarioSecShare-sharedSecret.json | jq . | tee ../../docs/examples/zencode_cookbook/scenarioSecShare-sharedSecret5parts.json

# Here we load the "secret shares", which is a an array of base64 numbers
Given I have a 'base64 array' named 'mySharedSecret'

# Here we are simply removing 4 randomly chosen shares from the array,
# so that only 4 are left.

When I pick the random object in 'mySharedSecret'
and I remove the 'random object' from 'mySharedSecret'
and I pick the random object in 'mySharedSecret'
and I remove the 'random object' from 'mySharedSecret'
and I pick the random object in 'mySharedSecret'
and I remove the 'random object' from 'mySharedSecret'
and I pick the random object in 'mySharedSecret'
and I remove the 'random object' from 'mySharedSecret'

# Now we have an array with 5 shares that print out 
When I rename the 'mySharedSecret' to 'my5partsOfTheSharedSecret'
Then print the 'my5partsOfTheSharedSecret'
EOF

let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo " Script $n: check the quorum  "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "





cat <<EOF | zexe ../../docs/examples/zencode_cookbook/scenarioSecShare-composeSecretShares.zen -k ../../docs/examples/zencode_cookbook/scenarioSecShare-sharedSecret5parts.json | tee ../../docs/examples/zencode_cookbook/scenarioSecShare-composedSecretShares.json
Scenario secshare: recompose the secret shares

# Here we are loading the "secret shares" 
Given I have a 'secret shares' named 'my5partsOfTheSharedSecret'

# Here we are testing if the secret shares can be recomposed to form the password
# in case the quorum isn't reached or isn't correct, Zenroom will anyway output a string,
# that will be different from the original secret.
# if the quorum is correct, the original secret should be printed out.
when I compose the secret using 'my5partsOfTheSharedSecret'
Then print the 'secret' as 'string'
EOF
