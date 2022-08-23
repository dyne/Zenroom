load ../bats_setup
load ../bats_zencode
SUBDOC=cookbook_then

@test "Huge print script" {
    cat <<EOF | save_asset myLargeNestedObjectThen.json
{
   "myObject":{
      "myNumber_1":1234567890,
      "myNumber_2":1234567890,
      "myNumber_3":1234567890,
      "myNumber_4":1234567890, 
   	  "myNumber_5":12345678,  
	  "myString_1":"Hello World!",
	  "myString_2":"Hello World!",
	  "myString_3":"Hello World!",
	  "myString_4":"Hello World!",
	  "myString_5":"Hello World!",
      "myHex_1": "68747470733a2f2f6769746875622e636f6d2f64796e652f5a656e726f6f6d",
      "myHex_2": "68747470733a2f2f6769746875622e636f6d2f64796e652f5a656e726f6f6d",
      "myHex_3": "68747470733a2f2f6769746875622e636f6d2f64796e652f5a656e726f6f6d",
	  "myHex_4": "68747470733a2f2f6769746875622e636f6d2f64796e652f5a656e726f6f6d",
	  "myHex_5": "68747470733a2f2f6769746875622e636f6d2f64796e652f5a656e726f6f6d",
      "myBase64_1": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbQ==",
      "myBase64_2": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbQ==",
      "myBase64_3": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbQ==",
	  "myBase64_4": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbQ==",
	  "myBase64_5": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbQ==",
	  "myUrl64_1": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbS8",
  	  "myUrl64_2": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbS8",
  	  "myUrl64_3": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbS8",
  	  "myUrl64_4": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbS8",
  	  "myUrl64_5": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbS8",
	  "myUrl64_6": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbS8",
	  "myBinary_1": "01011010011001010110111001110010011011110110111101101101",
	  "myBinary_2": "01011010011001010110111001110010011011110110111101101101",
	  "myBinary_3": "01011010011001010110111001110010011011110110111101101101",
	  "myBinary_4": "01011010011001010110111001110010011011110110111101101101",
	  "myBinary_5": "01011010011001010110111001110010011011110110111101101101",
	  
	  "myStringArray_1":[
         "Hello World! --- 1",
		 "Hello World! --- 2",
		 "Hello World! --- 3"
      ],
	  "myStringArray_2":[
         "Hello World! --- 1",
		 "Hello World! --- 2",
		 "Hello World! --- 3"
      ],
	   "myStringArray_3":[
         "Hello World! --- 1",
		 "Hello World! --- 2",
		 "Hello World! --- 3"
      ],
	   "myStringArray_4":[
         "Hello World! --- 1",
		 "Hello World! --- 2",
		 "Hello World! --- 3"
      ],
	   "myStringArray_5":[
         "Hello World! --- 1",
		 "Hello World! --- 2",
		 "Hello World! --- 3"
      ],
	  
	  "myNumberArray_1":[
         "123",
		 "456",
		 "1234.5678"
      ],
	  "myNumberArray_2":[
         "123",
		 "456",
		 "1234.5678"
      ],
	  "myNumberArray_3":[
         "123",
		 "456",
		 "1234.5678"
      ],
	  "myNumberArray_4":[
         "123",
		 "456",
		 "1234.5678"
      ],
	  "myNumberArray_5":[
         "123",
		 "456",
		 "1234.5678"
      ]
   },
   "Alice":{
      "keyring":{
         "ecdh":"AxLMXkey00i2BD675vpMQ8WhP/CwEfmdRr+BtpuJ2rM="
      },
	  "keys": {
			"issuer": {
				"x": "zK8Gs70vdLRErIKkTQdNbWfrWIExirgMKSxfGuPa1aU=",
				"y": "x83wJ6rYhwowX/q4R0fNiE87JD4R48U1lBN21OgFJoE="
			}
		}
   },
	"Bob": {
		"public_key": "BGdp6q41IE9X4H909u8dc05mJxfl+cYNmLChky2u6G3uUJPfEmM8hm4HRz/eSl+w75glCrW6WaOKwBMFCcfzoLg="
    },
	"Carl": {
         "public_key": "BG/TONSVfG5iQWNpp4bNG7Ev0g36XncIeaDOWOHX+MvDj/rPOEHahE2uJepOAv6ijZj07sc2XRddIH4HB78Nu4k="
    },
	"salesReport": {
      "maxPricePerKG": 100,
      "sumValueAllTransactions": 3800,
      "transferredProductAmountafterSalesStart": 30,
	  "shopOwner": "JackInTheShop"
   },
   "myFourthObject": {
    "myFourthArray": [
      "Hello World! inside myFourthObject, inside myFourthArray[0]",
      "Hello World! inside myFourthObject, inside myFourthArray[1]",
      "Will this string be found inside an array?",
      "Hello World! inside myFourthObject, inside myFourthArray[2]",
      "Hello World! inside myFourthObject, inside myFourthArray[3]"
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
    "mySixteenthString": "Hello World! myThirdObject, myThirdArray[2]"
  }
}
EOF
    cat <<EOF  | save_asset thenCompleteScriptGiven.zen
# rule input encoding base64
Scenario 'ecdh': load a issuer keypair
Scenario 'credential': Create the keypair
Given I am 'Alice'
Given I have my 'keyring' 
and I have a 'public key' from 'Bob'
and I have a 'public key' from 'Carl'
# Load Arrays
Given I have a 'string array' named 'myStringArray_1' inside 'myObject'
Given I have a 'string array' named 'myStringArray_2' inside 'myObject'
Given I have a 'string array' named 'myStringArray_3' inside 'myObject'
Given I have a 'string array' named 'myStringArray_4' inside 'myObject' 
Given I have a 'string array' named 'myStringArray_5' inside 'myObject'
Given I have a 'number array' named 'myNumberArray_1' inside 'myObject'
Given I have a 'number array' named 'myNumberArray_2' inside 'myObject'
Given I have a 'number array' named 'myNumberArray_3' inside 'myObject'
Given I have a 'number array' named 'myNumberArray_4' inside 'myObject'
Given I have a 'number array' named 'myNumberArray_5' inside 'myObject'
# Load Numbers
Given I have a 'number' named 'myNumber_1' inside 'myObject'
Given I have a 'number' named 'myNumber_2' inside 'myObject'
Given I have a 'number' named 'myNumber_3' inside 'myObject' 
Given I have a 'number' named 'myNumber_4' inside 'myObject'
Given I have a 'number' named 'myNumber_5' inside 'myObject'
# Load Strings
Given I have a 'string' named 'myString_1'  inside 'myObject'
# Questo sotto non funziona proprio, quindi toglierei la parte in 'qualcosa'
Given I have a 'string' named 'myString_2' inside 'myObject'
Given I have a 'string' named 'myString_3' inside 'myObject'
Given I have a 'string' named 'myString_4' inside 'myObject'
Given I have a 'string' named 'myString_5' inside 'myObject'
# Different data types
Given I have an 'hex' named 'myHex_1' inside 'myObject'
Given I have an 'hex' named 'myHex_2' inside 'myObject'
Given I have an 'hex' named 'myHex_3' inside 'myObject'
Given I have an 'hex' named 'myHex_4' inside 'myObject'
Given I have an 'hex' named 'myHex_5' inside 'myObject'
Given I have a  'base64' named 'myBase64_1' inside 'myObject'
Given I have a  'base64' named 'myBase64_2' inside 'myObject'
Given I have a  'base64' named 'myBase64_3' inside 'myObject'
Given I have a  'base64' named 'myBase64_4' inside 'myObject'
Given I have a  'base64' named 'myBase64_5' inside 'myObject'
Given I have a  'binary' named 'myBinary_1' inside 'myObject'
Given I have a  'binary' named 'myBinary_2' inside 'myObject'
Given I have a  'binary' named 'myBinary_3' inside 'myObject'
Given I have a  'binary' named 'myBinary_4' inside 'myObject'
Given I have a  'binary' named 'myBinary_5' inside 'myObject'
Given I have an 'url64' named 'myUrl64_1' inside 'myObject'
Given I have an 'url64' named 'myUrl64_2' inside 'myObject'
Given I have an 'url64' named 'myUrl64_3' inside 'myObject'
Given I have an 'url64' named 'myUrl64_4' inside 'myObject'
Given I have an 'url64' named 'myUrl64_5' inside 'myObject'
Given I have an 'url64' named 'myUrl64_6' inside 'myObject'
# Dictionary
Given I have a 'string dictionary' named 'salesReport'
Given I have a 'string dictionary' named 'myFourthObject'
EOF
    cat <<EOF  | save_asset thenExhaustiveScript.zen
Then print all data

# By printing all data, the first of the 5 items
# is printed with its default schema.
# 
# (0): default
# 1: string
# 2: number
# 3: base64
# 4: bin
# 5: hex

Then print 'myString_2' as 'number' 
Then print 'myString_3' as 'base64' 
Then print 'myString_4' as 'bin' 
Then print 'myString_5' as 'hex' 

Then print 'myNumber_2' as 'string' 
Then print 'myNumber_3' as 'base64'
Then print 'myNumber_4' as 'bin' 
Then print 'myNumber_5' as 'hex'

Then print 'myStringArray_2' as 'number' 
Then print 'myStringArray_3' as 'base64' 
Then print 'myStringArray_4' as 'bin' 
Then print 'myStringArray_5' as 'hex' 

Then print 'myNumberArray_2' as 'string' 
Then print 'myNumberArray_3' as 'base64' 
Then print 'myNumberArray_4' as 'bin' 
Then print 'myNumberArray_5' as 'hex' 

Then print 'myBinary_2' as 'string' 
Then print 'myBinary_3' as 'number' 
Then print 'myBinary_4' as 'base64' 
Then print 'myBinary_5' as 'hex' 

Then print 'myBase64_2' as 'string'
Then print 'myBase64_3' as 'number' 
Then print 'myBase64_4' as 'bin'
Then print 'myBase64_5' as 'hex' 

Then print 'myHex_2' as 'string'
Then print 'myHex_3' as 'number' 
Then print 'myHex_4' as 'base64'
Then print 'myHex_5' as 'bin' 

Then print 'myUrl64_2' as 'string'
Then print 'myUrl64_3' as 'number'
Then print 'myUrl64_4' as 'base64'
Then print 'myUrl64_5' as 'bin'
Then print 'myUrl64_6' as 'hex'
EOF
    cat $R/docs/examples/zencode_cookbook/$SUBDOC/thenCompleteScriptGiven.zen \
	$R/docs/examples/zencode_cookbook/$SUBDOC/thenExhaustiveScript.zen \
	| zexe then1.zen myLargeNestedObjectThen.json
    save_output thenExhaustiveScriptOutput.json
}

@test "print my data" {
    cat <<EOF  | save_asset thenCompleteScriptPart2.zen
# Then print all data

# By printing all data, the first of the 5 items
# is printed with its default schema.
# 
# (0): default
# 1: string
# 2: number
# 3: base64
# 4: bin
# 5: hex

Then print 'myString_1'
Then print 'myString_2' as 'number' 
Then print 'myString_3' as 'base64' 
Then print 'myString_4' as 'bin' 
Then print 'myString_5' as 'hex' 

Then print 'myNumber_1'  
Then print 'myNumber_2' as 'string' 
Then print 'myNumber_3' as 'base64'
Then print 'myNumber_4' as 'bin' 
Then print 'myNumber_5' as 'hex'

Then print 'myStringArray_1' 
Then print 'myStringArray_2' as 'number' 
Then print 'myStringArray_3' as 'base64' 
Then print 'myStringArray_4' as 'bin' 
Then print 'myStringArray_5' as 'hex' 

Then print 'myNumberArray_1' 
Then print 'myNumberArray_2' as 'string' 
Then print 'myNumberArray_3' as 'base64' 
Then print 'myNumberArray_4' as 'bin' 
Then print 'myNumberArray_5' as 'hex' 

Then print 'myBinary_1' 
Then print 'myBinary_2' as 'string' 
Then print 'myBinary_3' as 'number' 
Then print 'myBinary_4' as 'base64' 
Then print 'myBinary_5' as 'hex' 

Then print 'myBase64_1' 
Then print 'myBase64_2' as 'string'
Then print 'myBase64_3' as 'number' 
Then print 'myBase64_4' as 'bin'
Then print 'myBase64_5' as 'hex' 

Then print 'myHex_1' 
Then print 'myHex_2' as 'string'
Then print 'myHex_3' as 'number' 
Then print 'myHex_4' as 'base64'
Then print 'myHex_5' as 'bin' 

Then print 'myUrl64_1' 
Then print 'myUrl64_2' as 'string'
Then print 'myUrl64_3' as 'number'
Then print 'myUrl64_4' as 'base64'
Then print 'myUrl64_5' as 'bin'
Then print 'myUrl64_6' as 'hex'

# Print from and as
Then print the 'myFourthString' from 'myFourthObject'
Then print the 'myFifthString' from 'myFourthObject' as 'hex'
EOF
    cat $R/docs/examples/zencode_cookbook/$SUBDOC/thenCompleteScriptGiven.zen \
	$R/docs/examples/zencode_cookbook/$SUBDOC/thenCompleteScriptPart2.zen \
	| zexe then2.zen myLargeNestedObjectThen.json
}

@test "print messages" {
    cat <<EOF  | save_asset thenCompleteScriptPart3.zen
When I write string 'This message is for Bob.' in 'messageForBob'
When I write string 'This message is for Carl.' in 'messageForCarl'

and I write string 'This is the header' in 'header'
Then print 'header'

#and I encrypt the message for 'Bob'
# and I encrypt the 'messageForBob'
# and I rename the 'message' to 'Message for Bob'
# and debug
#and I encrypt the message for 'Carl'
#and I rename the 'message' to 'Message for Carl'
#Then print the 'Message for Bob'
#and print the 'Message for Carl'

# Then print my 'keypair' 
# Then print the 'public key' 
# print ''
# print '' as ''
# print '' as '' in ''
# print data
# print data as ''
# print my ''
# print my '' as ''
# print my data
# print my data as ''
# print the ''
# print the '' as ''
# print the '' as '' in ''
# print the '' in ''
EOF
    cat $R/docs/examples/zencode_cookbook/$SUBDOC/thenCompleteScriptGiven.zen \
	$R/docs/examples/zencode_cookbook/$SUBDOC/thenCompleteScriptPart3.zen \
	| zexe then3.zen myLargeNestedObjectThen.json
}

@test "print nested objects using 'in' and 'from'" {
    cat <<EOF  | save_asset thenCompleteScriptPart4.zen
When I create the issuer key
When I create the issuer public key
# This prints a child of dictionary, which can be a string (like here) or another dictionary
Then print the 'maxPricePerKG' from 'salesReport'

# This prints the "verifier", that is the cryptographical object produced by an issuer that is publicly accessible
# in order to match it with the proofs. 
Then print the 'issuer public key'
EOF
    cat $R/docs/examples/zencode_cookbook/$SUBDOC/thenCompleteScriptGiven.zen \
	$R/docs/examples/zencode_cookbook/$SUBDOC/thenCompleteScriptPart4.zen \
	| zexe then4.zen myLargeNestedObjectThen.json
    save_output thenCompleteOutputPart4.json
}
