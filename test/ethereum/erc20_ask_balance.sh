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

# First of all discover the current nonce
# nonce=`counttx "0x07837015333210AFE4953f61712997eD6563D0de"`
A="07837015333210AFE4953f61712997eD6563D0de"
Ask="6d8bddb6f25317dda2f2cbd8ad4d8e021b8447a453cfa5f4879721be865e1992"

# contract (ERC20)
C="101848D5C5bBca18E6b4431eEdF6B95E9ADF82FA"

cat <<EOF > balance.lua
ETH=require('crypto_ethereum')
print(ETH.erc20.balanceOf(O.from_hex('$A')):hex())
EOF

call "0x$C" "0x`$Z balance.lua`"
