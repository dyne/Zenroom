#!/usr/bin/env bash

# output path for documentation: ../../docs/examples/zencode_cookbook/
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





n=1

echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1

cat <<EOF | zexe alice_keygen.zen -z | save . alice_keypair.json
Scenario 'ecdh': Create the keyring
Given that I am known as 'Alice'
When I create the ecdh key
Then print my keyring
EOF


echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1



cat <<EOF | zexe randomArrayGeneration.zen -z | save . myFirstRandomArray.json
	Given nothing
	When I create the array of '16' random objects of '32' bits
	Then print all data
EOF

echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1



cat <<EOF | zexe randomArrayRename.zen -z | jq .
	Given nothing
	When I create the array of '16' random objects of '32' bits
	And I rename the 'array' to 'myArray'
	Then print all data
EOF

echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1

cat <<EOF | zexe randomArrayMultiple.zen -z | save . myArrays.json
	Given nothing
	When I create the array of '2' random objects of '8' bits
	And I rename the 'array' to 'myTinyArray'
	And I create the array of '4' random objects of '32' bits
	And I rename the 'array' to 'myAverageArray'
	And I create the array of '8' random objects of '128' bits
	And I rename the 'array' to 'myBigFatArray'
	Then print all data 
EOF







