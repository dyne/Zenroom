#!/usr/bin/env bash

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
# zexe() {
# 	out="$1"
# 	shift 1
# 	>&2 echo "test: $out"
# 	tee "$out" | zenroom -z $*
# }
####################

## Path: ../../docs/examples/zencode_cookbook/

cat <<EOF | save dictionary dictionariesIdentity_example.json
{
  "Identity": {
    "UserNo": 1021,
    "RecordNo": 22,
    "DateOfIssue": "2020-01-01",
    "Name": "Giacomo",
    "FirstNames": "Rossi",
    "DateOfBirth": "1977-01-01",
    "PlaceOfBirth": "Milano",
    "Address": "Piazza Venezia",
    "TelephoneNo": "327 1234567"
  },
  "HistoryOfTransactions": {
    "NumberOfPreviouslyExecutedTransactions": 1020,
    "NumberOfCurrentPeriodTransactions": 57,
    "CanceledTransactions": 6,
    "DateOfFirstTransaction": "2019-01-01",
    "TotalSoldWithTransactions": 2160,
    "TotalPurchasedWithTransactions": 1005,
    "Remarks": "none"
  }
}
EOF

cat <<EOF | zexe dictionariesCreate_issuer_keypair.zen | save dictionary dictionariesIssuer_keypair.json
rule check version 1.0.0
Scenario 'ecdh': Create the keypair
Given that I am known as 'Authority'
When I create the keypair
Then print my data
EOF


cat <<EOF | zexe dictionariesPublish_issuer_pubkey.zen -k dictionariesIssuer_keypair.json | save dictionary dictionariesIssuer_pubkey.json
rule check version 1.0.0
Scenario 'ecdh': Publish the public key
Given that I am known as 'Authority'
and I have my 'keypair'
Then print my 'public key' from 'keypair'
EOF

## Authority issues the signature for the Identity
cat <<EOF | zexe dictionariesIssuer_sign_Identity.zen -a dictionariesIdentity_example.json -k dictionariesIssuer_keypair.json | save dictionary dictionaries_Identity_signed.json
rule check version 1.0.0
Scenario ecdh: Sign a new Identity
Given that I am known as 'Authority'
and I have my 'keypair'
and I have a 'string dictionary' named 'Identity'
and I have a 'string dictionary' named 'HistoryOfTransactions'
When I create the signature of 'Identity'
and I rename the 'signature' to 'Identity.signature'
and I create the signature of 'HistoryOfTransactions'
and I rename the 'signature' to 'HistoryOfTransactions.signature'
Then print the 'Identity'
and print the 'Identity.signature'
and print the 'HistoryOfTransactions'
and print the 'HistoryOfTransactions.signature'
EOF

## Anyone can verify the Authority's signature of the Identity
cat <<EOF | zexe dictionariesVerify_Identity_signature.zen -a dictionaries_Identity_signed.json -k dictionariesIssuer_pubkey.json
rule check version 1.0.0
Scenario ecdh: Verify the Identity signature
Given I have a 'public key' from 'Authority'
and I have a 'string dictionary' named 'Identity'
and I have a 'string dictionary' named 'HistoryOfTransactions'
and I have a 'signature' named 'Identity.signature'
and I have a 'signature' named 'HistoryOfTransactions.signature'
When I verify the 'Identity' has a signature in 'Identity.signature' by 'Authority'
When I verify the 'HistoryOfTransactions' has a signature in 'HistoryOfTransactions.signature' by 'Authority'
Then print the string 'Signature of Identity by Authority is Valid'
and print the string 'Signature of HistoryOfTransactions by Authority is Valid'
EOF

cat <<EOF | zexe dictionariesCreate_transaction_entry.zen
rule check version 1.0.0
Scenario ecdh
Given nothing
When I create the 'string dictionary'
and I rename the 'string dictionary' to 'ABC-TransactionsStatement'
and I write number '108' in 'TransactionsConcluded'
and I write string 'Transaction Control Dictionary' in 'nameOfDictionary'
and I write number '21' in 'AverageAmountPerTransaction'
and I insert 'nameOfDictionary' in 'ABC-TransactionsStatement'
and I insert 'TransactionsConcluded' in 'ABC-TransactionsStatement'
and I insert 'AverageAmountPerTransaction' in 'ABC-TransactionsStatement'
Then print the 'ABC-TransactionsStatement' 
EOF

