load ../bats_setup
load ../bats_zencode
SUBDOC=cookbook_ecdh

@test "create the keyring" {
    cat <<EOF | zexe scenarioECDHZencodePart0.zen
Scenario 'ecdh': Generate a key
Given I am 'Alice'
When I create the ecdh key
Then print my keyring
EOF
    save_output scenarioECDHKeyring1.json
}

@test "create the public key" {
    cat <<EOF | zexe scenarioECDHZencodePart0Publickey.zen scenarioECDHKeyring1.json
Scenario 'ecdh': Generate a public key
Given I am 'Alice'
Given I have my 'keyring'
When I create the ecdh public key
Then print my 'ecdh public key'
EOF
    save_output scenarioECDHPubKey1.json
}

@test "encrypt a message with a password" {
    cat <<EOF | save_asset scenarioECDHInputSecretData1.json
{
   "mySecretStuff":{
	  "myPassword":"myVerySecretPassword",
      	  "header": "A very important secret",
	  "myMessage": "Dear Bob, your name is too short, goodbye - Alice." 
   }
}
EOF
    cat <<EOF | zexe scenarioECDHZencodePart1.zen scenarioECDHInputSecretData1.json
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
    save_output scenarioECDHPart1.json
}

@test "Decrypt message with a password" {
    cat <<EOF | save_asset scenarioECDHInputDataPart1.json
{
   "mySecretStuff":{
	  "password":"myVerySecretPassword" 
	}
}
EOF
    cat <<EOF | zexe scenarioECDHZencodePart2.zen scenarioECDHPart1.json scenarioECDHInputDataPart1.json
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
    save_output scenarioECDHPart2.json
}

@test "Create the signature of an object" {
    cat <<EOF | save_asset scenarioECDHInputDataPart2.json
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
    cat <<EOF | zexe scenarioECDHZencodePart3.zen scenarioECDHInputDataPart2.json
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
    save_output scenarioECDHPart3.json
}

@test "Verify the signature of an object" {
    cat <<EOF | save_asset scenarioECDHAlicePublicKey.json
{
	"Alice": {
		 "public_key": "BBCQg21VcjsmfTmNsg+I+8m1Cm0neaYONTqRnXUjsJLPa8075IYH+a9w2wRO7rFM1cKmv19Igd7ntDZcUvLq3xI="
    	},
	"myUserName":"Bob"
}
EOF
    cat <<EOF | zexe scenarioECDHZencodePart4.zen scenarioECDHPart3.json scenarioECDHAlicePublicKey.json
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
    save_output scenarioECDHPart4.json
}

@test "Encrypt a message with a public key" {
    cat <<EOF | save_asset scenarioECDHAliceKeyring.json
{
	"Alice": {
		"keyring": {
			"ecdh": "WBdsWLDno9/DNaap8cOXyQsCG182NJ0ddjLo/k05mgs="
		}
	},
	"myUserName":"Alice"
}
EOF
    cat <<EOF | save_asset scenarioECDHBobCarlKeysMessage.json
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

    cat <<EOF | zexe scenarioECDHZencodePart5.zen scenarioECDHAliceKeyring.json scenarioECDHBobCarlKeysMessage.json
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
    save_output scenarioECDHPart5.json
}

@test "Decrypt a message with a public key" {
    cat <<EOF | save_asset scenarioECDHAliceBobDecryptKeys.json
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
    cat <<EOF | zexe scenarioECDHZencodePart6.zen scenarioECDHPart5.json scenarioECDHAliceBobDecryptKeys.json 
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
    save_output scenarioECDHPart6.json
}

@test "Generate a keypair loading name from data" {
    cat <<EOF | save_asset scenarioECDHLoadNameFromData.json
{
	"myUserName":"Alice"
}
EOF
    cat <<EOF | zexe scenarioECDHZencodePart7.zen scenarioECDHLoadNameFromData.json
Scenario 'ecdh': Generate a keypair
Given my name is in a 'string' named 'myUserName'
When I create the ecdh key
Then print my keyring
EOF
}
