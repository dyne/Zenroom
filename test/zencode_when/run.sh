#!/usr/bin/env bash

# DEBUG=1
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"

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

cat <<EOF | save when stringnum.json
{
	"api": "http://3.68.108.18/api/v1/blocks/latest",
	"path": "blocks/",
	"height": 102
}
EOF

cat <<EOF | zexe append_number.zen -a stringnum.json
Given I have a 'string' named 'api'
and a 'string' named 'path'
and a 'number' named 'height'
When I append 'height' to 'path'
Then print 'path'
EOF
