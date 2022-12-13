load ../bats_setup
load ../bats_zencode
SUBDOC=dictionary

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

@test "Append foreach" {
    cat << EOF  | save_asset blockchains.json
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

    cat << EOF | zexe append_foreach.zen blockchains.json
Given I have a 'string dictionary' named 'blockchains'
When for each dictionary in 'blockchains' I append 'last-transaction' to 'endpoint'
Then print 'blockchains'
EOF
    save_output 'append_foreach.json'
    assert_output '{"blockchains":{"b1":{"endpoint":"http://pesce.com/123","last-transaction":"123"},"b2":{"endpoint":"http://fresco.com/234","last-transaction":"234"}}}'
}

@test "Copy content in" {
    cat << EOF | zexe copy_contents_in.zen blockchains.json batch_data.json
Given I have a 'string dictionary' named 'blockchains'
Given that I have a 'string dictionary' named 'TransactionsBatchA'
When I copy contents of 'blockchains' in 'TransactionsBatchA'
Then print 'TransactionsBatchA'
EOF
    save_output 'copy_contents_in.json'
    assert_output '{"TransactionsBatchA":{"ABC-Transactions1Data":{"PricePerKG":100,"ProductPurchasePrice":50,"TransactionValue":1500,"TransferredProductAmount":15,"UndeliveredProductAmount":7,"timestamp":1.597573e+09},"ABC-Transactions2Data":{"PricePerKG":80,"TransactionValue":1600,"TransferredProductAmount":20,"timestamp":1.597573e+09},"ABC-Transactions3Data":{"PricePerKG":70,"TransactionValue":700,"TransferredProductAmount":10,"timestamp":1.597573e+09},"Information":{"Buyer":"John Doe","Metadata":"TransactionsBatchB6789"},"MetaData":"This var is Not a Table","b1":{"endpoint":"http://pesce.com/","last-transaction":"123"},"b2":{"endpoint":"http://fresco.com/","last-transaction":"234"}}}'

}

@test "Dictionary named by" {
    cat << EOF  | save_asset dictionary_named_by.json
{
	"Recipient": "User1234",
	"NewRecipient": "User1235",
	"myDict": {
		"User1234": {
			"name": "John",
			"surname": "Doe"
		}
	}
}
EOF

    cat << EOF | zexe dictionary_named_by.zen dictionary_named_by.json
Given I have a 'string' named 'Recipient'
Given I have a 'string' named 'NewRecipient'
Given that I have a 'string dictionary' named 'myDict'

Given that I have a 'string dictionary' named by 'Recipient' inside 'myDict'

When I create the copy of object named by 'Recipient' from dictionary 'myDict'

When I rename the 'copy' to 'tempObject'
When I rename 'tempObject' to named by 'NewRecipient'

Then print the object named by 'NewRecipient'
EOF
    save_output 'dictionary_named_by.json'
    assert_output '{"User1235":{"name":"John","surname":"Doe"}}'


}


