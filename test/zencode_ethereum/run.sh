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
Then print the 'keyring'
EOF

# cat <<EOF | zexe pubgen.zen -k keys.json | save $SUBDOC pubkey.json
# Given I have the 'keyring'
# When I create the ethereum public key
# Then print the 'ethereum public key'
# EOF

cat <<EOF | zexe ${name}_addrgen.zen -k ${name}_keys.json | save $SUBDOC ${name}_address.json
Scenario ethereum
Given I am known as '$name'
and I have the 'keyring'
When I create the ethereum address
Then print my 'ethereum address'
EOF
# any address is an hash keccak 256 of public key, cut to 20 bytes
}

newaddr "alice"
newaddr "bob"

# rename does not change the encoding anymore,
# maybe create new functions for these operations

#cat <<EOF > ethval.json
#{"ethereum_value":"1"}
#EOF
#cat <<EOF > gweival.json
#{"gwei_value":"1000000000"}
#EOF
#cat <<EOF > weival.json
#{"wei_value":"1000000000000000000"}
#EOF
#cat <<EOF | zexe eth2wei.zen -a ethval.json \
#    > conv_weival.json
#Scenario ethereum
#Given I have the 'ethereum value'
#When I rename 'ethereum value' to 'wei value'
#Then I print 'wei value'
#EOF
# diff conv_weival.json weival.json
#cat <<EOF | zexe eth2gwei.zen -a ethval.json \
#    > conv_gweival.json
#Scenario ethereum
#Given I have the 'ethereum value'
#When I rename 'ethereum value' to 'gwei value'
#Then I print 'gwei value'
#EOF
# diff conv_gweival.json gweival.json
#
#cat <<EOF | zexe gwei2eth.zen -a gweival.json \
#    > conv_ethval.json
#Scenario ethereum
#Given I have the 'gwei value'
#When I rename 'gwei value' to 'ethereum value'
#Then I print 'ethereum value'
#EOF
# diff conv_ethval.json ethval.json
#cat <<EOF | zexe gwei2wei.zen -a gweival.json \
#    > conv_weival.json
#Scenario ethereum
#Given I have the 'gwei value'
#When I rename 'gwei value' to 'wei value'
#Then I print 'wei value'
#EOF
# diff conv_weival.json weival.json
#
#cat <<EOF | zexe wei2eth.zen -a weival.json \
#    > conv_ethval.json
#Scenario ethereum
#Given I have the 'wei value'
#When I rename 'wei value' to 'ethereum value'
#Then I print 'ethereum value'
#EOF
# diff conv_ethval.json ethval.json
#cat <<EOF | zexe wei2gwei.zen -a weival.json \
#    > conv_gweival.json
#Scenario ethereum
#Given I have the 'wei value'
#When I rename 'wei value' to 'gwei value'
#Then I print 'gwei value'
#EOF
# diff conv_gweival.json gweival.json

HOST=http://test.fabchain.net:8545
function getnonce() (
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_getTransactionCount","params":["'"$1"'", "latest"],"id":42}' $HOST
    sleep 1
)
alice_address=`cat alice_address.json | cut -d'"' -f6`
echo "Alice address: 0x${alice_address}"
# getnonce "0x${alice_address}"

NONCE=`getnonce 0x${alice_address} | jq -r '.result'`
cat <<EOF | save $SUBDOC alice_nonce_eth.json
    { "ethereum nonce": "`printf "%d" ${NONCE}`",
      "gas price": "100000000000",
      "gas limit": "300000",
      "gwei value": "10"
    }
EOF

cat <<EOF | zexe transaction.zen -k alice_nonce_eth.json \
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
given I have the 'keyring'
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
given I have the 'keyring'
and I have a 'ethereum transaction'
when I create the signed ethereum transaction for chain 'fabt'
then print the 'signed ethereum transaction'
eof

cat <<EOF | save $SUBDOC storage_contract.json
{ "storage_contract": "d01394Ade77807B3fE7DAE6f54462dE453Cc8741" }
EOF

