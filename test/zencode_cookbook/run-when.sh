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
tmpGiven=`mktemp`
tmpWhen1=`mktemp`	
tmpZen1="${tmpGiven} ${tmpWhen1}"
tmpWhen2=`mktemp`	
tmpZen2="${tmpGiven} ${tmpWhen2}"
tmpWhen3=`mktemp`	
tmpZen3="${tmpGiven} ${tmpWhen3}"
tmpWhen4=`mktemp`	
tmpZen4="${tmpGiven} ${tmpWhen4}"


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
		 "String2",
		 "String3"
      ],
	  "myFirstNumberArray":[10, 20, 30],
   "myOnlyEcpArray":[
      "AjHGaNdano8URHxzbkzBJgqWSUVL5Dm3YMx-AYaZFe8u4H-yZL1UmxwxAiWy4mysnQ",
      "AhhVr7iKRMvU1VGFld2-IUwh8ywNwPGLJ4_6_QAfQ4qpHD0BcFBNsQkdzmrrhWPGjg",
      "AzfRdz8Rvg0cZAmfd8tG_31rWPgPd1t_EQ_s-D9BjrtpiDl6gm1t8kwyLNqWacvYAw",
      "Az9Qi996vQvcQOxRiddsh8GGpFjMdpiDQv4LSh7IuFtA2WKmBVb5-5q43nRJsN3E9A"
   ]
   },
   "mySecondObject":{
      "mySecondNumber":2,
	  "mySecondString":"...and hi everybody!",
      "mySecondArray":[
         "anotherString1",
         "anotherString2"
      ]
   },
   "myThirdObject":{
      "myThirdNumber":3,
	  "myThirdString":"...and good morning!",
      "myThirdArray":[
         "oneMoreString1",
         "oneMoreString2",
         "oneMoreString3",
		 "Hello World!"
      ],
	  "myCopyOfFirstArray":[
		 "String1",
		 "String2",
		 "String3"
		 ]
   },
   "myFourthObject":{
      "myFourthArray":[
         "oneExtraString1",
         "oneExtraString2",
         "oneExtraString3",
		 "oneExtraString4"
      ],
  "myFourthString":"...and good evening!",
  "myFifthString":"We have run out of greetings.",
  "mySixthString":"So instead we'll tell the days of the week...",
  "mySeventhString":"...Monday,",
  "myEightEqualString":"These string is equal to another one.",
  "myNinthEqualString":"These string is equal to another one.",
  "myFourthNumber":3,
  "myTenthString":"oneExtraString1",
  "myEleventhStringToBeHashed":"hash me to kdf",
  "myTwelfthStringToBeHashedUsingPBKDF2":"hash me to pbkdf2",
  "myThirteenStringPassword":"my funky password",
  "myFourteenthStringToBeHashedUsingHMAC":"hash me to HMAC"

  
   },
   
   "Alice":{
      "keypair":{
         "private_key":"AxLMXkey00i2BD675vpMQ8WhP/CwEfmdRr+BtpuJ2rM=",
         "public_key":"BDDuiMyAjIu8tE3pGSccJcwLYFGWvo3zUAyazLgTlZyEYOePoj+/UnpMwV8liM8mDobgd/2ydKhS5kLiuOOW6xw="
      }
   }
   
}
EOF
cat $tmp > ../../docs/examples/zencode_cookbook/myLargeNestedObjectWhen.json


