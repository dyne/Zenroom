#!/usr/bin/env bash

# RNGSEED="hex:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

SUBDOC=secshare

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"

n=0

let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo " Script $n: Participant creates shared secret  "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "



cat <<EOF  | save secshare Secret.json
{
	"32BytesSecret":"myMilkshakeBringsAllTheBoysTo..."
}
EOF



cat <<EOF | zexe createSharedSecret.zen -k Secret.json | save secshare sharedSecret.json

# Let's define the scenario, we'll need the 'secshare' here
Scenario secshare: create a shared secret

# We'll start from a secret, which can be max 32 bytes in length
Given I have a 'string' named '32BytesSecret'

# Here we are creating the "secret shares", the output will be an array of pairs of numbers
# The quorum represents the minumum amount of secret shares needed to
# rebuild the secret, and it can be configured
When I create the secret shares of '32BytesSecret' with '9' quorum '5'

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




cat <<EOF | zexe removeShares.zen -k Secret.json -a sharedSecret.json \
    | save secshare sharedSecret5parts.json

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





cat <<EOF | zexe composeSecretShares.zen -k sharedSecret5parts.json \
    | save secshare composedSecretShares.json
Scenario secshare: recompose the secret shares

# Here we are loading the "secret shares" 
Given I have a 'secret shares' named 'my5partsOfTheSharedSecret'

# Here we are testing if the secret shares can be recomposed to form the password
# in case the quorum isn't reached or isn't correct, Zenroom will anyway output a string,
# that will be different from the original secret.
# if the quorum is correct, the original secret should be printed out.
when I compose the secret using 'my5partsOfTheSharedSecret'
when I rename 'secret' to 'composed secret'
Then print the 'composed secret' as 'string'
EOF

cat <<EOF | zexe checkSecret.zen -k Secret.json -a composedSecretShares.json | jq .
Scenario secshare
Given I have a 'string' named '32BytesSecret'
Given I have a 'string' named 'composed secret'
When I verify '32BytesSecret' is equal to 'composed secret'
Then print string 'Secrets match'
EOF


let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo " Script $n: split long secret in two and compose"
echo "------------------------------------------------"
echo "                                                "

cat <<EOF | save secshare 64secret.json
{ "secret": "3958dcd0a9161543d2b56016b5c79ad6cd5859f583c30c2ad4fc64381829146814e169a890cdc09d15669d663cc7e54103ee85ba120991e4f28038b9630dbcca" }
EOF

cat <<EOF | zexe 64secret.zen -k 64secret.json | save secshare 64shares.json
Rule check version 2.0.0
Scenario secshare: create a shared secret

Given I have a 'hex' named 'secret'

When I split the rightmost '32' bytes of 'secret'
and I create the secret shares of 'rightmost' with '5' quorum '3'
and I rename 'secret shares' to 'rightmost shares'

When I split the leftmost '32' bytes of 'secret'
and I create the secret shares of 'leftmost' with '5' quorum '3'
and I rename 'secret shares' to 'leftmost shares'

Then print the 'rightmost shares'
and print the 'leftmost shares'
EOF

cat <<EOF | zexe 64compose.zen -k 64shares.json -a 64secret.json | jq .
Rule check version 2.0.0
Scenario secshare: compose a shared secret

Given I have a 'secret shares' named 'rightmost shares'
and I have a 'secret shares' named 'leftmost shares'
and I have a 'hex' named 'secret'


When I rename 'secret' to 'original secret'

When I compose the secret using 'rightmost shares'
and I rename 'secret' to 'rightmost secret'

and I compose the secret using 'leftmost shares'
and I rename 'secret' to 'leftmost secret'

and I append 'rightmost secret' to 'leftmost secret'
and I rename 'leftmost secret' to 'composed secret'

and I verify 'original secret' is equal to 'composed secret'

Then print string 'SECRETS MATCH'
EOF

cat <<EOF | save secshare 32secret.json
{ "secret": "640e744984d511506a3ea1e52417c0a49caa11762626c7cae8f5302138205a07" }
EOF

# fails with this secret, slightly bigger than curve secp256k1 modulo:
# { "secret": "f40e744984d511506a3ea1e52417c0a49caa11762626c7cae8f5302138205a07" }

cat <<EOF | zexe 32secret.zen -k 32secret.json | save secshare 32shares.json
Rule check version 2.0.0
Scenario secshare: create a shared secret

Given I have a 'hex' named 'secret'

When I create the secret shares of 'secret' with '5' quorum '3'

Then print the 'secret shares'
EOF

cat <<EOF | zexe 32compose.zen -k 32shares.json -a 32secret.json | jq .
Rule check version 2.0.0
Scenario secshare: compose a shared secret

Given I have a 'secret shares'
and I have a 'hex' named 'secret'

When I rename 'secret' to 'original secret'
and I compose the secret using 'secret shares'
and I verify 'original secret' is equal to 'secret'

Then print string 'SECRETS MATCH'
EOF

