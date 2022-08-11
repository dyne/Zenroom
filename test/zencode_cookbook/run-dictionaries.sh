#!/usr/bin/env bash

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


cat <<EOF | save . dictionariesIdentity_example.json
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

# let n=1

echo "                                                "
echo "------------------------------------------------"
echo "   Create Authority keyring, script:  $n              "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "


cat <<EOF | zexe dictionariesCreate_issuer_keyring.zen | save . dictionariesIssuer_keyring.json
rule check version 1.0.0
Scenario 'ecdh'
Given that I am known as 'Authority1234'
When I create the ecdh key
Then print my keyring
EOF

# let n=2

echo "                                                "
echo "------------------------------------------------"
echo "  publish Authority keyring, script:  $n             "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "


cat <<EOF | zexe dictionariesPublish_issuer_pubkey.zen -a dictionariesIdentity_example.json -k dictionariesIssuer_keyring.json | save . dictionariesIssuer_pubkey.json
rule check version 1.0.0
Scenario 'ecdh': Publish the public key
Given my name is in a 'string' named 'myUserName'
and I have my 'keyring'
When I create the ecdh public key
Then print my 'ecdh public key'
EOF

# let n=3

# echo "                                                "
# echo "------------------------------------------------"
# echo "   Authority signs the Identity, script:  $n                 "
# echo " 												  "
# echo "------------------------------------------------"
# echo "   "

# ## Authority issues the signature for the Identity
# cat <<EOF | zexe dictionariesIssuer_sign_Identity.zen -a dictionariesIdentity_example.json -k dictionariesIssuer_keyring.json | save . dictionaries_Identity_signed.json
# rule check version 1.0.0
# Scenario ecdh: Sign a new Identity
# Given my name is in a 'string' named 'myUserName'
# and I have my 'keyring'
# and I have a 'string dictionary' named 'Identity'
# and I have a 'string dictionary' named 'HistoryOfTransactions'
# When I create the signature of 'Identity'
# and I rename the 'signature' to 'Identity.signature'
# and I create the signature of 'HistoryOfTransactions'
# and I rename the 'signature' to 'HistoryOfTransactions.signature'
# Then print the 'Identity'
# and print the 'Identity.signature'
# and print the 'HistoryOfTransactions'
# and print the 'HistoryOfTransactions.signature'
# EOF


# let n=4

# echo "                                                "
# echo "------------------------------------------------"
# echo "   verify Authority's signature, script:  $n                 "
# echo " 												  "
# echo "------------------------------------------------"
# echo "   "

# ## Anyone can verify the Authority's signature of the Identity
# cat <<EOF | debug dictionariesVerify_Identity_signature.zen -a dictionaries_Identity_signed.json -k dictionariesIssuer_pubkey.json | save . verifiedAuthoritySignature.json
# rule check version 1.0.0
# Scenario ecdh: Verify the Identity signature
# Given I have a 'public key' from 'Authority1234'
# and I have a 'string dictionary' named 'Identity'
# and I have a 'string dictionary' named 'HistoryOfTransactions'
# and I have a 'signature' named 'Identity.signature'
# and I have a 'signature' named 'HistoryOfTransactions.signature'
# When I verify the 'Identity' has a signature in 'Identity.signature' by 'Authority1234'
# When I verify the 'HistoryOfTransactions' has a signature in 'HistoryOfTransactions.signature' by 'Authority1234'
# Then print the string 'Signature of Identity by Authority1234 is Valid'
# and print the string 'Signature of HistoryOfTransactions by Authority1234 is Valid'
# EOF



let n=5

echo "                                                "
echo "------------------------------------------------"
echo "   Creating a number dictionary, script:  $n                 "
echo " 												  "
echo "------------------------------------------------"
echo "   "

cat <<EOF | zexe dictionariesCreate_transaction_entry.zen | save . created_dictionary.json
# rule check version 2.0.0
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

