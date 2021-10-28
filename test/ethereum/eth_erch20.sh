#!/usr/bin/env bash

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh $*
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

# HOST=http://85.93.88.149:8545
HOST=http://localhost:8545
function send() {
    echo '{"jsonrpc":"2.0","method":"eth_sendRawTransaction","params":["'"$1"'"],"id":1}'
    curl -X POST --data '{"jsonrpc":"2.0","method":"eth_sendRawTransaction","params":["'"$1"'"],"id":1}' $HOST
    sleep 1
}

function call() {
    params="{\"to\": \"$1\", \"data\": \"$2\"}"
    echo $params
    curl -X POST --data '{"jsonrpc":"2.0","method":"eth_call","params":['"$params"', "latest"],"id":42}' $HOST | jq '.result'
    sleep 1
}

# A has a lot of tokens

A="f17f52151EbEF6C7334FAD080c5704D77216b732"
Ask="ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f"
# On rinkeby
#A="19e942FB3193bb2a3D6bAD206ECBe9E60599c388"


B="e24Cd6B528A513181C765d3dadb0809E1eF991f5"
#B="f17f52151EbEF6C7334FAD080c5704D77216b732"

# contract
C="b9A219631Aed55eBC3D998f17C3840B7eC39C0cc"

# On rinkeby the contract is 0xEf56e128ba3682019116146361934dCcC9B18C2B
#C="Ef56e128ba3682019116146361934dCcC9B18C2B"

cat <<EOF > balance.lua
ETH=require('crypto_ethereum')
print(ETH.erc20.balanceOf(O.from_hex('$A')):hex())
EOF

echo "Balances before"
echo "balance A"
call $C `$Z balance.lua` 

cat <<EOF > balance.lua
ETH=require('crypto_ethereum')
print(ETH.erc20.balanceOf(O.from_hex('$B')):hex())
EOF

echo "balance B"
call $C `$Z balance.lua`

cat <<EOF > transfer.lua
ETH=require('crypto_ethereum')

tx = {}
tx["nonce"] = ETH.o2n(1)
tx["gasPrice"] = INT.new(1000)
tx["gasLimit"] = INT.from_decimal('300000')
tx["to"] = O.from_hex('$C')
tx["value"] = O.new()
tx["data"] = ETH.erc20.transfer(O.from_hex('$B'), BIG.from_decimal('1000'))

-- v contains the chain id (when the transaction is not signed)
-- We always use the chain id
tx["v"] = INT.new(1337)
tx["r"] = O.new()
tx["s"] = O.new()

from = O.from_hex('$Ask')

encodedTx = ETH.encodeSignedTransaction(from, tx)

print(encodedTx:hex())
EOF

send `$Z transfer.lua`

echo "Balances after"
cat <<EOF > balance.lua
ETH=require('crypto_ethereum')
print(ETH.erc20.balanceOf(O.from_hex('$A')):hex())
EOF

echo "balance A"
call $C `$Z balance.lua` 

cat <<EOF > balance.lua
ETH=require('crypto_ethereum')
print(ETH.erc20.balanceOf(O.from_hex('$B')):hex())
EOF

echo "balance B"
call $C `$Z balance.lua` 
