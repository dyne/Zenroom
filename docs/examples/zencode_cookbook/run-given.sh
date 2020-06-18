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
Given I have a 'string' named 'myString'  
Given I have a 'number' named 'myNumber'
Given I have a valid 'string array' named 'myArray'
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
Given I have a 'number' named 'myNumber'
Then print all data
EOF



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
Given I have a 'string' named 'myString' 
Given debug
Given I have a 'number' named 'myNumber'
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




rm -f $tmp



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
	  "myFirstString":"Hello World!",
      "myFirstHex": "616e7976616c7565",
	  "myFirstArray":[
         "String1",
		 "String2"
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
# Given I have a 'string array' named 'myFirstArray'   
Given I have a 'string array' named 'mySecondArray' inside 'mySecondObject'
Given I have a 'myThirdArray' inside 'myThirdObject' 
Given I have a 'myFourthArray' inside 'myFourthObject'   
Given I have a 'number' named 'myFirstNumber'
Given I have a 'string' named 'myFirstString' 
Given I have a 'hex' named 'myFirstHex'
Then print the 'myFirstString' as 'string'
Then print the 'myFirstHex' as 'hex'
# Then print the 'myFirstNumber' as 'number'
EOF


rm -f $tmp


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
	  "myFirstString":"Hello World!",
      "myFirstHex": "616e7976616c7565",
      "myFirstBase64": "SGVsbG8gV29ybGQh",
	  "myFirstUrl64": "SGVsbG8gV29ybGQh",
	  "myFirstBinary": "0100100001101001",
	  "myFirstArray":[
         "String1",
		 "String2"
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


cat <<EOF | tee givenFullList.zen | $Z -z -a $tmp | tee givenFullList.json

# Arrays
Given I have a 'string array' named 'myFirstArray'   
Given I have a 'string array' named 'myFirstArray'   
Given I have an 'array' named 'myFirstArray'      
Given I have a 'string array' named 'mySecondArray' inside 'mySecondObject'
Given I have a 'myThirdArray' inside 'myThirdObject' 
Given I have a 'string array' named 'myFourthArray'
# Given I have an 'array' named 'myFirstObject'
# Numbers
Given I have a 'number' named 'myFirstNumber'
# Given I have a 'myFirstNumber'
Given I have a 'number' named 'myFirstNumber' inside 'myFirstObject' 
# Strings
Given I have a 'string' named 'myFirstString' 
Given I have a 'string' named 'myFirstString' inside 'myFirstObject' 
# Different data types
Given I have an 'hex' named 'myFirstHex'
Given I have a  'base64' named 'myFirstBase64'
Given I have a  'binary' named 'myFirstBinary'
Given I have an 'url64' named 'myFirstUrl64'
# Then print the 'myFirstString' as 'string'
# Then print the 'myFirstHex' as 'hex'
# Then print the 'myFirstUrl64' as 'hex'
Then print all data
# BROKEN Then print the 'myFirstNumber' as 'number'
EOF

rm -f $tmp





