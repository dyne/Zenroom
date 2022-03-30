#!/bin/bash

# from the article on medium.com
SUBDOC=schnorr
. ../utils.sh $*
Z="`detect_zenroom_path` `detect_zenroom_conf`"

set -e

# needed for Schnorr_createpublickey2.zen
# public key is the corresponding public key
cat <<EOF | save $SUBDOC  Schnorr_readsecretkeys.keys
{
"private_key": "254d726deb59a97872091fcdf2549c462b3ca087b3160645d74d6572a4dd2d26"
}
EOF
cat <<EOF | save $SUBDOC Schnorr_readpubkey.json
{
"public_key": "162c895df27ea1d2c9429d274385792d468c4729a250c1f5099aa92febcf34f5691ae341b4481652cecc9ce7ffca7fe7"
}
EOF

# needed for Schnorr_sign.zen
cat <<EOF | save $SUBDOC  message.json
{
"message": "`echo "print(O.to_hex(O.random(32)))" | $Z`" 
}
EOF

#---simple Schnorr operations: uploading, creating private and public keys, sign/ver --#
cat <<EOF | zexe Schnorr_createprivatekey.zen | save $SUBDOC Alice_Schnorr_privatekey.keys
Rule check version 2.0.0
Scenario schnorr: Create the schnorr private key
Given I am 'Alice'
When I create the schnorr key
Then print the 'keys'
EOF

cat <<EOF | zexe Schnorr_readkeys.zen -k Alice_Schnorr_privatekey.keys | jq .
Rule check version 2.0.0 
Scenario schnorr : Upload the schnorr key
Given I am 'Alice'
and I have the 'keys'
Then print my 'keys'
EOF

cat <<EOF | zexe Schnorr_createpublickey.zen -k Alice_Schnorr_privatekey.keys | save $SUBDOC Alice_Schnorr_pubkey.json
Rule check version 2.0.0 
Scenario schnorr : Create and publish the schnorr public key
Given I am 'Alice'
and I have the 'keys'
When I create the schnorr public key
Then print my 'schnorr public key' 
EOF

cat <<EOF | zexe Schnorr_createpublickey2.zen -k Schnorr_readsecretkeys.keys -a Schnorr_readpubkey.json| jq .
Rule check version 2.0.0 
Scenario schnorr : Create and publish the schnorr public key
Given I am 'Alice'
and I have a 'hex' named 'private key' 
and I have a 'hex' named 'public key'
When I create the schnorr public key with secret key 'private key'
If I verify 'public key' is equal to 'schnorr public key' 
Then print my 'schnorr public key'
EndIf
EOF

cat <<EOF | zexe Schnorr_sign.zen -k Alice_Schnorr_privatekey.keys -a message.json | save $SUBDOC Alice_Schnorr_sign.json
Rule check version 2.0.0 
Scenario schnorr : Alice signs the message
Given I am 'Alice'
and I have the 'keys'
and I have a 'string' named 'message'
When I create the schnorr signature of 'message'
Then print the 'schnorr signature'
and print the 'message'
EOF

#merging Alice pubkey with Alice signature and message
jq -s '.[0]*.[1]' Alice_Schnorr_pubkey.json Alice_Schnorr_sign.json | save $SUBDOC Alice_data.json

cat <<EOF | zexe Schnorr_verifysign.zen -a Alice_data.json | jq .
Rule check version 2.0.0 
Scenario schnorr : Bob verifies Alice signature
Given that I am known as 'Bob'
and I have a 'schnorr public key' from 'Alice'
and I have a 'string' named 'message'
and I have a 'schnorr signature'
If I verify the 'message' has a schnorr signature in 'schnorr signature' by 'Alice'
Then print string 'Success!!!'
Endif
EOF


#--- checking the possibility to use ECDH and Schnorr together ---#
cat <<EOF |zexe Bob_ECDH.zen | save $SUBDOC Bob_data.json
Rule check version 2.0.0
Scenario ecdh : Create the private and public key and sign
Given I am 'Bob'
When I create the ecdh key
and I create the ecdh public key
and I write string 'Message signed by Bob with ECDH' in 'message ECDH'
and I create the signature of 'message ECDH'
Then print my 'ecdh public key'
and print the 'signature'
and print the 'message ECDH'
EOF

#merging Alice and Bob data
jq -s '.[0]*.[1]' Alice_data.json Bob_data.json | save $SUBDOC Alice_Bob_data.json

cat <<EOF | zexe Dave_Verify_ECDH_Schnorr.zen -a Alice_Bob_data.json | jq .
Rule check version 2.0.0
Scenario ecdh : Dave verifies the ECDH signature
Scenario schnorr : Dave verifies the Schnorr signature
Given I am 'Dave'
and I have a 'ecdh public key' from 'Bob'
and I have a 'schnorr public key' from 'Alice'
and I have a 'signature'
and I have a 'schnorr signature'
and I have a 'string' named 'message ECDH'
and I have a 'string' named 'message'
If I verify the 'message ECDH' has a signature in 'signature' by 'Bob'
If I verify the 'message' has a schnorr signature in 'schnorr signature' by 'Alice'
Then print string 'Succes!!!!'
EndIf
EOF

#cleaning the folder
rm *.json *.zen *.keys

success
