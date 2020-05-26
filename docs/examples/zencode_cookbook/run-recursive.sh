
Z=zenroom
n=0
tmp=`mktemp`


# This loads an object

# This loads an object
cat <<EOF  > $tmp
{
   "myFirstObject":{
      "myNumber":11223344,
      "myString":"Hello World!",
      "myArray":[
         "String1",
         "String2",
         "String3",
         "String4"
      ],
      "mySecondObject":{
         "myString2":"Oh, hello again!",
         "myArray2":[
            "anotherString1",
            "anotherString2",
            "anotherString3",
            "anotherString4"
         ],
         "myNumber2":1234567890
      }
   },
   "Bob":{
      "keypair":{
         "private_key":"DbjRMCC7fykuUaqYDX_cy_Zs7J0ZC0y9VxBLRcfwIJ63MAZtW4fJ4IxxdUdLNy0ye0-qf0IlRZI",
         "public_key":"BE39Wu7AXSzSplMd37VhCB094xHqCgvZxMhgaTA7B0Xz4mEIZmoO2FmWiokVXuJ0O9jH9AQD4UBkXiCU4gzYrLQc9VpfB4Qr8rz6jj_UYvC77FiLGc-0jsE4mQfpgLoOspBGcfNyiS8Y50hl8zthKjo"
      }
   }
}
EOF

cat <<EOF | tee alice_keypub.zen | $Z -z -k alice_keypair.json -a $tmp | tee givenLongOutput.json
Scenario 'simple'
Given I am 'Andrea'
Given I have a valid 'keypair' from 'Alice'
#-- Given the 'nomeOggetto?' is valid
#ROTTO: Given the 'myObject' is valid 
Given I have a 'myArray' in 'myObject'
Given I have a valid 'array string' named 'myArray' inside 'myFirstObject'
Given I have a valid 'array string' named 'myArray2' inside 'myFirstObject' inside 'mySecondObject'
Given I have a valid 'array string' named 'myArray2' inside 'mySecondObject' inside 'myFirstObject' 
# Given I have a valid 'number' named 'myNumber' inside 'myObject'
And debug
Then print all data
EOF