#!/usr/bin/env bash


####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

cat <<EOF | zexe numbers_hash_left.zen | save numbers numbers_left.json
Given nothing
When I write string 'a left string to be hashed' in 'source'
and I create the hash of 'source'
and I rename 'hash' to 'left'
Then print 'left'
EOF

cat <<EOF | zexe numbers_hash_right.zen | save numbers numbers_right.json
Given nothing
When I write string 'a right string to be hashed' in 'source'
and I create the hash of 'source'
and I rename 'hash' to 'right'
Then print 'right'
EOF

cat <<EOF | zexe numbers_hash_eq.zen -a numbers_left.json
Given I have a 'base64' named 'left'
When I write string 'a left string to be hashed' in 'source'
and I create the hash of 'source'
When I verify 'left' is equal to 'hash'
Then print the string 'OK'
Then print data
EOF

# cat <<EOF | debug ${out}/numbers_hash_eq.zen -a ${out}/numbers_left.json -k ${out}/numbers_right.json | jq
# cat <<EOF | zexe hash_neq.zen -a left.json -k right.json
# Given I have a 'base64' named 'left'
# and I have a 'base64' named 'right'
# When I verify 'left' is equal to 'right'
# Then print the string 'OK'
# EOF

cat <<EOF | zexe numbers_num_eq_base10.zen
rule check version 1.0.0
Given nothing
When I write number '42' in 'left'
and I write number '42' in 'right'
and I verify 'left' is equal to 'right'
Then print the string 'OK'
Then print data
EOF

# cat <<EOF | zexe num_neq_base10.zen
# rule check version 1.0.0
# Given nothing
# When I write number '142' in 'left'
# and I write number '42' in 'right'
# and I verify 'left' is equal to 'right'
# Then print the string 'OK'
# EOF


cat <<EOF | zexe numbers_cmp_base10.zen
rule check version 1.0.0
Given nothing
When I write number '10' in 'left'
and I write number '20' in 'right'
and number 'left' is less or equal than 'right'
Then print the string 'OK'
Then print data
EOF

cat <<EOF | zexe number_cast.zen
rule check version 1.0.0
Given nothing
When I write string '1234' in 'str'
and I create the number from 'str'
Then print all data
EOF


# cat <<EOF | zexe cmp_nlt_base10.zen
# rule check version 1.0.0
# Given nothing
# When I write number '10' in 'left'
# and I write number '20' in 'right'
# and number 'right' is less than 'left'
# Then print the string 'OK'
# EOF



cat <<EOF | zexe numbers_cmp_base16.zen
rule check version 1.0.0
Given nothing
When I set 'left' to '0a' base '16'
and I set 'right' to '14' base '16'
and number 'left' is less or equal than 'right'
Then print the string 'OK'
Then print data
EOF

cat <<EOF | zexe numbers_cmp_base16_less.zen
rule check version 1.0.0
Given nothing
When I set 'left' to '0a' base '16'
and I set 'right' to '14' base '16'
and number 'left' is less than 'right'
Then print the string 'OK'
Then print data
EOF

cat <<EOF | save numbers boolean.json
{ "mycat": {
    "black": true,
    "white": false,
     "name": "cat",
     "age": 6 }
}
EOF
cat <<EOF | zexe booleans.zen -a boolean.json
Given I have a 'string dictionary' named 'mycat'
Then print all data
EOF


cat << EOF > numbers_zero_values.json
{"packet": {
"Active_power_imported_kW":4.85835600,
"Active_energy_imported_kWh":53.72700119,
"Active_power_exported_kW":0.00000000,
"Active_energy_exported_kWh":33.39500046,
"Reactive_power_imported_kVAR":4.79620409,
"Reactive_energy_imported_kVARh":19.91500092,
"Reactive_power_exported_kVAR":0.00000000,
"Reactive_energy_exported_kVARh":51.02199936,
"Apparent_power_imported_kVA":6.82719707,
"Apparent_energy_imported_kVAh":0.00000000,
"Apparent_power_exported_kVA":0.00000000,
"Apparent_energy_exported_kVAh":0.00000000,
"Power_factor":0.71163559,
"Supply_frequency_Hz":50.00131226,
"FREE_VAL_15":0.00000000,
"FREE_VAL_16":0.00000000,
"FREE_VAL_17":0.00000000,
"FREE_VAL_18":0.00000000,
"FREE_VAL_19":0.00000000,
"User_data":"User_data_string",
"Application_data":"Application_data_string",
"Application_UID":"Application_UID_string",
"Application_type":"Application_type_string",
"Energy_price_for_client":0.00000000,
"Currency":"EUR",
"Maximum_power_kWp":0.00000000,
"Expected_annual_production":0.00000000,
} }
EOF

