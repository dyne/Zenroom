#!/usr/bin/env bash

RNGSEED="hex:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"


####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################
# use zexe if you have zenroom in a system-wide path
#
# zexe() {
#	out="$1"
#	shift 1
#	>&2 echo "test: $out"
#	tee "$out" | zenroom -z $*
# }
####################

## Path: ../../docs/examples/zencode_cookbook/

n=0


cat <<EOF > ../../docs/examples/zencode_cookbook/dictionariesIdentity_example.json
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

let n=n+1

echo "                                                "
echo "------------------------------------------------"
echo "   Create Authority keypair, script:  $n              "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "


cat <<EOF | zexe ../../docs/examples/zencode_cookbook/dictionariesCreate_issuer_keypair.zen | tee ../../docs/examples/zencode_cookbook/dictionariesIssuer_keypair.json
rule check version 1.0.0
Scenario 'ecdh': Create the keypair
Given that I am known as 'Authority'
When I create the keypair
Then print my data
EOF

let n=n+1

echo "                                                "
echo "------------------------------------------------"
echo "  publish Authority keypair, script:  $n             "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "


cat <<EOF | zexe ../../docs/examples/zencode_cookbook/dictionariesPublish_issuer_pubkey.zen -k ../../docs/examples/zencode_cookbook/dictionariesIssuer_keypair.json | tee ../../docs/examples/zencode_cookbook/dictionariesIssuer_pubkey.json
rule check version 1.0.0
Scenario 'ecdh': Publish the public key
Given that I am known as 'Authority'
and I have my 'keypair'
Then print my 'public key' from 'keypair'
EOF

let n=n+1

echo "                                                "
echo "------------------------------------------------"
echo "   Authority signs the Identity, script:  $n                 "
echo " 												  "
echo "------------------------------------------------"
echo "   "

## Authority issues the signature for the Identity
cat <<EOF | zexe ../../docs/examples/zencode_cookbook/dictionariesIssuer_sign_Identity.zen -a ../../docs/examples/zencode_cookbook/dictionariesIdentity_example.json -k ../../docs/examples/zencode_cookbook/dictionariesIssuer_keypair.json | tee ../../docs/examples/zencode_cookbook/dictionaries_Identity_signed.json | jq .
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


let n=n+1

echo "                                                "
echo "------------------------------------------------"
echo "   verify Authority's signature, script:  $n                 "
echo " 												  "
echo "------------------------------------------------"
echo "   "

## Anyone can verify the Authority's signature of the Identity
cat <<EOF | zexe ../../docs/examples/zencode_cookbook/dictionariesVerify_Identity_signature.zen -a ../../docs/examples/zencode_cookbook/dictionaries_Identity_signed.json -k ../../docs/examples/zencode_cookbook/dictionariesIssuer_pubkey.json | jq .
rule check version 1.0.0
Scenario ecdh: Verify the Identity signature
Given I have a 'public key' from 'Authority'
and I have a 'string dictionary' named 'Identity'
and I have a 'string dictionary' named 'HistoryOfTransactions'
and I have a 'signature' named 'Identity.signature'
and I have a 'signature' named 'HistoryOfTransactions.signature'
When I verify the 'Identity' has a signature in 'Identity.signature' by 'Authority'
When I verify the 'HistoryOfTransactions' has a signature in 'HistoryOfTransactions.signature' by 'Authority'
Then print 'Signature of Identity by Authority is Valid'
and print 'Signature of HistoryOfTransactions by Authority is Valid'
EOF



let n=n+1

echo "                                                "
echo "------------------------------------------------"
echo "   Creating a number dictionary, script:  $n                 "
echo " 												  "
echo "------------------------------------------------"
echo "   "

cat <<EOF | zexe ../../docs/examples/zencode_cookbook/dictionariesCreate_transaction_entry.zen | jq .
rule check version 1.0.0
Scenario ecdh
Given nothing
When I create the 'string dictionary'
and I rename the 'string dictionary' to 'ABC-TransactionsStatement'
and I write number '108' in 'TransactionsConcluded'
and I write string 'Transaction Control Dictionary' in 'nameOfDictionary'
and I write number '21' in 'AverageAmountPerTransaction'
and I move 'nameOfDictionary' in 'ABC-TransactionsStatement'
and I move 'TransactionsConcluded' in 'ABC-TransactionsStatement'
and I move 'AverageAmountPerTransaction' in 'ABC-TransactionsStatement'
Then print the 'ABC-TransactionsStatement' 
EOF

cat <<EOF > ../../docs/examples/zencode_cookbook/dictionariesBlockchain.json
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
      "ABC-Transactions1Data":{
         "timestamp":1597573040,
         "TransactionValue":1000,
		 "PricePerKG":2,
         "TransferredProductAmount":500
      },
      "ABC-Transactions2Data":{
         "timestamp":1597573140,
         "TransactionValue":1000,
		 "PricePerKG":2,
         "TransferredProductAmount":500
      },
      "ABC-Transactions4Data":{
         "timestamp":1597573240,
         "TransactionValue":2000,
		 "PricePerKG":4,
         "TransferredProductAmount":500
      },
	  "ABC-Transactions5Data":{
         "timestamp":1597573340,
         "TransactionValue":1000,
		 "PricePerKG":2,
         "TransferredProductAmount":500
      },
	  "ABC-Transactions6Data":{
         "timestamp":1597573440,
         "TransactionValue":1000,
		 "PricePerKG":2,
         "TransferredProductAmount":510
      },
	  "ABC-Transactions7Data":{
         "timestamp":1597573440,
         "TransactionValue":1000,
		 "PricePerKG":2,
         "TransferredProductAmount":520
      },
	  "ABC-Transactions8Data":{
         "timestamp":1597573440,
         "TransactionValue":2000,
		 "PricePerKG":4,
         "TransferredProductAmount":530
      }
   },
   "referenceTimestamp":1597573330
}
EOF

