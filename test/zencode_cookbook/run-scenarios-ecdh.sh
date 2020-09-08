#!/usr/bin/env bash

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


## Path: ../../docs/examples/zencode_cookbook/

n=0
tmpData1=`mktemp`
tmpData2=`mktemp`
tmpData3=`mktemp`
tmpData4=`mktemp`
tmpData5=`mktemp`
tmpData6=`mktemp`
tmpData7=`mktemp`


tmpKeys1=`mktemp`
tmpKeys2=`mktemp`
tmpKeys3=`mktemp`
tmpKeys4=`mktemp`
tmpKeys5=`mktemp`
tmpKeys6=`mktemp`

tmpZencode0=`mktemp`
tmpZencode1=`mktemp`
tmpZencode2=`mktemp`
tmpZencode3=`mktemp`
tmpZencode4=`mktemp`
tmpZencode5=`mktemp`
tmpZencode6=`mktemp`




let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo "   Generate a keypair: $n          "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "


cat <<EOF  > $tmpZencode0
Scenario 'ecdh': Generate a keypair
Given I am 'Alice'
When I create the keypair
Then print my data
EOF

cat $tmpZencode0 > ../../docs/examples/zencode_cookbook/scenarioECDHZencodePart0.zen

cat $tmpZencode0 | zexe ../../docs/examples/zencode_cookbook/temp.zen -z | jq . | tee ../../docs/examples/zencode_cookbook/scenarioECDHKeypair1.json

let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo "  Generate a keypair with known seed: $n       "
echo "  The known seed is:							  "
echo "  hex:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
echo "------------------------------------------------"
echo "                                                "



cat $tmpZencode0 | zexe ../../docs/examples/zencode_cookbook/temp.zen -c $RNGSEED -z | jq . | tee ../../docs/examples/zencode_cookbook/scenarioECDHKeypair2.json



echo "                                                "
echo "------------------------------------------------"
echo "   	END of Generate a keypair with known seed - script $n"
echo "                                                "
echo " The keypair should be:  "
echo "                                                "
echo " private_key : B4rYTWx6UMbc2YPWRNpl4w2M6gY9jqSa637n8Kr2pPc="
echo " public_key : BHdrWMNBRclVO1I1/iEaYjfEi5C0eEvG2GZgsCNq87qy8feZ74JEvnKK9FC07ThhJ8s4ON2ZQcLJ+8HpWMfKPww="
echo "                                                "
echo "------------------------------------------------"
echo "                                                "



let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo "   Encrypt message with a password: $n          "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "



cat <<EOF  > $tmpData1
{
   "mySecretStuff":{
	  "myPassword":"myVerySecretPassword",
      "header": "A very important secret",
	  "myMessage": "Dear Bob, your name is too short, goodbye - Alice." 
	}
}
EOF
cat $tmpData1 > ../../docs/examples/zencode_cookbook/scenarioECDHInputSecretData1.json



cat <<EOF  > $tmpZencode1
Scenario 'ecdh': Encrypt a message with the password

# Here we load the secret message (made of two strings, one must be named "header")
# along with the password, which is just a string in this case
Given that I have a 'string' named 'myPassword' inside 'mySecretStuff'
Given that I have a 'string' named 'header' inside 'mySecretStuff'
Given that I have a 'string' named 'myMessage' inside 'mySecretStuff'

# Below is where the encryption happens: you specify you want to 
# encrypt using the 'password' string. The newly created object is name "secret message"
When I encrypt the secret message 'myMessage' with 'myPassword'

# We're printing out only the "secret message", because using "Then print all data"
# would cause us to also print out the password.
Then print the 'secret message'	
EOF

cat $tmpZencode1 > ../../docs/examples/zencode_cookbook/scenarioECDHZencodePart1.zen


cat $tmpZencode1 | zexe ../../docs/examples/zencode_cookbook/temp.zen -z -a $tmpData1 | jq . | tee ../../docs/examples/zencode_cookbook/scenarioECDHPart1.json