cat << EOF | zexe numbers_remove_zero_values.zen -a numbers_zero_values.json
Given I have a 'string dictionary' named 'packet'
When I remove zero values in 'packet'
Then print all data
EOF

cat <<EOF | zexe big_numbers_cmp_base10.zen
rule check version 1.0.0
Given nothing
When I write number '161917811' in 'left'
and I write number '161917812' in 'right'
and number 'left' is less or equal than 'right'
Then print the string 'OK'
Then print data
EOF


# cat <<EOF | debug ${out}/big_number_import_base10.zen -a decimal.json -k timestamp.json
# Given I have a 'number' named 'decimal'
# Given I have a 'number' named 'timestamp'
# and debug
# When I create the 'string dictionary'
# and I rename the 'string dictionary' to 'outputData'
# and I create the result of 'timestamp' - 'decimal'
# Then print 'decimal' as 'string'
# and print 'timestamp' as 'number'
# and print 'result' as 'number'
# EOF

cat << EOF | save numbers number_dict.json
{
	"Transactions1Data": {
		"timestamp": 1597573139,
		"TransactionValue": 1500,
		"PricePerKG": 100,
		"TransferredProductAmount": 15,
		"UndeliveredProductAmount": 7,
		"ProductPurchasePrice": 50
	},
	"Transactions2Data": {
		"timestamp": 1597573239,
		"TransactionValue": 1600,
		"TransferredProductAmount": 20,
		"PricePerKG": 80
	},
	"dictionaryToBeFound": "Information",
	"salesStartTimestamp": 1597573200,
	"lastYearPricePerKG": 30,
	"lastYearMonthlySales": 15,
	"lastYearAvgTransactionsValue": 1500
}
EOF

cat << EOF | zexe divisions.zen -a number_dict.json
Rule check version 2.0.0
Scenario 'ecdh': keypair management and ECDSA signature

# Here we load a keypair to sign stuff
# Given that I am 'JackInTheShop'
# Given that I have my valid 'keypair'

# Here we are loading string dictionaries that contain numbers we will use
Given that I have a 'string dictionary' named 'Transactions1Data'
Given that I have a 'string dictionary' named 'Transactions2Data'

# Here we load some numbers that are at root level
Given that I have a 'number' named 'salesStartTimestamp'
Given that I have a 'number' named 'lastYearPricePerKG'
Given that I have a 'number' named 'lastYearMonthlySales'
Given that I have a 'number' named 'lastYearAvgTransactionsValue'


# Here we calculate the difference of two values, inside two dictionaries
When I create the result of 'TransferredProductAmount' in 'Transactions1Data' - 'TransferredProductAmount' in 'Transactions2Data'
and I rename the 'result' to 'salesDifference'


# Here we divide a number at root level with a number inside a dictionary
When I create the result of 'lastYearAvgTransactionsValue' / 'TransactionValue' in 'Transactions2Data'
and I rename the 'result' to 'percentOfSalesinTransaction2'

When I create the result of 'PricePerKG' in 'Transactions1Data' / 'lastYearPricePerKG'
and I rename the 'result' to 'priceRampinTransaction1'


# Here we create a dictionary
When I create the 'number dictionary'
and I rename the 'number dictionary' to 'salesReport'

# Here we insert elements into the newly created dictionary

When I insert 'salesDifference' in 'salesReport'
When I insert 'priceRampinTransaction1' in 'salesReport'
When I insert 'percentOfSalesinTransaction2' in 'salesReport'


