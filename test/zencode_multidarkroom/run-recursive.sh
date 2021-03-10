#!/usr/bin/env bash



####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

#### SETUP OUTPUT FOLDER and cleaning
# ${out}/credentialParticipantKeygen.zen
# out='../../docs/examples/zencode_cookbook'
out='/dev/shm/files'

mkdir -p ${out}
rm ${out}/*
rm /tmp/zenroom-test-summary.txt



# echo "${red}red text ${green}green text${reset}"
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
reset=`tput sgr0`


#################
# Change this to change the amount of participants 
# and the amount of recursion for some of the scripts

Participants=10
Recursion=1

users=""
for i in $(seq $Participants)
do
  users+=" Participant_${i}"
done

cycles=""
for i in $(seq $Recursion)
do
  cycles+=" Recursion_${i}"
done

#################
##### Template User Recursion
# for user in ${users[@]}
# do
# echo  ${user}
# done
# exit 0



echo -e "${reset} "
echo -e "${green} ======================================================" 
echo -e "${green} ======================================================" 
echo -e "${green} ======================================================" 
echo -e "${green} =============== START SCRIPT =========================" 
echo -e "${green} ======================================================" 
echo -e "${green} ======================================================" 
echo -e "${green} ======================================================" 
echo -e "${reset} "


## ISSUER creation
cat <<EOF | zexe ${out}/issuer_keygen.zen  | jq . | tee ${out}/issuer_key.json
Scenario credential
Given I am 'The Authority'
when I create the issuer key
Then print my 'keys'
EOF

cat <<EOF | zexe ${out}/issuer_credential.zen -k ${out}/issuer_key.json  | jq . | tee ${out}/credential.json
Scenario credential: publish verifier
Given that I am known as 'The Authority'
and I have my 'keys'
When I create the issuer public key
Then print my 'issuer public key'
EOF
##




generate_participant() {
    local name=$1
    ## PARTICIPANT
	cat <<EOF | zexe ${out}/keygen_${1}.zen  | jq . | tee ${out}/keypair_${1}.json
Scenario multidarkroom
Scenario credential
Given I am '${1}'
When I create the BLS key
and I create the credential key
Then print my 'keys'
EOF

	cat <<EOF | zexe ${out}/pubkey_${1}.zen -k ${out}/keypair_${1}.json  | jq . | tee ${out}/verifier_${1}.json
Scenario multidarkroom
Given I am '${1}'
and I have my 'keys'
When I create the BLS public key
Then print my 'bls public key'
EOF


	cat <<EOF | zexe ${out}/request_${1}.zen -k ${out}/keypair_${1}.json  | jq . | tee ${out}/request_${1}.json
Scenario credential
Given I am '${1}'
and I have my 'keys'
When I create the credential request
Then print my 'credential request'
EOF
	##

	## ISSUER SIGNS
	cat <<EOF | zexe ${out}/issuer_sign_${1}.zen -k ${out}/issuer_key.json -a ${out}/request_${1}.json  | jq . | tee ${out}/issuer_signature_${1}.json
Scenario credential
Given I am 'The Authority'
and I have my 'keys'
and I have a 'credential request' inside '${1}'
when I create the credential signature
and I create the issuer public key
Then print the 'credential signature'
and print the 'issuer public key'
EOF
	##

	## PARTICIPANT AGGREGATES SIGNED CREDENTIAL
	cat <<EOF | zexe ${out}/aggr_cred_${1}.zen -k ${out}/keypair_${1}.json -a ${out}/issuer_signature_${1}.json  | jq . | tee ${out}/verified_credential_${1}.json
Scenario credential
Given I am '${1}'
and I have my 'keys'
and I have a 'credential signature'
when I create the credentials
then print my 'credentials'
and print my 'keys'
EOF
	##

}

# generate two signed credentials

for user in ${users[@]}
do
generate_participant ${user}
echo  "now generating the participant: "  ${user}
done

# exit 0


issuer_keygen_sign() {
## ISSUER SIGNS

	cat <<EOF | zexe ${out}/issuer_sign_${1}.zen -k ${out}/issuer_key.json -a ${out}/request_${1}.json  | jq . | tee ${out}/issuer_signature_${1}.json
Scenario credential
Given I am 'The Authority'
and I have my 'keys'
and I have a 'credential request' inside '${1}'
when I create the credential signature
and I create the issuer public key
Then print the 'credential signature'
and print the 'issuer public key'
EOF
	##

}


for user in ${users[@]}
do
issuer_keygen_sign ${user}
echo  "Issuer creates keypair, verifier and signs the request from: "  ${user}
done

# exit 0






# agent: signature caller
# verb:  aggregate
# obj:   verifiers (sum of all participant verifiers)
# verb:  create
# obj:   uid (arbitrary string, may be the hash of a document)
# obj:   multisignature (session to sign uid)

# join the verifiers of signed credentials

# jq -s 'reduce .[] as $item ({}; . * $item)' . verifier_Alice.json verifier_Bob.json verifier_Carl.json verifier_Derek.json verifier_Eva.json verifier_Frank.json verifier_Gina.json verifier_Jessie.json verifier_Karl.json verifier_Ingrid.json | tee verifiers.json

jq -s 'reduce .[] as $item ({}; . * $item)' . ${out}/verifier_* | tee ${out}/verifiers.json


echo "{\"today\": \"`date +'%s'`\"}" > ${out}/uid.json

# anyone can start a session
#############################
### SCRIPT THAT PRODUCES THE MULTISIGNATURE
#############################

multisignature="Scenario multidarkroom \n"

for user in ${users[@]}
do

multisignature+="Given I have a 'bls public key' from '${user}' \n"  
done

multisignature+="Given I have a 'string' named 'today' \nWhen I create the multidarkroom session with uid 'today' \nThen print the 'multidarkroom session'\n"

echo -e "\n \n \n THis is the multisig script: \n \n \n" $multisignature 



#############################
# SIGNING SESSION

create_multisignature(){
echo -e $multisignature | zexe ${out}/session_start.zen -k ${out}/uid.json -a ${out}/verifiers.json > ${out}/multisignature.json
#
# TODO: credentials may be included in the multisignature
}

# preparing for the cycle


for cycle in ${cycles[@]}
do

rm -f ${out}/multisignature.json
create_multisignature

done

# create_multisignature

# participant is told of the multisignature and offered to sign
# participant joins the credential (=issuer pubkey) and the multisignature
json_join ${out}/credential.json ${out}/multisignature.json | jq . > ${out}/credential_to_sign.json

cp multisignature.json multisignature_input.json

# PARTICIPANT SIGNS (function)
function participant_sign() {
	local name=$1
	cat <<EOF | zexe ${out}/sign_session.zen -a ${out}/credential_to_sign.json -k ${out}/verified_credential_$name.json  | jq . | tee ${out}/signature_$name.json
Scenario multidarkroom
Scenario credential
Given I am '$name'
and I have my 'credentials'
and I have my 'keys'
and I have a 'multidarkroom session'
and I have a 'issuer public key' from 'The Authority'
When I create the multidarkroom signature
Then print the 'multidarkroom signature'
EOF
}

for user in ${users[@]}
do
participant_sign ${user}
echo  "now generating the participant: "  ${user}
done

# the line below is maybe useless
cp -v -f ${out}/multisignature.json ${out}/multisignature_temp.json

# TODO: check traceability option signature -> multisignature

function collect_sign() {
	local name=$1
	local tmp_msig=`mktemp`
	local tmp_sig=`mktemp`
	cp -v ${out}/multisignature.json $tmp_msig
	json_join ${out}/credential.json ${out}/signature_$name.json > $tmp_sig
	cat << EOF | zexe ${out}/collect_sign.zen -a $tmp_msig -k $tmp_sig  | jq . | tee ${out}/multisignature.json
Scenario multidarkroom
Scenario credential
Given I have a 'multidarkroom session'
and I have a 'issuer public key' in 'The Authority'
and I have a 'multidarkroom signature'
When I aggregate all the issuer public keys
and I verify the multidarkroom signature credential
and I check the multidarkroom signature fingerprint is new
and I add the multidarkroom fingerprint to the multidarkroom session
and I add the multidarkroom signature to the multidarkroom session
Then print the 'multidarkroom session'
EOF
	rm -f $tmp_msig $tmp_sig
}

# COLLECT UNIQUE SIGNATURES




echo "=========================================================="
echo "start collecting, the array is "  ${cycles} 
echo "========================================================="

cp -v ${out}/multisignature.json ${out}/multisignature_temp_empty.json

for user in ${users[@]}
do
if [[ "Participant_$Participants" == "$user" ]]; then 
break 
fi 

collect_sign ${user}
echo  "now collecting the signature: "  ${user}
done

cp -v ${out}/multisignature.json ${out}/multisignature_temp_completeMinusOne.json

echo -e "==== collecting the relevant ones ====" >> /tmp/zenroom-test-summary.txt

for cycle in ${cycles[@]}
do

echo "=========================================================="
echo "collecting sigs, cycle n:" ${cycles}
echo "=========================================================="

cp -v -f ${out}/multisignature_temp_empty.json ${out}/multisignature.json



collect_sign "Participant_1" 
echo  "now collecting the signature:  Participant_1"

cp -v -f ${out}/multisignature_temp_completeMinusOne.json ${out}/multisignature.json

collect_sign "Participant_$Participants" 
echo  "now collecting the signature: Participant_$Participants "  


done


# VERIFY SIGNATURE

verify_signature(){
cat << EOF | zexe ${out}/verify_sign.zen -a ${out}/multisignature.json | jq .
Scenario multidarkroom
Given I have a 'multidarkroom session'
When I verify the multidarkroom session is valid
Then print 'SUCCESS'
and print the 'multidarkroom session'
EOF
}

echo "=========================================================="
echo "done collecting, the array is "  ${cycles} 
echo "========================================================="


for cycle in ${cycles[@]}
do

echo "=========================================================="
echo "now verifying the signatures n:" ${cycles_ver}
echo "=========================================================="
echo  "" 

verify_signature

done



echo -e "${magenta}\n \n<============================================>${reset}"
echo -e "${green}\n Change the value of 'Participants' in the beginning of the script, to change the amount of signees, and the 'Recursion' in order to change how many time the multisig related scripts should cycle. Currently: \n\n - 'Partipants' is: ${red} $Participants \n${green} - 'Recursion' is: ${yellow} $Recursion \n" 
echo -e "${magenta}<============================================>${reset}\n"
