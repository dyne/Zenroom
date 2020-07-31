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
      "myNumber_4":123456789,
      "myNumber_5":123456789,	  
	  "myString_1":"Hello World!",
	  "myString_2":"Hello World!",
	  "myString_3":"Hello World!",
	  "myString_4":"Hello World!",
	  "myString_5":"Hello World!",
      "myHex_1": "68747470733a2f2f6769746875622e636f6d2f64796e652f5a656e726f6f6d",
      "myHex_2": "68747470733a2f2f6769746875622e636f6d2f64796e652f5a656e726f6f6d",
      "myHex_3": "68747470733a2f2f6769746875622e636f6d2f64796e652f5a656e726f6f6d",
	  "myHex_4": "68747470733a2f2f6769746875622e636f6d2f64796e652f5a656e726f6f6d",
	  "myHex_5": "68747470733a2f2f6769746875622e636f6d2f64796e652f5a656e726f6f6d",
      "myBase64_1": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbQ==",
      "myBase64_2": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbQ==",
      "myBase64_3": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbQ==",
	  "myBase64_4": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbQ==",
	  "myBase64_5": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbQ==",
	  "myUrl64_1": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbS8",
  	  "myUrl64_2": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbS8",
  	  "myUrl64_3": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbS8",
  	  "myUrl64_4": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbS8",
  	  "myUrl64_5": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbS8",
	  "myUrl64_6": "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbS8",
	  "myBinary_1": "01011010011001010110111001110010011011110110111101101101",
	  "myBinary_2": "01011010011001010110111001110010011011110110111101101101",
	  "myBinary_3": "01011010011001010110111001110010011011110110111101101101",
	  "myBinary_4": "01011010011001010110111001110010011011110110111101101101",
	  "myBinary_5": "01011010011001010110111001110010011011110110111101101101",
	  
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
	   "myStringArray_4":[
         "Hello World! --- 1",
		 "Hello World! --- 2",
		 "Hello World! --- 3"
      ],
	   "myStringArray_5":[
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
	  "myNumberArray_4":[
         "123",
		 "456",
		 "1234.5678"
      ],
	  "myNumberArray_5":[
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
Given I have a 'string array' named 'myStringArray_4'  
Given I have a 'string array' named 'myStringArray_5'
Given I have a 'number array' named 'myNumberArray_1'
Given I have a 'number array' named 'myNumberArray_2'
Given I have a 'number array' named 'myNumberArray_3'
Given I have a 'number array' named 'myNumberArray_4'
Given I have a 'number array' named 'myNumberArray_5'
# Load Numbers
Given I have a 'number' named 'myNumber_1'
Given I have a 'number' named 'myNumber_2'
Given I have a 'number' named 'myNumber_3' 
Given I have a 'number' named 'myNumber_4'
Given I have a 'number' named 'myNumber_5' 
# Load Strings
Given I have a 'string' named 'myString_1' 
Given I have a 'string' named 'myString_2' 
Given I have a 'string' named 'myString_3'  
Given I have a 'string' named 'myString_4' 
Given I have a 'string' named 'myString_5'  
# Different data types
Given I have an 'hex' named 'myHex_1' 
Given I have an 'hex' named 'myHex_2' 
Given I have an 'hex' named 'myHex_3' 
Given I have an 'hex' named 'myHex_4' 
Given I have an 'hex' named 'myHex_5' 
Given I have a  'base64' named 'myBase64_1'
Given I have a  'base64' named 'myBase64_2'
Given I have a  'base64' named 'myBase64_3'
Given I have a  'base64' named 'myBase64_4'
Given I have a  'base64' named 'myBase64_5'
Given I have a  'binary' named 'myBinary_1'
Given I have a  'binary' named 'myBinary_2'
Given I have a  'binary' named 'myBinary_3'
Given I have a  'binary' named 'myBinary_4'
Given I have a  'binary' named 'myBinary_5'
Given I have an 'url64' named 'myUrl64_1'
Given I have an 'url64' named 'myUrl64_2'
Given I have an 'url64' named 'myUrl64_3'
Given I have an 'url64' named 'myUrl64_4'
Given I have an 'url64' named 'myUrl64_5'
Given I have an 'url64' named 'myUrl64_6'
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

# (0): default
# 1: string
# 2: number
# 3: base64
# 4: bin
# 5: hex

Then print 'myString_2' as 'number' 
Then print 'myString_3' as 'base64' 
Then print 'myString_4' as 'bin' 
Then print 'myString_5' as 'hex' 

Then print 'myNumber_2' as 'string' 
Then print 'myNumber_3' as 'base64'
Then print 'myNumber_4' as 'bin' 
Then print 'myNumber_5' as 'hex'

Then print 'myStringArray_2' as 'number' 
Then print 'myStringArray_3' as 'base64' 
Then print 'myStringArray_4' as 'bin' 
Then print 'myStringArray_5' as 'hex' 

Then print 'myNumberArray_2' as 'string' 
Then print 'myNumberArray_3' as 'base64' 
Then print 'myNumberArray_4' as 'bin' 
Then print 'myNumberArray_5' as 'hex' 

Then print 'myBinary_2' as 'string' 
Then print 'myBinary_3' as 'number' 
Then print 'myBinary_4' as 'base64' 
Then print 'myBinary_5' as 'hex' 

Then print 'myBase64_2' as 'string'
Then print 'myBase64_3' as 'number' 
Then print 'myBase64_4' as 'bin'
Then print 'myBase64_5' as 'hex' 

Then print 'myHex_2' as 'string'
Then print 'myHex_3' as 'number' 
Then print 'myHex_4' as 'base64'
Then print 'myHex_5' as 'bin' 

Then print 'myUrl64_2' as 'string'
Then print 'myUrl64_3' as 'number'
Then print 'myUrl64_4' as 'base64'
Then print 'myUrl64_5' as 'bin'
Then print 'myUrl64_6' as 'hex'




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