When I create the hash of 'salesReport' using 'sha256'
When I rename the 'hash' to 'salesReport.hash'

# Here we produce an ECDSA signature the newly created dictionary using
# When I create the signature of 'salesReport'
# and I rename the 'signature' to 'salesReport.signature'

#Print out the data we produced along
Then print the 'salesReport'
# Then print the 'salesReport.signature'
Then print the 'salesReport.hash'
EOF
cat <<EOF  >big_pos_and_neg.data
{
  "a": "100000000000000",
  "b": "-20000000000000000",
  "fp1": "1.0",
  "fp2": "2.0",
  "c": 50000,
  "d": 5.6,
  "array": [ 5000, 5.6, "1.0", "1000000", "-300", "stringa" ]
}
EOF

# | zexe big_pos_and_neg.zen -a big_pos_and_neg.data
cat <<EOF | debug big_pos_and_neg.zen -a big_pos_and_neg.data
Given I have a 'number' named 'a'
Given I have a 'number' named 'b'
Given I have a 'float' named 'fp1'
Given I have a 'number' named 'fp2'
Given I have a 'number' named 'c'
Given I have a 'number' named 'd'
Given I have a 'string array' named 'array'
When I create the result of 'a' + 'b'
and I rename the 'result' to 'a+b'
When I create the result of 'a' - 'b'
and I rename the 'result' to 'a-b'
When I create the result of 'b' - 'a'
and I rename the 'result' to 'b-a'
When I create the result of 'b' + 'a'
and I rename the 'result' to 'b+a'
When I create the result of 'b' * 'a'
and I rename the 'result' to 'b*a'
When I create the result of 'b' / 'a'
and I rename the 'result' to 'b/a'
# When I delete the 'array'
Then print all data
EOF

cat <<EOF >expressions.data
{
  "a": "1",
  "b": "2",
  "c": "-3",
  "d": "4",
  "the solution": "42",
  "11": "22",
}
EOF

cat <<EOF | debug expressions.zen -a expressions.data
Given I have a 'integer' named 'a'
Given I have a 'integer' named 'b'
Given I have a 'integer' named 'c'
Given I have a 'integer' named 'd'
Given I have a 'integer' named 'the solution'
When I create the result of 'a * b + c'
and I rename 'result' to 'expr1'
When I create the result of 'a * (b + c)'
and I rename 'result' to 'expr2'
When I create the result of '(the solution  + a) * (b + c)'
and I rename 'result' to 'expr3'
When I create the result of '((the solution * d + b)  + a) * (b + (c + a * the solution))'
and I rename 'result' to 'expr4'
When I create the result of '(a + b * (a + b * (a + b))) * c + a'
and I rename 'result' to 'expr5'
When I create the result of 'b * b * b * b+a'
and I rename 'result' to 'expr6'
When I create the result of '(a + b) * (a + b) * (a + b * (a + b * (a + b))) * c + a'
and I rename 'result' to 'expr7'
When I create the result of 'the solution / (a + b + 1)'
and I rename 'result' to 'expr8'
When I create the result of '-a * (-b -c - (-c+d))'
and I rename 'result' to 'expr9'
EOF

cat <<EOF >expressions_float.data
{
  "a": "1.0",
  "b": "2.0",
  "c": "-3.0",
  "d": "4.0",
  "the solution": "42.0",
}
EOF

cat <<EOF | debug expressions_float.zen -a expressions_float.data
Given I have a 'float' named 'a'
Given I have a 'float' named 'b'
Given I have a 'float' named 'c'
Given I have a 'float' named 'd'
Given I have a 'float' named 'the solution'
When I create the result of 'the solution / (a + b + 1.0)'
and I rename 'result' to 'expr1'
When I create the result of '  (   (    a +   b  )   * ( b   +  c)) * (a / d)'
and I rename 'result' to 'expr2'
When I create the result of 'a / b / c'
and I rename 'result' to 'expr3'
When I create the result of 'a / b * c / d + a * b / c / d'
and I rename 'result' to 'expr4'
When I create the result of '-a * (-b -c - (-c+d))'
and I rename 'result' to 'expr5'
EOF


success
