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



echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1



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
		 "String2"
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
         "oneMoreString3"
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
  
   },
   
   "Alice":{
      "keypair":{
         "private_key":"PRHwDEZN5XZAPRB2fi33caOCrguLVvWR015SKfpOjzomzOu0bhIYp-2xDpj-OEFb6euu86xnCd4",
         "public_key":"BGDPKUMA0tUZV_I_6M73hPkeph-NJeaabbFIacQ-qbDF5dmtikm8wse641yPbN4ui45j97dz9wNw0oqEUcJyuCrDJnzQT6Os6ajjW1Nu9DdzJbqBucvNUA6jctbCfrohqxNXO88nyG14G4CIrVxtDzs"
      }
	}
   
}
EOF
cat $tmp > ../../docs/examples/zencode_cookbook/myLargeNestedObjectWhen1.json

cat <<EOF | zexe ../../docs/examples/zencode_cookbook/whenFullListPart1.zen -z -a $tmp | tee ../../docs/examples/zencode_cookbook/givenFullListPart1.json
# rule input encoding base64
# Load Arrays
Scenario 'simple': Create the keypair
# Given that I am known as 'Alice'
Given I have a 'keypair' from 'Alice'
Given I have a 'string array' named 'myFirstArray'   
Given I have a 'string array' named 'mySecondArray' inside 'mySecondObject'
Given I have a 'myThirdArray' inside 'myThirdObject' 
Given I have a 'string array' named 'myFourthArray'
# Load Numbers
Given I have a 'number' named 'myFirstNumber' in 'myFirstObject'
Given I have a 'number' named 'mySecondNumber' in 'mySecondObject'
# Load Strings
Given I have a 'string' named 'myFirstString' in 'myFirstObject'
Given I have a 'string' named 'myFirstString' inside 'myFirstObject' 
Given I have a 'string' named 'mySecondString'
Given I have a 'string' named 'myThirdString'
Given I have a 'string' named 'myFourthString'
Given I have a 'string' named 'myFifthString'
Given I have a 'string' named 'mySixthString'
Given I have a 'string' named 'mySeventhString'
# Different data types
Given I have an 'hex' named 'myFirstHex' 
Given I have an 'hex' named 'myFirstHex' inside 'myFirstObject' 
Given I have a  'base64' named 'myFirstBase64'
Given I have a  'binary' named 'myFirstBinary'
Given I have an 'url64' named 'myFirstUrl64'
and debug
# END of loading stuff
# ROTTO sotto: [W]  .  ERR Object not found: mySecondObject
# [W] [!] Object not found: mySecondObject
# When 'mySecondNumber' in 'mySecondObject' is more than 'myFirstNumber' in 'myFirstObject'
When I append 'myFirstString' to 'mySecondString' as 'string'
When I append string 'myThirdString' to 'myFourthString'
When I create a random 'newRandomObject'
#   da fare:    quello sopra dovrebbe avere "the" invece di "a" per consistenza   
# ROTTO qui sotto: [W] [!] [string "zencode_when"]:175: Unknown aggregation for type: zenroom.octet - ma ce lo aspettavamo questo ritorna errore se non è un array di ECP oppure number, ECP2, se nell'array ci sono degli ECP/numeri li somma, in un nuova variabile... come caco un array di ecp?
# When I create the aggregation of 'myFourthArray'
When I create the array of '16' random curve points
When I create the array of '32' random objects
When I create the array of '64' random objects of '512' bits
When I create the hash of 'myFifthString'
# this accepts sha256 or sha512 as hash types
When I create the hash of 'mySixthString' using 'sha256'
When I create the hash of 'mySeventhString' using 'sha512'
# The following accepts ecp or ecp2 as type of point, what it does is generating public keys from secret key
When I create the hash to point 'ecp' of each object in 'myFourthArray'
When I create the hash to point 'ecp2' of each object in 'myFirstArray'        
When I create the random object of '16' bits
Then print all data
EOF

rm -f $tmp





