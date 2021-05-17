#!/usr/bin/env bash

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
####################

#### SETUP OUTPUT FOLDER and cleaning
# ${out}/credentialParticipantKeygen.zen
# out='./files'

out='../../docs/examples/zencode_cookbook/reflow'

# out='/dev/shm/files'

mkdir -p ${out}
rm ${out}/*
rm /tmp/zenroom-test-summary.txt





#################
# Change this to change the amount of participants 
# and the amount of recursion for some of the scripts

Participants=3
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


echo -e "${green} ======================================================" 
echo -e "${green} ======================================================" 
echo -e "${green} ======================================================" 
echo -e "${green} =============== START SCRIPT =========================" 
echo -e "${green} ======================================================" 
echo -e "${green} ======================================================" 
echo -e "${green} ======================================================${reset}" 



## ISSUER creation
cat <<EOF | zexe ${out}/issuer_keygen.zen  | jq . | tee ${out}/issuer_keypair.json
Scenario credential
Given I am 'The Authority'
when I create the issuer key
Then print my 'keys'
EOF

cat <<EOF | zexe ${out}/issuer_verifier.zen -k ${out}/issuer_keypair.json  | jq . | tee ${out}/issuer_verifier.json
Scenario credential: publish verifier
Given that I am known as 'The Authority'
Given I have my 'keys'
When I create the issuer public key
Then print my 'issuer public key'
EOF
##




generate_participant() {
    local name=$1
    ## PARTICIPANT
	cat <<EOF | zexe ${out}/keygen_${1}.zen  | jq . | tee ${out}/keypair_${1}.json
Scenario reflow
Given I am '${1}'
When I create the reflow key
and I create the credential key
Then print my 'keys'
EOF

	cat <<EOF | zexe ${out}/pubkey_${1}.zen -k ${out}/keypair_${1}.json  | jq . | tee ${out}/public_key_${1}.json
Scenario reflow
Given I am '${1}'
and I have my 'keys'
When I create the reflow public key
Then print my 'reflow public key'
EOF


	cat <<EOF | zexe ${out}/request_${1}.zen -k ${out}/keypair_${1}.json  | jq . | tee ${out}/request_${1}.json
Scenario credential
Given I am '${1}'
Given I have my 'keys'
When I create the credential request
Then print my 'credential request'
EOF
	##

	## ISSUER SIGNS
	cat <<EOF | zexe ${out}/issuer_sign_${1}.zen -k ${out}/issuer_keypair.json -a ${out}/request_${1}.json  | jq . | tee ${out}/issuer_signature_${1}.json
Scenario credential
Given I am 'The Authority'
Given I have my 'keys'
Given I have a 'credential request' inside '${1}'
When I create the credential signature
When I create the issuer public key
Then print the 'credential signature'
Then print the 'issuer public key'
EOF
	##

	## PARTICIPANT AGGREGATES SIGNED CREDENTIAL
	cat <<EOF | zexe ${out}/aggr_cred_${1}.zen -k ${out}/keypair_${1}.json -a ${out}/issuer_signature_${1}.json  | jq . | tee ${out}/verified_credential_${1}.json
Scenario credential
Given I am '${1}'
Given I have my 'keys'
Given I have a 'credential signature'
When I create the credentials
Then print my 'credentials'
Then print my 'keys'
EOF
	##

}

# generate  signed credentials

for user in ${users[@]}
do
generate_participant ${user}
echo  "now generating the participant: "  ${user}
done

# exit 0




for user in ${users[@]}
do
issuer_keygen_sign ${user}
echo  "Issuer creates keypair, verifier and signs the request from: "  ${user}
done

#####################
# Joining files and creating uid
#####

echo "${yellow} =========================== merging public keys ===================${reset}" 

jq -s 'reduce .[] as $item ({}; . * $item)' . ${out}/public_key_* | tee ${out}/public_keys.json

echo "${yellow} =========================== writing public keys array ===================${reset}"

echo "{\"public_keys\": `cat ${out}/public_keys.json` }" | tee ${out}/public_key_array.json

echo "${yellow} =========================== writing uid ===================${reset}"

echo "{\"today\": \"`date +'%s'`\"}" | tee ${out}/uid-time.json


cat <<EOF > ${out}/uid.json
{
   "Sale":{
      "Buyer":"Alice",
      "Seller":"Bob",
	  "Witness":"Carl",
      "Good":"Cow",
      "Price":100,
      "Currency":"EUR",
      "Timestamp":1422779638,
      "Text":"Bob sells the cow to Alice, cause the cow grew too big and Carl, Bob's roomie, was complaining"
   }
}
EOF

#############################
# SIGNING SESSION

create_multisignature(){
cat <<EOF  | zexe ${out}/seal_start.zen -k ${out}/uid.json -a ${out}/public_key_array.json | tee  ${out}/reflow_seal.json
Scenario reflow
Given I have a 'reflow public key array' named 'public keys'
and I have a 'string dictionary' named 'Sale'
When I aggregate the reflow public key from array 'public keys'
and I create the reflow identity of 'Sale'
and I create the reflow seal with identity 'reflow identity'
Then print the 'reflow seal'
EOF
}

# preparing for the cycle


for cycle in ${cycles[@]}
do

rm -f ${out}/reflow_seal.json
create_multisignature

done

#############
# create_multisignature
# participant is told of the multisignature and offered to sign
# participant joins the credential (=issuer pubkey) and the multisignature
# json_join ${out}/issuer_public_key.json ${out}/reflow_seal.json | jq . > ${out}/credential_to_sign.json

jq -s '.[0] * .[1]' ${out}/issuer_verifier.json ${out}/reflow_seal.json | jq . > ${out}/credential_to_sign.json

cp ${out}/reflow_seal.json ${out}/reflow_seal_input.json

# PARTICIPANT SIGNS (function)
function participant_sign() {
	local name=$1
	cat <<EOF | zexe ${out}/sign_session.zen -a ${out}/credential_to_sign.json -k ${out}/verified_credential_$name.json  | jq . | tee ${out}/signature_$name.json
Scenario reflow
Given I am '$name'
Given I have my 'credentials'
Given I have my 'keys'
Given I have a 'reflow seal'
Given I have a 'issuer public key' from 'The Authority'
When I create the reflow signature
Then print the 'reflow signature'
EOF
}

for user in ${users[@]}
do
participant_sign ${user}
echo  "now generating the participant: "  ${user}
done



# TODO: check traceability option signature -> multisignature

function collect_sign() {
	local name=$1
	local tmp_msig=`mktemp`
	local tmp_sig=`mktemp`
	cp -v ${out}/reflow_seal.json $tmp_msig
#    json_join ${out}/issuer_public_key.json ${out}/signature_$name.json > $tmp_sig
	jq -s '.[0] * .[1]' ${out}/issuer_verifier.json ${out}/signature_$name.json > ${out}/issuer_verifier_signature_$name.json
	cat << EOF | zexe ${out}/collect_sign.zen -a $tmp_msig -k ${out}/issuer_verifier_signature_$name.json  | jq . | tee ${out}/reflow_seal.json
Scenario reflow
Given I have a 'reflow seal'
and I have a 'issuer public key' in 'The Authority'
and I have a 'reflow signature'
When I aggregate all the issuer public keys
and I verify the reflow signature credential
and I check the reflow signature fingerprint is new
and I add the reflow fingerprint to the reflow seal
and I add the reflow signature to the reflow seal
Then print the 'reflow seal'
EOF
	rm -f $tmp_msig 
}

# COLLECT UNIQUE SIGNATURES




echo "=========================================================="
echo "start collecting, the array is "  ${cycles} 
echo "========================================================="

cp -v ${out}/reflow_seal.json ${out}/reflow_seal_empty.json

for user in ${users[@]}
do
if [[ "Participant_$Participants" == "$user" ]]; then 
break 
fi 

collect_sign ${user}
echo  "now collecting the signature: "  ${user}
done

cp -v ${out}/reflow_seal.json ${out}/reflow_seal_temp_completeMinusOne.json

echo -e "==== collecting the relevant ones ====" >> /tmp/zenroom-test-summary.txt

for cycle in ${cycles[@]}
do

echo "=========================================================="
echo "collecting sigs, cycle n:" ${cycles}
echo "=========================================================="

cp -v -f ${out}/reflow_seal_empty.json ${out}/reflow_seal.json



collect_sign "Participant_1" 
echo  "now collecting the signature:  Participant_1"

cp -v -f ${out}/reflow_seal_temp_completeMinusOne.json ${out}/reflow_seal.json

collect_sign "Participant_$Participants" 
echo  "now collecting the signature: Participant_$Participants "  


done


# VERIFY SIGNATURE

verify_signature(){
cat << EOF | zexe ${out}/verify_sign.zen -a ${out}/reflow_seal.json | jq .
Scenario reflow
Given I have a 'reflow seal'
When I verify the reflow seal is valid
Then print the string 'SUCCESS'
Then print the 'reflow seal'
EOF
}

verify_identity(){
cat << EOF | zexe ${out}/verify_identity.zen -a ${out}/reflow_seal.json -k ${out}/uid.json  | jq .
Scenario 'reflow' : Verify the identity in the seal 
Given I have a 'reflow seal'
Given I have a 'string dictionary' named 'Sale'
When I create the reflow identity of 'Sale'
When I rename the 'reflow identity' to 'SaleIdentity'
When I verify 'SaleIdentity' is equal to 'identity' in 'reflow seal'
Then print the string 'The reflow identity in the seal is verified'
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
verify_identity

done



echo -e "${magenta}\n \n<============================================>${reset}"
echo -e "${green}\n Change the value of 'Participants' in the beginning of the script, to change the amount of signees, and the 'Recursion' in order to change how many time the multisig related scripts should cycle. Currently: \n\n - 'Partipants' is: ${red} $Participants \n${green} - 'Recursion' is: ${yellow} $Recursion \n" 
echo -e "${magenta}<============================================>${reset}\n"
