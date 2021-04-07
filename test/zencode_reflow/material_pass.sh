#!/bin/bash

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################


# # CREATE A NEW seal
# mv reflow_seal.json reflow_seal_1.json
# mv public_key_array.json public_key_array_1.json
# mv uid.json uid_1.json
# # generate two signed credentials
# generate_participant "Carl"
# generate_participant "Denis"
# # join the verifiers of signed credentials
# json_join verifier_Carl.json verifier_Denis.json > public_keys.json
# echo "{\"public_keys\": `cat public_keys.json` }" > public_key_array.json
# # make a uid using the current timestamp
# echo "{\"today\": \"`date`\"}" > uid.json
# # SIGNING seal
# cat <<EOF | debug seal_start.zen -k uid.json -a public_key_array.json > reflow_seal.json
# Scenario reflow
# Given I have a 'bls public key array' named 'public keys'
# and I have a 'string' named 'today'
# When I aggregate the bls public key from array 'public keys'
# and I rename the 'bls public key' to 'reflow public key'
# and I create the reflow identity of 'today'
# and I create the reflow seal with identity 'reflow identity'
# Then print the 'reflow seal'
# EOF

cat << EOF > EconomicResource.json
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

cat << EOF > EconomicEvent.json
{
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
EOF

cat << EOF > Process.json
{
  finished: false,
  id: "01EVTV5F0PHMH7R1J5A1QXEZM1",
  name: "A sample process",
  note: "Description of a sample process",
  inputs: [],
  outputs: []
}
EOF

cat << EOF | debug create_seal_of_resource.zen -a EconomicResource.json -k public_key_array.json |tee EconomicResource_seal.json 
Scenario reflow
Given I have a 'string dictionary' named 'EconomicResource'
and I have a 'bls public key array' named 'public keys'
When I aggregate the bls public key from array 'public keys'
and I rename the 'bls public key' to 'reflow public key'
and I create the reflow identity of 'EconomicResource'
and I create the reflow seal with identity 'reflow UID'
Then print the 'reflow seal'
and print the 'reflow identity'
EOF