cat <<EOF | zexe transaction_storage.zen -k alice_nonce_eth.json -a storage_contract.json | save $SUBDOC alice_storage_tx.json
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
given I have the 'keyring'
and I have a 'ethereum transaction'
when I create the signed ethereum transaction for chain 'fabt'
then print the 'signed ethereum transaction'
eof

# Store complex object
NONCE=`getnonce 0x${alice_address} | jq -r '.result'`
cat <<EOF | save $SUBDOC alice_nonce_data.json
    { "ethereum nonce": "`printf "%d" ${NONCE}`",
      "gas price": "100000000000",
      "gas limit": "300000",
      "storage_contract": "E54c7b475644fBd918cfeDC57b1C9179939921E6"
    }
EOF
# cat <<EOF | zexe store_complex_object.zen -a alice_nonce_data.json -k alice_keys.json
# Scenario ethereum
# Given I have the 'keys'
# Given I have a 'ethereum address' named 'storage contract'
# Given I have a 'ethereum nonce'
# and a 'gas price'
# and a 'gas limit'
# When I create the array of '12' random objects
# When I create the ethereum transaction to 'storage contract'
# and I use the ethereum transaction to store 'array'

# When I create the signed ethereum transaction for chain 'fabt'
# Then print the 'signed ethereum transaction'
# Then print data
# EOF

# Decode data stored
cat <<EOF >read_stored_string.data
{
  "data": "000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000674e656c206d657a7a6f2064656c2063616d6d696e206469206e6f7374726120766974610a6d6920726974726f7661692070657220756e612073656c7661206f73637572612c0a6368c3a9206c612064697269747461207669612065726120736d6172726974612e00000000000000000000000000000000000000000000000000"
}
EOF

cat <<EOF | debug read_stored_string.zen -a read_stored_string.data
Scenario ethereum
Given I have a 'hex' named 'data'
When I create the string from the ethereum bytes named 'data'
Then print data
EOF

# Transfer erc20 tokens
NONCE=`getnonce "0xef5dca69e9c573f6acce1b4c641b2b526217328f" | jq -r '.result'`
cat <<EOF | save $SUBDOC send_tokens.json
{
	"keyring": {
		   "ethereum": "634f3f80fc087ad90866012d74c41ccc698b43592dee7ed27ecb89333c2e3d1c"
	},
	"gas price": "100000000000",
	"gas limit": "100000",
	"token value": "1",
	"erc20": "1e30e53E87869aaD8dC5A1A9dAc31a8dD3559460",
	"receiver": "828bddf0231656fb736574dfd02b7862753de64b",
	"ethereum nonce": "`echo $(($NONCE))`"
}
EOF

cat <<EOF | zexe send_tokens.zen -a send_tokens.json | save $SUBDOC send_tokens_signed_tx.json
Scenario ethereum

# load the JSON file
Given I have the 'keyring'
Given I have a 'ethereum address' named 'receiver'
Given I have a 'ethereum address' named 'erc20'
Given I have a 'ethereum nonce'
and a 'gas price'
and a 'gas limit'
# load the number of tokens that will be transferred
and a 'number' named 'token value'

# create the transaction for the erc20 token contract
When I create the ethereum transaction to 'erc20'
# here we fill the data field with all the information needed by the erc20 token contract
and I use the ethereum transaction to transfer 'token value' erc20 tokens to 'receiver'
# then i sign it, and it is ready to be broadcast to a node
When I create the signed ethereum transaction for chain 'fabt'

# print the signed ethereum transaction
Then print the 'signed ethereum transaction'
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


# for documentation
cat <<EOF | save $SUBDOC doc_key.json
{
	"ethereum private key": "150ad66741dd4f917d1e7877e2cb5d47ce1baa8e635b41675fa4f1ca51b681bb"
}
EOF
cat <<EOF | zexe doc_key_upload.zen -a doc_key.json
Scenario ethereum
Given I have a 'hex' named 'ethereum private key'

