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

Ask="2a5ef38e4e86bd758efc85cd1e5e4d61de7a70c7d2a1358a461084aea48c4ee7"
Aaddr="0xdC51204D6ceB8aE21cD2e826A07D5406809aA389"

Baddr="0xe5c97889d755dCDFa5c2c678032143d45176DFBE"

erc721_addr="0xe419E41336a5b134570eaf1a786A08405e60eFC8"

cat <<EOF >transfer_erc721.keys
{
 "keyring": {
    "ethereum": "$Ask"
  },
 "erc721_address": "$erc721_addr",
 "ethereum_address": "$Aaddr",
 "dest_addr": "$Baddr",
 "fabchain": "http://test.fabchain.net:8545",
 "gas limit": "3000000",
 "gas price": "1000000000",
 "ethereum_nonce": "`counttx $Aaddr | xargs | perl -e "print hex(<>)"`",
 "token_id": 5
}
EOF


cat <<EOF >transfer_erc721.zen
Rule unknown ignore
Scenario ethereum:
Given I have the 'keyring'
Given I have a 'ethereum address' named 'erc721_address'
Given I have a 'ethereum address' named 'dest_addr'
Given I have a 'ethereum nonce'
Given I have a 'gas price'
Given I have a 'gas limit'
Given I have a 'number' named 'token id'
When I create the ethereum address
When I create the ethereum transaction to 'erc721_address'
When I use the ethereum transaction to approve the erc721 'token id' transfer from 'dest addr'
When I create the signed ethereum transaction for chain 'fabt'
Then print the 'signed ethereum transaction'
Then print data
EOF

ZEN=`$Z -z transfer_erc721.zen -k transfer_erc721.keys`
RET=$(send "0x`echo $ZEN | jq '.signed_ethereum_transaction' | xargs`")
TXID=`echo $RET | jq '.result'`

echo "The transaction id is $TXID"
