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
exit 0

HOST=http://test.fabchain.net:8545
function getnonce() (
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_getTransactionCount","params":["'"$1"'", "latest"],"id":42}' $HOST | jq '.result'
    sleep 1
)

alice_addr=`cat alice_address.json | awk '/ethereum address/ { print $2 }'`
cat <<EOF | save $SUBDOC alice_nonce.json
    { "alice nonce": "`getnonce ${alice_addr}`" }
EOF

cat <<EOF | zexe transaction.zen -a bob_address.json \
    | save $SUBDOC alice_to_bob_transaction.json
Scenario ethereum
and I have a 'ethereum address' inside 'bob'
# ?? restroom: and I have a nonce ??
# nonce is given via RPC input alice's address
and a 'gas price'
and a 'gas limit'
and an 'ethereum nonce' named 'alice nonce'
and an 'ethereum value'
# and a 'wei value'
# 1 eth is 10^18 wei
# 1 eth is 10^9 gwei
When I create the ethereum transaction to 'ethereum address'
Then print the 'ethereum transaction'
EOF

cat <<EOF | zexe sign_transaction.zen -a alice_to_bob_transaction.json \
		 -k alice_keys.json
Scenario ethereum
Given I have the 'keys'
and I have a 'ethereum transaction'
# tx["v"] = INT.new(1337) <- chain id
# tx["r"] = O.new()
# tx["s"] = O.new()
# encodedTx = ETH.encodeSignedTransaction(from, tx)
When I create the signed ethereum transaction for chain 'fab'
# needs keys.ethereum and valid eth transaction
Then print the 'signed ethereum transaction'
EOF

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