# here we upload the key
When I create the ethereum key with secret key 'ethereum private key'
# an equivalent statement is
# When I create the ethereum key with secret 'ethereum private key'

Then print the keyring
EOF

cat <<EOF | zexe doc_pubgen.zen -a alice_keys.json
Scenario ecdh
Scenario ethereum

# load the ethereum key
Given I have a 'hex' named 'ethereum' in 'keyring'

# create the ecdh public key
When I create the ecdh key with secret key 'ethereum'
When I create the ecdh public key
# rename it to ethereum public key
and I rename the 'ecdh public key' to 'ethereum public key'

# print the ethereum public key as hex
Then print the 'ethereum public key' as 'hex'
EOF

NONCE=`getnonce 0x${alice_address} | jq -r '.result'`
cat <<EOF | save $SUBDOC doc_tx_information.json
    { "ethereum nonce": "`printf "%d" ${NONCE}`",
      "gas price": "100000000000",
      "gas limit": "300000"
    }
EOF

cat <<EOF | save $SUBDOC doc_alice_data.json
    { 
      "data": "This is my first data stored on ethereum blockchain" 
    }
EOF

jq -s '.[0]*.[1]' alice_nonce_eth.json bob_address.json | save $SUBDOC doc_tx_information_eth.json
cat <<EOF | zexe doc_transaction.zen -a doc_tx_information_eth.json | save $SUBDOC doc_alice_to_bob_transaction.json
Scenario ethereum

# Load the JSON file
Given I have a 'ethereum address' inside 'bob'
and a 'gas price'
and a 'gas limit'
and an 'ethereum nonce'
and a 'gwei value'

# Create the ethereum transaction
When I create the ethereum transaction of 'gwei value' to 'ethereum address'

Then print the 'ethereum transaction'
EOF

jq -s '.[0]*.[1]' alice_nonce_data.json doc_alice_data.json | save $SUBDOC doc_tx_information_data.json
cat <<EOF | zexe doc_transaction_storage.zen -a doc_tx_information_data.json | save $SUBDOC doc_alice_storage_tx.json
Scenario ethereum

# Load  the JSON file
Given I have a 'ethereum address' named 'storage contract'
and a 'gas price'
and a 'gas limit'
and an 'ethereum nonce'
and a 'string' named 'data'

# Create the ethereum transaction
When I create the ethereum transaction to 'storage contract'
# use it to store the data
and I use the ethereum transaction to store 'data'

Then print the 'ethereum transaction'
EOF

cat <<EOF | zexe doc_sign_transaction.zen -a doc_alice_storage_tx.json -k alice_keys.json | save $SUBDOC doc_signed_tx.json
scenario ethereum

# Load the private key and the transacrtion
given I have the 'keyring'
and I have a 'ethereum transaction'

# sign the transaction for the chain with chain id 'fabt'
when I create the signed ethereum transaction for chain 'fabt'

then print the 'signed ethereum transaction'
EOF

cat <<EOF | zexe doc_sign_transaction_local.zen -a doc_alice_storage_tx.json -k alice_keys.json
scenario ethereum

# Load the private key and the transacrtion
given I have the 'keyring'
and I have a 'ethereum transaction'

# sign the transaction for the local testnet
when I create the signed ethereum transaction

then print the 'signed ethereum transaction'
EOF

cat <<EOF | save $SUBDOC doc_read_stored_string.json
{
  "data": "0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003354686973206973206d7920666972737420646174612073746f726564206f6e20657468657265756d20626c6f636b636861696e00000000000000000000000000"
}
EOF

cat <<EOF | zexe doc_read_stored_string.zen -a doc_read_stored_string.json | save $SUBDOC doc_retrieved_data.json
Scenario ethereum
Given I have a 'hex' named 'data'
When I create the 'data retrieved' decoded from ethereum bytes 'data'
Then print the 'data retrieved' as 'string'
EOF