cat <<EOF | save dictionary dictionariesBlockchain.json
{
   "ABC-TransactionListFirstBatch":{
      "ABC-Transactions1Data":{
         "timestamp":1597573139,
         "TransactionValue":1000,
		 "PricePerKG":2,
         "TransferredProductAmount":500
      },
      "ABC-Transactions2Data":{
         "timestamp":1597573239,
         "TransactionValue":1000,
		 "PricePerKG":2,
         "TransferredProductAmount":500
      },
      "ABC-Transactions3Data":{
         "timestamp":1597573339,
         "TransactionValue":1000,
		 "PricePerKG":2,
         "TransferredProductAmount":500
      },
      "ABC-Transactions4Data":{
         "timestamp":1597573439,
         "TransactionValue":2000,
		 "PricePerKG":4,
         "TransferredProductAmount":500
      },
      "ABC-Transactions5Data":{
         "timestamp":1597573539,
         "TransactionValue":2000,
		 "PricePerKG":4,
         "TransferredProductAmount":500
      },
      "ABC-Transactions6Data":{
         "timestamp":1597573639,
         "TransactionValue":2000,
		 "PricePerKG":4,
         "TransferredProductAmount":500
      }
   },
   "ABC-TransactionListSecondBatch":{
      "ABC-Transactions1Sum":{
         "timestamp":1597573040,
         "TransactionValue":1000,
		 "PricePerKG":2,
         "TransferredProductAmount":500
      },
      "ABC-Transactions2Sum":{
         "timestamp":1597573140,
         "TransactionValue":1000,
		 "PricePerKG":2,
         "TransferredProductAmount":500
      },
      "ABC-Transactions3Sum":{
         "timestamp":1597573240,
         "TransactionValue":2000,
		 "PricePerKG":4,
         "TransferredProductAmount":500
      },
	  "ABC-Transactions3Sum":{
         "timestamp":1597573340,
         "TransactionValue":1000,
		 "PricePerKG":2,
         "TransferredProductAmount":500
      },
	  "ABC-Transactions3Sum":{
         "timestamp":1597573440,
         "TransactionValue":2000,
		 "PricePerKG":4,
         "TransferredProductAmount":500
      }
   },
   "timestamp":1597573330
}
EOF

# old value: "timestamp":1597574000

cat <<EOF | zexe dictionariesFind_max_transactions.zen -a dictionariesBlockchain.json -k dictionariesIssuer_keypair.json
rule check version 1.0.0
Scenario ecdh: sign the result

# import the Authority keypair
Given that I am known as 'Authority'
and I have my 'keypair'

# import the blockchain data
Given I have a 'string dictionary' named 'ABC-TransactionListSecondBatch'
and I have a 'string dictionary' named 'ABC-TransactionListFirstBatch'
and I have a 'number' named 'timestamp'

# find the last (most recent) sum
When I find the max value 'timestamp' for dictionaries in 'ABC-TransactionListSecondBatch'
and rename the 'max value' to 'last sum'
and I write number '1597573440' in 'last sum known'
and I verify 'last sum' is equal to 'last sum known'

When I find the min value 'timestamp' for dictionaries in 'ABC-TransactionListSecondBatch'
and rename the 'min value' to 'first sum'
and I write number '1597573040' in 'first sum known'
and I verify 'first sum' is equal to 'first sum known'

# compute the total values of recent transactions not included in last sum
and create the sum value 'TransactionValue' for dictionaries in 'ABC-TransactionListFirstBatch' where 'timestamp' > 'last sum'
and rename the 'sum value' to 'TotalTransactionsValue'
and create the sum value 'TransferredProductAmount' for dictionaries in 'ABC-TransactionListFirstBatch' where 'timestamp' > 'last sum'
and rename the 'sum value' to 'TotalTransferredProductAmount'

# retrieve the values in last sum
When I find the 'TransactionValue' for dictionaries in 'ABC-TransactionListSecondBatch' where 'timestamp' = 'last sum'
and I find the 'TransferredProductAmount' for dictionaries in 'ABC-TransactionListSecondBatch' where 'timestamp' = 'last sum'

# sum the last with the new aggregated values from recent transactions
and I create the result of 'TotalTransactionsValue' + 'TransactionValue'
and I rename the 'result' to 'TransactionValueSums'
and I create the result of 'TotalTransferredProductAmount' + 'TransferredProductAmount'
and I rename the 'result' to 'TransactionProductAmountSums'

# create the entry for the new sum
and I create the 'number dictionary'
and I insert 'TransactionValueSums' in 'number dictionary'
and I insert 'TransactionProductAmountSums' in 'number dictionary'
and I insert 'timestamp' in 'number dictionary'
and I rename the 'number dictionary' to 'New-ABC-TransactionsSum'

# sign the new entry
and I create the signature of 'New-ABC-TransactionsSum'
and I rename the 'signature' to 'New-ABC-TransactionsSum.signature'

