#!/usr/bin/env bash

RNGSEED="hex:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"


####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh

is_cortexm=false
if [[ "$1" == "cortexm" ]]; then
	is_cortexm=true
fi

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

tmpGiven1=`mktemp`
tmpWhen1=`mktemp`	
tmpZen1="${tmpGiven1} ${tmpWhen1}"


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
  },
  "myUserName":"Authority1234"
}
EOF

let n=1

echo "                                                "
echo "------------------------------------------------"
echo "   Create Authority keypair, script:  $n              "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "


cat <<EOF | zexe ../../docs/examples/zencode_cookbook/dictionariesCreate_issuer_keypair.zen | tee ../../docs/examples/zencode_cookbook/dictionariesIssuer_keypair.json | jq
rule check version 1.0.0
Scenario 'ecdh': Create the keypair
Given that I am known as 'Authority1234'
When I create the keypair
Then print my data
EOF

let n=2

echo "                                                "
echo "------------------------------------------------"
echo "  publish Authority keypair, script:  $n             "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "


cat <<EOF | zexe ../../docs/examples/zencode_cookbook/dictionariesPublish_issuer_pubkey.zen -a ../../docs/examples/zencode_cookbook/dictionariesIdentity_example.json -k ../../docs/examples/zencode_cookbook/dictionariesIssuer_keypair.json | tee ../../docs/examples/zencode_cookbook/dictionariesIssuer_pubkey.json | jq
rule check version 1.0.0
Scenario 'ecdh': Publish the public key
Given my name is in a 'string' named 'myUserName'
and I have my 'keypair'
Then print my 'public key' from 'keypair'
EOF

let n=3

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
Given my name is in a 'string' named 'myUserName'
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


let n=4

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
Given I have a 'public key' from 'Authority1234'
and I have a 'string dictionary' named 'Identity'
and I have a 'string dictionary' named 'HistoryOfTransactions'
and I have a 'signature' named 'Identity.signature'
and I have a 'signature' named 'HistoryOfTransactions.signature'
When I verify the 'Identity' has a signature in 'Identity.signature' by 'Authority1234'
When I verify the 'HistoryOfTransactions' has a signature in 'HistoryOfTransactions.signature' by 'Authority1234'
Then print 'Signature of Identity by Authority1234 is Valid'
and print 'Signature of HistoryOfTransactions by Authority1234 is Valid'
EOF



let n=5

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
and I insert 'nameOfDictionary' in 'ABC-TransactionsStatement'
and I insert 'TransactionsConcluded' in 'ABC-TransactionsStatement'
and I insert 'AverageAmountPerTransaction' in 'ABC-TransactionsStatement'
Then print the 'ABC-TransactionsStatement' 
EOF

