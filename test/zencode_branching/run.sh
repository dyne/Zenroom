#!/usr/bin/env bash

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh $*
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

cat << EOF > leftright.json
{ "left": 10,
  "right": 50 }
EOF

cat << EOF | debug branch.zen -a leftright.json
Given I have a 'number' named 'left'
and I have a 'number' named 'right'

If number 'left' is less than 'right'
Then print string 'right is higher'

If number 'left' is more than 'right'
Then print string 'left is higher'
EOF

cat << EOF > leftright.json
{ "left": 60,
  "right": 50 }
EOF

cat << EOF | debug branch.zen -a leftright.json
Given I have a 'number' named 'left'
and I have a 'number' named 'right'

If number 'left' is less than 'right'
Then print string 'right is higher'
and print string 'and I am right'

If number 'left' is more than 'right'
Then print string 'left is higher'
and print string 'and I am right'

EOF

