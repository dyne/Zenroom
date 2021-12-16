#!/usr/bin/env bash

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh $*
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

HOST=http://85.93.88.149:8545
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

# First of all discover the current nonce
nonce=`counttx "0x07837015333210AFE4953f61712997eD6563D0de"`
echo $nonce
nonce=9
# indirizzo (derivato dalla chiave pubblica)
A="07837015333210AFE4953f61712997eD6563D0de"
# chiave privata
Ask="6d8bddb6f25317dda2f2cbd8ad4d8e021b8447a453cfa5f4879721be865e1992"

# contract
C="101848D5C5bBca18E6b4431eEdF6B95E9ADF82FA"

cat <<EOF > asktokens.lua
ETH=require('crypto_ethereum')

tx = {}
tx["nonce"] = ETH.o2n(${nonce})
--tx["gasPrice"] = INT.from_decimal('1000000000')
tx["gasPrice"] = INT.from_decimal('500000000000')
tx["gasLimit"] = INT.from_decimal('100000')
tx["to"] = O.from_hex('$C')
tx["value"] = O.new()
tx["data"] = O.new()

-- v contains the chain id (when the transaction is not signed)
-- We always use the chain id
tx["v"] = INT.new(3)
tx["r"] = O.new()
tx["s"] = O.new()

from = O.from_hex('$Ask')

encodedTx = ETH.encodeSignedTransaction(from, tx)

print(encodedTx:hex())
EOF

RAWTX="0x`$Z asktokens.lua`"
echo $RAWTX
send $RAWTX
# 0xbc6c1c9f0521f447300d27f956a014672dda862d649a144b50aef06b2859d3ae
# 0xcf7a012fd167576d6fde7b0e79c65856917cf91daefbaa7694f7461593def7ce