@test "Dict into array" {

    cat <<EOF | save_asset dict-into-array.data
{
	"dataFromEndpoint": {
		"data": {
			"batches": [
				{
					"header": {
						"signer_public_key": "0209373bda3561c82c246b226ab3dfdfcab5fbdcba3cb3969508ea5b427628bb1f",
						"transaction_ids": [
							"3ff09b69c5973eaed4f06214bfa45ad0cf3d88f92476f3f297b331efb7ec9ad51f27b94a217e0fe1c59a714f067bcdd9e595f8d73c8e3ab22a085b732fc8bb94"
						]
					},
					"header_signature": "b81f74eec9f49fd8062c3a90dc5bd48249842ea6149b4a2e7cded38f50ca0e4d30cb66f6d74a807b737143f07fa2f7e807ef5dd44e3e03e89ac1f39ac41012f0",
					"trace": false,
					"transactions": [
						{
							"header": {
								"batcher_public_key": "0209373bda3561c82c246b226ab3dfdfcab5fbdcba3cb3969508ea5b427628bb1f",
								"dependencies": [],
								"family_name": "restroom",
								"family_version": "1.0",
								"inputs": [
									"c274b5"
								],
								"nonce": "",
								"outputs": [
									"c274b5"
								],
								"payload_sha512": "263e4334456dbe1c5904417e8d2b80d0235fd6766a7e71ca3b95bd0fa134b0fe7c722877ee44a715ac81d9dda0df8496abb3455c0f447c26e801dbdfba5f2bc3",
								"signer_public_key": "0209373bda3561c82c246b226ab3dfdfcab5fbdcba3cb3969508ea5b427628bb1f"
							},
							"header_signature": "3ff09b69c5973eaed4f06214bfa45ad0cf3d88f92476f3f297b331efb7ec9ad51f27b94a217e0fe1c59a714f067bcdd9e595f8d73c8e3ab22a085b732fc8bb94",
							"payload": "omV2YWx1ZXiTeyJkYXRhVG9TdG9yZSI6IlRHbG1aU0JwY3lCaWIzSnBibWNzSUd4bGRDQjFjeUJ6Y0dsalpTQnBkQ0IxY0NCM2FYUm9JSE52YldVZ1lteHZZMnRqYUdGcGJpQm1kVzVySVE9PSIsIm15MTI4Qml0c1JhbmRvbSI6IklBTVRDNzNEMlB0b0dPdEVRVTlPUXc9PSJ9Z2FkZHJlc3N4RmMyNzRiNTAyYjk5YmUxZDA1NmFmY2UzYTRmZTI0ZmM2Y2NmZjM0NzdmOGJlYjE5ODk2YjdhYTY2ZTQ1MjVjYTAwMTdkY2U="
						}
					]
				}
			],
			"header": {
				"batch_ids": [
					"b81f74eec9f49fd8062c3a90dc5bd48249842ea6149b4a2e7cded38f50ca0e4d30cb66f6d74a807b737143f07fa2f7e807ef5dd44e3e03e89ac1f39ac41012f0"
				],
				"block_num": "50910",
				"consensus": "CjEKBFNlYWwQ7sZSGN2NAyIhAlle86noklkwJcqHaKdsqYG3wT5nY+zuLpAhUSM9neiaEkBsxMiV0seIGVRIl1DVmP83/vbSme6fteGVmAlMeBe07QLmdw9Q3vynYLa2vvJ4+F6IrTUuGEZL1LdoGxIRo0tkGrUCCngKIQLOFYL60z4cyx702e+XrMqd1trEIZWdtR/Lv+sEW1vsdRJAbte6Bw6GixkD89OgkIRDvM1c8EoQ3NuEiBO3Pg72U+Ff37HahDK7qGIcnjVN/5ZkSF2ZXTtTQhlcTAmP+jrhgRoEcGJmdCIDMS4wKgZDb21taXQSQH1T1oahhMUWUTIPndLggRKKt2BZ059XM6x/sevk4BVHJsNylXeyHF/ONRn9fdw4F9rEtNLAgGGDV9KcSBuhvIwadwozCgZDb21taXQQ7sZSGN2NAyIhAs4VgvrTPhzLHvTZ75esyp3W2sQhlZ21H8u/6wRbW+x1EkBsxMiV0seIGVRIl1DVmP83/vbSme6fteGVmAlMeBe07QLmdw9Q3vynYLa2vvJ4+F6IrTUuGEZL1LdoGxIRo0tkGrUCCngKIQKSXcyCS0X60UbP5Hj0dag218kdsxT1lLXaHqnoVdvgNBJAt7JFxR/u2DMCAQus7oRlM/FhWr9ja/nov/3hgFSltcr9dQhRCaiynEPR/XpN2sV/vBohb+7DHPkiMQN9spKPAhoEcGJmdCIDMS4wKgZDb21taXQSQFbuGoovqhUcqacE9IPwT5HFkX/2rSnh/w7hMAx3O4FASGkcn1TXKRD23r5yktoibxRmigZGvKyFDhHezrFJAQwadwozCgZDb21taXQQ7sZSGN2NAyIhApJdzIJLRfrRRs/kePR1qDbXyR2zFPWUtdoeqehV2+A0EkBsxMiV0seIGVRIl1DVmP83/vbSme6fteGVmAlMeBe07QLmdw9Q3vynYLa2vvJ4+F6IrTUuGEZL1LdoGxIRo0tkGrUCCngKIQKe9eL0dTf0jPiq36TOpsmcCYOqLq4Xp22sERmaF8XuIhJAZh5oduHWyx0ovqjYg3pbci/VoB3y2s/mURH3cztVb7IGDJMSwoMG6yi468uvdWLzZt3qa2aKay0F6EDiGe3zbRoEcGJmdCIDMS4wKgZDb21taXQSQFyyWIq4PPpsICqH6twz5x202pQfcRNGWXhppLE+ujWUXkaucXNY+sUEtxaejZYrZa+oUkLXmEt81BpcizM/+k0adwozCgZDb21taXQQ7sZSGN2NAyIhAp714vR1N/SM+KrfpM6myZwJg6ourhenbawRGZoXxe4iEkBsxMiV0seIGVRIl1DVmP83/vbSme6fteGVmAlMeBe07QLmdw9Q3vynYLa2vvJ4+F6IrTUuGEZL1LdoGxIRo0tk",
				"previous_block_id": "6cc4c895d2c7881954489750d598ff37fef6d299ee9fb5e19598094c7817b4ed02e6770f50defca760b6b6bef278f85e88ad352e18464bd4b7681b1211a34b64",
				"signer_public_key": "02595ef3a9e892593025ca8768a76ca981b7c13e6763ecee2e902151233d9de89a",
				"state_root_hash": "2debd89f31b8a8d18b663f16ab19d2b70ae79414a73d29b20eb19b60a4353997"
			},
			"header_signature": "6bfbf0662951751b62c6a43300d29cf9f80758d2ef0241d049f318d44ce0babd3228822482d57d161899598c5c876488e816e04a6a016c9653c1e26b15f2ca1c"
		},
		"link": "http://195.201.41.35:8008/blocks/6bfbf0662951751b62c6a43300d29cf9f80758d2ef0241d049f318d44ce0babd3228822482d57d161899598c5c876488e816e04a6a016c9653c1e26b15f2ca1c"
	}
}
EOF

cat <<EOF | zexe dict-into-array.zen dict-into-array.data
Given I have a 'string dictionary' named 'data' inside 'dataFromEndpoint'
When I create the copy of 'batches' from dictionary 'data'
When I rename the 'copy' to 'batches'
When I create the copy of 'header_signature' from dictionary 'batches'
then print the 'copy'
and print the 'batches'
EOF
    save_output 'dict-into-array.json'
    assert_output '{"batches":[{"header":{"signer_public_key":"0209373bda3561c82c246b226ab3dfdfcab5fbdcba3cb3969508ea5b427628bb1f","transaction_ids":["3ff09b69c5973eaed4f06214bfa45ad0cf3d88f92476f3f297b331efb7ec9ad51f27b94a217e0fe1c59a714f067bcdd9e595f8d73c8e3ab22a085b732fc8bb94"]},"header_signature":"b81f74eec9f49fd8062c3a90dc5bd48249842ea6149b4a2e7cded38f50ca0e4d30cb66f6d74a807b737143f07fa2f7e807ef5dd44e3e03e89ac1f39ac41012f0","trace":false,"transactions":[{"header":{"batcher_public_key":"0209373bda3561c82c246b226ab3dfdfcab5fbdcba3cb3969508ea5b427628bb1f","dependencies":[],"family_name":"restroom","family_version":"1.0","inputs":["c274b5"],"outputs":["c274b5"],"payload_sha512":"263e4334456dbe1c5904417e8d2b80d0235fd6766a7e71ca3b95bd0fa134b0fe7c722877ee44a715ac81d9dda0df8496abb3455c0f447c26e801dbdfba5f2bc3","signer_public_key":"0209373bda3561c82c246b226ab3dfdfcab5fbdcba3cb3969508ea5b427628bb1f"},"header_signature":"3ff09b69c5973eaed4f06214bfa45ad0cf3d88f92476f3f297b331efb7ec9ad51f27b94a217e0fe1c59a714f067bcdd9e595f8d73c8e3ab22a085b732fc8bb94","payload":"omV2YWx1ZXiTeyJkYXRhVG9TdG9yZSI6IlRHbG1aU0JwY3lCaWIzSnBibWNzSUd4bGRDQjFjeUJ6Y0dsalpTQnBkQ0IxY0NCM2FYUm9JSE52YldVZ1lteHZZMnRqYUdGcGJpQm1kVzVySVE9PSIsIm15MTI4Qml0c1JhbmRvbSI6IklBTVRDNzNEMlB0b0dPdEVRVTlPUXc9PSJ9Z2FkZHJlc3N4RmMyNzRiNTAyYjk5YmUxZDA1NmFmY2UzYTRmZTI0ZmM2Y2NmZjM0NzdmOGJlYjE5ODk2YjdhYTY2ZTQ1MjVjYTAwMTdkY2U="}]}],"copy":"b81f74eec9f49fd8062c3a90dc5bd48249842ea6149b4a2e7cded38f50ca0e4d30cb66f6d74a807b737143f07fa2f7e807ef5dd44e3e03e89ac1f39ac41012f0"}'
}

