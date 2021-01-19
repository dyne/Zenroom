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

Given that I have a 'string dictionary' named 'TransactionsBatchA'

# Hash dictionaries, using default (sha256) or sha256

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA01' 

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA02' 

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA03'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA04' 

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA05'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA06' 

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA07'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA08'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA09'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA10' 

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA11'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA12' 

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA13' 

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA14' 

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA15' 

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA16' 

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA17' 

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA18' 

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA19'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA20' 

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA21'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA22'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA23'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA24'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA25'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA26'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA27'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA28'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA29'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA30'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA31'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA32'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA33'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA34'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA35'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA36'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA36'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA37'                  

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA38'                  

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA39'                  

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA40'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA41'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA42'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA42'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA43'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA44'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA45'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA46'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA47'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA48'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA49'

When I create the hash of 'TransactionsBatchA' using 'sha256' 
When I rename the 'hash' to 'sha256hashOfTransactionsBatchA50'

Then print all data 
EOF

time zenroom -z $zencode -a $data


rm ./data
rm ./zencode

