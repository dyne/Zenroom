load ../bats_setup
load ../bats_zencode
SUBDOC=credential

@test "Dictionary create issuer keypair" {
    cat <<EOF | zexe dictionariesCreate_issuer_keypair.zen
rule check version 1.0.0
Scenario 'ecdh': Create the keyring
Given that I am known as 'Authority'
When I create the ecdh key
Then print my keyring
EOF
    save_output 'dictionariesIssuer_keypair.json'
    assert_output '{"Authority":{"keyring":{"ecdh":"B4rYTWx6UMbc2YPWRNpl4w2M6gY9jqSa637n8Kr2pPc="}}}'

}

@test "Dictionaries publish issuer pubkey" {
    cat <<EOF | zexe dictionariesPublish_issuer_pubkey.zen dictionariesIssuer_keypair.json
rule check version 1.0.0
Scenario 'ecdh': Publish the public key
Given that I am known as 'Authority'
and I have my 'keyring'
When I create the ecdh public key
Then print my 'ecdh public key'
EOF
    save_output 'dictionariesIssuer_pubkey.json'
    assert_output '{"Authority":{"ecdh_public_key":"BHdrWMNBRclVO1I1/iEaYjfEi5C0eEvG2GZgsCNq87qy8feZ74JEvnKK9FC07ThhJ8s4ON2ZQcLJ+8HpWMfKPww="}}'
}

@test "Authority issues the signature for the Identity" {
    cat <<EOF | save_asset dictionariesIdentity_example.json
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

    cat <<EOF | zexe dictionariesIssuer_sign_Identity.zen dictionariesIdentity_example.json dictionariesIssuer_keypair.json
rule check version 1.0.0
Scenario ecdh: Sign a new Identity
Given that I am known as 'Authority'
and I have my 'keyring'
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
    save_output 'dictionaries_Identity_signed.json'
    assert_output '{"HistoryOfTransactions":{"CanceledTransactions":6,"DateOfFirstTransaction":"2019-01-01","NumberOfCurrentPeriodTransactions":57,"NumberOfPreviouslyExecutedTransactions":1020,"Remarks":"none","TotalPurchasedWithTransactions":1005,"TotalSoldWithTransactions":2160},"HistoryOfTransactions.signature":{"r":"hLj1fqGCCrGQ4BccC7lbmcCEgo2H+YqMcdZToKeq8t0=","s":"1ZGjmzK4KqBW2EcyiHTT5TgLFX33txPktvntqJqSZdI="},"Identity":{"Address":"Piazza Venezia","DateOfBirth":"1977-01-01","DateOfIssue":"2020-01-01","FirstNames":"Rossi","Name":"Giacomo","PlaceOfBirth":"Milano","RecordNo":22,"TelephoneNo":"327 1234567","UserNo":1021},"Identity.signature":{"r":"d2tYw0FFyVU7UjX+IRpiN8SLkLR4S8bYZmCwI2rzurI=","s":"cuFsBvc4QLGWJaB3uyWXQf50SgiwNJ3dqESrCiIBymg="}}'
}

@test "Anyone can verify the Authority's signature of the Identity" {
    cat <<EOF | zexe dictionariesVerify_Identity_signature.zen dictionaries_Identity_signed.json dictionariesIssuer_pubkey.json
rule check version 1.0.0
Scenario ecdh: Verify the Identity signature
Given I have a 'ecdh public key' from 'Authority'
and I have a 'string dictionary' named 'Identity'
and I have a 'string dictionary' named 'HistoryOfTransactions'
and I have a 'signature' named 'Identity.signature'
and I have a 'signature' named 'HistoryOfTransactions.signature'
When I verify the 'Identity' has a signature in 'Identity.signature' by 'Authority'
When I verify the 'HistoryOfTransactions' has a signature in 'HistoryOfTransactions.signature' by 'Authority'
Then print the string 'Signature of Identity by Authority is Valid'
and print the string 'Signature of HistoryOfTransactions by Authority is Valid'
EOF
    save_output 'dictionariesVerify_Identity_signature.json'
    assert_output '{"output":["Signature_of_Identity_by_Authority_is_Valid","Signature_of_HistoryOfTransactions_by_Authority_is_Valid"]}'
}

@test "Dictionary create transaction entry" {
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
    save_output 'dictionariesCreate_transaction_entry.json'
    assert_output '{"ABC-TransactionsStatement":{"AverageAmountPerTransaction":21,"TransactionsConcluded":108,"nameOfDictionary":"Transaction_Control_Dictionary"}}'

}


