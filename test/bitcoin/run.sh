#!/bin/bash

amount="$1"
fee="$2"
from="$3"
to="$4"
sk="$5"

curl --data-binary \
     '{"jsonrpc":"2.0","id":"curltext","method":"listunspent","params":[]}' \
     http://user:password@127.0.0.1:7777 \
    | jq -S --arg amount $amount --arg fee $fee --arg from $from --arg to $to '
{
	unspent: [.result[] | select (.address == $from) | {txid: .prevout_hash, vout: .prevout_n, address: .address, amount: .value}],
	amount: $amount,
	fee: $fee,
	to: $to
}
'>data.json

cat <<EOF >keys.json
{
    "private_key": "$sk"
}
EOF


../../src/zenroom -k keys.json -a data.json bitcoin.lua