@test "Pickup from path" {
    cat <<EOF | zexe pickup.zen dict-into-array.data
Given I have a 'string dictionary' named 'data' inside 'dataFromEndpoint'
When I pickup from path 'data.batches.header_signature'
When I pickup a 'string' from path 'data.header.previous_block_id'
When I pickup a 'string array' from path 'data.batches'
When I insert 'previous block id' in 'batches'
When I take 'state root hash' from path 'data.header'
Then print the 'header signature'
Then print the 'batches'
and print the 'state root hash'
EOF
    save_output 'pickup.zen'
    assert_output '{"batches":[{"header":{"signer_public_key":"0209373bda3561c82c246b226ab3dfdfcab5fbdcba3cb3969508ea5b427628bb1f","transaction_ids":["3ff09b69c5973eaed4f06214bfa45ad0cf3d88f92476f3f297b331efb7ec9ad51f27b94a217e0fe1c59a714f067bcdd9e595f8d73c8e3ab22a085b732fc8bb94"]},"header_signature":"b81f74eec9f49fd8062c3a90dc5bd48249842ea6149b4a2e7cded38f50ca0e4d30cb66f6d74a807b737143f07fa2f7e807ef5dd44e3e03e89ac1f39ac41012f0","trace":false,"transactions":[{"header":{"batcher_public_key":"0209373bda3561c82c246b226ab3dfdfcab5fbdcba3cb3969508ea5b427628bb1f","dependencies":[],"family_name":"restroom","family_version":"1.0","inputs":["c274b5"],"outputs":["c274b5"],"payload_sha512":"263e4334456dbe1c5904417e8d2b80d0235fd6766a7e71ca3b95bd0fa134b0fe7c722877ee44a715ac81d9dda0df8496abb3455c0f447c26e801dbdfba5f2bc3","signer_public_key":"0209373bda3561c82c246b226ab3dfdfcab5fbdcba3cb3969508ea5b427628bb1f"},"header_signature":"3ff09b69c5973eaed4f06214bfa45ad0cf3d88f92476f3f297b331efb7ec9ad51f27b94a217e0fe1c59a714f067bcdd9e595f8d73c8e3ab22a085b732fc8bb94","payload":"omV2YWx1ZXiTeyJkYXRhVG9TdG9yZSI6IlRHbG1aU0JwY3lCaWIzSnBibWNzSUd4bGRDQjFjeUJ6Y0dsalpTQnBkQ0IxY0NCM2FYUm9JSE52YldVZ1lteHZZMnRqYUdGcGJpQm1kVzVySVE9PSIsIm15MTI4Qml0c1JhbmRvbSI6IklBTVRDNzNEMlB0b0dPdEVRVTlPUXc9PSJ9Z2FkZHJlc3N4RmMyNzRiNTAyYjk5YmUxZDA1NmFmY2UzYTRmZTI0ZmM2Y2NmZjM0NzdmOGJlYjE5ODk2YjdhYTY2ZTQ1MjVjYTAwMTdkY2U="}]},"6cc4c895d2c7881954489750d598ff37fef6d299ee9fb5e19598094c7817b4ed02e6770f50defca760b6b6bef278f85e88ad352e18464bd4b7681b1211a34b64"],"header_signature":"b81f74eec9f49fd8062c3a90dc5bd48249842ea6149b4a2e7cded38f50ca0e4d30cb66f6d74a807b737143f07fa2f7e807ef5dd44e3e03e89ac1f39ac41012f0","state_root_hash":"2debd89f31b8a8d18b663f16ab19d2b70ae79414a73d29b20eb19b60a4353997"}'
}