echo "                                                "
echo "------------------------------------------------"
echo "   	END of script $n       		  			"
echo "------------------------------------------------"
echo "                                                "


let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo "   Decrypt message with a password: $n          "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "



cat <<EOF  > $tmpData2
{
   "mySecretStuff":{
	  "password":"myVerySecretPassword" 
	}
}
EOF
cat $tmpData2 > ../../docs/examples/zencode_cookbook/scenarioECDHInputDataPart1.json



cat <<EOF  > $tmpZencode2
Scenario 'ecdh': Decrypt the message with the password

# Here we load the encrypted secret message along with the password
Given that I have a valid 'secret message'
Given that I have a 'string' named 'password' inside 'mySecretStuff'

# Here the decryption happens, we'll also rename the output.
When I decrypt the text of 'secret message' with 'password'
When I rename the 'text' to 'textDecrypted'

# And here we print out the decrypted message
Then print the 'textDecrypted' 
EOF


cat $tmpZencode2 > ../../docs/examples/zencode_cookbook/scenarioECDHZencodePart2.zen


cat $tmpZencode2 | zexe ../../docs/examples/zencode_cookbook/temp.zen -z -k $tmpData2 -a ../../docs/examples/zencode_cookbook/scenarioECDHPart1.json | jq . | tee ../../docs/examples/zencode_cookbook/scenarioECDHPart2.json




echo "                                                "
echo "------------------------------------------------"
echo "   	END of script $n			       		  "
echo "------------------------------------------------"
echo "                         			              "




let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo "   create the signature of an object: $n          "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "



cat <<EOF  > $tmpData3
{
   "mySecretStuff":{
	  "myMessage": "Dear Bob, your name is too short, goodbye - Alice." 
	},
	 "myStringArray":[
		 "Hello World! This is my string array, element [0]",
		 "Hello World! This is my string array, element [1]",
		 "Hello World! This is my string array, element [2]"
      ],
	  "Alice": {
		"keypair": {
		  "private_key": "Aku7vkJ7K01gQehKELav3qaQfTeTMZKgK+5VhaR3Ui0=",
      "public_key": "BBCQg21VcjsmfTmNsg+I+8m1Cm0neaYONTqRnXUjsJLPa8075IYH+a9w2wRO7rFM1cKmv19Igd7ntDZcUvLq3xI="
    }
  }
}
EOF
cat $tmpData3 > ../../docs/examples/zencode_cookbook/scenarioECDHInputDataPart2.json



cat <<EOF  > $tmpZencode3
Scenario 'ecdh': create the signature of an object

# Declaring who I am and loading all the stuff
Given I am 'Alice'
Given I have my 'keypair'
Given that I have a 'string' named 'myMessage' inside 'mySecretStuff'
Given I have a 'string array' named 'myStringArray'

# Here we create the signaturs and we rename them to samething that looks nicer
When I create the signature of 'myStringArray'
When I rename the 'signature' to 'myStringArray.signature'
When I create the signature of 'myMessage'
When I rename the 'signature' to 'myMessage.signature'

# Here we print both the messages and the signatures
Then print the 'myMessage'
Then print the 'myMessage.signature'	
Then print the 'myStringArray'
Then print the 'myStringArray.signature'

EOF


cat $tmpZencode3 > ../../docs/examples/zencode_cookbook/scenarioECDHZencodePart3.zen


cat $tmpZencode3 | zexe ../../docs/examples/zencode_cookbook/temp.zen -z -a $tmpData3 | jq . | tee ../../docs/examples/zencode_cookbook/scenarioECDHPart3.json




echo "                                                "
echo "------------------------------------------------"
echo "   	END of script $n			       		  "
echo "------------------------------------------------"
echo "                         			              "





let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo "   Verify the signature of an object: $n          "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "



