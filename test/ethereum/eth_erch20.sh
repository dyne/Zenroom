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
function send() (
    &>2 echo '{"jsonrpc":"2.0","method":"eth_sendRawTransaction","params":["'"$1"'"],"id":1}'
    curl -X POST --data '{"jsonrpc":"2.0","method":"eth_sendRawTransaction","params":["'"$1"'"],"id":1}' $HOST
    sleep 1
)

function call() (
    local params="{\"to\": \"$1\", \"data\": \"$2\"}"
    &>2 echo $params
    curl -X POST --data '{"jsonrpc":"2.0","method":"eth_call","params":['"$params"', "latest"],"id":42}' $HOST | jq '.result'
    sleep 1
)

# A has a lot of tokens

#A="f17f52151EbEF6C7334FAD080c5704D77216b732"
#Ask="ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f"
A="627306090abaB3A6e1400e9345bC60c78a8BEf57"
Ask="c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3"
# On rinkeby
#A="19e942FB3193bb2a3D6bAD206ECBe9E60599c388"


B="fe3b557e8fb62b89f4916b721be55ceb828dbd73"
#B="f17f52151EbEF6C7334FAD080c5704D77216b732"

# contract
#C="b9A219631Aed55eBC3D998f17C3840B7eC39C0cc"
C="8CdaF0CD259887258Bc13a92C0a6dA92698644C0"
# On rinkeby the contract is 0xEf56e128ba3682019116146361934dCcC9B18C2B
#C="Ef56e128ba3682019116146361934dCcC9B18C2B"

cat <<EOF > balance.lua
ETH=require('crypto_ethereum')
print(ETH.erc20.balanceOf(O.from_hex('$A')):hex())
EOF

# echo "Balances before"
# echo "balance A"
# call $C `$Z balance.lua`

# cat <<EOF > balance.lua
# ETH=require('crypto_ethereum')
# print(ETH.erc20.balanceOf(O.from_hex('$B')):hex())
# EOF

# echo "balance B"
# call $C `$Z balance.lua`

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

echo "Details of the contract"
cat <<EOF > contract_name.lua
ETH=require('crypto_ethereum')
print(ETH.erc20.name():hex())
EOF
echo "{ \"name\": " $(call $C `$Z contract_name.lua`) ", \"balance_b\": \"00000000000000000000000000000000000000000000000000000000000003e8\"}" >data.json

cat <<EOF > read_data.lua
ETH=require('crypto_ethereum')
DATA = JSON.decode(DATA)
I.spy(DATA)
print("Balance of B is " .. ETH.erc20return.balanceOf(DATA.balance_b)[1]:decimal())
print("The name of the contract is " .. ETH.erc20return.name(DATA.name)[1])

EOF

$Z -a data.json read_data.lua

$Z transfer.lua
