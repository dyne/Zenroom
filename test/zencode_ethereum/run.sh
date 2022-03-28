#!/bin/bash

# from the article on medium.com
SUBDOC=ethereum
. ../utils.sh $*
Z="`detect_zenroom_path` `detect_zenroom_conf`"

set -e

newaddr() {
name="$1"
cat <<EOF | zexe ${name}_keygen.zen | save $SUBDOC ${name}_keys.json
Scenario ethereum
Given nothing
When I create the ethereum key
Then print the 'keys'
EOF

# cat <<EOF | zexe pubgen.zen -k keys.json | save $SUBDOC pubkey.json
# Given I have the 'keys'
# When I create the ethereum public key
# Then print the 'ethereum public key'
# EOF

cat <<EOF | zexe ${name}_addrgen.zen -k ${name}_keys.json | save $SUBDOC ${name}_address.json
Scenario ethereum
Given I am known as '$name'
and I have the 'keys'
When I create the ethereum address
Then print my 'ethereum address'
EOF
# any address is an hash keccak 256 of public key, cut to 20 bytes
}

newaddr "alice"
newaddr "bob"

cat <<EOF > ethval.json
{"ethereum_value":"1"}
EOF
cat <<EOF > gweival.json
{"gwei_value":"1000000000"}
EOF
cat <<EOF > weival.json
{"wei_value":"1000000000000000000"}
EOF
cat <<EOF | zexe eth2wei.zen -a ethval.json \
    > conv_weival.json
Scenario ethereum
Given I have the 'ethereum value'
When I rename 'ethereum value' to 'wei value'
Then I print 'wei value'
EOF
diff conv_weival.json weival.json
cat <<EOF | zexe eth2gwei.zen -a ethval.json \
    > conv_gweival.json
Scenario ethereum
Given I have the 'ethereum value'
When I rename 'ethereum value' to 'gwei value'
Then I print 'gwei value'
EOF
diff conv_gweival.json gweival.json

cat <<EOF | zexe gwei2eth.zen -a gweival.json \
    > conv_ethval.json
Scenario ethereum
Given I have the 'gwei value'
When I rename 'gwei value' to 'ethereum value'
Then I print 'ethereum value'
EOF
diff conv_ethval.json ethval.json
cat <<EOF | zexe gwei2wei.zen -a gweival.json \
    > conv_weival.json
Scenario ethereum
Given I have the 'gwei value'
When I rename 'gwei value' to 'wei value'
Then I print 'wei value'
EOF
diff conv_weival.json weival.json

cat <<EOF | zexe wei2eth.zen -a weival.json \
    > conv_ethval.json
Scenario ethereum
Given I have the 'wei value'
When I rename 'wei value' to 'ethereum value'
Then I print 'ethereum value'
EOF
diff conv_ethval.json ethval.json
cat <<EOF | zexe wei2gwei.zen -a weival.json \
    > conv_gweival.json
Scenario ethereum
Given I have the 'wei value'
When I rename 'wei value' to 'gwei value'
Then I print 'gwei value'
EOF
diff conv_gweival.json gweival.json

HOST=http://test.fabchain.net:8545
function getnonce() (
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_getTransactionCount","params":["'"$1"'", "latest"],"id":42}' $HOST
    sleep 1
)
alice_address=`cat alice_address.json | cut -d'"' -f6`
echo "Alice address: 0x${alice_address}"
# getnonce "0x${alice_address}"

NONCE=`getnonce 0x${alice_address} | jq -r '.result'`
cat <<EOF | save $SUBDOC alice_nonce.json
    { "ethereum nonce": "`printf "%d" ${NONCE}`",
      "gas price": "100000000000",
      "gas limit": "300000",
      "gwei value": "10"
    }
EOF

cat <<EOF | zexe transaction.zen -k alice_nonce.json \
		 -a bob_address.json \
    | save $SUBDOC alice_to_bob_transaction.json
Scenario ethereum
Given I have a 'ethereum address' inside 'bob'
# ?? restroom: and I have a nonce ??
# nonce is given via RPC input alice's address
and a 'gas price'
and a 'gas limit'
and an 'ethereum nonce'
and a 'gwei value'
# and a 'wei value'
# 1 eth is 10^18 wei
# 1 eth is 10^9 gwei
When I create the ethereum transaction of 'gwei value' to 'ethereum address'
Then print the 'ethereum transaction'
EOF

cat <<eof | zexe sign_transaction.zen -a alice_to_bob_transaction.json \
		 -k alice_keys.json
