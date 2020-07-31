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
tmpInput=`mktemp`
tmpOutput=`mktemp`

tmpGiven=`mktemp`
tmpThen1=`mktemp`	
tmpZen1="${tmpGiven} ${tmpThen1}"
tmpThen2=`mktemp`	
tmpZen2="${tmpGiven} ${tmpThen2}"
tmpThen3=`mktemp`	
tmpZen3="${tmpGiven} ${tmpThen3}"
tmpThen4=`mktemp`	
tmpZen4="${tmpGiven} ${tmpThen4}"



cat <<EOF  > $tmpInput
{
   "myObject":{
      "myNumber_1":123456789,
      "myNumber_2":123456789,
      "myNumber_3":123456789,	  
	  "myString_1":"Hello World!",
	  "myString_2":"Hello World!",
	  "myString_3":"Hello World!",
      "myHex_1": "68747470733a2f2f6769746875622e636f6d2f64796e652f5a656e726f6f6d",
      "myHex_2": "68747470733a2f2f6769746875622e636f6d2f64796e652f5a656e726f6f6d",
      "myHex_3": "68747470733a2f2f6769746875622e636f6d2f64796e652f5a656e726f6f6d",
      "myBase64_1": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbQ==",
      "myBase64_2": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbQ==",
      "myBase64_3": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbQ==",
	  "myUrl64": "SGVsbG8gV29ybGQh",
	  "myBinary_1": "01001000011010011000100101001010010010101",
	  "myBinary_2": "01001000011010011000100101001010010010101",
	  "myBinary_3": "01001000011010011000100101001010010010101",
	  "myStringArray_1":[
         "Hello World! --- 1",
		 "Hello World! --- 2",
		 "Hello World! --- 3"
      ],
	  "myStringArray_2":[
         "Hello World! --- 1",
		 "Hello World! --- 2",
		 "Hello World! --- 3"
      ],
	   "myStringArray_3":[
         "Hello World! --- 1",
		 "Hello World! --- 2",
		 "Hello World! --- 3"
      ],
	  "myNumberArray_1":[
         "123",
		 "456",
		 "1234.5678"
      ],
	  "myNumberArray_2":[
         "123",
		 "456",
		 "1234.5678"
      ],
	  "myNumberArray_3":[
         "123",
		 "456",
		 "1234.5678"
      ],	  
   },
   
   "Alice":{
      "keypair":{
         "private_key":"AxLMXkey00i2BD675vpMQ8WhP/CwEfmdRr+BtpuJ2rM=",
         "public_key":"BDDuiMyAjIu8tE3pGSccJcwLYFGWvo3zUAyazLgTlZyEYOePoj+/UnpMwV8liM8mDobgd/2ydKhS5kLiuOOW6xw="
      }
   }
   
}
EOF
cat $tmpInput > ../../docs/examples/zencode_cookbook/myLargeNestedObjectThen.json



cat <<EOF  > $tmpGiven
# rule input encoding base64
Scenario 'ecdh': Create the keypair
Given I am 'Alice'
Given I have my 'keypair' 
# Load Arrays
Given I have a 'string array' named 'myStringArray_1'
Given I have a 'string array' named 'myStringArray_2'  
Given I have a 'string array' named 'myStringArray_3'  
Given I have a 'number array' named 'myNumberArray_1'
Given I have a 'number array' named 'myNumberArray_2'
Given I have a 'number array' named 'myNumberArray_3'
# Load Numbers
Given I have a 'number' named 'myNumber_1'
Given I have a 'number' named 'myNumber_2'
Given I have a 'number' named 'myNumber_3' 
# Load Strings
Given I have a 'string' named 'myString_1' 
Given I have a 'string' named 'myString_2' 
Given I have a 'string' named 'myString_3'  
# Different data types
Given I have an 'hex' named 'myHex_1' 
Given I have an 'hex' named 'myHex_2' 
Given I have an 'hex' named 'myHex_3' 
Given I have a  'base64' named 'myBase64_1'
Given I have a  'base64' named 'myBase64_2'
Given I have a  'base64' named 'myBase64_3'
Given I have a  'binary' named 'myBinary_1'
Given I have a  'binary' named 'myBinary_2'
Given I have a  'binary' named 'myBinary_3'
Given I have an 'url64' named 'myUrl64'
EOF
cat $tmpGiven > ../../docs/examples/zencode_cookbook/thenCompleteScriptGiven.zen



echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1






cat <<EOF  > $tmpThen1
Then print all data
Then print 'myString_2' as 'bin' 
Then print 'myString_3' as 'hex' 

Then print 'myNumber_2' as 'base64' 
Then print 'myNumber_3' as 'bin'

Then print 'myStringArray_2' as 'bin' 
Then print 'myStringArray_3' as 'hex' 

Then print 'myNumberArray_2' as 'base64' 
Then print 'myNumberArray_2' as 'bin' 

Then print 'myBinary_2' as 'hex' 
Then print 'myBinary_3' as 'base64' 

Then print 'myBase64_2' as 'string'
Then print 'myBase64_3' as 'bin' 

Then print 'myHex_2' as 'string'
Then print 'myHex_3' as 'base64' 





EOF




cat $tmpThen1 > ../../docs/examples/zencode_cookbook/thenCompleteScriptPart1.zen


cat $tmpZen1 | zexe ../../docs/examples/zencode_cookbook/temp.zen -z -a $tmpInput | jq | tee ../../docs/examples/zencode_cookbook/thenCompleteOutputPart1.json





echo "                                                "
echo "------------------------------------------------"
echo "               Script number $n                 "
echo "------------------------------------------------"
echo "                                                "
let n=n+1


cat <<EOF  > $tmpThen2

# Then print 'myNumber_3' as 'string'
# Then print 'myNumber_3' as 'hex'
# Then print my data 
# Then print data as 'hex' 
# Then print data as 'number'
# Then print my 'keypair' 
# Then print my 'keypair' as 'bin' 
# Then print my data as 'string' 
# Then print the 'myStringArray' 
# Then print 'leftmost' as 'string'
# Then print 'myString' as 'string'
# Then print 'myNumber_3' as 'hex'

 
# Da Rimuovere, doppi_1: Then print the 'mySecondArray' as 'base64' 
# Da Rimuovere, doppi_1: Then print the '' as '' in ''
# Da Rimuovere, doppi_1: Then print the '' in '' 


EOF


rm -f $tmpInput
rm -f $tmpGiven
rm -f $tmpThen1
rm -f $tmpZen1
rm -f $tmpThen2
rm -f $tmpZen2
rm -f $tmpThen3
rm -f $tmpZen3
rm -f $tmpThen4
rm -f $tmpZen4


