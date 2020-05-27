
Z=zenroom
n=0
tmp=`mktemp`


cat <<EOF  > $tmp
  {
      "myNumber":12345,
      "myString":"Hello World!",
      "myArray":[
         "String-1-one",
         "String-2-two",
         "String-3-three",
		 "String-4-four",
		 "String-5-five"
      ]
 }
EOF

cat <<EOF | tee givenLoadFlatObject.zen | $Z -z -a $tmp | tee givenLoadFlatObjectOutput.json
Given I have a valid 'string array' named 'myArray'   
# Given I have a valid 'string' in 'myString'  # Questo è ancora rotto
Given I have a valid number in 'myNumber'
When I randomize the 'myArray' array
Then print all data
EOF