cat <<EOF > ../../docs/examples/zencode_cookbook/dictionariesBlockchain.json
{
   "TransactionsBatchB":{
   "Information":{
         "Metadata": "TransactionsBatchB6789",
		 "Buyer" : "John Doe"
      },
      "ABC-Transactions1Data":{
         "timestamp":1597573139,
         "TransactionValue":1000,
		 "PricePerKG":2,
         "TransferredProductAmount":500,
		 "UndeliveredProductAmount":100,
		 "ProductPurchasePrice":1
      },
      "ABC-Transactions2Data":{
         "timestamp":1597573239,
         "TransactionValue":1000,
		 "PricePerKG":2
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
   "TransactionsBatchA":{
	"Information":{
         "Metadata": "TransactionsBatchA12345",
		 "Buyer" : "Jane Doe"
      },   
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
         "TransactionValue":1000
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
		 "PricePerKG":4
      }
   },
   "dictionaryToBeFound":"ABC-Transactions1Data",
   "referenceTimestamp":1597573340,
	"PricePerKG":3,
	"myUserName":"Authority1234",
	"myVerySecretPassword":"password123"
}
EOF

# old value: "timestamp":1597574000



let n=6

echo "                                                "
echo "------------------------------------------------"
echo "   comparing values and signing comparisons, script:  $n                 "
echo " 												  "
echo "------------------------------------------------"
echo "   "



cat <<EOF  > $tmpGiven1
rule check version 1.0.0
Scenario ecdh: dictionary computation and signing 

# LOAD DICTIONARIES
# Here we load the two dictionaries and import their data.
# Later we also load some numbers, one of them name "PricePerKG" exists in the dictionary's root, 
# as well as inside each element of the object: homonimy is not a problem in this case.
Given that I have a 'string dictionary' named 'TransactionsBatchA'
Given that I have a 'string dictionary' named 'TransactionsBatchB'

# Loading other stuff here
Given that I have a 'number' named 'referenceTimestamp'
Given that I have a 'number' named 'PricePerKG'
Given that I have a 'string' named 'dictionaryToBeFound'
Given that I have a 'string' named 'myVerySecretPassword'

# Loading the keypair afer setting my identity
Given my name is in a 'string' named 'myUserName'
Given that I have my 'keypair'

EOF

cat $tmpGiven1 > ../../docs/examples/zencode_cookbook/dictionariesGiven.zen

cat <<EOF  > $tmpWhen1

# FIND MAX and MIN values in Dictionaries
# All the dictionaries contain an internet date 'number' named 'timestamp' 
# In this statement we find the most recent transaction in the dictionary "TransactionsBatchA" 
# by finding the element that contains the number 'timestamp' with the highest value in that dictionary.
# We also save the value of this 'timestamp' in an object that we call "Theta"
When I find the max value 'timestamp' for dictionaries in 'TransactionsBatchA'
and I rename the 'max value' to 'Theta'
When I find the min value 'timestamp' for dictionaries in 'TransactionsBatchA'
and I rename the 'min value' to 'oldestTransaction'

# CREATE SUM with condition
# Here we compute the sum of the "TransactionValue" numbers, 
# in the elements of the dictionary "TransactionsBatchB", 
# that have a 'timestamp' higher than "Theta". 
# We also rename the sum into "sumOfTransactionsValueFirstBatchAfterTheta"
When I create the sum value 'TransactionValue' for dictionaries in 'TransactionsBatchB' where 'timestamp' > 'Theta'
and I rename the 'sum value' to 'sumOfTransactionsValueFirstBatchAfterTheta'

# Here we do something similar to the statements above, but using the numbers
# named "TransferredProductAmount" in the same dictionary 
# We rename the sum to "sumOfTransactionsValueFirstBatchAfterTheta"
When I create the sum value 'TransferredProductAmount' for dictionaries in 'TransactionsBatchB' where 'timestamp' > 'Theta'
and I rename the 'sum value' to 'TotalTransferredProductAmountFirstBatchAfterTheta'

# FIND VALUE inside Dictionary's object
# In the statements below we are looking for the transaction(s) happened at time "Theta", 
# in both the dictionaries, and saving their "TransactionValue" into a new object (and renaming the object)
When I find the 'TransactionValue' for dictionaries in 'TransactionsBatchA' where 'timestamp' = 'Theta'
and I rename the 'TransactionValue' to 'TransactionValueSecondBatchAtTheta'

When I find the 'TransferredProductAmount' for dictionaries in 'TransactionsBatchA' where 'timestamp' = 'Theta'
and I rename the 'TransferredProductAmount' to 'TransferredProductAmountSecondBatchAtTheta'

# Here we create a simple sum of the new aggregated values from recent transactions
When I create the result of 'sumOfTransactionsValueFirstBatchAfterTheta' + 'TransactionValueSecondBatchAtTheta'
and I rename the 'result' to 'SumTransactionValueAfterTheta'

When I create the result of 'TotalTransferredProductAmountFirstBatchAfterTheta' + 'TransferredProductAmountSecondBatchAtTheta'
and I rename the 'result' to 'SumTransactionProductAmountAfterTheta'

# FOUND, NOT FOUND
# Here we search for a dictionary what a certain name in a list. 
# This could be useful when searching for a certain transaction in different data sets
# We are loading the string to match from the dataset.
When the 'dictionaryToBeFound' is found in 'TransactionsBatchA'

# Here we are doing the opposite, so check the a dictionary is not in the list
# and we ar ecreating the string not to be match inline in the script, just for the fun of it
When I write string 'someRandomName' in 'not.there'
and the 'not.there' is not found in 'TransactionsBatchA'

# CREATE Dictionary
# You can create a new dictionary using a similar syntax to the one to create an array 
# in the case below we're create a "number dictionary", which is key value storage where 
# the values we want to insert are all numbers
When I create the 'number dictionary'
and I rename the 'number dictionary' to 'ABC-TransactionsAfterTheta'

# COPY
# You can copy a dictionary that is nested into a list of dictionaries
# to the root level of the data, to make manipulation and visibility easier.
When I create the copy of 'Information' from dictionary 'TransactionsBatchA'
And I rename the 'copy' to 'copyOfInformationBatchA'

# INSERT in Dictionary
# We can use the "insert" statement to add an element to a dictionary, as we would do with an array
When I insert 'SumTransactionValueAfterTheta' in 'ABC-TransactionsAfterTheta' 
When I insert 'SumTransactionProductAmountAfterTheta' in 'ABC-TransactionsAfterTheta'
When I insert 'TransactionValueSecondBatchAtTheta' in 'ABC-TransactionsAfterTheta'
When I insert 'TransferredProductAmountSecondBatchAtTheta' in 'ABC-TransactionsAfterTheta'
When I insert 'referenceTimestamp' in 'ABC-TransactionsAfterTheta'

# ECDSA SIGNATURE of Dictionaries
# sign the newly created dictionary using ECDSA cryptography
When I create the signature of 'ABC-TransactionsAfterTheta'
and I rename the 'signature' to 'ABC-TransactionsAfterTheta.signature'

# PRINT the results
# Here we're printing just what we need, but a whole list of dictionaries can be printed 
# in the usual fashion, just uncomment the last line to print all the dictionaries
# contained into 'TransactionsBatchA' and 'TransactionsBatchB' 

# HASH
# we can hash the dictionary using any hashing algorythm
When I create the hash of 'ABC-TransactionsAfterTheta' using 'sha512'
And I rename the 'hash' to 'sha512hashOf:ABC-TransactionsAfterTheta' 

When I create the key derivation of 'ABC-TransactionsAfterTheta' with password 'myVerySecretPassword'
And I rename the 'key_derivation' to 'pbkdf2Of:ABC-TransactionsAfterTheta'

# CBOR 
# You can render a whole (list of) dictionary as CBOR
When I create the cbor of 'TransactionsBatchA'
And I rename the 'cbor' to 'CBORof:TransactionsBatchA'


# Let's print it all out!
Then print the 'ABC-TransactionsAfterTheta'
and print the 'Theta'
and print the 'ABC-TransactionsAfterTheta.signature'
and print the 'Information' inside 'TransactionsBatchA'
and print the 'sha512hashOf:ABC-TransactionsAfterTheta'
and print the 'pbkdf2Of:ABC-TransactionsAfterTheta'
and print the 'CBORof:TransactionsBatchA'
and print the 'copyOfInformationBatchA'
EOF

cat $tmpWhen1 > ../../docs/examples/zencode_cookbook/dictionariesWhen.zen

cat $tmpZen1 | zexe ../../docs/examples/zencode_cookbook/dictionariesComputation.zen -z -a ../../docs/examples/zencode_cookbook/dictionariesBlockchain.json -k ../../docs/examples/zencode_cookbook/dictionariesIssuer_keypair.json | tee ../../docs/examples/zencode_cookbook/dictionariesComputationOutput.json | jq .

#cat <<EOF | zexe ../../docs/examples/zencode_cookbook/dictionariesFind_max_transactions.zen -a ../../docs/examples/zencode_cookbook/dictionariesBlockchain.json -k ../../docs/examples/zencode_cookbook/dictionariesIssuer_keypair.json | jq .

# cat <<EOF  > $tmpWhen1
