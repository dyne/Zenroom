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

# tests for encoding on print
cat <<EOF | save then coding_export.json
{
	"storage_contract": "1b620cA5172A8D6A64798FcA2ee690066F7A7816"
}
EOF

cat <<EOF | zexe coding_export.zen -a coding_export.json | jq
Scenario ethereum
Given I have a 'ethereum address' named 'storage contract'
Then print 'storage contract'
EOF

cat <<EOF | save then read_and_print_tx.json
{
	"tx": {
		"nonce": "0",
		"to": "1b620cA5172A8D6A64798FcA2ee690066F7A7816",
		"gas price": "100000000000",
		"gas limit": "300000",
		"value": "0"
	}
}
EOF
cat <<EOF | zexe read_and_print_tx.zen -a read_and_print_tx.json | jq
Scenario ethereum
Given I have a 'ethereum transaction' named 'tx'
Then print data
EOF
# end tests for encoding on print
