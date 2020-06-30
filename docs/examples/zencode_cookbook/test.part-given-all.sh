#!/usr/bin/env bash

####################
# common script init
# if ! test -r ../utils.sh; then
#  echo "run executable from its own directory: $0"; exit 1; fi
# . ../utils.sh
Z=zenroom
####################

n=0
tmp=`mktemp`

echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1


# This loads an object
cat <<EOF  > $tmp 
{
   "myFirstObject":{
      "myFirstNumber":11223344,
      "myFirstString":"Hello World!",
      "myFirstArray":[
         "String1",
         "String2",
         "String3",
         "String4"
      ]
   },
   "mySecondObject":{
      "mySecondNumber":1234567890,
	  "mySecondString":"Oh, hello again!",
      "mySecondArray":[
         "anotherString1",
         "anotherString2",
         "anotherString3",
         "anotherString4"
      ]      
   },
   "Alice":{
      "keypair":{
         "private_key":"DbjRMCC7fykuUaqYDX_cy_Zs7J0ZC0y9VxBLRcfwIJ63MAZtW4fJ4IxxdUdLNy0ye0-qf0IlRZI",
         "public_key":"BE39Wu7AXSzSplMd37VhCB094xHqCgvZxMhgaTA7B0Xz4mEIZmoO2FmWiokVXuJ0O9jH9AQD4UBkXiCU4gzYrLQc9VpfB4Qr8rz6jj_UYvC77FiLGc-0jsE4mQfpgLoOspBGcfNyiS8Y50hl8zthKjo"
      }
   }
}
EOF

# cat $tmp > temp.json





cat <<EOF | tee temp.zen | $Z -z -a $tmp | tee temp.json
Scenario 'simple': let us load some stuff cause it is fun!
#Rule input base64
Given I am 'Alice'
And I have my  'keypair'
And I have a 'string array' named 'myFirstArray' inside 'myFirstObject' 
And I have a 'string array' named 'mySecondArray' inside 'mySecondObject' 
and debug
Then print all data
and debug
Then print the 'myFirstArray' as 'string'
Then print the 'mySecondArray' as 'string'
EOF




rm -f $tmp
