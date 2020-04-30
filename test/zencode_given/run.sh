#!/usr/bin/env bash

# https://pad.dyne.org/code/#/2/code/edit/NTsTFsGUExxvnycVzM32AJvZ/

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

tmp=`mktemp`

cat <<EOF | tee nothing.zen | $Z -z
rule check version 1.0.0
Given nothing
When I create the random object of '256' bits
Then print the 'random object'
EOF

set +e
echo '{}' > $tmp
cat <<EOF | tee nothing.zen | $Z -z -a $tmp 2>/dev/null
rule check version 1.0.0
	 Given nothing
	 When I create the random object of '256' bits
	 Then print the 'random object'
EOF
if ! test $? == 1; then 
	echo "ERROR in Given nothing"
	exit 1; fi
set -e

cat <<EOF | tee nothing.zen | $Z -z
rule check version 1.0.0
	 Given nothing
	 When I create the random object of '256' bits
	 Then print the 'random object'
EOF

echo '{ "anykey": "anyvalue" }' > $tmp
cat <<EOF | tee have.zen | $Z -z -a $tmp
rule check version 1.0.0
rule input encoding string
rule output encoding string
	 Given I have a 'anykey'
	 Then print the 'anykey'
EOF
echo '{ "anykey": "616e7976616c7565" }' > $tmp
cat <<EOF | tee have.zen | $Z -z -a $tmp
rule check version 1.0.0
	 Given I have a 'anykey' as 'hex' 
	 Then print the 'anykey' as 'string'
EOF

cat <<EOF  > $tmp
  {
   "Andrea":{
      "keypair":{
         "private_key":"IIiTD89L6_sbIvaUc5jAVR88ySigaBXppS5GLUjm7Dv2OLKbNIVdiZ48jpLGskKVDPpukKe4R0A",
         "public_key":"BFKQTA1ZiebF0is_LtMcVgu4QXC-HOjMpCwDPLuvuXGVAgORIn5NUm7Ey7UDljeNrTCZvhEqxCPjSvWLtIuSYXeZcHWENp7oO37nv7hL2Qj1vMwwlpeRhnSZnjhnKYjq5aTQV1T-eH3e0UcJASzvnb8"
      },
	  "robba":"1000",
    "Arr":[
        "peppe2",
        "peppe3",
        "peppe4"
        ]  
   }
}
EOF
cat <<EOF | tee have_valid.zen | $Z -z -a $tmp
rule check version 1.0.0
scenario 'simple'
	 Given I am 'Andrea'
	 and I have my 'keypair'
	 and debug
	 Then print the 'keypair'
EOF

rm -f $tmp
