#!/bin/bash

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

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



echo "                                                "
echo "${magenta}------------------------------------------------"
echo "${magenta}  If broken, before running this script,        "
echo "${magenta}  execute 'run.sh' script in the same folder   "
echo "${magenta}------------------------------------------------"
echo "${reset}   											  "


cat << EOF | save reflow Agent.json
{ "Agent": {
  "id": "BADC0FFE",
  "name": "Alice",
  "note": "The smartypants who is lost in Wonderland"
  }
}
EOF

cat << EOF | save reflow EconomicResource.json
{ "EconomicResource": { 
        "accountingQuantity": {
          "hasNumericalValue": 0.0478270231353376,
          "hasUnit": {
            "label": "kilo"
          }
        },
        "currentLocation": {
          "lat": -18.895467439976088,
          "long": 13.45323887068065,
          "name": "Streich"
        },
        "id": "01EVTV5QR62V7A489V2W84NJHT",
        "image": null,
        "name": "Streich",
        "note": "Dicta velit quo neque qui unde fuga non laboriosam! Aliquam eligendi ex autem ut ratione incidunt et maiores voluptas? Vitae et repellat exercitationem omnis quos eaque totam pariatur. Autem quam a officiis rerum fuga aspernatur.",
        "primaryAccountable": {
          "name": "Cruickshank-Hodkiewicz"
        }
      }
    }
EOF

cat << EOF | save reflow EconomicEvent.json
{ "EconomicEvent": {
        "action": {
          "label": "transfer"
        },

        "id": "01EVTV5RCD4JTJDYX5HKERJ5KP",
        "note": "Earum placeat eveniet sint sint exercitationem ea? Sint libero perspiciatis ad et harum aliquid et minus. Natus reprehenderit asperiores sapiente quae.",
        "provider": {
          "id": "01EVTV5F0PHMH7R1J5A1QXEZM1",
          "name": "Cruickshank-Hodkiewicz"
        },
        "receiver": {
          "id": "01EVTV5F0PHMH7R1J5A1QXEZM1",
          "name": "Cruickshank-Hodkiewicz"
        },
        "resourceInventoriedAs": {
          "name": "Waters",
          "note": "Consequatur facilis dignissimos cum dolores dolorem qui facere numquam. Ea quia recusandae tempora modi facilis blanditiis dolores. Deserunt quia qui facere eius soluta vel quo itaque vitae. Nesciunt blanditiis ea nihil incidunt."
        },
        "resourceQuantity": {
          "hasNumericalValue": 0.5173676470814242,
          "hasUnit": {
            "label": "kilo"
          }
        }
      }
    }
EOF

cat << EOF | save reflow Process.json
{ "Process": {
  "finished": 0,
  "id": "01EVTV5F0PHMH7R1J5A1QXEZM1",
  "name": "A sample process",
  "note": "Description of a sample process",
  "inputs": [],
  "outputs": []
  }
}
EOF

cat <<EOF | zexe create_agent_reflow_identity.zen -a Agent.json | save reflow identity_Alice.json
Scenario reflow
Given I am 'Alice'
and I have a 'string dictionary' named 'Agent'
When I create the reflow identity of 'Agent'
Then print 'reflow identity'
EOF


## AGENT CRYPTO KEYS
# this is composed of various parts:
# 1. keys containing: reflow and credentials
# 2. credentials
# 3. identity
#
# DAMN json_join
# json_join identity_Alice.json verified_credential_Alice.json | save reflow alice.json

jq -s '.[0] * .[1]' identity_Alice.json verified_credential_Alice.json | save reflow alice.json


## AUTHORITY PUBLIC KEY
# add the issuer node public key to the object passed
#
#json_join issuer_verifier.json EconomicResource.json | save reflow EconomicResource_issuer.json

jq -s '.[0] * .[1]' issuer_verifier.json EconomicResource.json | save reflow EconomicResource_issuer.json