@test "" {
    cat << EOF | save_asset filter_from.data
{
	"myDict": {
		 "name": "John",
		 "surname": "Doe",
		 "age": "42"
	},
	"myNestedArray": [
			 {
		 	  	"name": "John",
			  	"surname": "Doe",
		 	  	"age": "42"
			 },
		       	 {
		 	  	"name": "Jane",
		 	  	"surname": "Moe",
		 	  	"age": "31"
			 },
		         {
		 	  	"name": "Amber",
		 	  	"surname": "Williams",
		 	  	"age": "68"
			 },
		       	 {
		       		"surname": "Tyson"
			 }
	],
	"myNestedDict": {
		       "myDict1": {
		 	  	"name": "John",
			  	"surname": "Doe",
		 	  	"age": "42"
				},
		       "myDict2": {
		 	  	"name": "Jane",
		 	  	"surname": "Moe",
		 	  	"age": "31"
				},
		       "myDict3": {
		 	  	"name": "Bruce",
		 	  	"surname": "Wayne"
				},
		       "myDict4": {
		       		"surname": "Tyson"
				},
		       "myDict5": {
		       		"myDict6": {
					   "name": "Alfred",
					   "surname": "Pennyworth"
					   }
				}
	},
	"myNumberDict": {
			"height" : 182,
			"age" : 55
	},
	"filters": [
		   "name",
		   "age"
	]
}
EOF

    cat << EOF | zexe filter_from.zen filter_from.data
Given I have a 'string dictionary' named 'myDict'
Given I have a 'string array' named 'myNestedArray'
Given I have a 'string dictionary' named 'myNestedDict'
Given I have a 'number dictionary' named 'myNumberDict'

Given I have a 'string array' named 'filters'

When I filter 'filters' fields from 'myDict'
When I filter 'filters' fields from 'myNestedArray'
When I filter 'filters' fields from 'myNestedDict'
When I filter 'filters' fields from 'myNumberDict'

Then print the 'myDict'
and print the 'myNestedArray'
and print the 'myNestedDict'
and print the 'myNumberDict'
EOF
    save_output 'filter_from.json'
    assert_output '{"myDict":{"age":"42","name":"John"},"myNestedArray":[{"age":"42","name":"John"},{"age":"31","name":"Jane"},{"age":"68","name":"Amber"},[]],"myNestedDict":{"myDict1":{"age":"42","name":"John"},"myDict2":{"age":"31","name":"Jane"},"myDict3":{"name":"Bruce"},"myDict4":[],"myDict5":{"myDict6":{"name":"Alfred"}}},"myNumberDict":{"age":55}}'
}

