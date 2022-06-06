#!/usr/bin/env bash

#input has to be 'ecdh' or 'qp'
if [ $# != 1 ] || ([ $1 != 'ecdh' ] && [ $1 != 'qp' ]); 
then
    echo -e "Correct use:\n ./benchmark_sig.sh ecdh  -->  to compute ecdh benchmark \n ./benchmark_sig.sh qp    -->  to compute qp dilithium benchmark"
    exit 0
fi

DIR=$1
if [ $1 == 'qp' ]; then
    DIR=$1/dilithium
fi
SUBDOC=$1/benchmark

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
# and 'Sizes' to change the length of the messages that need to be signed and verified
Recursion=10000
Sizes="100 500 1000 2500 5000 7500 10000"


####################
# The results are saved in the files /tmp/zenroom-test-summary.txt,
# $1_keygen.txt and $1_sigver.txt.
# Before launching the program we need to clear those files
rm -f /tmp/zenroom-test-summary.txt
rm -f $1_keygen.csv
rm -f $1_sigver.csv


cycles=""
for i in $(seq $Recursion)
do
  cycles+=" Recursion_${i}"
done

echo -e "pri_time,pri_mem,pub_time,pub_mem" >> $1_keygen.csv
echo -e "sizes,sig_time,sig_mem,ver_time,ver_mem" >> $1_sigver.csv


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
## Signer Creation
signer_creation() {
    cat "$DIR/keygen.zen.example" | zexe keygen.zen | save $SUBDOC signer_keys.keys
    
    cat "$DIR/pubkeygen.zen.example" | zexe pubkeygen.zen -k signer_keys.keys  | save $SUBDOC signer_pubkey.json
}

for cycle in ${cycles[@]}
do
    rm -f signer_keys.keys signer_pubkey.json
    signer_creation
done

# The rows in the file /tmp/zenroom-test-summary now have the following form:
# OK    |    keygen.zen    |    time    |    output_size    |    memory
# OK    |  pubkeygen.zen   |    time    |    output_size    |    memory
# OK    |    keygen.zen    |    time    |    output_size    |    memory
# OK    |  pubkeygen.zen   |    time    |    output_size    |    memory
# ...

# Computes the mean time and memory usage of keygen.zen using the third and the fifth
# entry of the rows starting with "OK|keygen.zen"  of /tmp/zenroom-tesy-summary.txt  
keygen=(`cat /tmp/zenroom-test-summary.txt \
	    | tr -d '\t ' \
	    | grep "OK|keygen.zen" \
	    | awk -F'|' \
	    '{time_k += $3; mem_k += $5} \
	    END {print time_k, mem_k}'`)
time_keygen_mean=`bc -q <<< "scale=5; ${keygen[0]}/$Recursion"`
mem_keygen_mean=`bc -q <<< "scale=5; ${keygen[1]}/$Recursion"`

# Computes the mean time and memory usage of pubkeygen.zen using the third and the fifth
# entry of the even rows (they starts from 1) of /tmp/zenroom-tesy-summary.txt  
pubgen=(`cat /tmp/zenroom-test-summary.txt \
	     | tr -d '\t ' \
	     | grep "OK|pubkeygen.zen" \
	     | awk -F'|' \
	     '{time_p += $3; mem_p += $5} \
	     END {print time_p, mem_p}'`)
time_pubgen_mean=`bc -q <<< "scale=5; ${pubgen[0]}/$Recursion"`
mem_pubgen_mean=`bc -q <<< "scale=5; ${pubgen[1]}/$Recursion"`

# Print the results
echo -e "$time_keygen_mean,$mem_keygen_mean,$time_pubgen_mean,$mem_pubgen_mean" >> $1_keygen.csv

#############################
# SIGNATURE AND VERIFICATION PHASE
# In order to collect in an safer way the data for the signature
# we erase the data in the file /tmp/zenroom-test-summary.txt
rm -f /tmp/zenroom-test-summary.txt


create_message(){
    cat <<EOF | save $SUBDOC ${1}_byte_tosign.json 
{
"message":"`echo "print(O.random($1))" | $Z`"
}
EOF
}

create_signature(){
    create_message $1
    cat "$DIR/signing.zen.example" | zexe signing.zen -k signer_keys.keys -a ${1}_byte_tosign.json | save $SUBDOC signature.json
}

verify_signature(){
    cat "$DIR/verify.zen.example" | zexe verify.zen -a to_verify.json | jq .
}

for size in ${Sizes[@]}
do
    # SIGNING SESSION
    for cycle in ${cycles[@]}
    do
	echo "=========================================================="
	echo "now signing the message of length: $size, n: ${cycle}"
	echo "=========================================================="
	echo  "" 
	rm -f signature.json
	create_signature $size
    done
    
    # For each size we compute the mean time and memory usage of signing.zen
    sig=(`cat /tmp/zenroom-test-summary.txt \
	  | tr -d '\t ' \
	  | grep "OK|signing.zen" \
	  | awk -F'|' \
	  '{time_s += $3; mem_s += $5} \
	  END {print time_s, mem_s}'`)
    time_sig_mean=`bc -q <<< "scale=5; ${sig[0]}/$Recursion"`
    mem_sig_mean=`bc -q <<< "scale=5; ${sig[1]}/$Recursion"`

    # Finally we erase the data in /tmp/zenroom-test-summary.txt
    rm -f /tmp/zenroom-test-summary.txt

    # Prepare the input file for the verification phase
    jq -s '.[0] * .[1]' signer_pubkey.json signature.json | save $SUBDOC to_verify.json

    # VERIFYING  SESSION
    for cycle in ${cycles[@]}
    do
	echo "=========================================================="
	echo "now verifying the signatures n: ${cycle}"
	echo "=========================================================="
	echo  "" 
	verify_signature
    done

    # For each size we compute the mean time and memory usage of verify.zen
    ver=(`cat /tmp/zenroom-test-summary.txt \
	  | tr -d '\t ' \
	  | grep "OK|verify.zen" \
	  | awk -F'|' \
	  '{time_v += $3; mem_v += $5} \
	  END {print time_v, mem_v}'`)
    time_ver_mean=`bc -q <<< "scale=5; ${ver[0]}/$Recursion"`
    mem_ver_mean=`bc -q <<< "scale=5; ${ver[1]}/$Recursion"`

    echo -e "$size,$time_sig_mean,$mem_sig_mean,$time_ver_mean,$mem_ver_mean" >> $1_sigver.csv

    rm -f /tmp/zenroom-test-summary.txt
done



for i in *.zen; do cat $i | save $SUBDOC $i; done

#Clean the folder
rm *.keys *.json *.zen
rm -rf ../../docs/examples/zencode_cookbook/qp/benchmark/
rm -rf ../../docs/examples/zencode_cookbook/ecdh/benchmark/

echo -e "${magenta}\n \n<============================================>${reset}"
echo -e "${green}\n Change the value of 'Sizes' in the beginning of the script, to change the length of the messages to be signed, and the 'Recursion' in order to change how many time the signature related scripts should cycle. Currently: \n\n - 'Length' are: ${red} $Sizes \n${green} - 'Recursion' is: ${yellow} $Recursion \n" 
echo -e "${magenta}<============================================>${reset}\n"
