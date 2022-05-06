#!/usr/bin/env bash

DEBUG=1
####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh

is_cortexm=false
if [[ "$1" == "cortexm" ]]; then
	is_cortexm=true
fi

Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

set -e

cat <<EOF | zexe copy_random.zen
Given nothing

When I create the random 'random'
When I copy 'random' to 'dest'

Then print 'random'
Then print 'dest'
EOF
cat <<EOF >copy_data.json
{ "my_hex": "0011FFFF" }
EOF
cat <<EOF | zexe copy_data.zen -a copy_data.json
Given I have a 'hex' named 'my hex'

When I copy 'my hex' to 'dest'

Then print 'my hex'
Then print 'dest'
EOF