@test "move statements" {
    cat << EOF | save_asset move.data
{
	"myDict": {
		 "name": "Bruce",
		 "surname": "Wayne",
		 "age": "44"
	},
	"myArray": [
			 "John",
			 "Doe",
		 	 "42"
	],
	"myString": "who?",
	"mySecondString": "where?",
	"name": "mySecondString"
}
EOF

    cat << EOF | zexe move.zen move.data
Given I have a 'string dictionary' named 'myDict'
Given I have a 'string array' named 'myArray'
Given I have a 'string' named 'myString'
Given I have a 'string' named 'mySecondString'
Given I have a 'string' named 'name'

When I move 'myString' in 'myDict'
When I move named by 'name' in 'myArray'
When I move 'surname' from 'myDict' to 'myArray'

When I create the 'string array' named 'myNewArray'
When I move 'name' from 'myDict' to 'myNewArray'

Then print the 'myDict'
and print the 'myArray'
and print the 'myNewArray'
EOF
    save_output 'move.json'
    assert_output '{"myArray":["John","Doe","42","where?","Wayne"],"myDict":{"age":"44","myString":"who?"},"myNewArray":["Bruce"]}'
}

@test "copy statements" {
    cat << EOF | save_asset copy.data
{
	"myDict": {
		 "name": "Bruce",
		 "surname": "Wayne",
		 "age": "44"
	},
	"myArray": [
			 "John",
			 "Doe",
		 	 "42"
	],
	"myString": "who?",
	"mySecondString": "where?",
	"name": "mySecondString"
}
EOF

    cat << EOF | zexe copy.zen copy.data
Given I have a 'string dictionary' named 'myDict'
Given I have a 'string array' named 'myArray'
Given I have a 'string' named 'myString'
Given I have a 'string' named 'mySecondString'
Given I have a 'string' named 'name'

When I copy 'myArray' in 'myDict'
When I copy 'myDict' in 'myArray'
When I copy named by 'name' in 'myArray'

Then print the 'myDict'
and print the 'myArray'
EOF
    save_output 'copy.json'
    assert_output '{"myArray":["John","Doe","42",{"age":"44","myArray":["John","Doe","42"],"name":"Bruce","surname":"Wayne"},"where?"],"myDict":{"age":"44","myArray":["John","Doe","42"],"name":"Bruce","surname":"Wayne"}}'
}
