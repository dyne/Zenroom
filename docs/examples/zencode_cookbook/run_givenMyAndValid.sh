#!/usr/bin/env bash



# https://pad.dyne.org/code/#/2/code/edit/NTsTFsGUExxvnycVzM32AJvZ/


# common script init
# if ! test -r ../../../test/utils.sh; then
#	echo "run executable from its own directory: $0"; exit 1; fi
# . ../../../test/utils.sh
# Z="`detect_zenroom_path` `detect_zenroom_conf`"
Z=zenroom
####################


n=0
tmp=`mktemp`





cat <<EOF | tee bob_keygen.zen | $Z -z > bob_keypair.json
Scenario 'simple': Create the keypair
Given that I am known as 'Bob'
When I create the keypair
Then print my data
EOF



# This loads an object
cat <<EOF  > $tmp 
  {
   "Alice":{
      "keypair":{
         "private_key":"OCaY55-NMptPvF1OdBzPSNhA_vcQXVEBPY8cblWOGIRkF3eZGPdYHG1OGcPR4IBQYOiL8bHRTMY",
         "public_key":"BGVUPlabVjQ-HfV1JrcmCFuCQ00t3skQBXtjeRkN7Djnj_-ql8GOtpbJxeBlRpQRVP8XKTc3Kl5qi6aYZRwZPN-M_4Uc9fmEwSvPcLtE7UGgpTMTBWhx25syX54DFqXsfz64Gt2_YvRh7HI_rooJJYI"
      },
      "myObject":{
         "myNumber":1000,
         "myString":"Hello World!",
         "myArray":[
            "String1",
            "String2",
            "String3"
         ]
      },
      "myRandomArrays":{
         "myAverageArray":[
            "Ivk",
            "Zeg",
            "gtM",
            "TcY"
         ],
         "myBigFatArray":[
            "SIznL5ZtY_E",
            "cmXzJ_GvPO4",
            "OFXDLZ-9rhA",
            "3WdscDMB_yA",
            "U_t9FszB5so",
            "xjLi-TSTnaA",
            "_29xJYsw_X4",
            "BVOlwdsgqXo",
            "9hjlpZ9a_hU",
            "QdlVu8yxpCU",
            "PFQBcLkxWQc",
            "ZEPp3CTVLuI",
            "N53Kojfi188",
            "x8Sn01O9ZXo",
            "uMO6iVkt8u0",
            "MlY_nscHp9Y"
         ],
         "myTinyArray":[
            "PQ",
            "ew"
         ]
      }
   }
}
EOF


cat <<EOF | tee given_my_valid.zen | $Z -z -k bob_keypair.json -a $tmp | tee givenMyAndValid.json
Rule check version 1.0.0
Scenario 'simple': Alice encrypts a message for Bob
	Given that I am known as 'Alice'
	and I have my 'keypair'
    and I have my 'myObject'
    and I have my 'myNumber'
    and I have my 'myString'
	and I have my 'myArray'
	and I have my 'myRandomArrays'
	and I have my 'myAverageArray'
	and I have my valid 'myObject'
	and I have my valid 'myNumber'
	and I have my valid 'myString'
	and I have my valid 'myArray'
	and I have my valid 'myRandomArrays'
	and I have my valid 'myAverageArray'
	and I have my valid 'keypair'
	and I have a valid 'public key' from 'Bob'
	When I write string 'This is my secret message.' in 'message'
	and I write string 'This is the header' in 'header'
	and I encrypt the message for 'Bob'
	Then print the 'secret message'
EOF


rm -f $tmp
# End of script loading object