# print the result
Then print the 'New-ABC-TransactionsSum'
and print the 'New-ABC-TransactionsSum.signature'
EOF

cat << EOF | save dictionary nested_dictionaries.json
{
   "dataTime0":{
      "Active_energy_imported_kWh":4027.66,
      "Ask_Price":0.1,
      "Currency":"EUR",
      "Expiry":3600,
      "Timestamp":1422779638,
      "TimeServer":"http://showcase.api.linx.twenty57.net/UnixTime/tounix?date=now"
   },
   "nested":{
      "dataTime1":{
         "Active_energy_imported_kWh":4030,
         "Ask_Price":0.15,
         "Currency":"EUR",
         "Expiry":3600,
         "Timestamp":1422779633,
         "TimeServer":"http://showcase.api.linx.twenty57.net/UnixTime/tounix?date=now"
      },
      "dataTime2":{
         "Active_energy_imported_kWh":4040.25,
         "Ask_Price":0.15,
         "Currency":"EUR",
         "Expiry":3600,
         "Timestamp":1422779634,
         "TimeServer":"http://showcase.api.linx.twenty57.net/UnixTime/tounix?date=now"
      }
   }
}
EOF

cat << EOF | zexe nested_dictionaries.zen -a nested_dictionaries.json | save dictionary pick_nested_dict.json
Given I have a 'string dictionary' named 'nested'
When I create the copy of 'dataTime1' from dictionary 'nested'
and I rename 'copy' to 'dataTime1'
and I create the copy of 'Currency' from dictionary 'dataTime1'
and I rename the 'copy' to 'first method'
When I create the copy of 'Currency' in 'dataTime1' in 'nested'
and I rename the 'copy' to 'second method'
Then print the 'first method'
and print the 'second method'
EOF


cat <<EOF | save dictionary batch_data.json
{
	"TransactionsBatchA": {
		"MetaData": "This var is Not a Table",
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

cat <<EOF | zexe dictionary_iter.zen -a batch_data.json
Rule check version 2.0.0

Given that I have a 'string' named 'dictionaryToBeFound'
Given that I have a 'string dictionary' named 'TransactionsBatchA'
Given that I have a 'number' named 'salesStartTimestamp'

# Here we search if a certain dictionary exists in the list
When the 'dictionaryToBeFound' is found in 'TransactionsBatchA'

# Here we find the highest value of an element, in all dictionaries
When I find the max value 'PricePerKG' for dictionaries in 'TransactionsBatchA'
and I rename the 'max value' to 'maxPricePerKG'

# Here we sum the values of an element, from all dictionaries
When I create the sum value 'TransactionValue' for dictionaries in 'TransactionsBatchA'
and I rename the 'sum value' to 'sumValueAllTransactions'

# Here we sum the values of an element, from all dictionaries, with a condition
When I create the sum value 'TransferredProductAmount' for dictionaries in 'TransactionsBatchA' where 'timestamp' > 'salesStartTimestamp'
and I rename the 'sum value' to 'transferredProductAmountafterSalesStart'

# Here we create a dictionary
When I create the 'number dictionary'
and I rename the 'number dictionary' to 'salesReport'


# Here we insert elements into the newly created dictionary
When I insert 'maxPricePerKG' in 'salesReport'
When I insert 'sumValueAllTransactions' in 'salesReport'
When I insert 'transferredProductAmountafterSalesStart' in 'salesReport'


When I create the hash of 'salesReport' using 'sha512'
When I rename the 'hash' to 'sha512hashOfsalesReport'

When I pick the random object in 'TransactionsBatchA'
When I remove the 'random object' from 'TransactionsBatchA'

#Print out the data we produced along
# We also print the dictionary 'Information' as hex, just for fun
Then print the 'salesReport'
EOF


cat << EOF  | save dictionary blockchains.json
{ 
   "blockchains":{ 
      "b1":{ 
         "endpoint":"http://pesce.com/" ,
         "last-transaction": "123" 
      }, 
      "b2":{ 
         "endpoint":"http://fresco.com/",
         "last-transaction": "234" 
      } 
   } 
}
EOF

cat << EOF | zexe append_foreach.zen -a blockchains.json
Given I have a 'string dictionary' named 'blockchains'
When for each dictionary in 'blockchains' I append 'last-transaction' to 'endpoint'
Then print 'blockchains'
EOF

cat << EOF | zexe copy_contents_in.zen -a blockchains.json -k batch_data.json
Given I have a 'string dictionary' named 'blockchains'
Given that I have a 'string dictionary' named 'TransactionsBatchA'
When I copy contents of 'blockchains' in 'TransactionsBatchA'
Then print 'TransactionsBatchA'
EOF
