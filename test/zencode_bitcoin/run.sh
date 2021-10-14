#!/usr/bin/env bash

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh $*
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

cat <<EOF | save bitcoin keys.json
{ "keys": { "bitcoin": "cPW7XRee1yx6sujBWeyZiyg18vhhQk9JaxxPdvwGwYX175YCF48G" } }
EOF

cat <<EOF | save bitcoin txinput.json
{
  "amount": "50000",
  "fee": "1000",
  "recipient_address": "tb1q73czlxl7us4s6num5sjlnq6r0yuf8uh5clr2tm",
  "unspent": [
    {
      "address": "tb1q04c9a079f3urc5nav647frx4x25hlv5vanfgug",
      "amount": "0.00031",
      "txid": "26a1258b6cc85b01a4ff98bee02f07ddc63decd9866a8cfa565aac77d145bc18",
      "vout": 1
    },
    {
      "address": "tb1q04c9a079f3urc5nav647frx4x25hlv5vanfgug",
      "amount": "0.00949",
      "txid": "2879312e3189270725669ff2f959baa97e09eee63431d82e3498c2fa546099c9",
      "vout": 1
    }
  ]
}
EOF

cat <<EOF | zexe create_bitcoin_rawtx.zen -a txinput.json -k keys.json \
    | save bitcoin bitcoin_rawtx.json
rule input encoding base58
Scenario bitcoin: create a rawtx from unspent
Given I have the 'keys'
and I have a 'amount'
and I have a 'fee'
and I have a 'recipient address'
and I have a 'unspent'
When I create the bitcoin transaction
Then print the 'bitcoin transaction' as 'hex'
When I sign with bitcoin the 'bitcoin transaction'
When I create the bitcoin raw transaction of the 'bitcoin transaction'
Then print the 'bitcoin raw transaction' as 'hex'
EOF

###########################
## REAL RANDOM TRANSACTION

RNGSEED=random
. ../utils.sh $*
Z="`detect_zenroom_path` `detect_zenroom_conf`"

function genagent() {

cat <<EOF | zexe keygen.zen | save bitcoin ${1}-keys.json
rule output encoding base58
Scenario bitcoin
Given I am known as '${1}'
When I create the bitcoin testnet key
Then print my 'keys'
EOF

cat <<EOF | zexe pubkey.zen -k ${1}-keys.json | save bitcoin ${1}-address.json
rule output encoding base58
Scenario bitcoin
Given I am known as '${1}'
and I have my 'keys'
When I create the bitcoin testnet public key
and I create the bitcoin testnet address
Then print my 'bitcoin testnet address'
EOF

}

genagent Satoshi
genagent AlpacaSocks

cat <<EOF | debug rawtx.zen -k AlpacaSocks-address.json -a txinput.json | save bitcoin rawtx_to_AlpacaSocks.json
rule output encoding base58
Scenario bitcoin
Given I have the 'bitcoin testnet address' in 'AlpacaSocks'
Given I have a 'amount'
and I have a 'fee'
and I have a 'unspent'
When I rename 'bitcoin testnet address' to 'recipient address'
When I create the bitcoin transaction
and debug
Then print the 'unspent'
EOF
#and I create the bitcoin testnet public key
