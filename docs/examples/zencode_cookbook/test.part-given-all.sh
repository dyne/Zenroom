#!/usr/bin/env bash

####################
# common script init
# if ! test -r ../utils.sh; then
#  echo "run executable from its own directory: $0"; exit 1; fi
# . ../utils.sh
Z="detect_zenroom_path detect_zenroom_conf"
####################

cat <<EOF  > arr.json
{
   "myFirstObject":{
      "myFirstNumber":1,
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
      "mySecondArray":[
         "anotherString1",
         "anotherString2"
      ]
   },
   "myThirdObject":{
      "myThirdNumber":3,
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
      ]
   }
}
EOF


cat <<EOF | zenroom givenFullList.zen -a arr.json
Given I have a 'string array' named 'myFirstArray'   
Given I have a 'string array' named 'myFirstArray'   
Given I have an 'array' named 'myFirstArray'      
Given I have a 'string array' named 'mySecondArray' inside 'mySecondObject'
Given I have a 'myThirdArray' inside 'myThirdObject' 
Given I have a 'string array' named 'myFourthArray'
# Given I have an 'array' named 'myFirstObject'
# Numbers
Given I have a 'number' named 'myFirstNumber'
# Given I have a 'myFirstNumber'
Given I have a 'number' named 'myFirstNumber' inside 'myFirstObject' 
# Strings
Given I have a 'string' named 'myFirstString' 
Given I have a 'string' named 'myFirstString' inside 'myFirstObject' 
# Different data types
Given I have an 'hex' named 'myFirstHex'
Given I have a  'base64' named 'myFirstBase64'
Given I have a  'binary' named 'myFirstBinary'
Given I have an 'url64' named 'myFirstUrl64'
# Then print the 'myFirstString' as 'string'
# Then print the 'myFirstHex' as 'hex'
# Then print the 'myFirstUrl64' as 'hex'
Then print all data
# BROKEN Then print the 'myFirstNumber' as 'number'
EOF