cat <<EOF  > $tmpGiven
# We're using scenario 'ecdh' cause we are loading a keypair
Scenario 'ecdh': Create the keypair
Given I have a 'keypair' from 'Alice'
# Load Arrays
Given I have a 'string array' named 'myFirstArray'   
Given I have a 'string array' named 'mySecondArray' inside 'mySecondObject'
Given I have a 'string array' named 'myThirdArray' inside 'myThirdObject' 
Given I have a 'string array' named 'myFourthArray'
Given I have a 'number array' named 'myFirstNumberArray' inside 'myFirstObject'
Given I have a 'string array' named 'myCopyOfFirstArray'
Given I have a 'ecp array' named 'myOnlyEcpArray'   
# Load Numbers
Given I have a 'number' named 'myFirstNumber' in 'myFirstObject'
Given I have a 'number' named 'mySecondNumber' in 'mySecondObject'
Given I have a 'number' named 'myFourthNumber'
Given I have a 'number' named 'myThirdNumber'
# Load Strings
Given I have a 'string' named 'myFirstString' in 'myFirstObject'
Given I have a 'string' named 'mySecondString'
Given I have a 'string' named 'myThirdString'
Given I have a 'string' named 'myFourthString'
Given I have a 'string' named 'myFifthString'
Given I have a 'string' named 'mySixthString'
Given I have a 'string' named 'mySeventhString'
Given I have a 'string' named 'myTenthString'
Given I have a 'string' named 'myEleventhStringToBeHashed'
Given I have a 'string' named 'myTwelfthStringToBeHashedUsingPBKDF2' 
Given I have a 'string' named 'myThirteenStringPassword'
Given I have a 'string' named 'myFourteenthStringToBeHashedUsingHMAC' 
# Different data types
Given I have an 'hex' named 'myFirstHex' 
Given I have an 'hex' named 'myFirstHex' inside 'myFirstObject' 
Given I have a  'base64' named 'myFirstBase64'
Given I have a  'binary' named 'myFirstBinary'
Given I have an 'url64' named 'myFirstUrl64'
# Let's debug here to make sure we know what we're loading
and debug
# Here we're done loading stuff 
EOF
cat $tmpGiven > ../../docs/examples/zencode_cookbook/whenCompleteScriptGiven.zen



let n=n+1

echo "                                                "
echo "------------------------------------------------"
echo "   The Manipulation statements: $n              "
echo " Manipulation: append, rename, insert, remove..."
echo "------------------------------------------------"
echo "                                                "



cat <<EOF  > $tmpWhen1
# APPEND
# The "append" statement are pretty self-explaining: 
# append a simple object like a number (or a string) to an existing array (or string array)
When I append 'myFirstString' to 'mySecondString' as 'string'
When I append string 'myThirdString' to 'myFourthString'

# RENAME
# The "rename" statement: we've been hinting at this for a while now,
# pretty self-explaining, it works with any object type or schema.
When I rename the 'myThirdArray' to 'myJustRenamedArray'

# INSERT
# The "insert" statement is used to append a simple object to an array (or string array).
# It's pretty self-explaining.
When I insert the 'myFirstString' in 'myFirstArray'

# REMOVE
# The "remove" statement does the opposite of the one above:
# Use it remove an element from an array, it takes as input the name of a string, 
# and the name of an array - we don't mix code and data! 
When I remove the 'myFirstString' from 'myJustRenamedArray'

# SPLIT (leftmost, rightmost)
# The "split" statements, take as input the name of a string and a numeric value,
# the statement removes the leftmost/outmost characters from the string 
# and places the result in a newly created string called "leftmost" or "rightmost"
When I split the leftmost '3' bytes of 'myFirstString'
When I split the rightmost '6' bytes of 'myThirdString'

# RANDOMIZE
# The "randomize" statements takes the name of an array as input and shuffles it. 
When I randomize the 'myFourthArray' array

# WRITE IN
# the "write in" statement create a new object, assigns it a schemas (number or string in the examples) 
# and assigns it the value you define.
When I write number '10' in 'nameOfFirstNewVariable'
When I write string 'This is my lovely new string!' in 'nameOfSecondNewVariable'

# PICK RANDOM
# The "pick a random object in" picks randomly an object from the target array
# and puts into a newly created object named "random_object".
# The name is hardcoded, the object can be renamed.
When I pick the random object in 'myFirstArray'
Then print all data
EOF

cat $tmpWhen1 > ../../docs/examples/zencode_cookbook/whenCompleteScriptPart1.zen


cat $tmpZen1 | zexe ../../docs/examples/zencode_cookbook/temp.zen -z -a $tmp | jq . | tee ../../docs/examples/zencode_cookbook/whenCompleteOutputPart1.json



echo "                                                "
echo "------------------------------------------------"
echo "   	END of script $n       		  			"
echo "------------------------------------------------"
echo "                                                "



