load ../bats_setup
load ../bats_zencode
SUBDOC=cookbook_when

@test "Manipulation statements: append, rename, insert, remove..." {
    cat <<EOF | save_asset myLargeNestedObjectWhen.json
{
  "myFirstObject": {
    "myFirstNumber": 1.2345,
    "myFirstString": "Hello World!",
    "myFirstHex": "616e7976616c7565",
    "myFirstBase64": "SGVsbG8gV29ybGQh",
    "myFirstUrl64": "SGVsbG8gV29ybGQh",
    "myFirstBinary": "0100100001101001",
    "myFirstArray": [
      "Hello World! myFirstObject, myFirstArray[0]",
      "Hello World! myFirstObject, myFirstArray[1]",
      "Hello World! myFirstObject, myFirstArray[2]"
    ],
    "myFirstNumberArray": [
      10,
      20,
      30,
      40,
      50
    ],
    "myOnlyEcpArray": [
      "Awz+ogtsf9xRn7hIw/6B1xvwoBNRgNFJOPYqSdPd+OAHXgDVuLWuKEvIsynbdWBJIw==",
      "A05tQgcTdT7+OAvfWZMIYI9G2owWBBR3/KqRBL/KPh2rPknbW1FBbRcee3P+7hpOoQ==",
      "AzijxD9GRztPcRtEXjdpXIPTzzmv0dvCdQNcmToC09pOw1ZLg/eAHdgEFV6oWhionQ==",
      "Ak8k6etvJjUPfSTFZFtQiRKaX1gIs3lUMzti+BQZW1XhUl8OOAOa/LrCRWyV1fpLwg=="
    ],
    "myOnlyEcp2Array": [
      "QTQcWNiZgxQSyk7z0Zuy7GSF7kfrvahtaKFfgWsQeZurOpSSEiA81amccUi6S0LEIozhraN8aL+S8X7cPoqg7s1ftnC/S/MH3kwRwJ0jscACVvf+1Y/XEtngBZ0g1frPBNe6CVuaoQiXuda0g5t4mZzItGt6hgtsn7f/iHyO+Iwe1+9vUEzfysxNmFVjEq8ADEeFLqnltHbrI2H3vVZTc5g5IWxAJF00wE7n0kKb4AF59bqxbBN62dIqmVEodMDH",
      "Anq3ieAxAEGfNzzQYUuQD1NPZuaojS6Fd3/nr3GFKqTPJmdEFTYamiGAN5nN5N5mMBMxE2sub/I39sqFKjDF22Iu/jZWsT+grD5E3PDuiaR4Ugr7V/WOdY3iiY5tfZm4AlWiNYSVR3KIcZe81E5q/GucEvAeC0VuGDgrTvTZ3/e7qxSxsi6aoqlLl2dD3AjABVQHfdY0BZ4gL1xYCmF7TYPs6LNeVb1+9buFZk3I7mskgGjrzgdKgm7IH3rL3Hsl",
      "SQn5DHPbQTPmxfQirsxZ28uJu6PKv54UDXUzAqqUliAmc52+yFhwgeJpBWwpGfUPP04m8eNUo0hIO3EA2MKDaVxc78HS4PM2nm8ngyX/fTcg1WheaNIkrF4yycGeIEByB3NsYm36CvrJmfKQMtbON0yMpjD6vTfG6C82xaF+vRSieXgXDqh0e3e0deWkWo2vAQht5aqMDX0hGub01gk6tv/IeboIfr3fva80g4XPoiyfI23VZpRP65LdjnAS1seQ",
      "FcLlzyRlrLBCQAEKs6d+WCtV4awcogoGiGlWKStiuPR+1ms4ZBGKmwW+bniPcAQ3PEUqLBsy+SGmWA0IdkeGRyoJA/gsjZFYr8s8L5ZBd+zIk6ycjuK1fINyfXif3efmR0K2gjSQvptlzmggTr0SLoA3qO1vRZ2ZjPJLa4ehyhZaqx3rxqNWSxK/WzviPHfsAnYQVIOmJGsMl8lGpaJdHWh7XiMDUqJLu2B9OfE4O4pTE8eARR10oSaaNovDzkF+"
    ],
    "myNestedArray": [
      [
        "hello World! myFirstObject, myNestedArray[0][0]",
        "hello World! myFirstObject, myNestedArray[0][1]"
      ],
      [
        "hello World! myFirstObject, myNestedArray[1][0]"
      ]
    ],
    "myNestedDictionary": {
      "1": {
        "1-first": "hello World!  myFirstObject, 1-first",
        "1-second": "hello World!  myFirstObject, 1-second"
      },
      "2": {
        "2-first": "hello World!  myFirstObject, 2-first"
      }
    }
  },
  "mySecondObject": {
    "mySecondNumber": 2,
    "mySecondString": "...and hi everybody!",
    "mySecondArray": [
      "anotherString1",
      "anotherString2"
    ]
  },
  "myThirdObject": {
    "myThirdNumber": 3,
    "myThirdString": "...and good morning!",
    "myThirdArray": [
      "Hello World! myThirdObject, myThirdArray[0]",
      "Hello World! myThirdObject, myThirdArray[1]",
      "Hello World! myThirdObject, myThirdArray[2]",
      "Hello World! myThirdObject, myThirdArray[3]"
    ],
    "myCopyOfFirstArray": [
      "Hello World!, myThirdObject, myCopyOfFirstArray[0]",
      "Hello World!, myThirdObject, myCopyOfFirstArray[1]",
      "Hello World!, myThirdObject, myCopyOfFirstArray[2]"
    ]
  },
  "myFourthObject": {
    "myFourthArray": [
      "Hello World! inside myFourthObject, inside myFourthArray[0]",
      "Hello World! inside myFourthObject, inside myFourthArray[1]",
      "Will this string be found inside an array?",
      "Hello World! inside myFourthObject, inside myFourthArray[2]",
      "Hello World! inside myFourthObject, inside myFourthArray[3]",
      "Will this string be found inside an array at least 3 times?",
      "Will this string be found inside an array at least 3 times?",
      "Will this string be found inside an array at least 3 times?"
    ],
    "myFourthString": "...and good evening!",
    "myFifthString": "We have run out of greetings.",
    "mySixthString": "So instead we'll tell the days of the week...",
    "mySeventhString": "...Monday,",
    "myEightEqualString": "These string is equal to another one.",
    "myNinthEqualString": "These string is equal to another one.",
    "myFourthNumber": 3,
    "myTenthString": "Will this string be found inside an array?",
    "myEleventhStringToBeHashed": "hash me to kdf",
    "myTwelfthStringToBeHashedUsingPBKDF2": "hash me to pbkdf2",
    "myThirteenStringPassword": "my funky password",
    "myFourteenthStringToBeHashedUsingHMAC": "hash me to HMAC",
    "myFifteenthString": "Hello World again!",
    "mySixteenthString": "Hello World! myThirdObject, myThirdArray[2]",
    "mySeventeenthString":"Will this string be found inside an array at least 3 times?",
    "myOnlyBIGArray": [
      "7dcd7392a9dea33b145a03279af78b1adf1c0549f5121ec28dd3dc136c0ca693",
      "8bd877e84538380c455448239f04d817e9657ecf2786442f11c98248ca8178a2",
      "d2cfc1b31b087d0d7137e3f5d45fc6a9cf33025fdba6f9cad40a04e36b420763",
      "554e2fcf3a4a1d872446febb81a91d910e772a4cf4c5e36a3569b159cb5ff439"
    ]
  },
  "myUserName": "User1234",
  "User1234": {
    "keyring": {
      "ecdh": "AxLMXkey00i2BD675vpMQ8WhP/CwEfmdRr+BtpuJ2rM="
    }
  },
  "ABC-Transactions1Data": {
    "timestamp": 1597573139,
    "TransactionValue": 1000,
    "PricePerKG": 2,
    "TransferredProductAmount": 500,
    "UndeliveredProductAmount": 100,
    "ProductPurchasePrice": 1
  },
  "mySecondNumberArray": [
    567,
    748,
    907,
    876,
    34,
    760,
    935
  ]
}
EOF
    cat <<EOF  | save_asset whenCompleteScriptGiven.zen
# We're using scenario 'ecdh' cause we are loading a keypair
Scenario 'ecdh': using keypair and signing
Given my name is in a 'string' named 'myUserName'
Given that I have my 'keyring'
# Load Arrays
Given I have a 'string array' named 'myFirstArray'  inside 'myFirstObject'
Given I have a 'string array' named 'myNestedArray' inside 'myFirstObject'
Given I have a 'string array' named 'mySecondArray' inside 'mySecondObject'
Given I have a 'string array' named 'myThirdArray' inside 'myThirdObject' 
Given I have a 'string array' named 'myFourthArray' inside 'myFourthObject'
Given I have a 'number array' named 'myFirstNumberArray' inside 'myFirstObject'
Given I have a 'string array' named 'myCopyOfFirstArray' inside 'myThirdObject'
Given I have a 'base64 array' named 'myOnlyEcpArray' inside 'myFirstObject'
Given I have a 'base64 array' named 'myOnlyEcp2Array' inside 'myFirstObject'
Given I have a 'number array' named 'mySecondNumberArray'

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
Given I have a 'string' named 'myNinthEqualString' inside 'myFourthObject'
Given I have a 'string' named 'myEightEqualString' inside 'myFourthObject'
Given I have a 'string' named 'myTenthString' inside 'myFourthObject'
Given I have a 'string' named 'myEleventhStringToBeHashed' inside 'myFourthObject'
Given I have a 'string' named 'myTwelfthStringToBeHashedUsingPBKDF2' inside 'myFourthObject' 
Given I have a 'string' named 'myThirteenStringPassword' inside 'myFourthObject'
Given I have a 'string' named 'myFourteenthStringToBeHashedUsingHMAC' inside 'myFourthObject'
Given I have a 'string' named 'myFifteenthString' inside 'myFourthObject'
Given I have a 'string' named 'mySixteenthString' inside 'myFourthObject'
Given I have a 'string' named 'mySeventeenthString' inside 'myFourthObject'
# Load dictionaries
Given I have a 'string dictionary' named 'myNestedDictionary' inside 'myFirstObject'
Given I have a 'string dictionary' named 'ABC-Transactions1Data'
# Different data types
Given I have an 'hex' named 'myFirstHex' inside 'myFirstObject' 
Given I have a  'base64' named 'myFirstBase64' in 'myFirstObject'
Given I have a  'binary' named 'myFirstBinary' in 'myFirstObject'
Given I have an 'url64' named 'myFirstUrl64' in 'myFirstObject'
# Here we're done loading stuff 
EOF
    cat <<EOF  | save_asset whenCompleteScriptPart1.zen
# WRITE IN (create string or number)
# the "write in" statement create a new object, assigns it an encoding but 
# only "number" or "string" (if you need any other encoding, 
# use the "set as" statement) and assigns it the value you define.
When I write number '10' in 'nameOfFirstNewVariable'
When I write string 'This is my lovely new string!' in 'nameOfSecondNewVariable'


# SUM, SUBTRACTION
# You can use the statement 'When I create the result of ... " to 
# sum, subtract, multiply, divide, modulo with values, see the examples below. The output of the 
# statement will be an object named "result" that we immediately rename.
# The operators allowed are: +, -, *, /, %.
When I create the result of 'mySecondNumber' + 'myThirdNumber'
and I rename the 'result' to 'resultOfmyFirstSum'
When I create the result of 'mySecondNumber' - 'myThirdNumber'
and I rename the 'result' to 'resultOfmyFirstSubtraction'
When I create the result of 'mySecondNumber' * 'myThirdNumber'
and I rename the 'result' to 'resultOfmyFirstMultiplication'
When I create the result of 'mySecondNumber' / 'myThirdNumber'
and I rename the 'result' to 'resultOfmyFirstDivision'
When I create the result of 'mySecondNumber' % 'myThirdNumber'
and I rename the 'result' to 'resultOfmyFirstModulo'

# Now let's do some math with the number that we just created: 

When I create the result of 'mySecondNumber' + 'nameOfFirstNewVariable'
and I rename the 'result' to 'resultOfmySecondSum'
When I create the result of 'mySecondNumber' * 'nameOfFirstNewVariable'
and I rename the 'result' to 'resultOfmySecondMultiplication'

# INVERT SIGN
# you can invert the sign of a number using this statement
# in this example, we create an inverted version of 'myFirstNumber' 
# that goes from '1.2345' to '-1.2345'
When I create the result of 'myFirstNumber' inverted sign
and I rename the 'result' to 'myFirstNumberInvertedSign'


# APPEND
# The "append" statement are pretty self-explaining: 
# append a simple object of any encoding to another one
When I append 'mySecondString' to 'myFifteenthString' 
When I append 'mySecondNumber' to 'myThirdNumber' 

# RENAME
# The "rename" statement: we've been hinting at this for a while now,
# pretty self-explaining, it works with any object type or schema.
When I rename the 'myThirdArray' to 'myJustRenamedArray'

# DELETE
# You can delete an object from the memory stack at runtime
# this is useful if, for example, you have copied an object to perform an operation
# and you don't need the copy anymore
When I delete 'myFourthNumber'

# COPY
# You can copy a an object into a new one
# it works for simple objects (number, string, etc) or complex
# ones (arrays, dictionaries, schemes)
When I copy 'mySixteenthString' to 'copyOfMySixteenthString'
When I copy 'myFirstArray' to 'copyOfMyFirstArray'

# You can copy a certain element from an array, to a new object named "copy", with the
# same encoding of the array, in the root level of the data. 
# We are immeediately renaming the outout for your convenience.
When I create the copy of element '3' in array 'myFourthArray'
and I rename the 'copy' to 'copyOfElement3OfmyFourthArray'

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


# PICK RANDOM
# The "pick a random object in" picks randomly an object from the target array
# and puts into a newly created object named "random_object".
# The name is hardcoded, the object can be renamed.
When I pick the random object in 'myFirstArray'
and I rename the 'random_object' to 'myRandomlyPickedObject'

# CREATE RANDOM DICTIONARY 
# If you need several objects from a dictionary, you can use this statement
# it will create a new dictionary with the defined amount of objects,
# picked from the original dictionary 
When I create the random dictionary with 'mySecondNumber' random objects from 'myOnlyEcpArray'
and I rename the 'random_dictionary' to 'myNewlyCreatedRandomDictionary'

# CREATE FLAT ARRAY
# The "flat array" statement, take as input the name of an array or a dictionary,
# the statement flat the input contents or the input keys
# and places the result in a newly created array called "flat array"
When I create the flat array of contents in 'myNestedArray'
and I rename the 'flat array' to 'myFlatArray'
When I create the flat array of contents in 'myNestedDictionary'
and I rename the 'flat array' to 'myFlatDictionaryContents'
When I create the flat array of keys in 'myNestedDictionary'
and I rename the 'flat array' to 'myFlatDictionaryKeys'

Then print all data
EOF
    cat $R/docs/examples/zencode_cookbook/$SUBDOC/whenCompleteScriptGiven.zen \
	$R/docs/examples/zencode_cookbook/$SUBDOC/whenCompleteScriptPart1.zen \
	| zexe when1.zen myLargeNestedObjectWhen.json
    save_output whenCompleteOutputPart1.json
}

