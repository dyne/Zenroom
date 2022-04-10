#!/usr/bin/env bash

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



let n=1
echo "                                                "
echo "------------------------------------------------"
echo "   Generate a keypair: $n          "
echo " 	this is generated with a known seed			  "
echo " 	to change, remove the	RNGSEED=   in the beginning "
echo "------------------------------------------------"
echo "                                                "


cat <<EOF | save . scenarioECDHZencodePart0.zen
Scenario 'ecdh': Generate a keypair
Given I am 'Alice'
When I create the ecdh key
Then print my keyring
EOF

cat scenarioECDHZencodePart0.zen | zexe ecdh$n.zen -z | save . scenarioECDHKeypair1.json

let n=2
echo "                                                "
echo "------------------------------------------------"
echo "  Generate a keypair with known seed: $n       "
echo "  The known seed is:							  "
echo "  hex:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
echo "------------------------------------------------"
echo "                                                "



cat scenarioECDHZencodePart0.zen | zexe ecdh$n.zen -z | save . scenarioECDHKeypair2.json



echo "                                                "
echo "------------------------------------------------"
echo "   	END of Generate a keypair with known seed - script $n"
echo "                                                "
echo " The keyring should be:  "
echo "                                                "
echo " ecdh : B4rYTWx6UMbc2YPWRNpl4w2M6gY9jqSa637n8Kr2pPc="
echo "                                                "
echo "------------------------------------------------"
echo "                                                "



let n=3
echo "                                                "
echo "------------------------------------------------"
echo "   Encrypt message with a password: $n          "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "



cat <<EOF | save . scenarioECDHInputSecretData1.json
{
   "mySecretStuff":{
	  "myPassword":"myVerySecretPassword",
      "header": "A very important secret",
	  "myMessage": "Dear Bob, your name is too short, goodbye - Alice." 
	}
}
EOF



cat <<EOF | save . scenarioECDHZencodePart1.zen
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

cat scenarioECDHZencodePart1.zen | zexe ecdh$n.zen -z -a scenarioECDHInputSecretData1.json | save . scenarioECDHPart1.json



echo "                                                "
echo "------------------------------------------------"
echo "   	END of script $n       		  			"
echo "------------------------------------------------"
echo "                                                "


let n=4
echo "                                                "
echo "------------------------------------------------"
echo "   Decrypt message with a password: $n          "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "



cat <<EOF | save . scenarioECDHInputDataPart1.json
{
   "mySecretStuff":{
	  "password":"myVerySecretPassword" 
	}
}
EOF

cat <<EOF | save . scenarioECDHZencodePart2.zen
Scenario 'ecdh': Decrypt the message with the password

# Here we load the encrypted secret message along with the password
Given that I have a valid 'secret message'
Given that I have a 'string' named 'password' inside 'mySecretStuff'

# Here the decryption happens, we'll also rename the output.
When I decrypt the text of 'secret message' with 'password'
When I rename the 'text' to 'textDecrypted'

# And here we print out the decrypted message
Then print the 'textDecrypted' as 'string'
EOF

cat scenarioECDHZencodePart2.zen | zexe ecdh$n.zen -z -k scenarioECDHInputDataPart1.json -a scenarioECDHPart1.json | save . scenarioECDHPart2.json


echo "                                                "
echo "------------------------------------------------"
echo "   	END of script $n			       		  "
echo "------------------------------------------------"
echo "                         			              "




let n=5
echo "                                                "
echo "------------------------------------------------"
echo "   create the signature of an object: $n          "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "



cat <<EOF | save . scenarioECDHInputDataPart2.json
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
		"keyring": {
	      "ecdh": "Aku7vkJ7K01gQehKELav3qaQfTeTMZKgK+5VhaR3Ui0="
	    },
        "public_key": "BBCQg21VcjsmfTmNsg+I+8m1Cm0neaYONTqRnXUjsJLPa8075IYH+a9w2wRO7rFM1cKmv19Igd7ntDZcUvLq3xI="
    },
  "myUserName":"Alice"
}
EOF

cat <<EOF | save . scenarioECDHZencodePart3.zen
Scenario 'ecdh': create the signature of an object

# Declaring who I am and loading all the stuff
Given my name is in a 'string' named 'myUserName'
Given I have my 'keyring'
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

cat scenarioECDHZencodePart3.zen | zexe ecdh$n.zen -z -a scenarioECDHInputDataPart2.json | save . scenarioECDHPart3.json




echo "                                                "
echo "------------------------------------------------"
echo "   	END of script $n			       		  "
echo "------------------------------------------------"
echo "                         			              "





let n=6
echo "                                                "
echo "------------------------------------------------"
echo "   Verify the signature of an object: $n          "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "



cat <<EOF | save . scenarioECDHAlicePublicKey.json
{

 "Alice": {
      "public_key": "BBCQg21VcjsmfTmNsg+I+8m1Cm0neaYONTqRnXUjsJLPa8075IYH+a9w2wRO7rFM1cKmv19Igd7ntDZcUvLq3xI="
    },
	"myUserName":"Bob"
}

