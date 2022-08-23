load ../bats_setup
load ../bats_zencode
SUBDOC=cookbook_given

@test "flat object and verbose out" {
    cat <<EOF | save myFlatObject.json
{ 
      "myNumber":12345,
      "myString":"Hello World!",
      "myFiveStrings":[
         "String-1-one",
         "String-2-two",
         "String-3-three",
	 "String-4-four",
	 "String-5-five"
      ]
}
EOF
    cat <<EOF | zexe givenLoadFlatObject.zen myFlatObject.json
Given I have a 'string' named 'myString'  
Given I have a 'number' named 'myNumber'
Then print all data
EOF
    save_output givenLoadFlatObjectOutput.json
    cat <<EOF | zexe givenLoadNumber.zen myFlatObject.json
Given I have a 'number' named 'myNumber'
Then print all data
EOF
    save_output givenLoadNumberOutput.json
    cat <<EOF | zexe givenLoadArrayDebug.zen myFlatObject.json
Given I have a  'string array' named 'myFiveStrings' 
Given debug 
When I randomize the 'myFiveStrings' array
Then print all data
EOF
    save_output givenDebugOutput.json
    cat <<EOF | zexe givenLoadArrayDebugVerbose.zen myFlatObject.json
Given debug
Given I have a 'string array' named 'myFiveStrings'
Given debug
Given I have a 'string' named 'myString' 
Given debug
Given I have a 'number' named 'myNumber'
Given debug 
When I randomize the 'myFiveStrings' array
When debug
Then print all data
Then debug
EOF
    save_output givenDebugOutputVerbose.json
}

