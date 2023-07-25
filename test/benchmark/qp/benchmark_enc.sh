#!/usr/bin/env bash

#input has to be 'ecdh' or 'qp'
if [ $# != 1 ] || ([ $1 != 'ecdh' ] && [ $1 != 'kyber' ] && [ $1 != 'ntrup' ]); 
then
    echo -e "Correct use:\n ./benchmark_enc.sh ecdh     -->  to compute ecdh benchmark \n ./benchmark_enc.sh kyber    -->  to compute qp kyber benchmark \n ./benchmark_enc.sh ntrup    -->  to compute qp ntrup benchmark"
    exit 0
fi

if ([ $1 == 'kyber' ] || [ $1 == 'ntrup' ]);
then
    DIR=qp/$1

else
    DIR=$1
fi
SUBDOC=$DIR/benchmark

######
# Setup output color aliases
#
# echo "${red}red text ${green}green text${reset}"
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
reset=`tput sgr0`

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh 
Z="`detect_zenroom_path` `detect_zenroom_conf`"

#################
# Change 'Recursion' to change the amount of recursion
# Change 'Size' to change the length of the message to be encrypted
# 32 is raccomanded since it is the same length of the secret created by Kyber and ntrup
Recursion=10000
Size=32


####################
# The results are saved in the files /tmp/zenroom-test-summary.txt,
# $1_keygen.txt and $1_sigver.txt.
# Before launching the program we need to clear those files
rm -f /tmp/zenroom-test-summary.txt
rm -f $1_enc_keygen.csv
rm -f $1_enc.csv


cycles=""
for i in $(seq $Recursion)
do
  cycles+=" Recursion_${i}"
done

echo -e "pri_time,pri_mem,pub_time,pub_mem" >> $1_enc_keygen.csv
echo -e "enc_time,enc_mem,dec_time,dec_mem" >> $1_enc.csv


#################
##### Template User Recursion
echo -e "${green} ======================================================" 
echo -e "${green} ======================================================" 
echo -e "${green} ======================================================" 
echo -e "${green} =============== START SCRIPT =========================" 
echo -e "${green} ======================================================" 
echo -e "${green} ======================================================" 
echo -e "${green} ======================================================${reset}" 


#############################
## Receiver and Sender Creation
# For kyber it is only needed the receiver
# For ecdh both are needed
receiver_creation() {
    cat "$DIR/enc_keygen.zen.example" | zexe enc_keygen.zen | save $SUBDOC receiver_keys.keys
    cat "$DIR/enc_pubkeygen.zen.example" | zexe enc_pubkeygen.zen -k receiver_keys.keys  | save $SUBDOC receiver_pubkey.json
}

sender_creation() {
    cat "$DIR/enc_sender_keygen.zen.example" | zexe enc_sender_keygen.zen | save $SUBDOC sender_keys.keys
    cat "$DIR/enc_sender_pubkeygen.zen.example" | zexe enc_sender_pubkeygen.zen -k sender_keys.keys  | save $SUBDOC sender_pubkey.json
}

for cycle in ${cycles[@]}
do
    rm -f receiver_keys.keys receiver_pubkey.json
    receiver_creation
done

# The rows in the file /tmp/zenroom-test-summary now have the following form:
# OK    |    enc_keygen.zen    |    time    |    output_size    |    memory
# OK    |  enc_pubkeygen.zen   |    time    |    output_size    |    memory
# OK    |    enc_keygen.zen    |    time    |    output_size    |    memory
# OK    |  enc_pubkeygen.zen   |    time    |    output_size    |    memory
# ...

# Computes the mean time and memory usage of enc_keygen.zen using the third and the fifth
# entry of the rows starting with "OK|enc_keygen.zen"  of /tmp/zenroom-tesy-summary.txt  
keygen=(`cat /tmp/zenroom-test-summary.txt \
	    | tr -d '\t ' \
	    | grep "OK|enc_keygen.zen" \
	    | awk -F'|' \
	    '{time_k += $3; mem_k += $5} \
	    END {print time_k, mem_k}'`)
time_keygen_mean=`bc -q <<< "scale=5; ${keygen[0]}/$Recursion"`
mem_keygen_mean=`bc -q <<< "scale=5; ${keygen[1]}/$Recursion"`

# Computes the mean time and memory usage of enc_pubkeygen.zen using the third and the fifth
# entry of the even rows (they starts from 1) of /tmp/zenroom-tesy-summary.txt  
pubgen=(`cat /tmp/zenroom-test-summary.txt \
	     | tr -d '\t ' \
	     | grep "OK|enc_pubkeygen.zen" \
	     | awk -F'|' \
	     '{time_p += $3; mem_p += $5} \
	     END {print time_p, mem_p}'`)
time_pubgen_mean=`bc -q <<< "scale=5; ${pubgen[0]}/$Recursion"`
mem_pubgen_mean=`bc -q <<< "scale=5; ${pubgen[1]}/$Recursion"`

# Print the results
echo -e "$time_keygen_mean,$mem_keygen_mean,$time_pubgen_mean,$mem_pubgen_mean" >> $1_enc_keygen.csv


#############################
## ENCRYPTION AND DECRYPTION PHASE
# In order to collect in an safer way the data for the encryption
# we erase the data in the file /tmp/zenroom-test-summary.txt
rm -f /tmp/zenroom-test-summary.txt

create_message(){
    cat <<EOF | save $SUBDOC ${Size}_byte_toencrypt.json
{
"message":"`echo "print(O.random($Size))" | $Z`"
}
EOF
    jq -s '.[0] * .[1]' receiver_pubkey.json ${Size}_byte_toencrypt.json | save $SUBDOC to_encrypt.json
}

create_cipher(){
    if [ $DIR == "ecdh" ]; then
	create_message
	cat "$DIR/encrypting.zen.example" | zexe encrypting.zen -k sender_keys.keys -a to_encrypt.json | save $SUBDOC tmp.json
	# ecdh needs the sender public key to be able to decrypt the message
	jq -s '.[0]*.[1]' tmp.json sender_pubkey.json | save $SUBDOC to_decrypt.json
    else
	cat "$DIR/encrypting.zen.example" | zexe encrypting.zen -a receiver_pubkey.json | save $SUBDOC to_decrypt.json
    fi
}

decrypt_secret(){
    cat "$DIR/decrypting.zen.example" | zexe decrypting.zen -k receiver_keys.keys -a to_dec.json
}

## ENCRYPTING SESSION

if [ $DIR == "ecdh" ]; then
    sender_creation
    rm -f /tmp/zenroom-test-summary.txt
fi

for cycle in ${cycles[@]}
do
    echo "=========================================================="
    echo "now encrypting the secret n: ${cycle}"
    echo "=========================================================="
    echo  "" 
    rm -f to_decrypt.json
    create_cipher
done

# compute the mean time and memory usage of encrypting.zen
cipher=(`cat /tmp/zenroom-test-summary.txt \
	     | tr -d '\t ' \
	     | grep "OK|encrypting.zen" \
	     | awk -F'|' \
	     '{time_s += $3; mem_s += $5} \
	     END {print time_s, mem_s}'`)
time_enc_mean=`bc -q <<< "scale=5; ${cipher[0]}/$Recursion"`
mem_enc_mean=`bc -q <<< "scale=5; ${cipher[1]}/$Recursion"`

# Erase the data in /tmp/zenroom-test-summary.txt
rm -f /tmp/zenroom-test-summary.txt


## DECRYPTING  SESSION
# Putting all the data together
if [ $DIR == "ecdh" ]; then
    jq -s '.[0] * .[1]' sender_pubkey.json to_decrypt.json | save $SUBDOC to_dec.json
else
    cat "to_decrypt.json" | save $SUBDOC to_dec.json
fi

for cycle in ${cycles[@]}
do
    echo "=========================================================="
    echo "now decrypting the cipher n: ${cycle}"
    echo "=========================================================="
    echo  "" 
    decrypt_secret
done

# Compute the mean time and memory usage of decrypting.zen
decrypt=(`cat /tmp/zenroom-test-summary.txt \
	      | tr -d '\t ' \
	      | grep "OK|decrypting.zen" \
	      | awk -F'|' \
	      '{time_v += $3; mem_v += $5} \
	      END {print time_v, mem_v}'`)
time_dec_mean=`bc -q <<< "scale=5; ${decrypt[0]}/$Recursion"`
mem_dec_mean=`bc -q <<< "scale=5; ${decrypt[1]}/$Recursion"`

echo -e "$time_enc_mean,$mem_enc_mean,$time_dec_mean,$mem_dec_mean" >> $1_enc.csv


for i in *.zen; do cat $i | save $SUBDOC $i; done

# Clean the folder
rm *.keys *.json *.zen
rm -rf ../../docs/examples/zencode_cookbook/qp/kyber/benchmark/
rm -rf ../../docs/examples/zencode_cookbook/qp/ntrup/benchmark/
rm -rf ../../docs/examples/zencode_cookbook/ecdh/benchmark/

echo -e "${magenta}\n \n<============================================>${reset}"
echo -e "${green}\n Change the 'Recursion' in order to change how many time the encryption related scripts should cycle. Currently: \n\n - 'Recursion' is: ${yellow} $Recursion \n" 
echo -e "${magenta}<============================================>${reset}\n"
