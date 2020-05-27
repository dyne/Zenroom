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

cat <<EOF | tee alice_keygen.zen | $Z -z > alice_keypair.json
Scenario 'simple': Create the keypair
Given that I am known as 'Alice'
When I create the keypair
Then print my data
EOF


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
      "myNumber":12345,
      "myString":"Hello World!",
      "myArray":[
         "String-1-one",
         "String-2-two",
         "String-3-three",
		 "String-4-four",
		 "String-5-five"
      ]
 }
EOF

cat <<EOF | tee givenLoadFlatObject.zen | $Z -z -a $tmp | tee givenLoadFlatObjectOutput.json
Given I have a valid 'string array' named 'myArray'   
# Given I have a valid 'string' in 'myString'  # Questo è ancora rotto
Given I have a valid number in 'myNumber'
When I randomize the 'myArray' array
Then print all data
EOF

cat $tmp > myFlatObject.json
# End of script loading object

echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1

cat <<EOF | tee givenLoadNumber.zen | $Z -z -a $tmp | tee givenLoadNumberOutput.json
Given I have a valid number in 'myNumber'
Then print all data
EOF



echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "               Unused in the manual                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1



cat <<EOF | tee givenLoadArray2.zen | $Z -z -a $tmp
Given I have a valid 'string array' named 'myArray' 
# Given I have a valid string inside 'myString'
# Given I have a valid number inside 'myNumber' 
When I randomize the 'myArray' array
Then print all data
EOF

# End of script loading object


echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1


cat <<EOF | tee givenLoadArrayDebugVerbose.zen | $Z -z -a myFlatObject.json | tee givenDebugOutputVerbose.json
Given debug
Given I have a valid 'string array' named 'myArray'
Given debug
Given I have a valid string inside 'myString'
Given debug
Given I have a valid number inside 'myNumber'
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

# This loads an object
cat <<EOF  > $tmp 
{
   "myFirstObject":{
      "myNumber":11223344,
      "myString":"Hello World!",
      "myArray":[
         "String1",
         "String2",
         "String3",
         "String4"
      ]
   },
   "mySecondObject":{
      "myNumber":1234567890,
	  "myString":"Oh, hello again!",
      "myArray":[
         "anotherString1",
         "anotherString2",
         "anotherString3",
         "anotherString4"
      ]
   },
   "Alice":{
      "keypair":{
         "private_key":"DbjRMCC7fykuUaqYDX_cy_Zs7J0ZC0y9VxBLRcfwIJ63MAZtW4fJ4IxxdUdLNy0ye0-qf0IlRZI",
         "public_key":"BE39Wu7AXSzSplMd37VhCB094xHqCgvZxMhgaTA7B0Xz4mEIZmoO2FmWiokVXuJ0O9jH9AQD4UBkXiCU4gzYrLQc9VpfB4Qr8rz6jj_UYvC77FiLGc-0jsE4mQfpgLoOspBGcfNyiS8Y50hl8zthKjo"
      }
   }
}
EOF

cat $tmp > myNestedRepetitveObject.json

cat <<EOF | tee givenLoadRepetitveObject.zen | $Z -z -a $tmp | tee givenLoadRepetitveObjectOutput.json
Scenario 'simple': let us load some stuff cause it is fun!
Given I am 'Alice'
And I have my valid 'keypair'
And I have a 'myArray' inside 'myFirstObject' 
And I have a 'myArray' inside 'mySecondObject' 
Then print all data
EOF



echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1

cat <<EOF | tee givenLoadRepetitveObjectDebug.zen | $Z -z -a $tmp | tee givenLoadRepetitveObjectDebugOutput.json
Scenario 'simple': let us load some stuff cause it is fun!
Given I am 'Alice'
And I have my valid 'keypair'
And I have a 'myArray' inside 'myFirstObject' 
And I have a 'myArray' inside 'mySecondObject' 
And debug
Then print all data
And debug
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
   "myFirstObject":{
      "myFirstNumber":11223344,
      "myFirstString":"Hello World!",
      "myFirstArray":[
         "String1",
         "String2",
         "String3",
         "String4"
      ]
   },
   "mySecondObject":{
      "mySecondNumber":1234567890,
	  "mySecondString":"Oh, hello again!",
      "mySecondArray":[
         "anotherString1",
         "anotherString2",
         "anotherString3",
         "anotherString4"
      ]      
   },
   "Alice":{
      "keypair":{
         "private_key":"DbjRMCC7fykuUaqYDX_cy_Zs7J0ZC0y9VxBLRcfwIJ63MAZtW4fJ4IxxdUdLNy0ye0-qf0IlRZI",
         "public_key":"BE39Wu7AXSzSplMd37VhCB094xHqCgvZxMhgaTA7B0Xz4mEIZmoO2FmWiokVXuJ0O9jH9AQD4UBkXiCU4gzYrLQc9VpfB4Qr8rz6jj_UYvC77FiLGc-0jsE4mQfpgLoOspBGcfNyiS8Y50hl8zthKjo"
      }
   }
}
EOF

cat $tmp > myNestedObject.json