@test "The 'create' and 'set' statements" {
    cat <<EOF  | save_asset whenCompleteScriptPart2.zen
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
When I create the random object of '16' bytes
and I rename the 'random_object' to 'my16BytesRandom'

# The "create array of random" statement, lets you create an array of random objects, 
# and you can select the length in bits. The first statement uses the default lenght of 512 bits.
# Like the previous one, this statement outputs an object whose name is hardcoded into "array".
# Since we're creating three arrays called "array" below, Zenroom would simply overwrite 
# the first two, so we are renaming the output immediately. 
When I create the array of '4' random objects
and I rename the 'array' to 'my4RandomObjectsArray'
When I create the array of '5' random objects of '256' bits
and I rename the 'array' to 'my256BitsRandomObjectsArray'
When I create the array of '6' random objects of '16' bytes
and I rename the 'array' to 'my16BytesRandomObjectsArray'

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

# CREATE KEYRING
# Keys inside keyrings can be created from a random seed or from a known seed

# Below is the standard keyring generation statement, which uses a random seed
# The random seed can in fact be passed to Zenroom and last for the whole 
# smart contract execution session, via the "config" parameter. 
# Note that, in order to create a keyring, you'll need to declare the identity of the script
# executor, which is done in the Given phase

# Note: we're renaming the created keyrings exclusively cause we're generating 2 keyringss 
# in the same script, so the second would overwrite the first. In reality you never want to 
# rename a keyring, as its schema is hardcoded in Zenroom and cryptographically it doesn't make sense
# to use more than one keyring in the same script.
When I rename the 'keyring' to 'GivenKeyring'
When I create the ecdh key
and I rename the 'keyring' to 'keyringFromRandom'

# Below is a statement to create a keyring from a known seed.
# The seed has to be passed to Zenroom via a string, that can have an arbitrary size
When I create the ecdh key with secret 'myThirteenStringPassword'
and I rename the 'keyring' to 'keyringFromSeed'

Then print all data
EOF
    cat $R/docs/examples/zencode_cookbook/$SUBDOC/whenCompleteScriptGiven.zen \
	$R/docs/examples/zencode_cookbook/$SUBDOC/whenCompleteScriptPart2.zen \
	| zexe when2.zen myLargeNestedObjectWhen.json
    save_output whenCompleteOutputPart2.json
}

