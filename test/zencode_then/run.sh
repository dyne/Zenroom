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
    },
   "second": {
    "v3": 3,
    "v4": 4,
    "vs": "world"
    }
  }
}
EOF

cat <<EOF | zexe print_data.zen -a dictionary.json
Given I have the 'string dictionary' named 'dictionary'
Then print all data
EOF

cat <<EOF | zexe print_my_data.zen -a dictionary.json
Given I am known as 'Alice'
Given I have the 'string dictionary' named 'dictionary'
Then print my data
EOF

cat <<EOF | zexe print_data_from.zen -a dictionary.json
Given I have the 'string dictionary' named 'dictionary'
Then print data from 'dictionary'
EOF

cat <<EOF | zexe print_data.zen -a dictionary.json
Given I have the 'string dictionary' named 'dictionary'
Then print 'second' from 'dictionary'
EOF
