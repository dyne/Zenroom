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

contract=$1


# send raw tx
function send() (
    &>2 echo '{"jsonrpc":"2.0","method":"eth_sendRawTransaction","params":["'"$1"'"],"id":1}'
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_sendRawTransaction","params":["'"$1"'"],"id":1}' $HOST
    sleep 1
)

# used for view=true readonly methods
function call() (
    local params="{\"to\": \"$1\", \"data\": \"$2\"}"
    &>2 echo $params
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_call","params":['"$params"', "latest"],"id":42}' $HOST | jq '.result'
    sleep 1
)

# retrieve nonce
function counttx() (
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_getTransactionCount","params":["'"$1"'", "latest"],"id":42}' $HOST | jq '.result'
    sleep 1
)

function txreceipt() (
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_getTransactionReceipt","params":["'"$1"'", "latest"],"id":42}' $HOST | jq '.result'
    sleep 1
)

function gasprice() (
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_gasPrice","params":[],"id":42}' $HOST | jq '.result'
    sleep 1
)

# First of all discover the current nonce
# nonce=`counttx "0x07837015333210AFE4953f61712997eD6563D0de"`
A="07837015333210AFE4953f61712997eD6563D0de"
Ask="6d8bddb6f25317dda2f2cbd8ad4d8e021b8447a453cfa5f4879721be865e1992"

# contract (ERC20)
C="0000000000000000000000000000000000000000"

# BEGIN HERE CONTRACT DEPLOYMENT
# Compile contract
solc --overwrite --bin --abi "${contract}.sol" -o build
# Current nonce
nonce=`counttx "0x$A"`
gasprice="1000"
data=`cat build/${contract}.bin`

cat <<EOF > _deploy.lua
ETH=require('crypto_ethereum')

tx = {}
tx["nonce"] = ETH.o2n($nonce)
tx["gasPrice"] = ETH.o2n(O.from_hex('$gasprice'))
tx["gasLimit"] = INT.from_decimal('3000000')
tx["to"] = O.from_hex('$C')
tx["value"] = O.new()
tx["data"] = O.from_hex('$data')

-- v contains the chain id (when the transaction is not signed)
-- We always use the chain id
tx["v"] = INT.new(3)
tx["r"] = O.new()
tx["s"] = O.new()

from = O.from_hex('$Ask')

encodedTx = ETH.encodeSignedTransaction(from, tx)

print(encodedTx:hex())
EOF

$Z _deploy.lua
send "0x`$Z _deploy.lua`"
