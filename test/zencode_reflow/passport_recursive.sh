#!/usr/bin/env bash

Participants=5

RNGSEED='random'

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

source shared_lib.sh

generate_issuer


users=""
for i in $(seq $Participants)
do
  users+=" PassParticipant_${i}"
done

for user in ${users[@]}
do
    echo "now generating the participant: "  ${user}
    generate_participant "${user}"
done


echo "${yellow} =========================== merging public keys ===================${reset}" 

jq -s 'reduce .[] as $item ({}; . * $item)' . ./public_key_PassParticipant* | save reflow public_keys.json

echo "{\"public_keys\": `cat ./public_keys.json` }" | save reflow public_key_array.json

cat <<EOF | save reflow uid.json
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

echo "${yellow} =========================== create the reflow seal ===================${reset}" 

cat <<EOF  | zexe seal_start.zen -k uid.json -a public_key_array.json | save reflow reflow_seal.json
Scenario reflow
Given I have a 'reflow public key array' named 'public keys'
and I have a 'string dictionary' named 'Sale'
When I aggregate the reflow public key from array 'public keys'
and I create the reflow identity of 'Sale'
and I create the reflow seal with identity 'reflow identity'
Then print the 'reflow seal'
EOF
# join seal with issuer verifier
jq -s '.[0] * .[1]' issuer_verifier.json reflow_seal.json | save reflow seal_to_sign.json

participant_sign() {
	local name=$1
	cat <<EOF | zexe sign_seal.zen -a seal_to_sign.json -k verified_credential_$name.json  | save reflow seal_signature_$name.json
Scenario reflow
Given I am '$name'
Given I have my 'credentials'
Given I have my 'keyring'
Given I have a 'reflow seal'
Given I have a 'issuer public key' from 'The Authority'
When I create the reflow signature
Then print the 'reflow signature'
EOF
}

for user in ${users[@]}
do
    participant_sign ${user}
    echo  "participant signing the seal: "  ${user}
done

function collect_sign() {
	local name=$1
	local tmp_msig=`mktemp`
	cp -v reflow_seal.json $tmp_msig
	# join seal with signature
	jq -s '.[0] * .[1]' $tmp_msig seal_signature_$name.json \
	    > seal_signed_$name.json

	cat << EOF | zexe collect_sign.zen \
			   -a seal_signed_$name.json -k issuer_verifier.json \
	    | save reflow reflow_seal.json
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

cp -v reflow_seal.json reflow_seal_unsigned.json
for user in ${users[@]}
do
    collect_sign ${user}
    echo  "now collecting the signature: "  ${user}
done

cat << EOF | zexe verify_sign.zen -a reflow_seal.json | jq .
Scenario reflow
Given I have a 'reflow seal'
When I verify the reflow seal is valid
Then print the string 'SIGNED'
Then print the 'reflow seal'

EOF

