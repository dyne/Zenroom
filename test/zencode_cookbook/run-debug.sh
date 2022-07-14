#!/bin/bash
DEBUG=1
SUBDOC=debug
. ../utils.sh $*
Z="`detect_zenroom_path` `detect_zenroom_conf`"

set -e

cat <<EOF | save $SUBDOC input.json
{
	"keyring": {
		   "eddsa": "CbAbexaForJ4ES27FR9SMCiNr33aG92CKH7qZG84tHa5",
		   "schnorr": "XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA="
	}
}
EOF

cat <<EOF | zexe main_script.zen -a input.json | save $SUBDOC main_output.json
Scenario 'eddsa': Generate the public key
Scenario 'schnorr': Generate the public key

Given I have the 'keyring'
When I create the eddsa public key
When I create the schnorr public key
Then print the data
EOF

cat <<EOF | zexe backtrace_script.zen -a input.json | jq 
Scenario 'eddsa': Generate the public key
Scenario 'schnorr': Generate the public key

Given I have the 'keyring'
When I create the eddsa public key
When I create the schnorr public key
and backtrace

Then print the data
EOF

cat <<EOF | zexe codec_script.zen -a input.json | jq 
Scenario 'eddsa': Generate the public key
Scenario 'schnorr': Generate the public key

Given I have the 'keyring'
When I create the eddsa public key
When I create the schnorr public key
and codec

Then print the data
EOF

cat <<EOF | zexe config_script.zen -a input.json | jq 
Scenario 'eddsa': Generate the public key
Scenario 'schnorr': Generate the public key

Given I have the 'keyring'
When I create the eddsa public key
When I create the schnorr public key
and config

Then print the data
EOF

cat <<EOF | zexe debug_script.zen -a input.json | jq 
Scenario 'eddsa': Generate the public key
Scenario 'schnorr': Generate the public key

Given I have the 'keyring'
When I create the eddsa public key
When I create the schnorr public key
and debug

Then print the data
EOF

cat <<EOF | zexe schema_script.zen -a input.json | jq 
Scenario 'eddsa': Generate the public key
Scenario 'schnorr': Generate the public key

Given I have the 'keyring'
When I create the eddsa public key
When I create the schnorr public key
and schema

Then print the data
EOF

rm -f *.zen *.json
