#!/usr/bin/env bash


data="data"
zencode="zencode"

cat <<EOF  > $data
{
	"JackInTheShop": {
		"keypair": {
			"private_key": "Aku7vkJ7K01gQehKELav3qaQfTeTMZKgK+5VhaR3Ui0=",
			"public_key": "BBCQg21VcjsmfTmNsg+I+8m1Cm0neaYONTqRnXUjsJLPa8075IYH+a9w2wRO7rFM1cKmv19Igd7ntDZcUvLq3xI="
		}
	},
	"TransactionsBatchA": {
		"Information": {
			"Metadata": "TransactionsBatchB6789",
			"Buyer": "John Doe"
		},
		"ABC-Transactions1Data": {
			"timestamp": 1597573139,
			"TransactionValue": 1500,
			"PricePerKG": 100,
			"TransferredProductAmount": 15,
			"UndeliveredProductAmount": 7,
			"ProductPurchasePrice": 50
		},
		"ABC-Transactions2Data": {
			"timestamp": 1597573239,
			"TransactionValue": 1600,
			"TransferredProductAmount": 20,
			"PricePerKG": 80
		},
		"ABC-Transactions3Data": {
			"timestamp": 1597573340,
			"TransactionValue": 700,
			"PricePerKG": 70,
			"TransferredProductAmount": 10
		}
	},
	"dictionaryToBeFound": "Information",
	"salesStartTimestamp": 1597573200,
	"PricePerKG": 3
}
EOF

cat <<EOF  > $zencode
Rule check version 1.0.0
Scenario 'ecdh': keypair management and ECDSA signature

# Here we load everything we need
Given that I am 'JackInTheShop' 
Given that I have my valid 'keypair' 
Given that I have a 'string dictionary' named 'TransactionsBatchA'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA01' 

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA02' 

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA03'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA04' 

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA05'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA06' 

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA07'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA08'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA09'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA10' 

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA11'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA12' 

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA13' 

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA14' 

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA15' 

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA16' 

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA17' 

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA18' 

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA19'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA20' 

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA21'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA22'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA23'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA24'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA25'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA26'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA27'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA28'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA29'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA30'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA31'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA32'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA33'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA34'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA35'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA36'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA36'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA37'                  

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA38'                  

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA39'                  

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA40'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA41'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA42'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA42'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA43'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA44'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA45'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA46'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA47'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA48'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA49'

When I create the signature of 'TransactionsBatchA' 
When I rename the 'signature' to 'signatureOfTransactionsBatchA50'

Then print all data 

EOF

time for i in {1..10}
do
   zenroom -z $zencode -a $data
done





rm ./data
rm ./zencode

