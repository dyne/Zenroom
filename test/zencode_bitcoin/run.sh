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
  "satoshi amount": "1",
  "satoshi fee": "142",
  "bitcoin address": "tb1q73czlxl7us4s6num5sjlnq6r0yuf8uh5clr2tm",
  "bitcoin unspent": [
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
Given I have the 'keys'
and I have a 'satoshi amount'
and I have a 'satoshi fee'
and I have a 'bitcoin address'
and I have a 'bitcoin unspent'

When I create the bitcoin transaction to 'bitcoin address'
and I sign the bitcoin transaction
and I create the bitcoin raw transaction
Then print the 'bitcoin raw transaction' as 'hex'
EOF

cat << EOF | save bitcoin wif.json
{ "wif": "cPW7XRee1yx6sujBWeyZiyg18vhhQk9JaxxPdvwGwYX175YCF48G" }
EOF
cat <<EOF | zexe import_key.zen -a txinput.json -k wif.json \
    | save bitcoin import_key.json

Given I have the 'bitcoin key' named 'wif'
and I have a 'satoshi amount'
and I have a 'satoshi fee'
and I have a 'bitcoin address'
and I have a 'bitcoin unspent'
and schema
When I create the keys
and I rename 'wif' to 'bitcoin'
and I move 'bitcoin' in 'keys'
and I create the bitcoin transaction to 'bitcoin address'
and I sign the bitcoin transaction
and I create the bitcoin raw transaction

Then print the 'bitcoin raw transaction' as 'hex'
EOF
