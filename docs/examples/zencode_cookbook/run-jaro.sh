#!/usr/bin/env bash



# https://pad.dyne.org/code/#/2/code/edit/NTsTFsGUExxvnycVzM32AJvZ/


# common script init
# if ! test -r ../../../test/utils.sh; then
#	echo "run executable from its own directory: $0"; exit 1; fi
# . ../../../test/utils.sh
# Z="`detect_zenroom_path` `detect_zenroom_conf`"
Z=zenroom
####################


n=0
tmp=`mktemp`

echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1



cat <<EOF | tee randomArrayGeneration.zen | $Z -z
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



cat <<EOF | tee randomArrayRename.zen | $Z -z
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

cat <<EOF | tee randomArrayMultiple.zen | $Z -z | tee myArrays.json
	Given nothing
	When I create the array of '2' random objects of '8' bits
	And I rename the 'array' to 'myTinyArray'
	And I create the array of '4' random objects of '16' bits
	And I rename the 'array' to 'myAverageArray'
	And I create the array of '16' random objects of '64' bits
	And I rename the 'array' to 'myBigFatArray'
	Then print all data
EOF

echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1


# This loads an object
cat <<EOF  > $tmp
  {
      "myNumber":1000,
      "myString":"Hello World!",
      "myArray":[
         "String1",
         "String2",
         "String3"
      ]
 }
EOF

cat <<EOF | tee givenLoadArray1.zen | $Z -z -a $tmp
Given I have a valid array of 'string' in 'myArray'
Given I have a valid 'string' in 'myString'
Given I have a valid number in 'myNumber'
When I randomize the 'myArray' array
Then print all data
EOF

echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1


cat <<EOF | tee givenLoadArray2.zen | $Z -z -a $tmp
Given I have a valid array of 'string' in 'myArray'
# Given I have a valid 'string' in 'myString'
# Given I have a valid number in 'myNumber'
When I randomize the 'myArray' array
Then print all data
EOF

echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1


cat <<EOF | tee givenLoadArrayDebug.zen | $Z -z -a $tmp | tee givenDebugOutput.json
Given I have a valid array of 'string' in 'myArray'
# Given I have a valid 'string' in 'myString'
# Given I have a valid number in 'myNumber'
Given debug
When I randomize the 'myArray' array
Then print all data
EOF


echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1

cat <<EOF | tee givenLoadArrayDebugVerbose.zen | $Z -z -a $tmp | tee givenDebugOutputVerbose.json
Given debug
Given I have a valid array of 'string' in 'myArray'
Given debug
Given I have a valid 'string' in 'myString'
Given debug
Given I have a valid number in 'myNumber'
Given debug
When I randomize the 'myArray' array
When debug
Then print all data
Then debug
EOF


echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1

cat <<EOF | tee alice_keygen.zen | $Z -z > alice_keypair.json
Scenario 'simple': Create the keypair
Given that I am known as 'Alice'
When I create the keypair
Then print my data
EOF


cat <<EOF | tee alice_keypub.zen | $Z -z -k alice_keypair.json -a $tmp | tee givenLongOutput.json
Scenario 'simple'
Given I am 'Andrea'
Given I have a valid 'keypair' from 'Alice'
#-- Given the 'nomeOggetto?' is valid
Given the 'myObject' is valid
Given the 'myNumber' is valid
Given the 'myArray' is valid
Given the 'myString' is valid
#-- Given I have a 'nomeOggetto' in 'nomeAltroOggetto'
#-- l'unico che funziona è: Given I have a 'myArray' in 'myObject'
Given I have a 'myNumber' in 'myObject'
Given I have a 'myString' in 'myObject'
Given I have a 'myArray' in 'myObject'
#-- Given I have a 'tipo?' in 'nomeOggetto'
Given I have a 'array' in 'myObject'
Given I have a 'array' in 'myArray'
Given I have a 'number' in 'myObject'
Given I have a 'number' in 'myNumber'
Given I have a 'string' in 'myObject'
Given I have a 'string' in 'myString'
#-- Given I have a valid array of 'tipo?' in (deve 'myArray'
Given I have a valid array of 'string' in 'myArray'
Given I have a valid array of 'string' in 'myObject'
#-- Given I have a valid array in 'nomeOggetto'
Given I have a valid array in 'myArray'
Given I have a valid array in 'myObject'
#-- Given I have a valid... in 'nomeOggetto'
Given I have a valid 'string' in 'myString'
Given I have a valid number in 'myNumber'
#--
And debug
When I create a random 'url64'
When I create a random 'number'
When I create a random 'string'
When I create a random 'base64'
Then print all data
EOF



echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1

rm -f $tmp

# This loads an object
cat <<EOF  > $tmp
{
  "myObject":{
      "myNumber":1000,
      "myString":"Hello World!",
      "myArray":[
         "String1",
         "String2",
         "String3"
      ]
   }
 }
EOF

cat <<EOF | tee givenLoadArray1.zen | $Z -z -a $tmp
# Given I have a valid array of 'string' in 'myArray'
# Given I have a valid 'string' in 'myString'
# Given I have a valid number in 'myNumber'
# When I randomize the 'myArray' array
Given I have a valid 'array string' named 'myArray' inside 'myObject'
Then print all data
EOF


echo "-------------------------------------------------------"
echo "--------------------- old script ----------------------"
echo "-------------------------------------------------------"


# Invisible script below

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



echo "-------------------------------------------------------"
echo "--------------------- old script ----------------------"
echo "-------------------------------------------------------"



cat <<EOF | tee nothing.zen | $Z -z
rule check version 1.0.0
	 Given nothing
	 When I create the random object of '256' bits
	 Then print the 'random object'
EOF

echo "-------------------------------------------------------"
echo "--------------------- old script ----------------------"
echo "-------------------------------------------------------"



echo '{ "anykey": "anyvalue" }' > $tmp
cat <<EOF | tee have.zen | $Z -z -a $tmp
rule check version 1.0.0
rule input encoding string
rule output encoding string
	 Given I have a 'anykey'
	 Then print the 'anykey'
EOF

echo "-------------------------------------------------------"
echo "--------------------- old script ----------------------"
echo "-------------------------------------------------------"


echo '{ "anykey": "616e7976616c7565" }' > $tmp
cat <<EOF | tee have.zen | $Z -z -a $tmp
rule check version 1.0.0
	 Given I have a 'anykey' as 'hex'
	 Then print the 'anykey' as 'string'
EOF

echo "-------------------------------------------------------"
echo "--------------------- old script ----------------------"
echo "-------------------------------------------------------"



cat <<EOF  > $tmp  # > tmp.json
{
   "Andrea":{
      "keypair":{
         "private_key":"IIiTD89L6_sbIvaUc5jAVR88ySigaBXppS5GLUjm7Dv2OLKbNIVdiZ48jpLGskKVDPpukKe4R0A",
         "public_key":"BFKQTA1ZiebF0is_LtMcVgu4QXC-HOjMpCwDPLuvuXGVAgORIn5NUm7Ey7UDljeNrTCZvhEqxCPjSvWLtIuSYXeZcHWENp7oO37nv7hL2Qj1vMwwlpeRhnSZnjhnKYjq5aTQV1T-eH3e0UcJASzvnb8"
      }
   },
   "Object":{
      "myNumber":1000,
      "myString":"Hello World once more!",
      "myArray":[
         "AnotherString1",
         "AnotherString2",
         "AnotherString3"
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