@test "The cryptography statements: hashes, kdf, pbkdf, hmac" {
    cat <<EOF  | save_asset whenCompleteScriptPart3.zen
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

# In the same fashion, we can hash arrays 
When I create the hash of 'myFirstArray'
And I rename the 'hash' to 'hashOf:MyFirstArray'

# or we can hash every element in the array
When I create the hashes of each object in 'myFirstArray'
And I rename the 'hashes' to 'hashOf:ObjectsInMyFirstArray'

# and we can as well hash dictionaries
When I create the hash of 'ABC-Transactions1Data'
And I rename the 'hash' to 'hashOfDictionary:ABC-Transactions1Data'

# Following is a version of the statement above that takes the hashing algorythm as parameter, 
# it accepts sha256 or sha512 as hash types
When I create the hash of 'mySixthString' using 'sha256'
And I rename the 'hash' to 'hashOfMySixthString'
When I create the hash of 'mySeventhString' using 'sha512'
And I rename the 'hash' to 'hashOfMySeventhString'

# Again, you can hash with sha256 or sha512 also arrays and dictionaries
When I create the hash of 'myFirstArray' using 'sha512'
And I rename the 'hash' to 'sha512HashOf:MyFirstArray'

When I create the hash of 'ABC-Transactions1Data' using 'sha512'
And I rename the 'hash' to 'sha512HashOfDictionary:ABC-Transactions1Data'



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
    cat $R/docs/examples/zencode_cookbook/$SUBDOC/whenCompleteScriptGiven.zen \
	$R/docs/examples/zencode_cookbook/$SUBDOC/whenCompleteScriptPart3.zen \
	| zexe when3.zen myLargeNestedObjectWhen.json
    save_output whenCompleteOutputPart3.json
}


