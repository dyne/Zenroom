#!/usr/bin/env bash

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh $*
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

HOST=http://78.47.38.223:8545
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

nonce=4
A="54dBd956968Eb0a0d7827934BECc7B5Ca0a9C5a3"
Ask="b19f33adb283305d646785c7ed596aea6e0c61ffabbbdfcf6a6fd2f6941629f1"

# contract
C="3A5c21A60e5bE4D621B64A659F4a42c504d08c52"


cat <<EOF > transfer.lua
ETH=require('crypto_ethereum')

tx = {}
tx["nonce"] = ETH.o2n($nonce)
tx["gasPrice"] = INT.from_decimal('100000000000')
tx["gasLimit"] = INT.from_decimal('300000')
tx["to"] = O.from_hex('$C')
tx["value"] = O.new()
tx["data"] = ETH.makeStringStorageData("ciao mondo")

-- v contains the chain id (when the transaction is not signed)
-- We always use the chain id
tx["v"] = INT.from_decimal('1717658228')
tx["r"] = O.new()
tx["s"] = O.new()

from = O.from_hex('$Ask')

encodedTx = ETH.encodeSignedTransaction(from, tx)

print(encodedTx:hex())
EOF
send "0x`$Z transfer.lua`"