cat <<EOF  > $tmpData4
{

 "Alice": {
      "public_key": "BBCQg21VcjsmfTmNsg+I+8m1Cm0neaYONTqRnXUjsJLPa8075IYH+a9w2wRO7rFM1cKmv19Igd7ntDZcUvLq3xI="
    }
  }

EOF
cat $tmpData4 > ../../docs/examples/zencode_cookbook/scenarioECDHAlicePublicKey.json



cat <<EOF  > $tmpZencode4
rule check version 1.0.0 
Scenario 'ecdh': Bob verifies the signature from Alice

# Declaring who I am and loading all the stuff
Given that I am known as 'Bob' 
Given I have a 'public key' from 'Alice' 
Given I have a 'string' named 'myMessage' 
Given I have a 'signature' named 'myMessage.signature'
Given I have a 'string array' named 'myStringArray'
Given I have a 'signature' named  'myStringArray.signature'

# The verification happens here: if the verification would fails, Zenroom would stop and print an error 
When I verify the 'myMessage' has a signature in 'myMessage.signature' by 'Alice'
When I verify the 'myStringArray' has a signature in 'myStringArray.signature' by 'Alice'	

# Here we're printing the original message along with happy statement of success
Then print the 'myMessage'
Then print 'Zenroom certifies that signatures are all correct!' as 'string'
EOF


cat $tmpZencode4 > ../../docs/examples/zencode_cookbook/scenarioECDHZencodePart4.zen


cat $tmpZencode4 | zexe ../../docs/examples/zencode_cookbook/temp.zen -z -k $tmpData4 -a ../../docs/examples/zencode_cookbook/scenarioECDHPart3.json | jq . | tee ../../docs/examples/zencode_cookbook/scenarioECDHPart4.json




echo "                                                "
echo "------------------------------------------------"
echo "   	END of script $n			       		  "
echo "------------------------------------------------"
echo "                         			              "




let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo "   encrypt a message with a public key: $n          "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "



cat <<EOF  > $tmpData5
{
	"Alice": {
		"keypair": {
			"private_key": "WBdsWLDno9/DNaap8cOXyQsCG182NJ0ddjLo/k05mgs=",
			"public_key": "BNRzlJ4csYlWgycGGiK/wgoEw3OizCdx9MWg06rxUBTP5rP9qPASOW5KY8YgmNjW5k7lLpboboHrsApWsvgkMN4="
		}
	}
}
EOF
cat $tmpData5 > ../../docs/examples/zencode_cookbook/scenarioECDHAliceKeyapir.json

cat <<EOF  > $tmpData7
{
	"Bob": {
		"public_key": "BBA0kD35T9lUHR/WhDwBmgg/vMzlu1Vb0qtBjBZ8rbhdtW3AcX6z64a59RqF6FCV5q3lpiFNTmOgA264x1cZHE0="
	},
	"Carl": {
		"public_key": "BLdpLbIcpV5oQ3WWKFDmOQ/zZqTo93cT1SId8HNITgDzFeI6Y3FCBTxsKHeyY1GAbHzABsOf1Zo61FRQFLRAsc8="
	},
	"myMessageForBobAndCarl": "Dear Bob and Carl, we're not friends anymore cause your names are too short. Goodbye.",
	"header": "Secret message for Bob and Carl"
}
EOF
cat $tmpData7 > ../../docs/examples/zencode_cookbook/scenarioECDHBobCarlKeysMessage.json


cat <<EOF  > $tmpZencode5
Rule check version 1.0.0
Scenario 'ecdh': Alice encrypts a message for Bob and Carl

# Loading Alice' keypair
Given that I am 'Alice'
Given that I have my 'keypair'

# Loading the public keys of the recipients, you can load as many as you like
Given that I have a 'public key' from 'Bob'
Given that I have a 'public key' from 'Carl'

# Loading the secret message
Given that I have a 'string' named 'myMessageForBobAndCarl'
Given that I have a 'string' named 'header'

