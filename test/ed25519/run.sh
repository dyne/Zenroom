#!/usr/bin/env bash

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
TEMP="$(mktemp)"

IFS=$'\n'       # make newlines the only separator
for row in $(cat ./ed25519_tests.txt)
do
  echo "$row" >$TEMP
  ../../src/zenroom test_row.lua -a $TEMP
#  if [[ $? != 0 ]]; then
#    echo "Verifica fallita alla riga"
#    echo "$row"
#    exit -1
#  fi
done
rm $TEMP
# Note: IFS needs to be reset to default!
