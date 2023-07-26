#!/usr/bin/env bash

n_signatures=1000

if [ $# != 1 ]; then
    echo "Generating $n_signatures signatures and verify them.\nIf you want to use a different number use: $0 <number_of_signatures>"
else
    n_signatures=$1
    echo "Generating $n_signatures signatures and verify them."
fi

# much slower than zenroom foreach
echo signing $n_signatures times...
cp key_add_sign_gen.keys.bench add_and_sign.json
tmp=mktemp
start_time=`date +%s%N`
for ((i=1; i<=$n_signatures; i++)); do
    zenroom -a key_add_sign_gen.keys.bench -z key_add_sign_gen_manual.zen.bench >res_1.json 2>execution_data_1.txt
    if [ "$?" != "0" ]; then
        echo "Error during generation"
        cat execution_data_1.txt
        rm $tmp
        exit 1
    fi
    a=`jq -r '.ethereum_address' res_1.json`
    s=`jq -r '.ethereum_signature' res_1.json`
    jq --arg value_a $a --arg value_s $s '.ethereum_addresses[.ethereum_addresses| length] |= . + $value_a | 
                                    .ethereum_signatures[.ethereum_signatures| length] |= . + $value_s' add_and_sign.json > $tmp && mv $tmp add_and_sign.json
done
end_time=`date +%s%N`
echo generating: $((($end_time - $start_time)/1000)) microseconds

#max_iter=$(($n_signatures+3))
#tmp=mktemp
#jq --arg value $n_signatures '.n_signatures = $value' key_add_sign_gen.keys.bench > $tmp && mv $tmp key_add_sign_gen.keys.bench
#
#echo signing $n_signatures times...
#zenroom -c maxiter=dec:$max_iter -a key_add_sign_gen.keys.bench -z key_add_sign_gen.zen.bench > add_and_sign.json 2>execution_data_1.txt
#time_used_1=`cat execution_data_1.txt | grep "Time used" | cut -d: -f2`
#echo generate: $time_used_1 microseconds

echo verifying $n_signatures signatures...
zenroom -a add_and_sign.json -z batch_verification.zen.bench >res.json 2>execution_data.txt
if [ "`cat res.json`" != "{\"output\":[\"OK\"]}" ]; then
    echo "Error during verification"
    cat execution_data.txt
    exit 0
fi
time_used=`cat execution_data.txt | grep "Time used" | cut -d: -f2`
echo verify: $time_used microseconds
rm -f res.json execution_data.txt execution_data_1.txt #add_and_sign.json