# old value: "timestamp":1597574000



let n=n+1

echo "                                                "
echo "------------------------------------------------"
echo "   comparing values and signing comparisons, script:  $n                 "
echo " 												  "
echo "------------------------------------------------"
echo "   "

cat <<EOF | zexe ../../docs/examples/zencode_cookbook/dictionariesFind_max_transactions.zen -a ../../docs/examples/zencode_cookbook/dictionariesBlockchain.json -k ../../docs/examples/zencode_cookbook/dictionariesIssuer_keypair.json | jq .
rule check version 1.0.0
Scenario ecdh: sign the result

# Import the Authority keypair
Given that I am known as 'Authority'
and I have my 'keypair'

# Here we load the two dictionaries and import their data
# and we also load a number named 'timestamp': there are also numbers with the same
# inside the dictionaries, but those are referred to differently
Given I have a 'string dictionary' named 'ABC-TransactionListSecondBatch'
and I have a 'string dictionary' named 'ABC-TransactionListFirstBatch'
and I have a 'number' named 'referenceTimestamp'

# In this statement we find the last (most recent) transaction in the dictionary 
# "ABC-TransactionListSecondBatch" by finding the element that contains
# the number 'timestamp' with the highest value in that dictionary.
# We also save the value of this 'timestamp' in an object that we call "Theta"
When I find the max value 'timestamp' for dictionaries in 'ABC-TransactionListSecondBatch'
and I rename the 'max value' to 'Theta'

# Here we compute the sum of the "TransactionValue" numbers, 
# in the elements of the dictionary "ABC-TransactionListFirstBatch", 
# that have a 'timestamp' higher than "Theta". 
# We also rename the sum into "sumOfTransactionsValueFirstBatchAfterTheta"
When I create the sum value 'TransactionValue' for dictionaries in 'ABC-TransactionListFirstBatch' where 'timestamp' > 'Theta'
and I rename the 'sum value' to 'sumOfTransactionsValueFirstBatchAfterTheta'

# Here we do something similar to the statements above, but using the numbers
# named "TransferredProductAmount" in the same dictionary 
# We rename the sum to "sumOfTransactionsValueFirstBatchAfterTheta"
When I create the sum value 'TransferredProductAmount' for dictionaries in 'ABC-TransactionListFirstBatch' where 'timestamp' > 'Theta'
and I rename the 'sum value' to 'TotalTransferredProductAmountFirstBatchAfterTheta'

# In the statements below we are looking for the transaction(s) happened at time "Theta", 
# in both the dictionaries, and saving their "TransactionValue" into a new object (and renaming the object)
When I find the 'TransactionValue' for dictionaries in 'ABC-TransactionListSecondBatch' where 'timestamp' = 'Theta'
and I rename the 'TransactionValue' to 'TransactionValueSecondBatchAtTheta'
When I find the 'TransferredProductAmount' for dictionaries in 'ABC-TransactionListSecondBatch' where 'timestamp' = 'Theta'
and I rename the 'TransferredProductAmount' to 'TransferredProductAmountSecondBatchAtTheta'

# sum the last with the new aggregated values from recent transactions
When I create the result of 'sumOfTransactionsValueFirstBatchAfterTheta' + 'TransactionValueSecondBatchAtTheta'
and I rename the 'result' to 'SumTransactionValueAfterTheta'
When I create the result of 'TotalTransferredProductAmountFirstBatchAfterTheta' + 'TransferredProductAmountSecondBatchAtTheta'
and I rename the 'result' to 'SumTransactionProductAmountAfterTheta'

# create the entry for the new sum
When I create the 'number dictionary'
When I move 'SumTransactionValueAfterTheta' in 'number dictionary'
When I move 'SumTransactionProductAmountAfterTheta' in 'number dictionary'
and debug
When I move 'TransactionValueSecondBatchAtTheta' in 'number dictionary'
When I move 'TransferredProductAmountSecondBatchAtTheta' in 'number dictionary'
When I move 'referenceTimestamp' in 'number dictionary'
# When I move 'Theta' in 'number dictionary'
and I rename the 'number dictionary' to 'ABC-TransactionsAfterTheta'

# sign the new entry
When I create the signature of 'ABC-TransactionsAfterTheta'
and I rename the 'signature' to 'ABC-TransactionsAfterTheta.signature'

# print the result
Then print the 'ABC-TransactionsAfterTheta'
and print the 'ABC-TransactionsAfterTheta.signature'
# and print the 'Theta'
# and print the 'TransactionValueSecondBatchAtTheta'
# and print the 'TransferredProductAmountSecondBatchAtTheta'
EOF