cat << EOF | zexe create_seal_of_resource.zen -a EconomicResource_issuer.json -k alice.json | save reflow EconomicResource_seal.json
Scenario reflow
Given I am 'Alice'
and I have the 'keyring'
and I have the 'credentials'
and I have a 'issuer public key' in 'The Authority'
and I have a 'reflow identity'
and I have a 'string dictionary' named 'EconomicResource'
When I create the material passport of 'EconomicResource'
Then print the 'EconomicResource'
and print the 'material passport'
EOF

cat << EOF | zexe verify_seal_of_resource.zen -a EconomicResource_seal.json -k issuer_verifier.json
Scenario reflow
Given I have a 'string dictionary' named 'EconomicResource'
and I have a 'issuer public key' in 'The Authority'
and I have a 'material passport'
When I verify the material passport of 'EconomicResource'
Then print the string 'Valid Resource material passport'
EOF

## AUTHORITY PUBLIC KEY
# add the issuer node public key to the object passed
#json_join issuer_verifier.json EconomicEvent.json | save reflow EconomicEvent_issuer.json

jq -s '.[0] * .[1]' issuer_verifier.json EconomicEvent.json | save reflow EconomicEvent_issuer.json

cat << EOF | zexe create_seal_of_event.zen -a EconomicEvent_issuer.json -k alice.json | save reflow EconomicEvent_seal.json 
Scenario reflow
Given I am 'Alice'
and I have the 'keyring'
and I have the 'credentials'
and I have a 'issuer public key' in 'The Authority'
and I have a 'reflow identity'
and I have a 'string dictionary' named 'EconomicEvent'
When I create the material passport of 'EconomicEvent'
Then print the 'EconomicEvent'
and print the 'material passport'
EOF

cat << EOF | zexe verify_seal_of_event.zen -a EconomicEvent_seal.json -k issuer_verifier.json
Scenario reflow
Given I have a 'string dictionary' named 'EconomicEvent'
and I have a 'issuer public key' in 'The Authority'
and I have a 'material passport'
When I verify the material passport of 'EconomicEvent'
Then print the string 'Valid Event material passport'
EOF

#############
# AGGREGATION

# make an array of material_passport.seal structs.  this is optionally
# done with zenroom, host application may have a quick way to
# manipulate structures
cat <<EOF | zexe extract_seal.zen -a EconomicEvent_seal.json > seal1.json
Scenario reflow
Given I have a 'material passport'
When I create the copy of 'seal' from dictionary 'material passport'
and I rename 'copy' to 'seal1'
Then print the 'seal1'
EOF
cat <<EOF | zexe extract_seal.zen -a EconomicResource_seal.json > seal2.json
Scenario reflow
Given I have a 'material passport'
When I create the copy of 'seal' from dictionary 'material passport'
and I rename 'copy' to 'seal2'
Then print the 'seal2'
EOF
cat <<EOF | zexe make_seal_array.zen -a seal1.json -k seal2.json > SealArray.json
Scenario reflow
Given I have a 'reflow seal' named 'seal1'
and I have a 'reflow seal' named 'seal2'
When I create the new array
and I insert 'seal1' in 'new array'
and I insert 'seal2' in 'new array'
and I rename 'new array' to 'Seals'
Then print 'Seals'
EOF

# json_join SealArray.json issuer_verifier.json Process.json | save reflow Aggregate_seal.json

jq -s  '.[0] * .[1] * .[2]' SealArray.json issuer_verifier.json Process.json | save reflow Aggregate_seal.json


cat << EOF | zexe create_seal_of_process.zen -a Aggregate_seal.json -k alice.json | save reflow Process_seal.json 
Scenario reflow
Given I am 'Alice'
and I have the 'keyring'
and I have the 'credentials'
and I have a 'issuer public key' in 'The Authority'
and I have a 'reflow identity'
and I have a 'reflow seal array' named 'Seals'
When I create the sum value 'identity' for dictionaries in 'Seals'
Then print the 'sum value'
EOF

# Verify seal 

# Verify identity

 


echo "                                                "
echo "${magenta}------------------------------------------------"
echo "${magenta}  If broken, before running this script,        "
echo "${magenta}  execute 'run.sh' script in the same folder   "
echo "${magenta}------------------------------------------------"
echo "${reset}   											  "