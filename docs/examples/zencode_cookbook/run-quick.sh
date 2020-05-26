
Z=zenroom
n=0
tmp=`mktemp`


cat <<EOF  > $tmp
{
   "myFirstObject":{
      "myFirstNumber":1,
      "myFirstArray":[
         "String1"
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
Given I have a valid 'array string' named 'myFirstArray'   
Given I have a valid 'array string' named 'mySecondArray' inside 'mySecondObject'
And I have a 'myThirdArray' inside 'myThirdObject' 
And I have a 'myFourthArray'  
Then print all data
EOF
