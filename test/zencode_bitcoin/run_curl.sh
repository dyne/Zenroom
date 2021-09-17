#!/usr/bin/env bash

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh $*
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

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
	recipient_address: $to
}
'>curltx.json


cat <<EOF | save bitcoin keys.json
{ "keys": { "bitcoin": {
  "secret": "$sk",
  "address": "$from" }
} }
EOF

cat <<EOF | debug create_bitcoin_rawtx.zen -a curltx.json -k keys.json 
rule input encoding base58
Scenario bitcoin: create a rawtx from unspent
Given I have the 'keys'
and I have a 'amount'
and I have a 'fee'
and I have a 'recipient address'
and I have a 'unspent'
When I create the bitcoin transaction
Then print the 'bitcoin transaction' as 'hex'
EOF
