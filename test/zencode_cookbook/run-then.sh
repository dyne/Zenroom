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
  "myEightEqualString":"These string is equal to another one.",
  "myNinthEqualString":"These string is equal to another one.",
  "myFourthNumber":3,
  "myTenthString":"oneExtraString1"
  
   },
   
   "Alice":{
	   "keypair":{
		  "private_key":"L9pogbrN_oU6BOt2U37-hK5c4-McvHU-SNhT0P7QDsI",
		  "public_key":"BPg1CFFH1eCsq3HHGWo3dCDG4QPA9VHxrF30y8MHtar-JLcXOQvjq81yXydcR5KWaYnxNIgzUVNtqTh4s2QsXNI"
	   }
	}
   
}
EOF
cat $tmp > ../../docs/examples/zencode_cookbook/myLargeNestedObjectThen.json

cat <<EOF | zexe ../../docs/examples/zencode_cookbook/thenFullList.zen -z -a $tmp | jq | tee ../../docs/examples/zencode_cookbook/thenOutputFullList.json
# rule input encoding base64
Scenario 'ecdh': Create the keypair
Given I am 'Alice'
Given I have my 'keypair' 
# Load Arrays
Given I have a 'string array' named 'myFirstArray'   
Given I have a 'string array' named 'mySecondArray' inside 'mySecondObject'
Given I have a 'string array' named 'myThirdArray' inside 'myThirdObject' 
Given I have a 'string array' named 'myFourthArray'
# Load Numbers
Given I have a 'number' named 'myFirstNumber' in 'myFirstObject'
Given I have a 'number' named 'mySecondNumber' in 'mySecondObject'
Given I have a 'number' named 'myFourthNumber'
Given I have a 'number' named 'myThirdNumber'
# Load Strings
Given I have a 'string' named 'myFirstString' in 'myFirstObject'
Given I have a 'string' named 'myFirstString' inside 'myFirstObject' 
Given I have a 'string' named 'mySecondString'
Given I have a 'string' named 'myThirdString'
Given I have a 'string' named 'myFourthString'
Given I have a 'string' named 'myFifthString'
Given I have a 'string' named 'mySixthString'
Given I have a 'string' named 'mySeventhString'
Given I have a 'string' named 'myTenthString'
# Different data types
Given I have an 'hex' named 'myFirstHex' 
Given I have an 'hex' named 'myFirstHex' inside 'myFirstObject' 
Given I have a  'base64' named 'myFirstBase64'
Given I have a  'binary' named 'myFirstBinary'
Given I have an 'url64' named 'myFirstUrl64'
and debug
#
# END of loading stuff
#
When I insert the 'myFirstString' in 'myFirstArray'
When I pick the random object in 'myFirstArray'
When I randomize the 'myFourthArray' array
# FORSE NON ROTTO sotto: 
# When I remove the 'oneMoreString1' from 'myThirdArray'
When I rename the 'myThirdArray' to 'myJustRenamedArray'
#  When I set 'nameOfVariable' to 'value' as 'number | string | based64 ... '
When I set 'myFirstString' to 'call me The Pink Panther!' as 'string'
When I set 'myFirstNumber' to '42' as 'number'
# ROTTO sotto con tutte le basi
# When I set 'mySecondNumber' to '42' base '16'
# When I set 'myThirdNumber' to '42' base '2 | 10 | 16'
When I split the leftmost '3' bytes of 'myFirstString'
# ROTTO sotto:  [W]  .  ERR Overwrite error: rightmost   -[W] [!] Overwrite error: rightmost
# When I split the rightmost '3' bytes of 'myThirdString'
When I verify 'myEightEqualString' is equal to 'myNinthEqualString'         
When I write number '10' in 'nameOfFirstNewVariable'
When I write string 'pippo' in 'nameOfSecondNewVariable'
When number 'myFourthNumber' is less or equal than 'myThirdNumber'
# The comparison below happens after we changed value to 'myFirstNumber'
When number 'myThirdNumber' is less than 'myFirstNumber'
When number 'myThirdNumber' is more or equal than 'mySecondNumber'
When number 'myThirdNumber' is more than 'mySecondNumber'
When the 'myTenthString' is found in 'myFourthArray'
When the 'myFirstString' is not found in 'myFourthArray'
When the 'myFirstNumber' is not found in 'myFourthArray'
# Begin the Then phase:
Then print my data 
Then print 'myFirstNumber' 
Then print 'mySecondNumber' as 'hex' 
Then print 'myThirdString' as 'string' in 'myThirdObject' 
Then print data 
# Then print data as 'hex' 
Then print my 'keypair' 
# Then print my 'keypair' as 'bin' 
# Then print my data as 'string' 
Then print the 'myFirstArray' 
Then print 'leftmost' as 'string'
Then print 'myFirstString' as 'string'
# Da Rimuovere, doppione: Then print the 'mySecondArray' as 'base64' 
# Da Rimuovere, doppione: Then print the '' as '' in ''
# Da Rimuovere, doppione: Then print the '' in '' 
EOF

rm -f $tmp