@test "load arrays" {
    cat <<EOF | save givenArraysLoadInput.json
{
      "myStringArray":[
         "String-1-one",
         "String-2-two",
         "String-3-three"
      ],
	  "myNumberArray":[
         "123",
         "45678",
		 "123.456"
      ],
	  "myBinArray":[
         "010110101001001",
         "101100010100101",
		 "000100101001010"
      ],
	  "myHexArray":[
         "27e4a0444f4f6473e00b6d1fa21f25fd",
         "80e3351b9b310659567332450112c902",
		 "d1f500b8af6d1f8f4ef2ce933ee5de23"
      ],
	  "myBase64Array":[
         "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbS1BbmRyb2lkLWFwcA==",
         "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvWmVucm9vbQ==",
		 "aHR0cHM6Ly9naXRodWIuY29tL2R5bmUvcmVzdHJvb20tbXc="
      ],
	  "myECPArray":[
        "Awz+ogtsf9xRn7hIw/6B1xvwoBNRgNFJOPYqSdPd+OAHXgDVuLWuKEvIsynbdWBJIw==",
		"A05tQgcTdT7+OAvfWZMIYI9G2owWBBR3/KqRBL/KPh2rPknbW1FBbRcee3P+7hpOoQ==",
		"AzijxD9GRztPcRtEXjdpXIPTzzmv0dvCdQNcmToC09pOw1ZLg/eAHdgEFV6oWhionQ==",
		"Ak8k6etvJjUPfSTFZFtQiRKaX1gIs3lUMzti+BQZW1XhUl8OOAOa/LrCRWyV1fpLwg=="
	  ],
	"myECP2Array": [	"QTQcWNiZgxQSyk7z0Zuy7GSF7kfrvahtaKFfgWsQeZurOpSSEiA81amccUi6S0LEIozhraN8aL+S8X7cPoqg7s1ftnC/S/MH3kwRwJ0jscACVvf+1Y/XEtngBZ0g1frPBNe6CVuaoQiXuda0g5t4mZzItGt6hgtsn7f/iHyO+Iwe1+9vUEzfysxNmFVjEq8ADEeFLqnltHbrI2H3vVZTc5g5IWxAJF00wE7n0kKb4AF59bqxbBN62dIqmVEodMDH",	"Anq3ieAxAEGfNzzQYUuQD1NPZuaojS6Fd3/nr3GFKqTPJmdEFTYamiGAN5nN5N5mMBMxE2sub/I39sqFKjDF22Iu/jZWsT+grD5E3PDuiaR4Ugr7V/WOdY3iiY5tfZm4AlWiNYSVR3KIcZe81E5q/GucEvAeC0VuGDgrTvTZ3/e7qxSxsi6aoqlLl2dD3AjABVQHfdY0BZ4gL1xYCmF7TYPs6LNeVb1+9buFZk3I7mskgGjrzgdKgm7IH3rL3Hsl",	"SQn5DHPbQTPmxfQirsxZ28uJu6PKv54UDXUzAqqUliAmc52+yFhwgeJpBWwpGfUPP04m8eNUo0hIO3EA2MKDaVxc78HS4PM2nm8ngyX/fTcg1WheaNIkrF4yycGeIEByB3NsYm36CvrJmfKQMtbON0yMpjD6vTfG6C82xaF+vRSieXgXDqh0e3e0deWkWo2vAQht5aqMDX0hGub01gk6tv/IeboIfr3fva80g4XPoiyfI23VZpRP65LdjnAS1seQ", 	"FcLlzyRlrLBCQAEKs6d+WCtV4awcogoGiGlWKStiuPR+1ms4ZBGKmwW+bniPcAQ3PEUqLBsy+SGmWA0IdkeGRyoJA/gsjZFYr8s8L5ZBd+zIk6ycjuK1fINyfXif3efmR0K2gjSQvptlzmggTr0SLoA3qO1vRZ2ZjPJLa4ehyhZaqx3rxqNWSxK/WzviPHfsAnYQVIOmJGsMl8lGpaJdHWh7XiMDUqJLu2B9OfE4O4pTE8eARR10oSaaNovDzkF+"
	],
	"myBIGArray":[
	"7dcd7392a9dea33b145a03279af78b1adf1c0549f5121ec28dd3dc136c0ca693",
	"8bd877e84538380c455448239f04d817e9657ecf2786442f11c98248ca8178a2",
	"d2cfc1b31b087d0d7137e3f5d45fc6a9cf33025fdba6f9cad40a04e36b420763",
	"554e2fcf3a4a1d872446febb81a91d910e772a4cf4c5e36a3569b159cb5ff439"
      ]	  
}
EOF
    cat <<EOF | zexe givenArraysLoad.zen givenArraysLoadInput.json
Given I have a 'string array' named 'myStringArray'
Given I have a 'number array' named 'myNumberArray'
Given I have a 'bin array' named 'myBinArray'
Given I have a 'hex array' named 'myHexArray'
Given I have a 'base64 array' named 'myBase64Array'
Given I have a 'base64 array' named 'myECPArray'
Given I have a 'base64 array' named 'myBIGArray'
Given I have a 'base64 array' named 'myECP2Array'
Then print all data
EOF
    save_output givenArraysLoadOutput.json
}

@test "loads a complex object" {
    cat <<EOF | save myNestedRepetitveObject.json
{
   "myFirstObject":{
      "myNumber":11223344,
      "myString":"Hello World!",
      "myStringArray":[
         "String1",
         "String2",
         "String3",
         "String4"
      ]
   },
   "mySecondObject":{
      "mySecondNumber":1234567890,
	  "mySecondString":"Oh, hello again!",
      "myStringArray":[
         "anotherString1",
         "anotherString2",
         "anotherString3",
         "anotherString4"
      ]
   },
	 "Alice":{
		  "keyring":{
			 "ecdh":"AxLMXkey00i2BD675vpMQ8WhP/CwEfmdRr+BtpuJ2rM="
		  }
	   }
   
   
   
}
EOF
    cat <<EOF | zexe givenLoadRepetitveObject.zen myNestedRepetitveObject.json
Scenario 'ecdh': let us load some stuff cause it is fun!
Given I am 'Alice'
And I have my 'keyring'
And I have a 'string array' named 'myStringArray' inside 'myFirstObject' 
#
# # # Uncomment the line below to enjoy the fireworks
# And I have a 'string array' named 'myStringArray' inside 'mySecondObject' 
Then print all data
EOF
    save_output givenLoadRepetitveObjectOutput.json
}