let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo "   The 'create' and 'set' statements: $n                 "
echo "------------------------------------------------"
echo "                                                "




cat <<EOF  > $tmpWhen2
# CREATE RANDOM
# The "create random" creates a random object with a default set of parameters
# The name of the generate objected is defined between the ' '  
# The parameters can be modified by passing them to Zenroom as configuration file
When I create the random 'newRandomObject'
# Below is a variation that lets you create a random number of configurable length.
# This statement doesn't let you choose the name of the name of the newly created object,
# which is hardcoded to "random_object". We are immediately renaming it.
When I create the random object of '128' bits
and I rename the 'random_object' to 'my128BitsRandom'
# The "create array of random" statement, lets you create an array of random objects, 
# and you can select the length in bits.
# Like the previous one, this statement outputs an object whose name is hardcoded into "array".
# Since we're creating three arrays called "array" below, Zenroom would simply overwrite 
# the first two, so we are renaming the output immediately. 
When I create the array of '4' random objects
and I rename the 'array' to 'my4RandomObjectsArray'
When I create the array of '5' random objects of '512' bits
and I rename the 'array' to 'my512BitsRandomObjectsArray'
# A special case of the "create random" is the "create random curve points":
# this statement outputs an array of ECP points and put in an array called "array"
#The curve used can be modified via configuration file.
When I create the array of '3' random curve points
and I rename the 'array' to 'myECPPointsArray'

# SET
# The 'set' statement creates a new variable and assign it a value.
# Overwriting variables discouraged in Zenroom: if you try to overwrite an existing variable, 
# you will get an error, that you can override the error using a rule in the beginning of the script.
# The 'set' statement can generate different kind of schemas, as well as to create variables 
# containing numbers in different bases.
When I set 'myNewlyCreatedString' to 'call me The Pink Panther!' as 'string'
When I set 'myFirstNewlyCreatedNumber' to '42' as 'number'
When I set 'mySecondNewlyCreatedNumber' to '42' base '16'
Then print all data 
EOF

cat $tmpWhen2 > ../../docs/examples/zencode_cookbook/whenCompleteScriptPart2.zen


cat $tmpZen2 | zexe ../../docs/examples/zencode_cookbook/temp.zen -z -a $tmp | jq . | tee ../../docs/examples/zencode_cookbook/whenCompleteOutputPart2.json



echo "                                                "
echo "------------------------------------------------"
echo "   				END of script $n       		  "
echo "------------------------------------------------"
echo "                                                "




let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo "   The cryptography statements: $n              "
echo "------------------------------------------------"
echo "                                                "




cat <<EOF  > $tmpWhen3
# HASH

# Output objects: as overwriting variables is discouraged in Zenroom, all the hashing
# and cryptography statements will output a new object with a hardcoded name, listed
# along with the statement. It's a good practice to rename the object immediately after
# its creation, both to make it more readable and as well to avoid overwriting in case you
# are using a statement with similar output more than once in the same script.

# The "create hash" statement hashes a string, but it does not hash an array!
# The default algorythm for the hash can be modified by passing them to Zenroom as config file. 
# Note that the object produced, containing the hashing of the string, will be named "hash", 
# which we promptly rename. The same is true for the two following statements.
When I create the hash of 'myFifthString'
And I rename the 'hash' to 'hashOfMyFifthString'

# Following is a version of the statement above that takes the hashing algorythm as parameter, 
# it accepts sha256 or sha512 as hash types
When I create the hash of 'mySixthString' using 'sha256'
And I rename the 'hash' to 'hashOfMySixthString'
When I create the hash of 'mySeventhString' using 'sha512'
And I rename the 'hash' to 'hashOfMySeventhString'

# The "create hash to point" statement can do some serious cryptography: 
# use it generating public keys from a secret key, where the secret key can be any random number.
# The statement accepts curves "ecp" or "ecp2" to produce the hash.
# This statement takes an array as input, and produces an array as output named "hashes", which
# we immediately rename.
When I create the hash to point 'ecp' of each object in 'myFourthArray'
And I rename the 'hashes' to 'ECPhashesOfMyFourthArray'
When I create the hash to point 'ecp2' of each object in 'myFirstArray'        
And I rename the 'hashes' to 'ECP2hashesOfMyFirstArray'

