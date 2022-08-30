load ../bats_setup
load ../bats_zencode
SUBDOC=bitcoin


@test "Create and sign raw tx" {
    cat <<EOF | save_asset keys.json
{ "keyring": { "testnet": "cPW7XRee1yx6sujBWeyZiyg18vhhQk9JaxxPdvwGwYX175YCF48G" } }
EOF

    cat <<EOF | save_asset txinput.json
{
  "satoshi amount": "1",
  "satoshi fee": "142",
  "testnet address": "tb1q73czlxl7us4s6num5sjlnq6r0yuf8uh5clr2tm",
  "testnet unspent": [
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

    cat <<EOF | zexe create_bitcoin_rawtx.zen txinput.json keys.json
Given I have the 'keyring'
and I have a 'satoshi amount'
and I have a 'satoshi fee'
and I have a 'testnet address'
and I have a 'testnet unspent'

When I create the testnet transaction to 'testnet address'
and I sign the testnet transaction
and I create the testnet raw transaction
Then print the 'testnet raw transaction' as 'hex'
and print the 'keyring'
EOF
    save_output "create_bitcoin_rawtx.json"
}

@test "Import key" {
    cat << EOF | save_asset wif.json
{ "keyring": { "testnet": "cPW7XRee1yx6sujBWeyZiyg18vhhQk9JaxxPdvwGwYX175YCF48G" } }
EOF
    cat <<EOF | zexe import_key.zen txinput.json wif.json
Given I have a 'keyring'
and I have a 'satoshi amount'
and I have a 'satoshi fee'
and I have a 'testnet address'
and I have a 'testnet unspent'

When I create the testnet transaction to 'testnet address'
and I sign the testnet transaction
and I create the testnet raw transaction

Then print the 'testnet raw transaction' as 'hex'
and print the 'keyring'
EOF
    save_output "import_key.json"
}


@test "Export bitcoin address" {
  cat <<EOF | zexe export_bitcoin_address.zen
Given nothing
When I create the bitcoin key
When I create the bitcoin address
Then print the 'keyring'
Then print data
EOF
    save_output "export_bitcoin_address.out"
}

@test "Import bitcoin address" {
  cat <<EOF | zexe import_bitcoin_address.zen export_bitcoin_address.out
Given I have the 'bitcoin_address'
Then print data
EOF
    save_output "import_bitcoin_address.out"
}