@test "loads another complex object" {
    cat <<EOF | save myNestedObject.json
{
	"Alice":{
      "keyring":{
         "ecdh":"AxLMXkey00i2BD675vpMQ8WhP/CwEfmdRr+BtpuJ2rM="
      },
	  "myFirstNumber":87654321,
      "myFirstString":"Hello World!",
      "myFirstArray":[
         "Hello World! N.1",
         "Hello World! N.2",
         "Hello World! N.3",
         "Hello World! N.4"
      ]
   },
	"theSecondObject":{
      "theSecondNumber":12345678,
	  "theSecondString":"Oh, hello again!",
      "theSecondArray":[
         "123",
         "4.56",
         "123.45678",
         "12345678"
      ]      
   }   
}
EOF
    cat <<EOF | zexe givenLoadNestedObject.zen myNestedObject.json
Scenario 'ecdh': let us load some stuff cause it is fun!
# 
# Here I am stating who I am:
Given I am 'Alice'
#
# Here I load the data from the JSON object having my name:
And I have my 'keyring'
And I have my 'string' named 'myFirstString'
And I have my 'number' named 'myFirstNumber'
#
# Here I load data from a different JSON object:
And I have a 'string' named 'theSecondString' inside 'theSecondObject'
And I have a 'number' named 'theSecondNumber' inside 'theSecondObject' 
Then print all data
EOF
    save_output givenLoadNestedObjectOutput.json
}

@test "load a triple nested object" {
    cat <<EOF | save myTripleNestedObject.json
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
    cat <<EOF | zexe givenLoadTripleNestedObject.zen myTripleNestedObject.json
# Given I have a 'string array' named 'myFirstArray'   
Given I have a 'string array' named 'mySecondArray' inside 'mySecondObject'
Given I have a 'string array' named 'myThirdArray' inside 'myThirdObject' 
Given I have a 'string array' named  'myFourthArray' inside 'myFourthObject'   
Given I have a 'number' named 'myFirstNumber' inside 'myFirstObject'
Given I have a 'string' named 'myFirstString' inside 'myFirstObject'
Given I have a 'hex' named 'myFirstHex' inside 'myFirstObject'
Then print all data
EOF
    save_output givenTripleNestedObjectOutput.json
}

@test "load a large and complex nested object" {
    cat <<EOF | save myLargeNestedObject.json
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
    cat <<EOF | zexe givenFullList.zen myLargeNestedObject.json
# Load Arrays
Given I have a 'string array' named 'myFirstArray' inside 'myFirstObject' 
# Remember that you can load arrays of other types, just 
# like writing the encoding before the word array, for example 
# you could load a 'number array' or 'base64 array'
# 
# Load Numbers
Given I have a 'number' named 'mySecondNumber' inside 'mySecondObject'
# Load Strings
Given I have a 'string' named 'myFirstString' inside 'myFirstObject' 
# Different data types
Given I have an 'hex' named 'myFirstHex' inside 'myFirstObject' 
Given I have a  'base64' named 'myFirstBase64' inside 'myFirstObject' 
Given I have a  'binary' named 'myFirstBinary' inside 'myFirstObject' 
Given I have an 'url64' named 'myFirstUrl64' inside 'myFirstObject' 
Then print all data
EOF
    save_output givenFullList.json
}

@test "Given I am, loaded from data" {
    cat <<EOF | save givenUserData.json
{
   "myUserName":"User1234",
	 "User1234":{
		  "keyring":{
			 "ecdh":"AxLMXkey00i2BD675vpMQ8WhP/CwEfmdRr+BtpuJ2rM="
		  }
	   } 
}
EOF
    cat <<EOF | zexe givenLoadNameFromData.zen givenUserData.json
Scenario 'ecdh': load name from data
Given my name is in a 'string' named 'myUserName'
And I have my  'keyring'
Then print my data
EOF
    save_output givenLoadNameFromDataOutput.json
}
