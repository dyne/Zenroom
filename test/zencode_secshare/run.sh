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
echo " Script $n: Participant creates a keypair	  "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "

cat <<EOF | zexe create_secret.zen | tee secret.json
Given nothing
When I write string 'my small secret' in 'secret'
Then print the 'secret'
EOF

cat <<EOF | debug create_secret_shares.zen -k secret.json | jq . | tee shares.json
Scenario secshare
Given I have a 'string' named 'secret'
When I create the secret shares of 'secret' with '9' quorum '5'
and I randomize the 'secret shares' array
# now remove shares until we use only 5
and I pick the random object in 'secret shares'
and I remove the 'random object' from 'secret shares'
and I pick the random object in 'secret shares'
and I remove the 'random object' from 'secret shares'
and I pick the random object in 'secret shares'
and I remove the 'random object' from 'secret shares'
and I pick the random object in 'secret shares'
and I remove the 'random object' from 'secret shares'
Then print the 'secret shares'
EOF

cat <<EOF | zexe compose_secret_shares.zen -k shares.json | tee composed.json
Scenario secshare
Given I have a 'secret shares'
when I compose the secret using 'secret shares'
Then print the 'secret' as 'string'
EOF