cat <<EOF | tee givenLoadNestedObject.zen | $Z -z -a $tmp | tee givenLoadNestedObjectOutput.json
Scenario 'simple': let us load some stuff cause it is fun!
Given I am 'Alice'
And I have my valid 'keypair'
And I have a 'myFirstArray' inside 'myFirstObject' 
And I have a 'mySecondArray' inside 'mySecondObject' 
Then print all data
EOF




echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1


cat <<EOF | tee alice_keypub.zen | $Z -z -k alice_keypair.json -a $tmp | tee givenLongOutput.json
Scenario 'simple' : load stuff
Given I am 'Andrea'
Given I have a valid 'keypair' from 'Alice'
#-- Given the 'nomeOggetto?' is valid
Given the 'myObject' is valid
Given the 'myNumber' is valid
Given the 'myArray' is valid
Given the 'myString' is valid
#-- Given I have a 'nomeOggetto' inside 'nomeAltroOggetto'
#-- l'unico che funziona è: Given I have a 'myArray' inside 'myObject'  
Given I have a 'myNumber' inside 'myObject'
Given I have a 'myString' inside 'myObject'
Given I have a 'myArray' inside 'myObject' 
#-- Given I have a 'tipo?' inside 'nomeOggetto'
Given I have a 'array' inside 'myObject'
Given I have a 'array' inside 'myArray'
Given I have a 'number' inside 'myObject'
Given I have a 'number' inside 'myNumber'
Given I have a 'string' inside 'myObject'
Given I have a 'string' inside 'myString'
#-- Given I have a valid array of 'tipo?' inside (deve 'myArray'
Given I have a valid array of 'string' inside 'myArray'
Given I have a valid array of 'string' inside 'myObject'
#-- Given I have a valid array inside 'nomeOggetto'
Given I have a valid array inside 'myArray'
Given I have a valid array inside 'myObject'
#-- Given I have a valid... inside 'nomeOggetto'
Given I have a valid string inside 'myString'
Given I have a valid number inside 'myNumber' 
#-- 
And debug
When I create a random 'url64'
When I create a random 'number'
When I create a random 'string'
When I create a random 'base64'
Then print all data
EOF


rm -f $tmp
# End of script loading object


echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1


cat <<EOF | tee givenLoadArrayDebug.zen | $Z -z -a myFlatObject.json | tee givenDebugOutput.json
Given I have a valid 'string array' named 'myArray' 
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


cat <<EOF  > $tmp
{
   "myFirstObject":{
      "myFirstNumber":1,
      "myFirstArray":[
         "String1"
      ]
   },
   "mySecondObject":{
      "mySecondNumber":2,
      "mySecondArray":[
         "anotherString1",
         "anotherString2"
      ]
   },
   "myThirdObject":{
      "myThirdNumber":3,
      "myThirdArray":[
         "oneMoreString1",
         "oneMoreString2",
         "oneMoreString3"
      ]
   },
   "myFourthObject":{
      "myFourthArray":[
         "oneExtraString1",
         "oneExtraString2",
         "oneExtraString3",
		 "oneExtraString4"
      ]
   }
}
EOF
cat $tmp > myTripleNestedObject.json


cat <<EOF | tee givenLoadTripleNestedObject.zen | $Z -z -a myTripleNestedObject.json | tee givenTripleNestedObjectOutput.json
Given I have a valid 'string array' named 'myFirstArray'   
And I have a valid 'string array' named 'mySecondArray' inside 'mySecondObject'
And I have a 'myThirdArray' inside 'myThirdObject' 
And I have a 'myFourthArray'  
Then print all data
EOF

rm -f $tmp

let n=0
echo "                                                "
echo "------------------------------------------------"
echo "------------------------------------------------"
echo "------------------------------------------------"
echo "------------------------------------------------"
echo "     OLDER (and invisible) Script number $n     "
echo "------------------------------------------------"
echo "                                                "
let n=n+1

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


echo "                                                "
echo "------------------------------------------------"
echo "               OLDER Script number $n           "
echo "------------------------------------------------"
echo "                                                "
let n=n+1


cat <<EOF | tee nothing.zen | $Z -z
rule check version 1.0.0
	 Given nothing
	 When I create the random object of '256' bits
	 Then print the 'random object'
EOF


echo "                                                "
echo "------------------------------------------------"
echo "               OLDER Script number $n           "
echo "------------------------------------------------"
echo "                                                "
let n=n+1


echo '{ "anykey": "anyvalue" }' > $tmp
cat <<EOF | tee have.zen | $Z -z -a $tmp
rule check version 1.0.0
rule input encoding string
rule output encoding string
	 Given I have a 'anykey'
	 Then print the 'anykey'
EOF


echo "                                                "
echo "------------------------------------------------"
echo "               OLDER Script number $n           "
echo "------------------------------------------------"
echo "                                                "
let n=n+1

echo '{ "anykey": "616e7976616c7565" }' > $tmp
cat <<EOF | tee have.zen | $Z -z -a $tmp
rule check version 1.0.0
	 Given I have a 'anykey' as 'hex' 
	 Then print the 'anykey' as 'string'
EOF


echo "                                                "
echo "------------------------------------------------"
echo "               OLDER Script number $n           "
echo "------------------------------------------------"
echo "                                                "
let n=n+1


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



