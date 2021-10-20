#!/bin/bash

# run electrum daemon on port 7777
# electrum --testnet setconfig rpcport 7777
# electrum --testnet daemon 

. ../utils.sh $*
Z="`detect_zenroom_path` `detect_zenroom_conf`"

# five satoshi
amount="0.00000005"
# one satoshi
fee="0.00000001"

. ./common.sh

genagent alpaca

cat <<EOF | debug wifkey.zen -k alpaca-keys.json | save bitcoin alpaca-wif.json
Scenario bitcoin
Given I am known as 'alpaca'
and I have my 'keys'
When I create the bitcoin testnet wif key
Then print my 'bitcoin testnet wif key' as 'base58'
EOF

electrum --testnet close_wallet
rm -f ~/.electrum/testnet/wallets/default_wallet

wif="p2wpkh:`cat alpaca-wif.json | jq '.alpaca' | sed 's/\"//g'`"
echo "WIF: $wif"
electrum --testnet restore $wif

addr=`cat alpaca-address.json | jq '.bitcoin_address' | sed 's/\"//g'`

# alberto's testnet address
to="tb1q73czlxl7us4s6num5sjlnq6r0yuf8uh5clr2tm"

electrum --testnet setconfig rpcuser     zenroom
electrum --testnet setconfig rpcpassword zencode
electrum --testnet load_wallet

# electrum --testnet getprivatekeys $from

# sk=`electrum --testnet getprivatekeys $from 2> /dev/null`
# if [[ "$sk" == "" ]]; then
#     echo "error: no private key found in electrum for address $from"
#     exit 1
# fi

sleep 3
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

# \
#     | jq -S --arg amount $amount --arg fee $fee --arg from $from --arg to $to '
# {
# 	unspent: [.result[] | select (.address == $from) | {txid: .prevout_hash, vout: .prevout_n, address: .address, amount: .value}],
# 	amount: $amount,
# 	fee: $fee,
# 	recipient_address: $to
# }
# ' | tee curltx.json | jq .
