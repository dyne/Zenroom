#!/usr/bin/env bash

n_signatures=1000

if [ $# != 1 ]; then
    printf "Generating $n_signatures signatures and verify them.\nIf you want to use a different number use: $0 <number_of_signatures>\n"
else
    n_signatures=$1
    echo "Generating $n_signatures signatures and verify them."
fi
msg='"message": "I love the Beatles, all but 3",'

echo
echo Signing $n_signatures times...
echo '"address_signature_pair": [' >addresses_signatures.txt
time for ((i=1; i<=$n_signatures; i++)); do
    zenroom -a key_add_sign_gen.keys.bench -z key_add_sign_gen_manual.zen.bench >res_1.json 2>execution_data_1.txt
    if [ "$?" != "0" ]; then
        echo "Error during generation"
        cat execution_data_1.txt
        exit 1
    fi
    if [ "$i" != "$n_signatures" ]; then
        cat res_1.json | cut -d: -f2- | cut -d\} -f1-2 | sed 's/$/,/' >> addresses_signatures.txt
    else
        cat res_1.json | cut -d: -f2- | cut -d\} -f1-2 >> addresses_signatures.txt
    fi
done
echo ']' >>addresses_signatures.txt
echo "{$msg" > add_and_sign.json
cat addresses_signatures.txt >> add_and_sign.json
echo "}" >> add_and_sign.json
rm res_1.json execution_data_1.txt addresses_signatures.txt

echo
echo Verifying $n_signatures signatures...
time zenroom -a add_and_sign.json -z batch_verification.zen.bench >res_2.json 2>execution_data_2.txt
if [ "`cat res_2.json`" != "{\"output\":[\"OK\"]}" ]; then
    echo "Error during verification"
    cat execution_data_2.txt
    exit 0
fi
rm -f res_2.json execution_data_2.txt

echo
echo Create the verification result of $n_signatures signatures...
time zenroom -a add_and_sign.json -z batch_verification_result.zen.bench >res_3.json 2>execution_data_3.txt
if [ "$?" != "0" ]; then
    echo "Error during verification result creation"
    cat execution_data_3.txt
    exit 0
fi
cat res_3.json | grep "not verified"
rm -f res_3.json execution_data_3.txt add_and_sign.json