# Key derivation function (KDF)
# The output object is named "key_derivation":
When I create the key derivation of 'myEleventhStringToBeHashed'
And I rename the 'key_derivation' to 'kdfOfMyEleventhString'

# Password-Based Key Derivation Function (pbkdf) hashing, 
# this also outputs an object named "key_derivation":
When I create the key derivation of 'myTwelfthStringToBeHashedUsingPBKDF2' with password 'myThirteenStringPassword'
And I rename the 'key_derivation' to 'pbkdf2OfmyTwelfthString'

# Hash-based message authentication code (HMAC), 
When I create the HMAC of 'myFourteenthStringToBeHashedUsingHMAC' with key 'myThirteenStringPassword'
And I rename the 'HMAC' to 'HMACOfMyFourteenthString'

# AGGREGATE ECP POINTS
# The "create the aggregation" statement takes as input an array of ECP points
# and aggregates it into a new object called "aggregation" that we'll rename
When I create the aggregation of 'myOnlyEcpArray'
And I rename the 'aggregation' to 'aggregationOfMyOnlyEcpArray'

# Since we've been dealing with cryptography, we probably want to format the output
# as "hex", which we do as follows:
Then print all data as 'hex' 
EOF

cat $tmpWhen3 > ../../docs/examples/zencode_cookbook/whenCompleteScriptPart3.zen

cat $tmpZen3 | zexe ../../docs/examples/zencode_cookbook/temp.zen -z -a $tmp | jq . | tee ../../docs/examples/zencode_cookbook/whenCompleteOutputPart3.json



echo "                                                "
echo "------------------------------------------------"
echo "                END of script $n                "
echo "------------------------------------------------"
echo "                                                "


let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo "   The Comparisons statements: $n               "
echo " more, less or equal, find elements in objects..."
echo "------------------------------------------------"
echo "                                                "


cat <<EOF  > $tmpWhen4
# VERIFY EQUAL
# The "verify equal" statement checks that the value of two ojects is equal.
# It works with strings, numbers and arrays.
When I verify 'myEightEqualString' is equal to 'myNinthEqualString'         
When I verify 'myThirdNumber' is equal to 'myFourthNumber'
# When I verify 'myCopyOfFirstArray' is equal to 'myFirstArray'

# LESS, MORE, EQUAL
# Number comparisons: those are pretty self explaining.
When number 'myFourthNumber' is less or equal than 'myThirdNumber'
When number 'myFirstNumber' is less than  'myThirdNumber'
When number 'myThirdNumber' is more or equal than 'mySecondNumber'
When number 'myThirdNumber' is more than 'mySecondNumber'

# FOUND, NOT FOUND
# The "is found" statement, takes two objects as input: 
# the name of a variable and the name of an array. It reads its content of the variable 
# and matches it against each element of the array.
# It works with any kind of array, as long as the element of the array are of the same schema
# as the variable.
When the 'myTenthString' is found in 'myFourthArray'
When the 'myFirstString' is not found in 'myFourthArray'
Then print all data
EOF

cat $tmpWhen4 > ../../docs/examples/zencode_cookbook/whenCompleteScriptPart4.zen



cat $tmpZen4 | zexe ../../docs/examples/zencode_cookbook/temp.zen -z -a $tmp | jq . | tee ../../docs/examples/zencode_cookbook/whenCompleteOutputPart4.json 

# > jq >

echo "                                                "
echo "------------------------------------------------"
echo "   	END of script $n			       		  "
echo "------------------------------------------------"
echo "                                      "

rm -f ../../docs/examples/zencode_cookbook/temp.zen

rm -f $tmp
rm -f $tmpGiven
rm -f $tmpWhen1
rm -f $tmpZen1
rm -f $tmpWhen2
rm -f $tmpZen2
rm -f $tmpWhen3
rm -f $tmpZen3
rm -f $tmpWhen4
rm -f $tmpZen4
