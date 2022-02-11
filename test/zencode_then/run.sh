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

cat <<EOF | zexe print_data.zen -a dictionary.json
Given I have the 'string dictionary' named 'dictionary'
Then print all data
EOF

cat <<EOF | zexe print_data_in.zen -a dictionary.json
Given I have the 'string dictionary' named 'dictionary'
Then print data in 'dictionary'
EOF
