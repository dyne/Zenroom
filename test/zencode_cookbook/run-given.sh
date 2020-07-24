#!/usr/bin/env bash

# output path for documentation: ../../docs/examples/zencode_cookbook/


####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

n=0
tmp=`mktemp`



echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1


echo '{ 
      "myNumber":12345,
      "myString":"Hello World!",
      "myArray":[
         "String-1-one",
         "String-2-two",
         "String-3-three",
		 "String-4-four",
		 "String-5-five"
      ]
}' > $tmp


cat <<EOF | zexe ../../docs/examples/zencode_cookbook/givenLoadFlatObject.zen -z -a $tmp | jq | tee ../../docs/examples/zencode_cookbook/givenLoadFlatObjectOutput.json
Given I have a 'string' named 'myString'  
Given I have a 'number' named 'myNumber'
Given I have a 'string array' named 'myArray'
When I randomize the 'myArray' array
Then print 'myNumber' 
Then print 'myString' as 'string'
Then print 'myArray' as 'string'
Then print all data
EOF

cat $tmp > ../../docs/examples/zencode_cookbook/myFlatObject.json
# End of script loading object



echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1

cat <<EOF | zexe ../../docs/examples/zencode_cookbook/givenLoadNumber.zen -z -a $tmp | jq | tee ../../docs/examples/zencode_cookbook/givenLoadNumberOutput.json
Given I have a 'number' named 'myNumber'
Then print all data
EOF



echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1


cat <<EOF | zexe ../../docs/examples/zencode_cookbook/givenLoadArrayDebugVerbose.zen -z -a ../../docs/examples/zencode_cookbook/myFlatObject.json | jq | tee ../../docs/examples/zencode_cookbook/givenDebugOutputVerbose.json
Given debug
Given I have a 'string array' named 'myArray'
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
			 "private_key":"AxLMXkey00i2BD675vpMQ8WhP/CwEfmdRr+BtpuJ2rM=",
			 "public_key":"BDDuiMyAjIu8tE3pGSccJcwLYFGWvo3zUAyazLgTlZyEYOePoj+/UnpMwV8liM8mDobgd/2ydKhS5kLiuOOW6xw="
		  }
	   }
   
   
   
}
EOF

cat $tmp > ../../docs/examples/zencode_cookbook/myNestedRepetitveObject.json

cat <<EOF | zexe ../../docs/examples/zencode_cookbook/givenLoadRepetitveObject.zen -z -a $tmp | jq | tee ../../docs/examples/zencode_cookbook/givenLoadRepetitveObjectOutput.json
Scenario 'ecdh': let us load some stuff cause it is fun!
Given I am 'Alice'
And I have my  'keypair'
And I have a 'string array' named 'myArray' inside 'myFirstObject' 
And I have a 'string array' named 'myArray' inside 'mySecondObject' 
Then print all data
EOF



echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1

cat <<EOF | zexe ../../docs/examples/zencode_cookbook/givenLoadRepetitveObjectDebug.zen -z -a $tmp | jq | tee ../../docs/examples/zencode_cookbook/givenLoadRepetitveObjectDebugOutput.json
Scenario 'ecdh': let us load some stuff cause it is fun!
Given I am 'Alice'
And I have my  'keypair'
And I have a 'string array' named 'myArray' inside 'myFirstObject' 
And I have a 'string array' named 'myArray' inside 'mySecondObject' 
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
         "private_key":"AxLMXkey00i2BD675vpMQ8WhP/CwEfmdRr+BtpuJ2rM=",
         "public_key":"BDDuiMyAjIu8tE3pGSccJcwLYFGWvo3zUAyazLgTlZyEYOePoj+/UnpMwV8liM8mDobgd/2ydKhS5kLiuOOW6xw="
      }
   }
}
EOF

cat $tmp > ../../docs/examples/zencode_cookbook/myNestedObject.json





cat <<EOF | zexe ../../docs/examples/zencode_cookbook/givenLoadNestedObject.zen -z -a $tmp | jq | tee ../../docs/examples/zencode_cookbook/givenLoadNestedObjectOutput.json
Scenario 'ecdh': let us load some stuff cause it is fun!
Given I am 'Alice'
And I have my  'keypair'
And I have a 'string array' named 'myFirstArray' inside 'myFirstObject' 
And I have a 'string array' named 'mySecondArray' inside 'mySecondObject' 
Then print all data
EOF




rm -f $tmp



echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1


cat <<EOF | zexe ../../docs/examples/zencode_cookbook/givenLoadArrayDebug.zen -z -a ../../docs/examples/zencode_cookbook/myFlatObject.json | jq | tee ../../docs/examples/zencode_cookbook/givenDebugOutput.json
Given I have a  'string array' named 'myArray' 
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
cat $tmp > ../../docs/examples/zencode_cookbook/myTripleNestedObject.json


cat <<EOF | zexe ../../docs/examples/zencode_cookbook/givenLoadTripleNestedObject.zen -z -a ../../docs/examples/zencode_cookbook/myTripleNestedObject.json | jq | tee ../../docs/examples/zencode_cookbook/givenTripleNestedObjectOutput.json
# Given I have a 'string array' named 'myFirstArray'   
Given I have a 'string array' named 'mySecondArray' inside 'mySecondObject'
Given I have a 'string array' named 'myThirdArray' inside 'myThirdObject' 
Given I have a 'string array' named  'myFourthArray' inside 'myFourthObject'   
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
      "myFirstNumber":1.23456,
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
cat $tmp > ../../docs/examples/zencode_cookbook/myLargeNestedObject.json

cat <<EOF | zexe ../../docs/examples/zencode_cookbook/givenFullList.zen -z -a $tmp | jq | tee ../../docs/examples/zencode_cookbook/givenFullList.json

# Load Arrays
Given I have a 'string array' named 'myFirstArray'   
Given I have an 'string array' named 'myFirstArray' 
Given I have a 'string array' named 'mySecondArray' inside 'mySecondObject'
Given I have a 'string array' named 'myThirdArray' inside 'myThirdObject' 
Given I have a 'string array' named 'myFourthArray'
# Load Numbers
Given I have a 'number' named 'myFirstNumber'
Given I have a 'number' named 'mySecondNumber' inside 'mySecondObject'
# Load Strings
Given I have a 'string' named 'myFirstString' 
Given I have a 'string' named 'myFirstString' inside 'myFirstObject' 
# Different data types
Given I have an 'hex' named 'myFirstHex' 
Given I have an 'hex' named 'myFirstHex' inside 'myFirstObject' 
Given I have a  'base64' named 'myFirstBase64'
Given I have a  'binary' named 'myFirstBinary'
Given I have an 'url64' named 'myFirstUrl64'
and debug
Then print all data
EOF

rm -f $tmp