EOF

cat <<EOF | save . scenarioECDHZencodePart4.zen
# rule check version 1.0.0 
Scenario 'ecdh': Bob verifies the signature from Alice

# Declaring who I am and loading all the stuff
Given my name is in a 'string' named 'myUserName'
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
Then print the string 'Zenroom certifies that signatures are all correct!'
EOF

cat scenarioECDHZencodePart4.zen | zexe ecdh$n.zen -z -k scenarioECDHAlicePublicKey.json -a scenarioECDHPart3.json | save . scenarioECDHPart4.json




echo "                                                "
echo "------------------------------------------------"
echo "   	END of script $n			       		  "
echo "------------------------------------------------"
echo "                         			              "




let n=7
echo "                                                "
echo "------------------------------------------------"
echo "   encrypt a message with a public key: $n          "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "



cat <<EOF | save . scenarioECDHAliceKeyapir.json
{
	"Alice": {
		"keyring": {
			"ecdh": "WBdsWLDno9/DNaap8cOXyQsCG182NJ0ddjLo/k05mgs="
		}
	},
	"myUserName":"Alice"
}
EOF

cat <<EOF | save . scenarioECDHBobCarlKeysMessage.json
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

cat <<EOF | save . scenarioECDHZencodePart5.zen
Rule check version 1.0.0
Scenario 'ecdh': Alice encrypts a message for Bob and Carl

# Loading Alice' keypair
Given my name is in a 'string' named 'myUserName'
Given that I have my 'keyring'

# Loading the public keys of the recipients, you can load as many as you like
Given that I have a 'public key' from 'Bob'
Given that I have a 'public key' from 'Carl'

# Loading the secret message
Given that I have a 'string' named 'myMessageForBobAndCarl'
# Commenting reading og the header, as we don't need the header, 
# so Zenroom will set it as "DefaultHeader"
#  
# Given that I have a 'string' named 'header'

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

cat scenarioECDHZencodePart5.zen | zexe ecdh$n.zen -z -k scenarioECDHAliceKeyapir.json -a scenarioECDHBobCarlKeysMessage.json  | save . scenarioECDHPart5.json




echo "                                                "
echo "------------------------------------------------"
echo "   	END of script $n			       		  "
echo "------------------------------------------------"
echo "                         			              "


let n=8
echo "                                                "
echo "------------------------------------------------"
echo "   decrypt a message with a public key: $n          "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "



cat <<EOF | save . scenarioECDHAliceBobDecryptKeys.json
{
	"Bob": {
		"keyring": {
			"ecdh": "psBF05iHz/X8WBpwitJoSsZ7BiKawrdaVfQN3AtTa6I="
		}
	},
	"public_keys": {
		"Alice": "BNRzlJ4csYlWgycGGiK/wgoEw3OizCdx9MWg06rxUBTP5rP9qPASOW5KY8YgmNjW5k7lLpboboHrsApWsvgkMN4="
		},
	"myUserName":"Bob"
}
EOF

cat <<EOF | save . scenarioECDHZencodePart6.zen
Rule check version 1.0.0 
Scenario 'ecdh': Bob decrypts the message from Alice 

# Here we state that Bob is running the script and we load his keypair 
Given my name is in a 'string' named 'myUserName'
Given I have my 'keyring'

# Here we load Alice's public key
Given I have a 'public key' named 'Alice' in 'public keys'

# Here we load the encrypted message(s)
Given I have a 'secret message' named 'secretForBob'

# Here we decrypt the message and rename it
When I decrypt the text of 'secretForBob' from 'Alice'
When I rename the 'text' to 'textForBob'

# Here we print out the message and its header
Then print the 'textForBob' as 'string' 
Then print the 'header' from 'secretForBob' as 'string'
EOF



cat scenarioECDHZencodePart6.zen | zexe ecdh$n.zen -z -k scenarioECDHAliceBobDecryptKeys.json -a scenarioECDHPart5.json | save . scenarioECDHPart6.json



let n=9
echo "                                                "
echo "------------------------------------------------"
echo "   Generate a keypair loading name from data $n          "
echo " 	this is generated with a known seed			  "
echo " 	to change, remove the	RNGSEED=   in the beginning "
echo "------------------------------------------------"
echo "                                                "

cat <<EOF | save . scenarioECDHLoadNameFromData.json
{
	"myUserName":"Alice"
}
EOF

cat <<EOF | save .  scenarioECDHZencodePart7.zen
Scenario 'ecdh': Generate a keypair
Given my name is in a 'string' named 'myUserName'
When I create the ecdh key
Then print my keyring
EOF

cat scenarioECDHZencodePart7.zen | zexe ecdh$n.zen -z -a scenarioECDHLoadNameFromData.json | save . scenarioECDHKeypair3.json



echo "                                                "
echo "------------------------------------------------"
echo "   	END of script $n			       		  "
echo "------------------------------------------------"
echo "                         			              "