scenario ethereum
given I have the 'keys'
and I have a 'ethereum transaction'
# tx["v"] = int.new(1337) <- chain id
# tx["r"] = o.new()
# tx["s"] = o.new()
# encodedtx = eth.encodesignedtransaction(from, tx)
when I create the signed ethereum transaction
#for chain 'fab'
# needs keys.ethereum and valid eth transaction
then print the 'signed ethereum transaction'
eof

cat <<eof | zexe sign_transaction_chainid.zen -a alice_to_bob_transaction.json -k alice_keys.json
scenario ethereum
given I have the 'keys'
and I have a 'ethereum transaction'
when I create the signed ethereum transaction for chain 'fabt'
then print the 'signed ethereum transaction'
eof

cat <<EOF | save $SUBDOC storage_contract.json
{ "storage_contract": "d01394Ade77807B3fE7DAE6f54462dE453Cc8741" }
EOF

cat <<EOF | zexe transaction_storage.zen -k alice_nonce.json -a storage_contract.json | save $SUBDOC alice_storage_tx.json
Scenario ethereum
Given I have a 'ethereum address' named 'storage contract'
# here we assume bob is a storage contract
and a 'gas price'
and a 'gas limit'
and an 'ethereum nonce'
When I create the ethereum transaction to 'storage contract'
and I create the random object of '256' bits
and I use the ethereum transaction to store 'random object'
Then print the 'ethereum transaction'
EOF

cat <<eof | zexe sign_transaction_chainid.zen -a alice_storage_tx.json -k alice_keys.json
scenario ethereum
given I have the 'keys'
and I have a 'ethereum transaction'
when I create the signed ethereum transaction for chain 'fabt'
then print the 'signed ethereum transaction'
eof

# Store complex object
NONCE=`getnonce 0x${alice_address} | jq -r '.result'`
cat <<EOF | save $SUBDOC alice_nonce.json
    { "ethereum nonce": "`printf "%d" ${NONCE}`",
      "gas price": "100000000000",
      "gas limit": "300000",
      "gwei value": "0",
      "storage_contract": "E54c7b475644fBd918cfeDC57b1C9179939921E6"
    }
EOF
cat <<EOF | zexe store_complex_object.zen -a alice_nonce.json -k alice_keys.json
Scenario ethereum
Given I have the 'keys'
Given I have a 'ethereum address' named 'storage contract'
Given I have a 'ethereum nonce'
and a 'gas price'
and a 'gas limit'
When I create the array of '12' random objects
When I create the ethereum transaction to 'storage contract'
and I use the ethereum transaction to store 'array'

When I create the signed ethereum transaction for chain 'fabt'
Then print the 'signed ethereum transaction'
Then print data
EOF

# Decode data stored
cat <<EOF >store_string.data
{
  "data": "0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000009528b52ffd208f650400b2c8202490c70dffff7fec9944400318421479988024d6b0b928604d78db53a6a9feb7e8ffdfb2013f909c593166bad5c0283193fe93b5b9c71167560c37fdd7f6a78002d1e4a57af9264dbb977bbc2d24cddce30908460c6a6f4abe08cef7276905af238ac2283130ca946c7f6afa0059ad44bac12d163b1d2fea50c049c70aca04c6711c8d0100c28312050000000000000000000000"
}
EOF

cat <<EOF | debug store_string.zen -a store_string.data
Scenario ethereum
Given I have a 'hex' named 'data'
When create the 'string' stored in the ethereum data named 'data'
Then print data
EOF

# TODO: verify tx using Alice's public key (not the address)

# local ERC20_SIGNATURES = {
#    balanceOf         = { view=true, i={'address'}, o={'uint256'} },
#    transfer          = {            i={'address', 'uint256'}, o={'bool'} },
#    approve           = {            i={'address', 'uint256'}, o={'bool'} },
#    allowance         = { view=true, i={'address', 'address'}, o={'uint256'} },
#    transferFrom      = {            i={'address', 'address', 'uint256'}, o={'bool'} },
#    decimals          = { view=true, o={'uint8'} },
#    name              = { view=true, o={'string'} },
#    symbol            = { view=true, o={'string'} },
#    totalSupply       = { view=true, o={'uint256'} },
# }

# # wishlist for Restroom
# Given I have the 'balance' of 'address' for erc20 'contract address'
# Given I have the 'balance' of 'address' for erc20 'contract address' named 'variable name'
# Given I have the 'decimals' for erc20 'contract address' ( named 'variable name' )
# Given I have the 'name'     for erc20 'contract address' ( named 'variable name' )
# Given I have the 'symbol'   for erc20 'contract address' ( named 'variable name' )
# Given I have the 'total supply' for erc20 'contract address' ( named 'variable name' )
