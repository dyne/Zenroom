#!/usr/bin/env bash

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh $*
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

HOST="http://test.fabchain.net:8545"
# HOST=http://localhost:8545
function send() (
    &>2 echo '{"jsonrpc":"2.0","method":"eth_sendRawTransaction","params":["'"$1"'"],"id":1}'
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_sendRawTransaction","params":["'"$1"'"],"id":1}' $HOST
    sleep 1
)

function call() (
    local params="{\"to\": \"$1\", \"data\": \"$2\"}"
    &>2 echo $params
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_call","params":['"$params"', "latest"],"id":42}' $HOST | jq '.result'
    sleep 1
)

function counttx() (
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_getTransactionCount","params":["'"$1"'", "latest"],"id":42}' $HOST | jq '.result'
    sleep 1
)

function txreceipt() (
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_getTransactionReceipt","params":["'"$1"'", "latest"],"id":42}' $HOST | jq '.result'
    sleep 1
)

# Alice creates a asset and she sends it to Bob

Ask="74ade23849eae580125cf5852b97dd6d81635a94f7ad46c081ef6e568ce713bb"
Aaddr="0xe5c97889d755dCDFa5c2c678032143d45176DFBE"

transfer_outside_address="0xc57776A3353991f3794977430BbA39133528eFeb"
erc721_addr="0xEeeea9ff09d75365C2c6467D82A0607ea34Aad88"

cat <<EOF >transfer_erc721.keys
{
 "keyring": {
    "ethereum": "$Ask"
  },
 "transfer_outside_address": "$transfer_outside_address",
 "erc721_address": "$erc721_addr",
 "ethereum_address": "$Aaddr",
 "fabchain": "http://test.fabchain.net:8545",
 "gas limit": "300000",
 "gas price": "1000000000",
 "ethereum_nonce": "`counttx $Aaddr | xargs | perl -e "print hex(<>)"`",
 "planetmint_public_key": "2umg6yiPZV5QqnaLBy1cwszFiAUSNTVAaXjekwqXL8NW",
 "token_id": 33
}
EOF


cat <<EOF >transfer_erc721.zen
Rule unknown ignore
Scenario ethereum:
Given I have the 'keyring'
Given I have a 'ethereum address' named 'transfer outside address'
Given I have a 'ethereum address' named 'erc721 address'
Given I have a 'ethereum nonce'
Given I have a 'gas price'
Given I have a 'gas limit'
Given I have a 'number' named 'token id'
Given I have a 'string' named 'planetmint_public_key'
When I create the ethereum address
When I create the ethereum transaction to 'transfer_outside_address'
When I use the ethereum transaction to transfer the erc721 'token id' in the contract 'erc721 address' to 'planetmint public key' in planetmint
When I create the signed ethereum transaction for chain 'fabt'
Then print the 'signed ethereum transaction'
Then print data
EOF

ZEN=`$Z -z transfer_erc721.zen -k transfer_erc721.keys`
#echo "0x`echo $ZEN | jq '.signed_ethereum_transaction' | xargs`"
RET=$(send "0x`echo $ZEN | jq '.signed_ethereum_transaction' | xargs`")
TXID=`echo $RET | jq '.result'`

echo "The transaction id is $TXID"
