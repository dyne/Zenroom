#!/usr/bin/env bash

time=50

users=""
for i in $(seq $time)
do
  users+=" time_${i}"
done

data="data"
zencode="zencode"

cat <<EOF  > $data
{  "TransactionsBatchA.signature": {
    "r": "zvYkc3dqgMYooq29EeiF3aaJaGcee0Sg5Y7PO72/gZ4=",
    "s": "S9xr7Qt2ncjiUh4pYwuJznhN7oqY/0SnQhZgQpZtSqU="
  },
  	"JackInTheShop": {
			"public_key": "BBCQg21VcjsmfTmNsg+I+8m1Cm0neaYONTqRnXUjsJLPa8075IYH+a9w2wRO7rFM1cKmv19Igd7ntDZcUvLq3xI="
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
	}
}

EOF

cat <<EOF  > $zencode
rule check version 1.0.0 
Scenario 'ecdh': Bob verifies the signature from JackInTheShop 
Given I have a 'public key' from 'JackInTheShop' 
Given I have a 'string dictionary' named 'TransactionsBatchA' 
Given I have a 'signature' named 'TransactionsBatchA.signature' 
#
When I verify the 'TransactionsBatchA' has a signature in 'TransactionsBatchA.signature' by 'JackInTheShop' 
#
Then print the string 'Zenroom certifies that signatures are all correct!' 


EOF

ecdsa() {

zenroom -z $zencode -a $data

}


loop(){
for user in ${users[@]}
do
ecdsa ${user}
echo  " "
echo  "-----------------------------"
echo  " "
echo  " I have done ecdsa verify"  ${time} "times"
echo  " "
echo  " it took a total of: "
done
}

time loop

echo  " "
echo  "-----------------------------"
echo  " "



rm ./data
rm ./zencode

