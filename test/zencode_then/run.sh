#!/usr/bin/env bash

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh $*
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

cat <<EOF | save then dictionary.json
{ "dictionary": {
   "first": {
    "v1": 1,
    "v2": 2,
    "vs": "hello"
    }
  }
}
EOF

cat <<EOF | debug first_child.zen -a dictionary.json | save then first_child.json
Given I have the 'string dictionary' named 'dictionary'
Then print the first child in 'dictionary'
Then print the 'dictionary'
and codec
EOF
