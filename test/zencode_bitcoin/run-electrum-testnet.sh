#!/bin/bash

# run electrum daemon on port 7777
# electrum --testnet setconfig rpcport 7777
# electrum --testnet daemon 

. ../utils.sh $*
Z="`detect_zenroom_path` `detect_zenroom_conf`"

# five satoshi
amount="0.00000666"
# one satoshi
   fee="0.00001000"
# recipient's testnet address (alberto's)
to="tb1q73czlxl7us4s6num5sjlnq6r0yuf8uh5clr2tm"

. ./common.sh

genagent alpaca

genwallet alpaca

echo "Wait 5 seconds to gather unspent list"
sleep 5

curl -s --data-binary \
     '{"jsonrpc":"2.0","id":"curltext","method":"listunspent","params":[]}' \
     http://zenroom:zencode@127.0.0.1:7777 \
    | tee electrum-unspent.json

cat <<EOF > txorder.json
{
  "satoshi amount": "$amount",
  "satoshi fee": "$fee",
  "bitcoin address": "$to"
}

EOF
cat <<EOF | zexe maketransaction.zen \
		 -k electrum-unspent.json -a txorder.json \
    | save bitcoin electrum-transaction.json
Scenario bitcoin
Given I have a 'bitcoin address'
and a 'satoshi fee'
and an 'satoshi amount'
and a 'bitcoin unspent' named 'result'

When I rename 'result' to 'bitcoin unspent'
and I rename 'bitcoin address' to 'recipient address'
and I create the bitcoin transaction

Then print the 'bitcoin transaction'
EOF

cat <<EOF | zexe sign_transaction.zen \
		 -k alpaca-keys.json -a electrum-transaction.json \
    | save bitcoin signed-transaction.json
Scenario bitcoin
Given I am known as 'alpaca'
and I have my 'keys'
and I have a 'base64 dictionary' named 'bitcoin transaction'
When I sign the bitcoin transaction
and I create the bitcoin raw transaction
and I create the size of 'bitcoin raw transaction'
Then print the 'bitcoin raw transaction' as 'hex'
and print the 'size'
EOF

echo "Broadcasting transaction via electrum"
rawtx=`cat signed-transaction.json | jq '.bitcoin_raw_transaction' | sed 's/\"//g'`

electrum broadcast --testnet $rawtx

# \
#     | jq -S --arg amount $amount --arg fee $fee --arg from $from --arg to $to '
# {
# 	unspent: [.result[] | select (.address == $from) | {txid: .prevout_hash, vout: .prevout_n, address: .address, amount: .value}],
# 	amount: $amount,
# 	fee: $fee,
# 	recipient_address: $to
# }
# ' | tee curltx.json | jq .
