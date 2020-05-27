
Z=zenroom
n=0
tmp=`mktemp`


cat <<EOF  > $tmp
{
   "myFirstObject":{
      "myFirstNumber":1,
	  "myFirstString":"Hello World!",
      "myFirstHex": "616e7976616c7565",
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
cat $tmp > myTripleNestedObject.json


cat <<EOF | tee givenLoadTripleNestedObject.zen | $Z -z -a myTripleNestedObject.json | tee givenTripleNestedObjectOutput.json
Given I have a 'string array' named 'myFirstArray'   
Given I have a 'string array' named 'mySecondArray' inside 'mySecondObject'
Given I have a 'myThirdArray' inside 'myThirdObject' 
Given I have a 'myFourthArray'  
Given I have a 'number' named 'myFirstNumber'
Given I have a 'string' named 'myFirstString' 
Given I have a 'hex' named 'myFirstHex'
Then print the 'myFirstString' as 'string'
Then print the 'myFirstHex' as 'hex'
Then print the 'myFirstNumber' as 'number'
EOF