# Encrypt the secret message for 1st recipient and rename the output
When I encrypt the secret message of 'myMessageForBobAndCarl' for 'Bob'
When I rename the 'secret message' to 'secretForBob'

# Encrypt the secret message for 2nd recipient and rename the output,
# you can go on encrypting as many recipients as you like, as long as you have their public key
When I encrypt the secret message of 'myMessageForBobAndCarl' for 'Carl'
When I rename the 'secret message' to 'secretForCarl'

# Printing out the encrypted messages: it's recommended to print them one by one
# Cause if you use the "Then print all" statement, you would also print all the keys.
Then print the 'secretForBob'
Then print the 'secretForCarl'
EOF


cat $tmpZencode5 > ../../docs/examples/zencode_cookbook/scenarioECDHZencodePart5.zen


cat $tmpZencode5 | zexe ../../docs/examples/zencode_cookbook/temp.zen -z -k $tmpData5 -a $tmpData7  | jq . | tee ../../docs/examples/zencode_cookbook/scenarioECDHPart5.json




echo "                                                "
echo "------------------------------------------------"
echo "   	END of script $n			       		  "
echo "------------------------------------------------"
echo "                         			              "


let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo "   decrypt a message with a public key: $n          "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "



cat <<EOF  > $tmpData6
{
	"Bob": {
		"keypair": {
			"private_key": "psBF05iHz/X8WBpwitJoSsZ7BiKawrdaVfQN3AtTa6I=",
			"public_key": "BBA0kD35T9lUHR/WhDwBmgg/vMzlu1Vb0qtBjBZ8rbhdtW3AcX6z64a59RqF6FCV5q3lpiFNTmOgA264x1cZHE0="
		}
	},
		"Alice": {
		"public_key": "BNRzlJ4csYlWgycGGiK/wgoEw3OizCdx9MWg06rxUBTP5rP9qPASOW5KY8YgmNjW5k7lLpboboHrsApWsvgkMN4="
	}
}
EOF
cat $tmpData6 > ../../docs/examples/zencode_cookbook/scenarioECDHAliceBobDecryptKeys.json



cat <<EOF  > $tmpZencode6
Rule check version 1.0.0 
Scenario 'ecdh': Bob decrypts the message from Alice 

# Here we state that Bob is running the script and we load his keypair 
Given that I am known as 'Bob' 
Given I have my 'keypair'

# Here we load Alice's public key
Given I have a 'public key' from 'Alice' 

# Here we load the encrypted message(s)
Given I have a 'secret message' named 'secretForBob'

# Here we decrypt the message and rename it
When I decrypt the text of 'secretForBob' from 'Alice'
When I rename the 'text' to 'textForBob'

# Here we print out the message and its header
Then print the 'textForBob' as 'string' 
Then print the 'header' as 'string' inside 'secretForBob' 
EOF


cat $tmpZencode6 > ../../docs/examples/zencode_cookbook/scenarioECDHZencodePart6.zen


cat $tmpZencode6 | zexe ../../docs/examples/zencode_cookbook/temp.zen -z -k $tmpData6 -a ../../docs/examples/zencode_cookbook/scenarioECDHPart5.json | jq . | tee ../../docs/examples/zencode_cookbook/scenarioECDHPart6.json




echo "                                                "
echo "------------------------------------------------"
echo "   	END of script $n			       		  "
echo "------------------------------------------------"
echo "                         			              "




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


rm -f $tmpData1
rm -f $tmpData2
rm -f $tmpData3
rm -f $tmpData4
rm -f $tmpData5
rm -f $tmpData6
rm -f $tmpData7


rm -f $tmpKeys1
rm -f $tmpKeys2
rm -f $tmpKeys3
rm -f $tmpKeys4
rm -f $tmpKeys5
rm -f $tmpKeys6

rm -f $tmpZencode1
rm -f $tmpZencode2
rm -f $tmpZencode3
rm -f $tmpZencode4
rm -f $tmpZencode5
rm -f $tmpZencode6
