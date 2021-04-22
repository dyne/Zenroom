#!/usr/bin/env bash


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

out=../../docs/examples/zencode_cookbook
# out=/dev/shm/files

set -e

cat <<EOF | zexe ${out}/numbers_hash_left.zen | tee ${out}/numbers_left.json 
Given nothing
When I write string 'a left string to be hashed' in 'source'
and I create the hash of 'source'
and I rename 'hash' to 'left'
Then print 'left'
EOF

cat <<EOF | zexe ${out}/numbers_hash_right.zen | tee ${out}/numbers_right.json
Given nothing
When I write string 'a right string to be hashed' in 'source'
and I create the hash of 'source'
and I rename 'hash' to 'right'
Then print 'right'
EOF

cat <<EOF | zexe ${out}/numbers_hash_eq.zen -a ${out}/numbers_left.json
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

cat <<EOF | zexe ${out}/numbers_num_eq_base10.zen
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


cat <<EOF | zexe ${out}/numbers_cmp_base10.zen | jq
rule check version 1.0.0
Given nothing
When I write number '10' in 'left'
and I write number '20' in 'right'
and number 'left' is less or equal than 'right'
Then print the string 'OK'
Then print data
EOF



# cat <<EOF | zexe cmp_nlt_base10.zen
# rule check version 1.0.0
# Given nothing
# When I write number '10' in 'left'
# and I write number '20' in 'right'
# and number 'right' is less than 'left'
# Then print the string 'OK'
# EOF



cat <<EOF | zexe ${out}/numbers_cmp_base16.zen | jq
rule check version 1.0.0
Given nothing
When I set 'left' to '0a' base '16'
and I set 'right' to '14' base '16'
and number 'left' is less or equal than 'right'
Then print the string 'OK'
Then print data
EOF

cat <<EOF | zexe ${out}/numbers_cmp_base16_less.zen | jq
rule check version 1.0.0
Given nothing
When I set 'left' to '0a' base '16'
and I set 'right' to '14' base '16'
and number 'left' is less than 'right'
Then print the string 'OK'
Then print data
EOF

cat << EOF > ${out}/numbers_zero_values.json | jq
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

cat << EOF | zexe ${out}/numbers_remove_zero_values.zen -a ${out}/numbers_zero_values.json | jq
Given I have a 'string dictionary' named 'packet'
When I remove zero values in 'packet'
Then print all data
EOF

cat <<EOF | zexe ${out}/big_numbers_cmp_base10.zen | jq
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


success