@test "The Comparisons statements: more, less or equal, find elements in objects..." {
    cat <<EOF  | save_asset whenCompleteScriptPart4.zen
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

# FOUND, NOT FOUND, FOUND AT LEAST n TIMES
# The "is found" statement, takes two objects as input: 
# the name of a variable and the name of an array. It reads its content of the variable 
# and matches it against each element of the array.
# It works with any kind of array, as long as the element of the array are of the same schema
# as the variable.
When the 'myTenthString' is found in 'myFourthArray'
When the 'myFirstString' is not found in 'myFourthArray'
When the 'mySeventeenthString' is found in 'myFourthArray' at least 'myFourthNumber' times
Then print all data
EOF
    cat $R/docs/examples/zencode_cookbook/$SUBDOC/whenCompleteScriptGiven.zen \
	$R/docs/examples/zencode_cookbook/$SUBDOC/whenCompleteScriptPart4.zen \
	| zexe when4.zen myLargeNestedObjectWhen.json
    save_output whenCompleteOutputPart4.json
}

@test "The array statements: insert, remove, length, sum, copy element" {
    cat <<EOF  | save_asset whenCompleteScriptPart5.zen
# CREATE
# These creates a new empty array named 'array'
When I create the new array

# INSERT
# The "insert" statement is used to append a simple object to an array.
# It's pretty self-explaining. 
When I insert 'myFirstString' in 'myFirstArray'

# LENTGH
# These two statements create objects, named "size" and "length" 
# containing the length of the array
When I create the length of 'mySecondNumberArray'
When I create the size of 'mySecondNumberArray'

# SUM 
# These two statements create objects, named "aggregation" and "sum value" containing the 
# arithmetic sum of the array, they work only with "number array"
When I create the aggregation of array 'mySecondNumberArray'
When I create the sum value of elements in array 'mySecondNumberArray'

# STATISTICAL INFORMATIONS
# These statements perform some statistical operations on the arrays
# These statements compute the average, the standard deviation and the
# variance of the elements of the array, saving them in three object named
# respectively "average", "standard deviation" and "variance", and
# they work only with "number array"
When I create the average of elements in array 'mySecondNumberArray'
When I create the standard deviation of elements in array 'mySecondNumberArray'
When I create the variance of elements in array 'mySecondNumberArray'

# COPY ELEMENT
# This statement creates a an object named "copy" containing
# the given element of the array
When I create the copy of element '2' in array 'mySecondNumberArray'

# REMOVE
# The "remove" statement does the opposite of the one above:
# Use it remove an element from an array, it takes as input the name of a string, 
# and the name of an array - we don't mix code and data! 
When I rename the 'myThirdArray' to 'myJustRenamedArray'
When I remove the 'mySixteenthString' from 'myJustRenamedArray'

Then print the 'mySecondNumberArray'
Then print the 'myFirstArray'
Then print the 'myJustRenamedArray'

Then print the 'length'
Then print the 'size'

Then print the 'aggregation'
Then print the 'sum value'

Then print the 'average'
Then print the 'standard deviation'
Then print the 'variance'

Then print the 'copy'

EOF
    cat $R/docs/examples/zencode_cookbook/$SUBDOC/whenCompleteScriptGiven.zen \
	$R/docs/examples/zencode_cookbook/$SUBDOC/whenCompleteScriptPart5.zen \
	| zexe when5.zen myLargeNestedObjectWhen.json
    save_output whenCompleteOutputPart5.json
}