@test "Dictionaries find max value" {
    cat <<EOF | save_asset dictionariesBlockchain.json
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


    cat <<EOF | zexe dictionariesFind_max_transactions.zen dictionariesBlockchain.json dictionariesIssuer_keypair.json
rule check version 1.0.0
Scenario ecdh: sign the result

# import the Authority keypair
Given that I am known as 'Authority'
and I have my 'keyring'

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
    save_output 'dictionariesFind_max_transactions.json'
    assert_output '{"New-ABC-TransactionsSum":{"TransactionProductAmountSums":1500,"TransactionValueSums":6000,"timestamp":1.597573e+09},"New-ABC-TransactionsSum.signature":{"r":"d2tYw0FFyVU7UjX+IRpiN8SLkLR4S8bYZmCwI2rzurI=","s":"NeeOCvb7hhawMPsGwfyUWLZesndeLxAYRnA69iM+xp4="}}'


}

@test "Random dictionary" {
    cat << EOF | save_asset nested_dictionaries.json
{
   "dataTime0":{
      "Active_energy_imported_kWh":4027.66,
      "Ask_Price":0.1,
      "Currency":"EUR",
      "Expiry":3600,
      "Timestamp":"1422779638",
      "TimeServer":"http://showcase.api.linx.twenty57.net/UnixTime/tounix?date=now"
   },
   "nested":{
      "dataTime1":{
         "Active_energy_imported_kWh":4030,
         "Ask_Price":0.15,
         "Currency":"EUR",
         "Expiry":3600,
         "Timestamp":"1422779633",
         "TimeServer":"http://showcase.api.linx.twenty57.net/UnixTime/tounix?date=now"
      },
      "dataTime2":{
         "Active_energy_imported_kWh":4040.25,
         "Ask_Price":0.15,
         "Currency":"EUR",
         "Expiry":3600,
         "Timestamp":"1422779634",
         "TimeServer":"http://showcase.api.linx.twenty57.net/UnixTime/tounix?date=now"
      }
   }
}
EOF

    cat <<EOF | zexe random_dictionary.zen dictionariesBlockchain.json
Given I have a 'string dictionary' named 'ABC-TransactionListFirstBatch'
When I create the random dictionary with '3' random objects from 'ABC-TransactionListFirstBatch'
Then print the 'random dictionary'
EOF
    save_output 'random_dictionary.json'
    assert_output '{"random_dictionary":{"ABC-Transactions2Data":{"PricePerKG":2,"TransactionValue":1000,"TransferredProductAmount":500,"timestamp":1.597573e+09},"ABC-Transactions3Data":{"PricePerKG":2,"TransactionValue":1000,"TransferredProductAmount":500,"timestamp":1.597573e+09},"ABC-Transactions5Data":{"PricePerKG":4,"TransactionValue":2000,"TransferredProductAmount":500,"timestamp":1.597574e+09}}}'

}

@test "Another random dictionary" {
    cat <<EOF | save_asset num.json
{ "few": 2 }
EOF

    cat <<EOF | zexe another_random_dictionary.zen num.json dictionariesBlockchain.json
Given I have a 'string dictionary' named 'ABC-TransactionListFirstBatch'
and I have a 'number' named 'few'
When I create the random dictionary with 'few' random objects from 'ABC-TransactionListFirstBatch'
Then print the 'random dictionary'
EOF
    save_output 'another_random_dictionary.json'
    assert_output '{"random_dictionary":{"ABC-Transactions2Data":{"PricePerKG":2,"TransactionValue":1000,"TransferredProductAmount":500,"timestamp":1.597573e+09},"ABC-Transactions5Data":{"PricePerKG":4,"TransactionValue":2000,"TransferredProductAmount":500,"timestamp":1.597574e+09}}}'
}

@test "Nested dictionaries" {
    cat << EOF | zexe nested_dictionaries.zen nested_dictionaries.json
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
    save_output 'pick_nested_dict.json'
    assert_output '{"first_method":"EUR","second_method":"EUR"}'

}

@test "Dictionary iter" {
    cat <<EOF | save_asset batch_data.json
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

    cat <<EOF | zexe dictionary_iter.zen batch_data.json
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
    save_output 'dictionary_iter.json'
    assert_output '{"salesReport":{"maxPricePerKG":100,"sumValueAllTransactions":3800,"transferredProductAmountafterSalesStart":10}}'


}
