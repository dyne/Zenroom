load ../bats_setup
load ../bats_zencode
SUBDOC=cookbook_when

@test "Manipulation statements: append, rename, insert, remove..." {
    cat <<EOF | save_asset myLargeNestedObjectWhen.json
{
  "myFirstObject": {
    "a": 1.2345,
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
    "aArray": [
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
    "b": 2,
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
  "bArray": [
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
Given I have a 'number array' named 'aArray' inside 'myFirstObject'
Given I have a 'string array' named 'myCopyOfFirstArray' inside 'myThirdObject'
Given I have a 'base64 array' named 'myOnlyEcpArray' inside 'myFirstObject'
Given I have a 'base64 array' named 'myOnlyEcp2Array' inside 'myFirstObject'
Given I have a 'number array' named 'bArray'

# Load Numbers
Given I have a 'number' named 'a' in 'myFirstObject'
Given I have a 'number' named 'b' in 'mySecondObject'
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
When I create the result of 'b' + 'myThirdNumber'
and I rename the 'result' to 'resultOfmyFirstSum'
When I create the result of 'b' - 'myThirdNumber'
and I rename the 'result' to 'resultOfmyFirstSubtraction'
When I create the result of 'b' * 'myThirdNumber'
and I rename the 'result' to 'resultOfmyFirstMultiplication'
When I create the result of 'b' / 'myThirdNumber'
and I rename the 'result' to 'resultOfmyFirstDivision'
When I create the result of 'b' % 'myThirdNumber'
and I rename the 'result' to 'resultOfmyFirstModulo'

# Now let's do some math with the number that we just created: 

When I create the result of 'b' + 'nameOfFirstNewVariable'
and I rename the 'result' to 'resultOfmySecondSum'
When I create the result of 'b' * 'nameOfFirstNewVariable'
and I rename the 'result' to 'resultOfmySecondMultiplication'

# INVERT SIGN
# you can invert the sign of a number using this statement
# in this example, we create an inverted version of 'a' 
# that goes from '1.2345' to '-1.2345'
When I create the result of 'a' inverted sign
and I rename the 'result' to 'aInvertedSign'


# APPEND
# The "append" statement are pretty self-explaining: 
# append a simple object of any encoding to another one
When I append 'mySecondString' to 'myFifteenthString' 
When I append 'b' to 'myThirdNumber' 

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
When I copy '3' from 'myFourthArray' to 'copyOfElement3OfmyFourthArray'

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
# The "create a random pick from" picks randomly an element from the target array
# and puts into a newly created variable named "random_pick".
# The name is hardcoded, the object can be renamed.
When I create random pick from 'myFirstArray'
and I rename the 'random_pick' to 'myRandomlyPickedObject'

# PICK MULTIPLE RANDOM ELEMENTS
# If you need several objects from a table, you can use this statement
# it will create a new table (array if source was an array, or dictionary otherwise)
# with the defined amount of objects picked from the original table
When I create random array with 'b' elements from 'myOnlyEcpArray'
and I rename the 'random_array' to 'myNewlyCreatedRandomArray'

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

# Below is a variation that lets you create a random elements of configurable length.
# This statement doesn't let you choose the name of the name of the newly created element,
# which is hardcoded to "random". We are immediately renaming it.
When I create the random of '128' bits
and I rename the 'random' to 'my128BitsRandom'
When I create the random of '16' bytes
and I rename the 'random' to 'my16BytesRandom'

# The "create random array with" statement, lets you create an array of random elements, 
# and you can select the length in bits or bytes. The first statement uses the default lenght of 512 bits.
# Like the previous one, this statement outputs an object whose name is hardcoded into "array".
# Since we're creating three arrays called "array" below, Zenroom would throw an error because by
# design Zenroom does not allow you to implicity overwrite, so we are renaming the output immediately. 
When I create the random array with '4' elements
and I rename the 'random array' to 'my4RandomArray'
When I create the random array with '5' elements each of '256' bits
and I rename the 'random array' to 'my256BitsRandomArray'
When I create the random array with '6' elements each of '16' bytes
and I rename the 'random array' to 'my16BytesRandomArray'

# You can generate an array of random numbers, from 0 o 65355, with this statement.
When I create the random array with '10' numbers 
and I rename the 'random array' to 'my10RandomNumbersArray'
# A variation of the statement above, allows you to use the "modulo" function to cap the max value
# of the random numbers. In the example below, the max value will be "999".
When I create the random array with '16' numbers modulo '1000'
and I rename the 'random array' to 'my16RandomNumbersModulo1000Array'

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
When I create the aggregation of array 'aArray'
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
When I verify number 'myFourthNumber' is less or equal than 'myThirdNumber'
When I verify number 'a' is less than  'myThirdNumber'
When I verify number 'myThirdNumber' is more or equal than 'b'
When I verify number 'myThirdNumber' is more than 'b'

# FOUND, NOT FOUND, FOUND AT LEAST n TIMES
# The "is found" statement, takes two objects as input: 
# the name of a variable and the name of an array. It reads its content of the variable 
# and matches it against each element of the array.
# It works with any kind of array, as long as the element of the array are of the same schema
# as the variable.
When I verify the 'myTenthString' is found in 'myFourthArray'
When I verify the 'myFirstString' is not found in 'myFourthArray'
When I verify the 'mySeventeenthString' is found in 'myFourthArray' at least 'myFourthNumber' times
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

# MOVE
# The "move" statement is used to append a simple object to an array.
# It's pretty self-explaining. 
When I move 'myFirstString' in 'myFirstArray'

# SIZE
# These two statements create objects, named "size"
# containing the size of the array
When I create the size of 'bArray'

# SUM 
# These two statements create objects, named "aggregation" and "sum value" containing the 
# arithmetic sum of the array, they work only with "number array"
When I create the aggregation of array 'bArray'
When I create the sum value of elements in array 'bArray'

# STATISTICAL INFORMATIONS
# These statements perform some statistical operations on the arrays
# These statements compute the average, the standard deviation and the
# variance of the elements of the array, saving them in three object named
# respectively "average", "standard deviation" and "variance", and
# they work only with "number array"
When I create the average of elements in array 'bArray'
When I create the standard deviation of elements in array 'bArray'
When I create the variance of elements in array 'bArray'

# COPY ELEMENT
# This statement creates a an object named "copy" containing
# the given element of the array
When I copy '2' from 'bArray' to 'copy'

# REMOVE
# The "remove" statement does the opposite of the one above:
# Use it remove an element from an array, it takes as input the name of a string, 
# and the name of an array - we don't mix code and data! 
When I rename the 'myThirdArray' to 'myJustRenamedArray'
When I remove the 'mySixteenthString' from 'myJustRenamedArray'

Then print the 'bArray'
Then print the 'myFirstArray'
Then print the 'myJustRenamedArray'

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

@test "create: new array" {
    cat <<EOF | zexe when_create_new_array.zen
Given nothing

When I create the 'string array'

Then print the 'string array'
EOF
    save_output when_create_new_array.out.json
    assert_output '{"string_array":[]}'
}

@test "create: new array with a name" {
    cat <<EOF | zexe when_create_new_array_with_name.zen
Given nothing

When I create the 'string array' named 'array 1'
When I create the 'string array' named 'array 2'

Then print the 'array 1'
Then print the 'array 2'
EOF
    save_output when_create_new_array_with_name.out.json
    assert_output '{"array_1":[],"array_2":[]}'
}

@test "create: new key" {
    cat <<EOF | zexe when_create_new_key.zen
Scenario 'ecdh': create an ecdh key

Given nothing

When I create the ecdh key

Then print the 'keyring'
EOF
    save_output when_create_new_key.out.json
    assert_output '{"keyring":{"ecdh":"B4rYTWx6UMbc2YPWRNpl4w2M6gY9jqSa637n8Kr2pPc="}}'
}

@test "rename: all statements" {
    cat <<EOF | save_asset when_rename_examples.data.json
{
    "to_be_renamed_1": "rename to first",
    "to_be_renamed_2": "rename to named by new_name_1",
    "to_be_renamed_3": "rename named by old_name to third",
    "to_be_renamed_4": "rename named by old_name to named by new_name_2",
    "new_name_1": "second",
    "old_name_1": "to_be_renamed_3",
    "new_name_2": "fourth",
    "old_name_2": "to_be_renamed_4"
}
EOF
    cat <<EOF | zexe when_rename_examples.zen when_rename_examples.data.json
Given I have a 'string' named 'to_be_renamed_1'
Given I have a 'string' named 'to_be_renamed_2'
Given I have a 'string' named 'to_be_renamed_3'
Given I have a 'string' named 'to_be_renamed_4'
Given I have a 'string' named 'new_name_1'
Given I have a 'string' named 'old_name_1'
Given I have a 'string' named 'new_name_2'
Given I have a 'string' named 'old_name_2'

# the new name can be passed directly with
When I rename 'to_be_renamed_1' to 'first'

# or indirectly by using the 'named by' followed
# by the name of the variable that contains the new name
When I rename 'to_be_renamed_2' to named by 'new_name_1'

# you can also indicates the variable to be renamed using
# another variable with
When I rename object named by 'old_name_1' to 'third'

# even further, you can use the 'named by' keyword on both fields
When I rename object named by 'old_name_2' to named by 'new_name_2' 

Then print the data
EOF
    save_output when_rename_examples.out.json
    assert_output '{"first":"rename to first","fourth":"rename named by old_name to named by new_name_2","new_name_1":"second","new_name_2":"fourth","old_name_1":"to_be_renamed_3","old_name_2":"to_be_renamed_4","second":"rename to named by new_name_1","third":"rename named by old_name to third"}'
}

@test "remove or delete: simply remove" {
    cat <<EOF | zexe when_remove_examples.zen
Given nothing

# create a new array to be removed
When I create the new array

# remove the new array
When I remove the 'new array'

# equivalenty with the delete
When I create the new array
When I delete the 'new array'

Then print the data
EOF
    save_output when_remove_examples.out.json
    assert_output '[]'
}

@test "remove: element from an object" {
    cat <<EOF | save_asset when_remove_from_examples.data.json
{
    "dictionary": {
        "key 1": "value 1",
        "key 2": "value 2"
    },
    "array": ["value 3", "value 4"],
    "value to be removed from array": "value 3"
}
EOF
    cat <<EOF | zexe when_remove_from_examples.zen when_remove_from_examples.data.json
Given I have a 'string dictionary' named 'dictionary'
Given I have a 'string array' named 'array'

Given I have a 'string' named 'value to be removed from array'

# to remove an element from a dictionary specify the key you want to remove
When I remove the 'key 1' from 'dictionary'

# to remove an element from an array specify the value you want to remove
When I remove the 'value to be removed from array' from 'array'

Then print 'dictionary'
Then print 'array'
EOF
    save_output when_remove_from_examples.out.json
    assert_output '{"array":["value 4"],"dictionary":{"key_2":"value 2"}}'
}

@test "found: element in memory" {
    cat <<EOF | zexe when_found_examples.zen
Given nothing

When I create the 'string dictionary' named 'dictionary'

# check for the existance
When I verify the 'dictionary' is found

# check for the not existance
When I verify the 'clearly not existing dictionary' is not found

Then print the string 'success'
EOF
    save_output when_found_examples.out.json
    assert_output '{"output":["success"]}'
}

@test "found: element in another object" {
    cat <<EOF | save_asset when_found_in_examples.data.json
{
    "dictionary": {
        "key 1": "value_1",
        "key 2": "value_2"
    },
    "array": [
        "value_3",
        "value_4",
        "value_4"
    ],
    "key": "key_1",
    "value": "value_4",
    "N": "2"
}
EOF
    cat <<EOF | zexe when_found_in_examples.zen when_found_in_examples.data.json
Given I have a 'string dictionary' named 'dictionary'
Given I have a 'string array' named 'array'

Given I have a 'string' named 'key'
Given I have a 'string' named 'value'
Given I have a 'integer' named 'N'

# check by key in a dictionary
When I verify the 'key 1' is found in 'dictionary'
When I verify the 'key' is found in 'dictionary'
# value_1 is a value in dictionary, not a key, thus it is not found
When I verify the 'value 1' is not found in 'dictionary'

# check by value in an array
When I verify the 'value 4' is found in 'array'
When I verify the 'value' is found in 'array'
# 1 is a key in array, not a value, thus it is not found
When I verify the '1' is not found in 'array'

# check if found in an array at least N times
When I verify the 'value' is found in 'array' at least 'N' times

Then print the string 'success'
EOF
    save_output when_found_in_examples.out.json
    assert_output '{"output":["success"]}'
}

@test "copy: element in another object" {
    cat <<EOF | save_asset when_copy_to_object.data.json
{
	"string_1": "string_to_copy",
	"dictionary_1": {
		"string_2": "string_in_ob_1",
		"string_3": "string_in_ob_2"
	},
	"string_4": "string_1",
	"dictionary_2": {}
}
EOF
    cat <<EOF | zexe when_copy_to_object.zen when_copy_to_object.data.json
Given I have 'string' named 'string_1'
Given I have a 'string dictionary' named 'dictionary_1'
Given I have a 'string dictionary' named 'dictionary_2'
Given I have 'string' named 'string_4'

# simple copy to
When I copy 'string_1' to 'string_1_copied'

# copy in object
When I copy 'string_1' in 'dictionary_1'

When I copy named by 'string_4' in 'dictionary_2'

When I copy 'string_4' to 'string_4_copied' in 'dictionary_2'

Then print all data
EOF
    save_output when_copy_to_object.out.json
    assert_output '{"dictionary_1":{"string_1":"string_to_copy","string_2":"string_in_ob_1","string_3":"string_in_ob_2"},"dictionary_2":{"string_1":"string_to_copy","string_4_copied":"string_1"},"string_1":"string_to_copy","string_1_copied":"string_to_copy","string_4":"string_1"}'
}

@test "copy: element from object" {
    cat <<EOF | save_asset when_copy_from_object.data.json
{
	"dictionary_1": {
		"string_1": "string_in_ob_1"
	},
	"dictionary_2": {
		"string_2": "string_in_ob_2"
	}
}
EOF
    cat <<EOF | zexe when_copy_from_object.zen when_copy_from_object.data.json
Given I have a 'string dictionary' named 'dictionary_1'
Given I have a 'string dictionary' named 'dictionary_2'

# copy from object
When I copy 'string_1' from 'dictionary_1' to 'string_copied'

# copy from object into another object
When I copy 'string_2' from 'dictionary_2' in 'dictionary_1'

Then print all data
EOF
    save_output when_copy_from_object.out.json
    assert_output '{"dictionary_1":{"string_1":"string_in_ob_1","string_2":"string_in_ob_2"},"dictionary_2":{"string_2":"string_in_ob_2"},"string_copied":"string_in_ob_1"}'
}

@test "copy: encoding elements" {
    cat <<EOF | save_asset when_copy_enc.data.json
{
	"string_1": "string_to_copy",
	"dictionary_1": {}
}
EOF
    cat <<EOF | zexe when_copy_enc.zen when_copy_enc.data.json
Given I have a 'string dictionary' named 'dictionary_1'
Given I have a 'string' named 'string_1'

# copy changing encoding
When I copy 'string_1' as 'hex' in 'dictionary_1'
When I copy 'string_1' as 'bin' to 'string_copied'

Then print all data
EOF
    save_output when_copy_enc.out.json
    assert_output '{"dictionary_1":{"string_1":"737472696e675f746f5f636f7079"},"string_1":"string_to_copy","string_copied":"0111001101110100011100100110100101101110011001110101111101110100011011110101111101100011011011110111000001111001"}'
}

@test "copy: object" {
    cat <<EOF | save_asset when_copy_object.data.json
{
	"dictionary_1": {
		"string_1": "string_in_ob_1",
        "string_2": "string_in_ob_2"
	},
	"dictionary_2": {
		"string_3": "string_in_ob_3"
	}
}
EOF
    cat <<EOF | zexe when_copy_object.zen when_copy_object.data.json
Given I have a 'string dictionary' named 'dictionary_1'
Given I have a 'string dictionary' named 'dictionary_2'

#copy of entire object
When I copy contents of 'dictionary_1' in 'dictionary_2'
#copy element of an object
When I copy contents of 'dictionary_2' named 'string_3' in 'dictionary_1'
When I create copy of last element from 'dictionary_1'

Then print all data
EOF
    save_output when_copy_object.out.json
    assert_output '{"copy_of_last_element":"string_in_ob_3","dictionary_1":{"string_1":"string_in_ob_1","string_2":"string_in_ob_2","string_3":"string_in_ob_3"},"dictionary_2":{"string_1":"string_in_ob_1","string_2":"string_in_ob_2","string_3":"string_in_ob_3"}}'
}

@test "move an element/object in another object" {
    cat <<EOF | save_asset When_move_in_object.data.json
{
	"dictionary1": {
		"key 1": "value 1",
		"key 2": "value 2"
	},
	"dictionary2": {
		"key 3": "value 3"
	},
	"array1": [
		"str1",
		"str2"
	],
    "array2": [
		"str3"
	],
    "string": "a_string"
}
EOF
    cat <<EOF | zexe When_move_in_object.zen When_move_in_object.data.json
Given I have a 'string dictionary' named 'dictionary1'
Given I have a 'string dictionary' named 'dictionary2'
Given I have a 'string array' named 'array1'
Given I have a 'string array' named 'array2'
Given I have a 'string' named 'string'


When I move 'array1' in 'dictionary2'

When I move 'key 3' from 'dictionary2' in 'dictionary1'

When I move 'string' to 'array2' in 'array2'


Then print 'dictionary2'
Then print 'dictionary1'
Then print 'array2'
EOF
    save_output When_move_in_object.out.json
    assert_output '{"array2":["str3","a_string"],"dictionary1":{"key_1":"value 1","key_2":"value 2","key_3":"value 3"},"dictionary2":{"array1":["str1","str2"]}}'
} 

@test "move an element from an object" {
    cat <<EOF | save_asset when_move_from.data.json
{
	"dictionary1": {
		"key 1": "value 1",
		"key 2": "value 2"
	},
	"dictionary2": {
		"key 3": "value 3"
	}
	
}
EOF
    cat <<EOF | zexe when_move_from.zen when_move_from.data.json
Given I have a 'string dictionary' named 'dictionary1'
Given I have a 'string dictionary' named 'dictionary2'

#move key 3 from dictionary2 and add it in dictionary1
When I move 'key 3' from 'dictionary2' in 'dictionary1'

#take key 1 from dictionary1 and add a string named 'from key 1' in data.
When I move 'key 1' from 'dictionary1' to 'from key 1'

Then print the data
EOF
    save_output When_move_in_object.out.json
    assert_output '{"dictionary1":{"key_2":"value 2","key_3":"value 3"},"dictionary2":[],"from_key_1":"value 1"}'
} 

@test "move an element as chosen basis" {
    cat <<EOF | save_asset when_move_as.data.json
{
	"dictionary1": {
		"key 1": "value 1",
		"key 2": "value 2"
	},
	"dictionary2": {
		"key 3": "value 3"
	},
    "array": [
        "str1",
        "str2"
    ],
    "string to convert": "string"
}
EOF
    cat <<EOF | zexe when_move_as.zen when_move_as.data.json
Given I have a 'string dictionary' named 'dictionary1'
Given I have a 'string dictionary' named 'dictionary2'
Given I have a 'string array' named 'array'
Given I have a 'string' named 'string to convert'

#takes an element (outside of a Complex Object) and moves it into a Complex Object
When I move 'string to convert' as 'hex' in 'dictionary1'

#take elements from array and create a new array with converted elements in the chosen basis.
When I move 'array' as 'base64' to 'converted array'

Then print the data
EOF
    save_output When_move_as.out.json
    assert_output '{"converted_array":["c3RyMQ==","c3RyMg=="],"dictionary1":{"key_1":"value 1","key_2":"value 2","string_to_convert":"737472696e67"},"dictionary2":{"key_3":"value 3"}}'
} 

@test "move an element to another" {
    cat <<EOF | save_asset when_move_to.data.json
{
	"dictionary1": {
		"key 1": "value 1",
		"key 2": "value 2"
	},
    "array": [
        "str1",
        "str2"
    ]
}
EOF
    cat <<EOF | zexe when_move_to.zen when_move_to.data.json
Given I have a 'string dictionary' named 'dictionary1'
Given I have a 'string array' named 'array'

#actually it works as a rename
When I move 'array' to 'renamed array'

Then print the data
EOF
    save_output When_move_to.out.json
    assert_output '{"dictionary1":{"key_1":"value 1","key_2":"value 2"},"renamed_array":["str1","str2"]}'
}

@test "numbers: create" {
    cat <<EOF | zexe when_numbers_create.zen 
Given nothing
#save a certain number 
When I write number '12345' in 'nameOfNewNumber'
#save in "number" the value of "nameOfNewNumber" in base64
When I create number from 'nameOfNewNumber'

Then print the data
EOF
    save_output when_numbers_create.out.json
    assert_output '{"nameOfNewNumber":12345,"number":"MDk="}'
}

@test "numbers: casting" {
cat <<EOF | save_asset when_numbers_cast.data.json
{
	"number": 1234
}
EOF
    cat <<EOF | zexe when_numbers_cast.zen when_numbers_cast.data.json
Given I have a 'string' named 'number'

#casting a string into float
When I create 'float' cast of strings in 'number'
#casting a string into integer
When I create 'integer' cast of strings in 'number'
#casting an integer into a float
When I create float 'f' cast of integer in 'integer'

Then print the data
EOF
    save_output when_numbers_cast.out.json
    assert_output '{"f":1234,"float":1234,"integer":"1234","number":1234}'
}

@test "numbers: operations" {
cat <<EOF | save_asset when_numbers_operations.data.json
{
  "a": 373,
  "b": 67
}
EOF
    cat <<EOF | zexe when_numbers_operations.zen when_numbers_operations.data.json
Given I have a 'number' named 'a'
And I have a 'number' named 'b'
#sum
When I create the result of 'a' + 'b'
and I rename the 'result' to 'resultOfMyFirstSum'
#subtraction
When I create the result of 'a' - 'b'
and I rename the 'result' to 'resultOfMyFirstSubtraction'
#multiplication
When I create the result of 'a' * 'b'
and I rename the 'result' to 'resultOfMyFirstMultiplication'
#division
When I create the result of 'a' / 'b'
and I rename the 'result' to 'resultOfMyFirstDivision'
#modulo
When I create the result of 'a' % 'b'
and I rename the 'result' to 'resultOfMyFirstModulo'
#opposite
When I create the result of 'a' inverted sign
and I rename the 'result' to 'aInvertedSign'

Then print the data
EOF
    save_output when_numbers_operations.out.json
    assert_output '{"a":373,"aInvertedSign":-373,"b":67,"resultOfMyFirstDivision":5.567164,"resultOfMyFirstModulo":38,"resultOfMyFirstMultiplication":24991,"resultOfMyFirstSubtraction":306,"resultOfMyFirstSum":440}'
}

@test "numbers: equations" {
cat <<EOF | save_asset when_numbers_operations.data.json
{
  "a": 373,
  "b": 67
}
EOF
    cat <<EOF | zexe when_numbers_equations.zen when_numbers_operations.data.json
Given I have a 'number' named 'a'
Given I have a 'number' named 'b'

When I create the result of '-a * b * ( b - a )'
#save the result in expr
and I rename 'result' to 'expr'

Then print 'expr'
EOF
    save_output when_numbers_equations.out.json
    assert_output '{"expr":7647246.0}'
}

@test "numbers: compare" {
cat <<EOF | save_asset when_numbers_compare.data.json
{
	"a": 373,
	"b": 67,
	"c": 67,
	"dictionary": {
		"d": 373
	}
}
EOF
    cat <<EOF | zexe when_numbers_compare.zen when_numbers_compare.data.json
Given I have a 'number' named 'a'
Given I have a 'number' named 'b'
Given I have a 'number' named 'c'

When I verify number 'b' is less than 'a'
When I verify number 'a' is more than 'b'
When I verify number 'b' is less or equal than 'b'
When I verify number 'a' is more or equal than 'c'

Then print the string 'success'
EOF
    save_output when_numbers_compare.out.json
    assert_output '{"output":["success"]}'
}

@test "numbers: equal or not" {
cat <<EOF | save_asset when_numbers_compare.data.json
{
	"a": 373,
	"b": 67,
	"c": 67,
	"dictionary": {
		"d": 373
	}
}
EOF
    cat <<EOF | zexe when_numbers_equal.zen when_numbers_compare.data.json
Given I have a 'number' named 'a'
Given I have a 'number' named 'b'
Given I have a 'number' named 'c'
Given I have a 'string dictionary' named 'dictionary'

When I verify 'b' is equal to 'b'
When I verify 'a' is not equal to 'b'
When I verify 'a' is equal to 'd' in 'dictionary'
When I verify 'b' is not equal to 'd' in 'dictionary'

Then print the string 'success'
EOF
    save_output when_numbers_equal.out.json
    assert_output '{"output":["success"]}'
}

@test "creation of a string" {
 
    cat <<EOF | zexe when_create_string.zen 
Given nothing

#create a string "is new" and label it as "new string"
When I write string 'is new' in 'new string'

#create a string "is new" and label it as "newer string"
When I set 'newer string' to 'is newer' as 'string'

Then print data

EOF
    save_output when_create_string.out.json
    assert_output '{"new_string":"is_new","newer_string":"is_newer"}'
}


@test "appending string" {
    cat <<EOF | save_asset when_append.data.json
{
	"new string": "str",
    "to append": "ing"
}
EOF
    cat <<EOF | zexe when_append.zen when_append.data.json
Given I have a 'string' named 'new string'
Given I have a 'string' named 'to append'

#append the content of "to append" and the end of the content of "new string"
When I append 'to append' to 'new string'

#append the content among '' to the content of "new string"
When I append string '_complete' to 'new string'

Then print 'new string'
EOF
    save_output when_append.out.json
    assert_output '{"new_string":"string_complete"}'
}



@test "split a string" {
    cat <<EOF | save_asset when_split.data.json
{
	"string": "a_not_too_much_long_string_to_split"
    
}
EOF
    cat <<EOF | zexe when_split.zen when_split.data.json
Given I have a 'string' named 'string'

#split the first 6 characters from the string 
When I split leftmost '6' bytes of 'string'

#split the final 9 characters from the string
When I split rightmost '9' bytes of 'string'

Then print 'string'
EOF
    save_output when_split.out.json
    assert_output '{"string":"too_much_long_string"}'
}


@test "split a string to array" {
    cat <<EOF | save_asset when_split_into_array.data.json
{
	"string": "a_not_too_much_long_string_to_split",
    "character": "_"
}
EOF
    cat <<EOF | zexe when_split_into_array.zen when_split_into_array.data.json
Given I have a 'string' named 'string'
Given I have a 'string' named 'character'

#create an array by dividing a string removing from the string "character" 
When I create array by splitting 'string' at 'character'

Then print 'array'
EOF
    save_output when_split_into_array.out.json
    assert_output '{"array":["a","not","too","much","long","string","to","split"]}'
}

@test "table: size" {
    cat <<EOF | save_asset when_table_size.data.json
{
	"array": [
		"first_element",
		"second_element",
		"third_element"
	]
}
EOF
    cat <<EOF | zexe when_table_size.zen when_table_size.data.json
Given I have a 'string array' named 'array'

When I create the size of 'array'

Then print the 'size'
EOF
    save_output when_table_size.out.json
    assert_output '{"size":3}'
}

@test "table: json" {
    cat <<EOF | save_asset when_table_json.data.json
{
	"dictionary": {
		"string_in_table": "my_json_string"
	}
}
EOF
    cat <<EOF | zexe when_table_json.zen when_table_json.data.json
Given I have a 'string dictionary' named 'dictionary'

#encode a string into a json
When I create json escaped string of 'dictionary'
#check if it is a json
When I verify 'json_escaped_string' is a json
#decode a json into a string
When I create json unescaped object of 'json_escaped_string'

Then print the data 
EOF
    save_output when_table_json.out.json
    assert_output '{"dictionary":{"string_in_table":"my_json_string"},"json_escaped_string":"{\"string_in_table\":\"my_json_string\"}","json_unescaped_object":{"string_in_table":"my_json_string"}}'
}

@test "table: zero" {
    cat <<EOF | save_asset when_table_zero.data.json
{
	"array": [
		4,
		123.45,
		3,
		0
	]
}
EOF
    cat <<EOF | zexe when_table_zero.zen when_table_zero.data.json
Given I have a 'number array' named 'array'

When I remove zero values in 'array'

Then print the data 
EOF
    save_output when_table_zero.out.json
    assert_output '{"array":[4,123.45,3]}'
}

@test "table: pickup" {
    cat <<EOF | save_asset when_table_pickup.data.json
{
	"dictionary": {
		"string_1": "string_dic_1",
    "string_2": "string_dic_2",
    "string_3": "string_dic_3"
	}
}
EOF
    cat <<EOF | zexe when_table_pickup.zen when_table_pickup.data.json
Given I have a 'string dictionary' named 'dictionary'

#pickup an element of a dictionary
When I pickup from path 'dictionary.string_1'
#pickup an element of a dictionary and return in base64
When I pickup a 'string' from path 'dictionary.string_2'
#take an element of a dictionary
When I take 'string_3' from path 'dictionary'

Then print the data 
EOF
    save_output when_table_pickup.out.json
    assert_output '{"dictionary":{"string_1":"string_dic_1","string_2":"string_dic_2","string_3":"string_dic_3"},"string_1":"string_dic_1","string_2":"string_dic_2","string_3":"string_dic_3"}'
}

@test "remove characters" {
    cat <<EOF | save_asset when_remove_char.data.json
{
	"new string 1": "string without spaces",
    "new string 2": "string \nall \nin \na \nline",
    "new string 3": "a character have to be erase",
    "new string 4": "\\\\a \b c d e \f g h i j k l m \n o p q \r s \t u \\\\v w x y z",
    "to remove": "a"
}
EOF
    cat <<EOF | zexe when_remove_char.zen when_remove_char.data.json
Given I have a 'string' named 'new string 1'
Given I have a 'string' named 'new string 2'
Given I have a 'string' named 'new string 3'
Given I have a 'string' named 'new string 4'
Given I have a 'string' named 'to remove'

#removes all spaces in a string
When I remove spaces in 'new string 1'

#removes all newlines from a string
When I remove newlines in 'new string 2'

#remove all the occurence of character "a" in the string "new string 3"
When I remove all occurrences of character 'to remove' in 'new string 3'

#remove spaces ad letters a, b, f, n, r, t, v 
When I compact ascii strings in 'new string 4'

Then print data

EOF
    save_output when_remove_char.out.json
    assert_output '{"new_string_1":"stringwithoutspaces","new_string_2":"string all in a line","new_string_3":" chrcter hve to be erse","new_string_4":"cdeghijklmopqsuwxyz","to_remove":"a"}'
}   

@test "array: creation" {
    cat <<EOF | zexe when_array_create.zen 
Given nothing
#create a new empty array called "new_array"
When I create the new array

Then print the data
EOF
    save_output when_array_create.out.json
    assert_output '{"new_array":[]}'
}

@test "array: insert" {
    cat <<EOF | save_asset when_array_insert.data.json
{
	"new_array": []
}
EOF
    cat <<EOF | zexe when_array_insert.zen when_array_insert.data.json
Given I have a 'string array' named 'new_array'
#insert a string into an array
When I insert string 'string_in_array' in 'new_array'
#insert 'true' into an array
When I insert true in 'new_array'
#insert 'false' into an array
When I insert false in 'new_array'

Then print the data
EOF
    save_output when_array_insert.out.json
    assert_output '{"new_array":["string_in_array",true,false]}'
}

@test "array: math ops" {
    cat <<EOF | save_asset when_array_math.data.json
{"num_array":[23,134,323,758,13]}
EOF
    cat <<EOF | zexe when_array_math.zen when_array_math.data.json
Given I have a 'number array' named 'num_array'

When I create sum value of elements in array 'num_array'
# equal to `When I create aggregation of array ''`
When I create average of elements in array 'num_array'
When I create variance of elements in array 'num_array'
When I create standard deviation of elements in array 'num_array'

Then print the 'sum value'
Then print the 'average'  
Then print the 'variance'
Then print the 'standard deviation'
EOF
    save_output when_array_math.out.json
    assert_output '{"average":"250","standard_deviation":"310","sum_value":1251,"variance":"96136"}'
}

@test "array: flat" {
    cat <<EOF | save_asset when_array_flat.data.json
{
	"num_dic_1": {
		"num_1": 23,
		"num_2": 134
	},
	"num_dic_2": {
		"num_3": 34,
		"num_4": 234
	}
}
EOF
    cat <<EOF | zexe when_array_flat.zen when_array_flat.data.json
Given I have a 'number dictionary' named 'num_dic_1'
Given I have a 'number dictionary' named 'num_dic_2'

When I create flat array of contents in 'num_dic_1'
#move the 'flat_array' to 'flat_array_1' 
When I move 'flat_array' to 'flat_array_1'
#save keys of 'num_array_2' in 'flat_array' 
When I create flat array of keys in 'num_dic_2'

Then print the data
EOF
    save_output when_array_flat.out.json
    assert_output '{"flat_array":["num_3","num_4"],"flat_array_1":[23,134],"num_dic_1":{"num_1":23,"num_2":134},"num_dic_2":{"num_3":34,"num_4":234}}'
}

@test "array: of object" {
    cat <<EOF | save_asset when_array_of_objects.data.json
{
    "string": "string_1",
	"num_dic_1": {
		"string_1": "s_d_1",
		"string_2": "s_d_2"
	}
}
EOF
    cat <<EOF | zexe when_array_of_objects.zen when_array_of_objects.data.json
Given I have a 'string dictionary' named 'num_dic_1'
Given I have a 'string' named 'string'
# create an array with an element of the dictionary
When I create array of objects named by 'string' found in 'num_dic_1'
# create a string with an element of the dictionary
When I create 'copied_string_2' from 'string_2' in 'num_dic_1'

Then print the 'array'
Then print the 'copied_string_2'
EOF
    save_output when_array_of_objects.out.json
    assert_output '{"array":["s_d_1"],"copied_string_2":"s_d_2"}'
}

@test "count of a character in a string" {
    cat <<EOF | save_asset when_count_char.data.json
{
	"new string": "we expetc three t",
    "to count": "t"
}
EOF
    cat <<EOF | zexe when_count_char.zen when_count_char.data.json
Given I have a 'string' named 'new string'
Given I have a 'string' named 'to count'

#count the number of occurence of "to count" contained in "new string"
When I create count of char 'to count' found in 'new string'

Then print data
EOF
    save_output when_count_char.out.json
    assert_output '{"count":3,"new_string":"we expetc three t","to_count":"t"}'
}  


@test "dictionary: create" {
    cat <<EOF | zexe when_create_dict.zen
Given nothing

#create an empty dictionary named "new dictionary"
When I create new dictionary

#create and named a new empty dictionary
When I create new dictionary named 'an empty dictionary'

Then print data
EOF
    save_output when_create_dict.out.json
    assert_output '{"an_empty_dictionary":[],"new_dictionary":[]}'
}

@test "dictionary: math operations" {
    cat <<EOF | save_asset when_dict_ops.data.json
{
	"dic": {
		"dic_1": {
			"num_1": 12,
			"num_2": 34
		},
		"dic_2": {
			"num_1": 54,
			"num_2": 67
		},
		"dic_3": {
			"num_1": 32,
			"num_2": 22
		}
	},
	"num_3": 12
}
EOF
    cat <<EOF | zexe when_dict_ops.zen when_dict_ops.data.json
Given I have a 'string dictionary' named 'dic'
Given I have a 'number' named 'num_3'

#find the max valu of num_1 in all the dictionaries in dic
When I find max value 'num_1' for dictionaries in 'dic'
#find the min valu of num_2 in all the dictionaries in dic
When I find min value 'num_2' for dictionaries in 'dic'
#sum all the values of num_1 in all the dictionaries
When I create sum value 'num_1' for dictionaries in 'dic'
When I move 'sum_value' to 'sum_num_1'
#sum all the values of num_2 in the dictionaries where num_1 > num_3
#POSSIBLE BUG: no element of a dictionaries in the second argument of >
When I create sum value 'num_2' for dictionaries in 'dic' where 'num_1' > 'num_3'
#find num_2 in the dctionary where num_1 = num_3
When I find 'num_2' for dictionaries in 'dic' where 'num_1' = 'num_3'

Then print the data
EOF
    save_output when_dict_ops.out.json
    assert_output '{"dic":{"dic_1":{"num_1":12,"num_2":34},"dic_2":{"num_1":54,"num_2":67},"dic_3":{"num_1":32,"num_2":22}},"max_value":54,"min_value":22,"num_2":[34],"num_3":12,"sum_num_1":98,"sum_value":89}'
}  

@test "dictionary: filter" {
    cat <<EOF | save_asset when_dict_filter.data.json
{
	"dic": {
		"dic_1": {
			"num_1": 12,
			"num_2": 34
		},
		"dic_2": {
			"num_1": 54,
			"num_2": 67
		},
		"dic_3": {
			"num_1": 32,
			"num_2": 22
		}
	},
	"num_array": [
		"num_2"
	]
}
EOF
    cat <<EOF | zexe when_dict_filter.zen when_dict_filter.data.json
Given I have a 'string dictionary' named 'dic'
Given I have a 'string array' named 'num_array'

When I filter 'num_array' fields from 'dic'

Then print the data
EOF
    save_output when_dict_filter.out.json
    assert_output '{"dic":{"dic_1":{"num_2":34},"dic_2":{"num_2":67},"dic_3":{"num_2":22}},"num_array":["num_2"]}'
}

@test "dictionary: append" {
    cat <<EOF | save_asset when_dict_append.data.json
{
	"dic": {
		"dic_1": {
			"string_1": "string_dic1_1",
			"string_2": "string_dic1_2"
		},
		"dic_2": {
			"string_1": "string_dic2_1",
			"string_2": "string_dic2_2"
		},
		"dic_3": {
			"string_1": "string_dic3_1",
			"string_2": "string_dic3_2"
		}
	}
}
EOF
    cat <<EOF | zexe when_dict_append.zen when_dict_append.data.json
Given I have a 'string dictionary' named 'dic'
#IMPORTANT: Both the first and second objects must be present in all dictionaries.
When I for each dictionary in 'dic' append 'string_1' to 'string_2'

Then print the data
EOF
    save_output when_dict_append.out.json
    assert_output '{"dic":{"dic_1":{"string_1":"string_dic1_1","string_2":"string_dic1_2string_dic1_1"},"dic_2":{"string_1":"string_dic2_1","string_2":"string_dic2_2string_dic2_1"},"dic_3":{"string_1":"string_dic3_1","string_2":"string_dic3_2string_dic3_1"}}}'
}

@test "dictionary: array" {
    cat <<EOF | save_asset when_dict_append.data.json
{
	"dic": {
		"dic_1": {
			"string_1": "string_dic1_1",
			"string_2": "string_dic1_2"
		},
		"dic_2": {
			"string_1": "string_dic2_1",
			"string_2": "string_dic2_2"
		},
		"dic_3": {
			"string_1": "string_dic3_1",
			"string_2": "string_dic3_2"
		}
	}
}
EOF
    cat <<EOF | zexe when_dict_array.zen when_dict_append.data.json
Given I have a 'string dictionary' named 'dic'

When I create array of elements named 'string_1' for dictionaries in 'dic'

Then print the 'array'
EOF
    save_output when_dict_array.out.json
    assert_output '{"array":["string_dic1_1","string_dic2_1","string_dic3_1"]}'
}    

@test "hash: hmac" {
    cat <<EOF | save_asset when_hash_hmac.data.json
{
	"string_for_hmac": "hash_me_to_HMAC",
	"secret_key": "my_password"
}
EOF
    cat <<EOF | zexe when_hash_hmac.zen when_hash_hmac.data.json
Given I have a 'string' named 'string_for_hmac'
Given I have a 'string' named 'secret_key'

When I create hmac of 'string_for_hmac' with key 'secret_key'

Then print the 'HMAC'
EOF
    save_output when_hash_hmac.out.json
    assert_output '{"HMAC":"NN5eotJvxm5RcOiEXls8a7aD2HMxU0Na+Ah6ANKyOF8="}'
}    

@test "hash: kdf" {
    cat <<EOF | save_asset when_hash_kdf.data.json
{
	"string": "string_for_kd",
	"dic": {
		"s_1": "string_1",
		"s_2": "string_2",
		"s_3": "string_3"
	}
}
EOF
    cat <<EOF | zexe when_hash_kdf.zen when_hash_kdf.data.json
Given I have a 'string' named 'string'
Given I have a 'string dictionary' named 'dic'

When I create key derivation of 'string'
When I move 'key_derivation' to 'key_derivation_string'
When I create key derivations of each object in 'dic' 

Then print the 'key_derivation_string'
Then print the 'key_derivations'
EOF
    save_output when_hash_kdf.out.json
    assert_output '{"key_derivation_string":"1aEoQudo5gbfTQ24/3V9UFLaaTpadhC7Ga5g2X1JvZo=","key_derivations":{"s_1":"wS1x9VHuK+aooKTsJ4s39nQEEEEsEDs+beBI6Gea/R4=","s_2":"LTGx1qxmde3N8kV38Mg8+4+nMky9BJYumUkEZrCvLvw=","s_3":"ndkeE/5LsH4R1rVaLGyVnu1ZaENsPduRS5J/EW/NB8U="}}'
}  

@test "hash: pbkdf" {
    cat <<EOF | save_asset when_hash_pbkdf.data.json
{
	"string": "string_for_kdf",
	"password": "my_password"
}
EOF
    cat <<EOF | zexe when_hash_pbkdf.zen when_hash_pbkdf.data.json
Given I have a 'string' named 'string'
Given I have a 'string' named 'password'

When I create key derivation of 'string' with password 'password'
When I move 'key_derivation' to 'key_derivation_password'
When I create key derivation of 'string' with '5' rounds
When I move 'key_derivation' to 'key_derivation_with_5_rounds'
When I create key derivation of 'string' with '5' rounds with password 'password'
When I move 'key_derivation' to 'key_derivation_with_5_rounds_password'

Then print the 'key_derivation_with_5_rounds_password'
Then print the 'key_derivation_with_5_rounds'
Then print the 'key_derivation_password'
EOF
    save_output when_hash_pbkdf.out.json
    assert_output '{"key_derivation_password":"WDZs6aGmm/z7vlcMmuK1vtkhD+GvKxV4xpsNxmJN+Do=","key_derivation_with_5_rounds":"WW28N7j3pzryD2cyNzODqRSRybgBn5rARMfG/VWkIa8=","key_derivation_with_5_rounds_password":"POTUmmPWyv5355R0xYL0qbiYq0xI2H2L2nyUcl0Y36Y="}'
}  