cat <<EOF | save . dictionariesBlockchain.json
{
   "TransactionsBatchB":{
      "Information":{
         "Metadata":"TransactionsBatchB6789",
         "Buyer":"John Doe"
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
         "Metadata":"TransactionsBatchA12345",
         "Buyer":"Jane Doe"
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
   "TransactionAmountsA":{
      "InitialAmount":20,
      "LaterAmount":30,
      "Currency":"EUR"
   },
   "TransactionAmountsB":{
      "InitialAmount":50,
      "LaterAmount":60,
      "Currency":"EUR"
   },
   "PowerData":{
      "Active_power_imported_kW":4.85835600,
      "Active_energy_imported_kWh":53.72700119,
      "Active_power_exported_kW":0.0,
      "Apparent_energy_imported_kVAh":0,
      "Apparent_power_exported_kVA":0.00000000,
      "Apparent_energy_exported_kVAh":0.00000000,
      "Power_factor":0.71163559,
      "Application_data":"Application_data_string",
      "Application_UID":"Application_UID_string",
      "Currency":"EUR",
      "Expected_annual_production":0.00000000
   },
   "dictionaryToBeFound":"ABC-Transactions1Data",
   "objectToBeCopied":"LaterAmount",
   "referenceTimestamp":1597573340,
   "PricePerKG":3,
   "otherPricePerKG":5,
   "myUserName":"Authority1234",
   "myVerySecretPassword":"password123",
   "notPrunedDictionary": {
      "empty1": "",
      "notEmpty": "Hello World!",
      "empty2": "",
      "emptyDictionary": {
         "empty3": "",
	 "empty4": ""
      }
   }
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



cat <<EOF | save . dictionariesGiven.zen
# rule check version 1.0.0
Scenario ecdh: dictionary computation and signing 

# LOAD DICTIONARIES
# Here we load the two dictionaries and import their data.
# Later we also load some numbers, one of them name "PricePerKG" exists in the dictionary's root, 
# as well as inside each element of the object: homonimy is not a problem in this case.
Given that I have a 'string dictionary' named 'TransactionsBatchA'
Given that I have a 'string dictionary' named 'TransactionsBatchB'

Given that I have a 'string dictionary' named 'TransactionAmountsA'
Given that I have a 'string dictionary' named 'TransactionAmountsB'
Given that I have a 'string dictionary' named 'PowerData'

Given that I have a 'string dictionary' named 'notPrunedDictionary'


# Loading other stuff here
Given that I have a 'number' named 'referenceTimestamp'
Given that I have a 'number' named 'PricePerKG'
Given that I have a 'number' named 'otherPricePerKG'
Given that I have a 'string' named 'dictionaryToBeFound'
Given that I have a 'string' named 'objectToBeCopied'
Given that I have a 'string' named 'myVerySecretPassword'

# Loading the keyring afer setting my identity
Given my name is in a 'string' named 'myUserName'
Given that I have my 'keyring'

EOF

cat <<EOF | save . dictionariesWhen.zen

# FIND MAX and MIN values in Dictionaries
# All the dictionaries contain an internet date 'number' named 'timestamp' 
# In this statement we find the most recent transaction in the dictionary "TransactionsBatchA" 
# by finding the element that contains the number 'timestamp' with the highest value in that dictionary.
# We also save the value of this 'timestamp' in an object that we call "Theta"
When I find the max value 'timestamp' for dictionaries in 'TransactionsBatchA'
and I rename the 'max value' to 'Theta'
When I find the min value 'timestamp' for dictionaries in 'TransactionsBatchA'
and I rename the 'min value' to 'oldestTransaction'

# CREATE SUM, SUM with condition
# Here we compute the sum of the "TransactionValue" numbers,
# in the elements of the dictionary "TransactionsBatchB".
# We also rename the sum into "sumOfTransactionsValueFirstBatch"
When I create the sum value 'TransactionValue' for dictionaries in 'TransactionsBatchB'
and I rename the 'sum value' to 'sumOfTransactionsValueFirstBatch'

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
#When the 'dictionaryToBeFound' is found in 'TransactionsBatchA'
#When the 'dictionaryToBeFound' is found in 'TransactionsBatchA'

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

# You can also copy an element of a dictionary, to the root level.
# We're then renaming the object and we're using the notation "element<<dictionary"
# just for convenience, the name of the newly created object is just a string.
When I create the copy of 'InitialAmount' from dictionary 'TransactionAmountsA'
And I rename the 'copy' to 'InitialAmount<<TransactionAmountsA'

# You can also copy an element of a dictionary, which is named from another variable.
When I create the copy of object named by 'objectToBeCopied' from dictionary 'TransactionAmountsA'
And I rename the 'copy' to 'LaterAmount<<TransactionAmountsA'

# And you can also copy an element of a dictionary, that is nested 
# into another dictionary, to the root level:
When I create the copy of 'Buyer' in 'Information' in 'TransactionsBatchA'
and I rename the 'copy' to 'Buyer<<Information<<TransactionsBatchA'

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

# MATH OPERATIONS
# Like with regular numbers, you can sum, subtract, multiply, divide, modulo with values, 
# see the examples below. The output of the statement will be an object named "result" 
# that we immediately rename.
# The operators allowed are: +, -, *, /, %.
# MATH with numbers found in dictionaries, at root level of the dictionary

When I create the result of 'InitialAmount' in 'TransactionAmountsA' + 'InitialAmount' in 'TransactionAmountsB'
and I rename the 'result' to 'NumbersInDicts-Sum'
When I create the result of 'InitialAmount' in 'TransactionAmountsA' - 'InitialAmount' in 'TransactionAmountsB'
and I rename the 'result' to 'NumbersInDicts-Subtraction'
When I create the result of 'InitialAmount' in 'TransactionAmountsA' * 'InitialAmount' in 'TransactionAmountsB'
and I rename the 'result' to 'NumbersInDicts-Multiplication'
When I create the result of 'InitialAmount' in 'TransactionAmountsA' / 'InitialAmount' in 'TransactionAmountsB'
and I rename the 'result' to 'NumbersInDicts-Division'
When I create the result of 'InitialAmount' in 'TransactionAmountsA' % 'InitialAmount' in 'TransactionAmountsB'
and I rename the 'result' to 'NumbersInDicts-Modulo'


# MATH between numbers loaded individually and numbers found in dictionaries
When I create the result of 'InitialAmount' in 'TransactionAmountsA' + 'PricePerKG'
and I rename the 'result' to 'NumbersMixed-Sum'
When I create the result of 'InitialAmount' in 'TransactionAmountsA' - 'PricePerKG'
and I rename the 'result' to 'NumbersMixed-Subtraction'
When I create the result of 'InitialAmount' in 'TransactionAmountsA' * 'PricePerKG'
and I rename the 'result' to 'NumbersMixed-Multiplication'
When I create the result of 'InitialAmount' in 'TransactionAmountsA' / 'PricePerKG'
and I rename the 'result' to 'NumbersMixed-Division'
When I create the result of 'InitialAmount' in 'TransactionAmountsA' % 'PricePerKG'
and I rename the 'result' to 'NumbersMixed-Modulo'

# REMOVE ZERO values
# Use this statement to clean up a dictionary by removing all the object whose value is 0
# In this case we're using the dictionary 'PowerData' which has several 0 objects.
When I remove zero values in 'PowerData'

# CREATE ARRAY of elements with the same key
# You can group all the elements in a dictionary that have the same key
# value inside a fresh new generated array named array
When I write string 'timestamp' in 'Key'
When I create the array of objects named by 'Key' found in 'TransactionsBatchA'
and I rename the 'array' to 'TimestampArray'

# PRUNE dictionaries
# Given a string dictionary the prune operation removes all the
# empty strings ("") and the empty dictionaries (dictionaries that
# contain only empty strings).
When I create the pruned dictionary of 'notPrunedDictionary'


# Let's print it all out!
Then print the 'ABC-TransactionsAfterTheta'
and print the 'sumOfTransactionsValueFirstBatch'
and print the 'Theta'
and print the 'ABC-TransactionsAfterTheta.signature'
and print the 'Information' from 'TransactionsBatchA'
and print the 'sha512hashOf:ABC-TransactionsAfterTheta'
and print the 'pbkdf2Of:ABC-TransactionsAfterTheta'
and print the 'copyOfInformationBatchA'

and print the 'NumbersInDicts-Sum'
and print the 'NumbersInDicts-Subtraction'
and print the 'NumbersInDicts-Multiplication'
and print the 'NumbersInDicts-Division'
and print the 'NumbersInDicts-Modulo'

and print the 'NumbersMixed-Sum'
and print the 'NumbersMixed-Subtraction'
and print the 'NumbersMixed-Multiplication'
and print the 'NumbersMixed-Division'
and print the 'NumbersMixed-Modulo'

and print the 'PowerData'
and print the 'InitialAmount<<TransactionAmountsA'
and print the 'LaterAmount<<TransactionAmountsA'
and print the 'Buyer<<Information<<TransactionsBatchA'

and print the 'TimestampArray'

and print the 'pruned dictionary'

EOF

cat dictionariesGiven.zen dictionariesWhen.zen | debug dictionariesComputation.zen -a dictionariesBlockchain.json -k dictionariesIssuer_keyring.json | save . dictionariesComputationOutput.json

#cat <<EOF | zexe ../../docs/examples/zencode_cookbook/dictionariesFind_max_transactions.zen -a ../../docs/examples/zencode_cookbook/dictionariesBlockchain.json -k ../../docs/examples/zencode_cookbook/dictionariesIssuer_keyring.json | jq .

# cat <<EOF  > $tmpWhen1
