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

# electrum testnet on palma
from="tb1qf7c3s3amqxlmmm8r9tw0j7mxf38v98ft6wemth"
# alberto's testnet address
to="tb1q73czlxl7us4s6num5sjlnq6r0yuf8uh5clr2tm"

electrum --testnet setconfig rpcuser     zenroom
electrum --testnet setconfig rpcpassword zencode
electrum --testnet load_wallet

electrum --testnet getprivatekeys $from

sk=`electrum --testnet getprivatekeys $from 2> /dev/null`
if [[ "$sk" == "" ]]; then
    echo "error: no private key found in electrum for address $from"
    exit 1
fi

curl -s --data-binary \
     '{"jsonrpc":"2.0","id":"curltext","method":"listunspent","params":[]}' \
     http://zenroom:zencode@127.0.0.1:7777 \
    | tee unspent.json | tee electrum-unspent.json

cat <<EOF > txorder.json
{
  "amount": "$amount",
  "fee": "$fee",
  "recipient address": "$from"
}

EOF
cat <<EOF | zexe maketransaction.zen \
		 -k electrum-unspent.json -a txorder.json \
    | save bitcoin electrum-transaction.json
Scenario bitcoin
Given I have a 'recipient address'
and a 'fee'
and an 'amount'
and an 'unspent' named 'result'

When I rename 'result' to 'unspent'
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
