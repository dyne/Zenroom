#!/bin/bash

# from the article on medium.com

. ../utils.sh $*
Z="`detect_zenroom_path` `detect_zenroom_conf`"

# sequenceDiagram
#     participant SK as Secure off-line PC
#     participant PK as Public on-line PC
#     participant BC as Public blockchain explorer
#     SK->>SK: keygen.txt
#     SK-->>PK: copy public address
#     PK->>+BC: send public address
#     BC->>-PK: download unspent (UTXO)
#     PK->>PK: create transaction: amount + recipient + UTXO
#     PK-->>SK: copy transaction to sign
#     SK->>SK: sign transaction offline
#     SK-->>PK: copy signed transaction
#     PK->>BC: broadcast signed transaction

cat << EOF | zexe keygen.zen | save bitcoin keys.json
Given nothing
When I create the testnet key
Then print the 'keyring'
EOF

cat <<EOF | zexe pubgen.zen -k keys.json | save bitcoin address.json
Given I have the 'keyring'
When I create the testnet address
Then print the 'testnet address'
EOF


addr=`cat address.json | jq '.testnet_address' | sed 's/\"//g'`

echo "curl -s https://blockstream.info/testnet/api/address/${addr}/utxo" | tee unspent_query.sh ../../docs/examples/zencode_cookbook/bitcoin/unspent_query.sh

# cat <<EOF | tee  culo.json 
# {
#  "satoshi amount": "1",
#  "satoshi fee": "141",
#  "recipient": "tb1q73czlxl7us4s6num5sjlnq6r0yuf8uh5clr2tm",
#  "sender": "${addr}",
#  "satoshi unspent": `curl -s https://blockstream.info/testnet/api/address/${addr}/utxo`
# }
# EOF

cat <<EOF | tee transaction_data.json ../../docs/examples/zencode_cookbook/bitcoin/transaction_data.json
{
  "satoshi amount": "1",
  "satoshi fee": "141",
  "recipient": "tb1q73czlxl7us4s6num5sjlnq6r0yuf8uh5clr2tm",
  "sender": "${addr}"
}
EOF

cat <<EOF | tee unspent.json  ../../docs/examples/zencode_cookbook/bitcoin/unspent.json
{
  "satoshi unspent": `curl -s https://blockstream.info/testnet/api/address/${addr}/utxo`
}
EOF


jq -s '.[0] * .[1]' unspent.json  transaction_data.json | save bitcoin order.json

cat <<EOF | zexe sign.zen -a order.json | save bitcoin transaction.json
Given I have a 'testnet address' named 'sender'
and I have a 'testnet address' named 'recipient'
and a 'satoshi fee'
and a 'satoshi amount'
and a 'satoshi unspent'
When I rename 'satoshi unspent' to 'testnet unspent'
and I create the testnet transaction
Then print the 'testnet transaction'
EOF

cat <<EOF | zexe sign_transaction.zen -k keys.json -a transaction.json | save bitcoin rawtx.json
Given I have the 'keyring'
and I have a 'base64 dictionary' named 'testnet transaction'
When I sign the testnet transaction
and I create the testnet raw transaction
and I create the size of 'testnet raw transaction'
Then print the 'testnet raw transaction' as 'hex'
EOF
