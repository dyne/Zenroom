#!/usr/bin/env bash

# output path for documentation: ../../docs/examples/zencode_cookbook/

RNGSEED="hex:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

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
      "myFirstNumber":1.2345,
	  "myFirstString":"Hello World!",
      "myFirstHex": "616e7976616c7565",
      "myFirstBase64": "SGVsbG8gV29ybGQh",
	  "myFirstUrl64": "SGVsbG8gV29ybGQh",
	  "myFirstBinary": "0100100001101001",
	  "myFirstArray":[
		 "Hello World! myFirstObject, myFirstArray[0]",
		 "Hello World! myFirstObject, myFirstArray[1]",
		 "Hello World! myFirstObject, myFirstArray[2]"
      ],
	  "myFirstNumberArray":[10, 20, 30, 40, 50],
   "myOnlyEcpArray":[
        "Awz+ogtsf9xRn7hIw/6B1xvwoBNRgNFJOPYqSdPd+OAHXgDVuLWuKEvIsynbdWBJIw==",
		"A05tQgcTdT7+OAvfWZMIYI9G2owWBBR3/KqRBL/KPh2rPknbW1FBbRcee3P+7hpOoQ==",
		"AzijxD9GRztPcRtEXjdpXIPTzzmv0dvCdQNcmToC09pOw1ZLg/eAHdgEFV6oWhionQ==",
		"Ak8k6etvJjUPfSTFZFtQiRKaX1gIs3lUMzti+BQZW1XhUl8OOAOa/LrCRWyV1fpLwg=="
   ],
    "myOnlyEcp2Array":[    "QTQcWNiZgxQSyk7z0Zuy7GSF7kfrvahtaKFfgWsQeZurOpSSEiA81amccUi6S0LEIozhraN8aL+S8X7cPoqg7s1ftnC/S/MH3kwRwJ0jscACVvf+1Y/XEtngBZ0g1frPBNe6CVuaoQiXuda0g5t4mZzItGt6hgtsn7f/iHyO+Iwe1+9vUEzfysxNmFVjEq8ADEeFLqnltHbrI2H3vVZTc5g5IWxAJF00wE7n0kKb4AF59bqxbBN62dIqmVEodMDH",	"Anq3ieAxAEGfNzzQYUuQD1NPZuaojS6Fd3/nr3GFKqTPJmdEFTYamiGAN5nN5N5mMBMxE2sub/I39sqFKjDF22Iu/jZWsT+grD5E3PDuiaR4Ugr7V/WOdY3iiY5tfZm4AlWiNYSVR3KIcZe81E5q/GucEvAeC0VuGDgrTvTZ3/e7qxSxsi6aoqlLl2dD3AjABVQHfdY0BZ4gL1xYCmF7TYPs6LNeVb1+9buFZk3I7mskgGjrzgdKgm7IH3rL3Hsl",	"SQn5DHPbQTPmxfQirsxZ28uJu6PKv54UDXUzAqqUliAmc52+yFhwgeJpBWwpGfUPP04m8eNUo0hIO3EA2MKDaVxc78HS4PM2nm8ngyX/fTcg1WheaNIkrF4yycGeIEByB3NsYm36CvrJmfKQMtbON0yMpjD6vTfG6C82xaF+vRSieXgXDqh0e3e0deWkWo2vAQht5aqMDX0hGub01gk6tv/IeboIfr3fva80g4XPoiyfI23VZpRP65LdjnAS1seQ", 	"FcLlzyRlrLBCQAEKs6d+WCtV4awcogoGiGlWKStiuPR+1ms4ZBGKmwW+bniPcAQ3PEUqLBsy+SGmWA0IdkeGRyoJA/gsjZFYr8s8L5ZBd+zIk6ycjuK1fINyfXif3efmR0K2gjSQvptlzmggTr0SLoA3qO1vRZ2ZjPJLa4ehyhZaqx3rxqNWSxK/WzviPHfsAnYQVIOmJGsMl8lGpaJdHWh7XiMDUqJLu2B9OfE4O4pTE8eARR10oSaaNovDzkF+"
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
         "Hello World! myThirdObject, myThirdArray[0]",
         "Hello World! myThirdObject, myThirdArray[1]",
         "Hello World! myThirdObject, myThirdArray[2]",
		 "Hello World! myThirdObject, myThirdArray[3]"
      ],
	  "myCopyOfFirstArray":[
		 "Hello World!, myThirdObject, myCopyOfFirstArray[0]",
		 "Hello World!, myThirdObject, myCopyOfFirstArray[1]",
		 "Hello World!, myThirdObject, myCopyOfFirstArray[2]"
		 ]
   },
   "myFourthObject":{
      "myFourthArray":[
         "Hello World! inside myFourthObject, inside myFourthArray[0]",
         "Hello World! inside myFourthObject, inside myFourthArray[1]",
		 "Will this string be found inside an array?",
         "Hello World! inside myFourthObject, inside myFourthArray[2]",
		 "Hello World! inside myFourthObject, inside myFourthArray[3]"
      ],
  "myFourthString":"...and good evening!",
  "myFifthString":"We have run out of greetings.",
  "mySixthString":"So instead we'll tell the days of the week...",
  "mySeventhString":"...Monday,",
  "myEightEqualString":"These string is equal to another one.",
  "myNinthEqualString":"These string is equal to another one.",
  "myFourthNumber":3,
  "myTenthString":"Will this string be found inside an array?",
  "myEleventhStringToBeHashed":"hash me to kdf",
  "myTwelfthStringToBeHashedUsingPBKDF2":"hash me to pbkdf2",
  "myThirteenStringPassword":"my funky password",
  "myFourteenthStringToBeHashedUsingHMAC":"hash me to HMAC",
  "myFifteenthString":"Hello World again!",
  "mySixteenthString":"Hello World! myThirdObject, myThirdArray[2]",
  "myOnlyBIGArray":[
	"7dcd7392a9dea33b145a03279af78b1adf1c0549f5121ec28dd3dc136c0ca693",
	"8bd877e84538380c455448239f04d817e9657ecf2786442f11c98248ca8178a2",
	"d2cfc1b31b087d0d7137e3f5d45fc6a9cf33025fdba6f9cad40a04e36b420763",
	"554e2fcf3a4a1d872446febb81a91d910e772a4cf4c5e36a3569b159cb5ff439"
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
cat $tmp > ../../docs/examples/zencode_cookbook/myLargeNestedObjectWhen.json


cat <<EOF  > $tmpGiven
# We're using scenario 'ecdh' cause we are loading a keypair
Scenario 'ecdh': Create the keypair
Given I have a 'keypair' from 'Alice'
# Load Arrays
Given I have a 'string array' named 'myFirstArray'  inside 'myFirstObject'
Given I have a 'string array' named 'mySecondArray' inside 'mySecondObject'
Given I have a 'string array' named 'myThirdArray' inside 'myThirdObject' 
Given I have a 'string array' named 'myFourthArray' inside 'myFourthObject'
Given I have a 'number array' named 'myFirstNumberArray' inside 'myFirstObject'
Given I have a 'string array' named 'myCopyOfFirstArray' inside 'myThirdObject'
Given I have a 'base64 array' named 'myOnlyEcpArray' inside 'myFirstObject'
Given I have a 'base64 array' named 'myOnlyEcp2Array' inside 'myFirstObject'
# Load Numbers
Given I have a 'number' named 'myFirstNumber' in 'myFirstObject'
Given I have a 'number' named 'mySecondNumber' in 'mySecondObject'
Given I have a 'number' named 'myFourthNumber' inside 'myFourthObject'
Given I have a 'number' named 'myThirdNumber' inside 'myThirdObject' 
# Load Strings
Given I have a 'string' named 'myFirstString' in 'myFirstObject'
Given I have a 'string' named 'mySecondString' inside 'mySecondObject'
Given I have a 'string' named 'myThirdString' inside 'myThirdObject' 
Given I have a 'string' named 'myFourthString' inside 'myFourthObject'
Given I have a 'string' named 'myFifthString' inside 'myFourthObject'
Given I have a 'string' named 'mySixthString' inside 'myFourthObject'
Given I have a 'string' named 'mySeventhString' inside 'myFourthObject'
Given I have a 'string' named 'myTenthString' inside 'myFourthObject'
Given I have a 'string' named 'myEleventhStringToBeHashed' inside 'myFourthObject'
Given I have a 'string' named 'myTwelfthStringToBeHashedUsingPBKDF2' inside 'myFourthObject' 
Given I have a 'string' named 'myThirteenStringPassword' inside 'myFourthObject'
Given I have a 'string' named 'myFourteenthStringToBeHashedUsingHMAC' inside 'myFourthObject'
Given I have a 'string' named 'myFifteenthString' inside 'myFourthObject'
Given I have a 'string' named 'mySixteenthString' inside 'myFourthObject'
# Different data types
Given I have an 'hex' named 'myFirstHex' inside 'myFirstObject' 
Given I have a  'base64' named 'myFirstBase64' in 'myFirstObject'
Given I have a  'binary' named 'myFirstBinary' in 'myFirstObject'
Given I have an 'url64' named 'myFirstUrl64' in 'myFirstObject'
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
# SUM, SUBTRACTION
# You can use the statement 'When I create the result of ... " to 
# sum or subtract values, see the examples below. The output of the 
# statement will be an object named "result" that we immediately rename.
When I create the result of 'mySecondNumber' + 'myThirdNumber'
and I rename the 'result' to 'resultOfmyFirstSum'
When I create the result of 'mySecondNumber' - 'myThirdNumber'
and I rename the 'result' to 'resultOfmyFirstSubtraction'

# APPEND
# The "append" statement are pretty self-explaining: 
# append a simple object of any encoding to another one
When I append 'mySecondString' to 'myFifteenthString' 
When I append 'mySecondNumber' to 'myThirdNumber' 

# RENAME
# The "rename" statement: we've been hinting at this for a while now,
# pretty self-explaining, it works with any object type or schema.
When I rename the 'myThirdArray' to 'myJustRenamedArray'

# INSERT
# The "insert" statement is used to append a simple object to an array.
# It's pretty self-explaining. 
When I insert 'myFirstString' in 'myFirstArray'

# REMOVE
# The "remove" statement does the opposite of the one above:
# Use it remove an element from an array, it takes as input the name of a string, 
# and the name of an array - we don't mix code and data! 
When I remove the 'mySixteenthString' from 'myJustRenamedArray'

# SPLIT (leftmost, rightmost)
# The "split" statements, take as input the name of a string and a numeric value,
# the statement removes the leftmost/outmost characters from the string 
# and places the result in a newly created string called "leftmost" or "rightmost"
# which we immediately rename
When I split the leftmost '4' bytes of 'mySecondString'
And I rename the 'leftmost' to 'myFirstStringLeftmost'
When I split the rightmost '6' bytes of 'myThirdString'
And I rename the 'rightmost' to 'myThirdStringRightmost'

# RANDOMIZE
# The "randomize" statements takes the name of an array as input and shuffles it. 
When I randomize the 'myFourthArray' array

# WRITE IN (create string or number)
# the "write in" statement create a new object, assigns it an encoding but 
# only "number" or "string" (if you need any other encoding, 
# use the "set as" statement) and assigns it the value you define.
When I write number '10' in 'nameOfFirstNewVariable'
When I write string 'This is my lovely new string!' in 'nameOfSecondNewVariable'

# PICK RANDOM
# The "pick a random object in" picks randomly an object from the target array
# and puts into a newly created object named "random_object".
# The name is hardcoded, the object can be renamed.
When I pick the random object in 'myFirstArray'
and I rename the 'random_object' to 'myRandomlyPickedObject'

# FLATTEN
# The flatten (or serialization) statement is used to flatten an array or a complex structure. 
# The main use case is pre-processing the data to be hashed or signed.
# The serialization uses an custom algorythm: it can only be reproduced 
# with Zenroom, but there are ways to make Zenroom's hashing of complex structured
# verifiable with other tools, as well as use Zenroom to check hashes produced by
# other softwares. As statement, you can use both "flattening" and "serialization"  
When I create the flattening of 'myFirstArray'
And I rename the 'flattening' to 'serializationOfmyFirstArray'
When I create the serialization of data
And I rename the 'serialization' to 'serializationOfAllData'

Then print all data
EOF

cat $tmpWhen1 > ../../docs/examples/zencode_cookbook/whenCompleteScriptPart1.zen


cat $tmpZen1 | zexe ../../docs/examples/zencode_cookbook/temp.zen -z -a $tmp | jq . | tee ../../docs/examples/zencode_cookbook/whenCompleteOutputPart1.json | jq



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
# and you can select the length in bits. The first statement uses the default lenght of 512 bits.
# Like the previous one, this statement outputs an object whose name is hardcoded into "array".
# Since we're creating three arrays called "array" below, Zenroom would simply overwrite 
# the first two, so we are renaming the output immediately. 
When I create the array of '4' random objects
and I rename the 'array' to 'my4RandomObjectsArray'
When I create the array of '5' random objects of '256' bits
and I rename the 'array' to 'my256BitsRandomObjectsArray'

# You can generate an array of random numbers, from 0 o 65355, with this statement.
When I create the array of '10' random numbers 
and I rename the 'array' to 'my10RandomNumbersArray'
# A variation of the statement above, allows you to use the "modulo" function to cap the max value
# of the random numbers. In the example below, the max value will be "999".
When I create the array of '16' random numbers modulo '1000'
and I rename the 'array' to 'my16RandomNumbersModulo1000Array'

# SET
# The 'set' statement creates a new variable and assign it a value.
# Overwriting variables discouraged in Zenroom: if you try to overwrite an existing variable, 
# you will get an error, that you can override the error using a rule 
# in the beginning of the script.
# The 'set' statement can generate different kind of schemas, as well as to create variables 
# containing numbers in different bases. 
# When working with strings, remember that spaces are converted to underscores.
When I set 'myNewlyCreatedString' to 'call me The Pink Panther!' as 'string'
When I set 'myNewlyCreatedBase64' to 'SGVsbG8gV29ybGQh' as 'base64'
When I set 'myNewlytCreatedNumber' to '42' as 'number'
When I set 'myNewlyCreatedNumberInBaseSomething' to '42' base '16'

Then print all data
EOF

cat $tmpWhen2 > ../../docs/examples/zencode_cookbook/whenCompleteScriptPart2.zen


cat $tmpZen2 | zexe ../../docs/examples/zencode_cookbook/temp.zen -z -a $tmp | jq . | tee ../../docs/examples/zencode_cookbook/whenCompleteOutputPart2.json | jq



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
# This statement takes an array as input, and produces an array as output named "hash_to_point", which
# we immediately rename.
When I create the hash to point 'ecp' of each object in 'myFourthArray'
And I rename the 'hash_to_point' to 'ecpHashesOfMyFourthArray'
When I create the hash to point 'ecp2' of each object in 'myFirstArray'        
And I rename the 'hash_to_point' to 'ecp2HashesOfMyFirstArray'

# Key derivation function (KDF)
# The output object is named "key_derivation":
When I create the key derivation of 'myEleventhStringToBeHashed'
And I rename the 'key_derivation' to 'kdfOfMyEleventhString'

# Password-Based Key Derivation Function (pbKDF) hashing, 
# this also outputs an object named "key_derivation":
When I create the key derivation of 'myTwelfthStringToBeHashedUsingPBKDF2' with password 'myThirteenStringPassword'
And I rename the 'key_derivation' to 'pbkdf2OfmyTwelfthString'

# Hash-based message authentication code (HMAC)
When I create the HMAC of 'myFourteenthStringToBeHashedUsingHMAC' with key 'myThirteenStringPassword'
And I rename the 'HMAC' to 'hmacOfMyFourteenthString'

# AGGREGATE
# The "create the aggregation" statement takes as input an array of numers
# and sums then it into a new object called "aggregation" that we'll rename immediately.
# It works on both arrays and dictionaries, the data type needs to be 
# specified as in the example.
When I create the aggregation of array 'myFirstNumberArray'
And I rename the 'aggregation' to 'aggregationOfMyFirstNumberArray'

# Now let's print out everything
Then print all data  
EOF

cat $tmpWhen3 > ../../docs/examples/zencode_cookbook/whenCompleteScriptPart3.zen

cat $tmpZen3 | zexe ../../docs/examples/zencode_cookbook/temp.zen -z -a $tmp | jq . | tee ../../docs/examples/zencode_cookbook/whenCompleteOutputPart3.json | jq



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
# It works with simple objects of any encoding.
When I verify 'myEightEqualString' is equal to 'myNinthEqualString'         
When I verify 'myThirdNumber' is equal to 'myFourthNumber'

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



cat $tmpZen4 | zexe ../../docs/examples/zencode_cookbook/temp.zen -z -a $tmp | jq . | tee ../../docs/examples/zencode_cookbook/whenCompleteOutputPart4.json | jq

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
