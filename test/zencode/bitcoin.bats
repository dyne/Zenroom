load ../bats_setup
load ../bats_zencode
SUBDOC=bitcoin

@test "Create the testnet key" {
    cat <<EOF | zexe create_testnet_key.zen
Given nothing
When I create the testnet key
Then print the 'keyring'
EOF
    save_output "create_testnet_key.out.json"
    assert_output '{"keyring":{"testnet":"cMqN1QyWYZqAAw5qVH8AzFF3GVM9VQKyNEY7ZUQsPivVpVYWjzfx"}}'
}

@test "Create the bitcoin key" {
    cat <<EOF | zexe create_bitcoin_key.zen
Given nothing
When I create the bitcoin key
Then print the 'keyring'
EOF
    save_output "create_bitcoin_key.out.json"
    assert_output '{"keyring":{"bitcoin":"KwUNYVyf7W8u1Vca6sK3cvjyeG3jpxEHJCPeT3xMtcGVZkU3WX8S"}}'
}

@test "Create the testnet public key" {
    cat <<EOF | zexe create_testnet_public_key.zen create_testnet_key.out.json
Given I have the 'keyring'
When I create the testnet public key
Then print the 'testnet public key'
EOF
    save_output "create_testnet_public_key.out.json"
    assert_output '{"testnet_public_key":"AndrWMNBRclVO1I1/iEaYjfEi5C0eEvG2GZgsCNq87qy"}'
}

@test "Create the bitcoin public key" {
    cat <<EOF | zexe create_bitcoin_public_key.zen create_bitcoin_key.out.json
Given I have the 'keyring'
When I create the bitcoin public key
Then print the 'bitcoin public key'
EOF
    save_output "create_bitcoin_public_key.out.json"
    assert_output '{"bitcoin_public_key":"AndrWMNBRclVO1I1/iEaYjfEi5C0eEvG2GZgsCNq87qy"}'
}

@test "Create the testnet address" {
    cat <<EOF | zexe create_testnet_address.zen create_testnet_key.out.json
Given I have the 'keyring'
When I create the testnet address
Then print the 'testnet address'
EOF
    save_output "create_testnet_address.out.json"
    assert_output '{"testnet_address":"tb1qc5wzp53l39v499nvycmcvu2aaqlu84xnkhq3dv"}'
}

@test "Create the bitcoin address" {
    cat <<EOF | zexe create_bitcoin_address.zen create_bitcoin_key.out.json
Given I have the 'keyring'
When I create the bitcoin address
Then print the 'bitcoin address'
EOF
    save_output "create_bitcoin_public_key.out.json"
    assert_output '{"bitcoin_address":"bc1qc5wzp53l39v499nvycmcvu2aaqlu84xnu3mzkl"}'
}

@test "Create the transaction" {
    cat <<EOF | save_asset create_transaction.keys.json
{
  "satoshi amount": "1",
  "satoshi fee": "141",
  "recipient": "tb1q73czlxl7us4s6num5sjlnq6r0yuf8uh5clr2tm",
  "sender": "tb1qc5wzp53l39v499nvycmcvu2aaqlu84xnkhq3dv"
}
EOF
    cat <<EOF | save_asset create_transaction.data.json
{
  "satoshi unspent": [
    {
      "txid": "dd6d3c58fe0cd8729e731545830307fcdd36620c14bc5988308e0485d23ea53c",
      "vout": 1,
      "status": {
        "confirmed": true,
        "block_height": 2103197,
        "block_hash": "0000000000000004e0ff305a04c1b23e26cf4c6a903b2304eb58a8b18c81414d",
        "block_time": 1636388875
      },
      "value": 79716
    },
    {
      "txid": "f435e5f2139b7a919b51ee6950b82f8b60031158960d66ec67135320d68f54a2",
      "vout": 1,
      "status": {
        "confirmed": true,
        "block_height": 2102869,
        "block_hash": "000000000000f4cb5540d429d37e3716317acc34f071a90f14c8a4536716382e",
        "block_time": 1636187124
      },
      "value": 1563967
    },
    {
      "txid": "63145fe24a787a25e721e6be4fc3db08dbec21f7924d54d68d139c6506f509f7",
      "vout": 0,
      "status": {
        "confirmed": true,
        "block_height": 2102869,
        "block_hash": "000000000000f4cb5540d429d37e3716317acc34f071a90f14c8a4536716382e",
        "block_time": 1636187124
      },
      "value": 80000
    },
    {
      "txid": "98aea64e8c923240f8abc9af577bd68ecc5a20d9f6b1b6d8e174a57b68d825bf",
      "vout": 1,
      "status": {
        "confirmed": true,
        "block_height": 2103471,
        "block_hash": "00000000000000287d5251d6be9a8d8f18fdf91bb4e20a14471a025384d593a8",
        "block_time": 1636567249
      },
      "value": 96560
    },
    {
      "txid": "7166ff2dd8cd0893253c984c031896335d68f31d18aafffb1020f024735fc5c9",
      "vout": 1,
      "status": {
        "confirmed": true,
        "block_height": 2102869,
        "block_hash": "000000000000f4cb5540d429d37e3716317acc34f071a90f14c8a4536716382e",
        "block_time": 1636187124
      },
      "value": 100000
    },
    {
      "txid": "592c35a7e710828746988926317f6929073ece459b55f935e0a8091b97564f24",
      "vout": 1,
      "status": {
        "confirmed": true,
        "block_height": 2101106,
        "block_hash": "0000000000000020e76792ea88ad80ed6cf634b9bc08f0adc2cc7c8db5f22a5a",
        "block_time": 1635376667
      },
      "value": 995036
    },
    {
      "txid": "60431824fa7a2b085b7cabf72bbaa3cfe97ffe69708e0d8bccbe5c301eed30e5",
      "vout": 1,
      "status": {
        "confirmed": true,
        "block_height": 2103470,
        "block_hash": "0000000000003317181c3239426b7e9a1aed9164cb4726b2777ca50b2c54309d",
        "block_time": 1636566498
      },
      "value": 79716
    },
    {
      "txid": "17a37cdbab83718435a0bebd747337a943add4af34b9c124c14f679b5a0b1cd0",
      "vout": 0,
      "status": {
        "confirmed": true,
        "block_height": 2101201,
        "block_hash": "000000000001aad40c5be20f667630f2a85dc0da3003c4605bdb628ee180c325",
        "block_time": 1635436736
      },
      "value": 100000
    },
    {
      "txid": "3fcdad9b6289fbba25d306fadac78062949c63164eabd35e4541c3f84992ffb1",
      "vout": 12,
      "status": {
        "confirmed": true,
        "block_height": 2102981,
        "block_hash": "000000000000000f9e0f2e29a4756a7564a38eade977d5253271c41fa8de2760",
        "block_time": 1636256674
      },
      "value": 3527419
    }
  ]
}
EOF
    cat <<EOF | zexe create_transaction.zen create_transaction.data.json create_transaction.keys.json
Given I have a 'testnet address' named 'sender'
and I have a 'testnet address' named 'recipient'
and I have a 'satoshi fee'
and I have a 'satoshi amount'
and I have a 'satoshi unspent'
When I rename the 'satoshi unspent' to 'testnet unspent'
When I create the testnet transaction
Then print the 'testnet transaction'
EOF
    save_output "create_transaction.out.json"
    assert_output '{"testnet_transaction":{"nHashType":"AAAAAQ==","nLockTime":"AA==","txIn":[{"address":{"network":"dGI=","raw":"xRwg0j+JWVKWbCY3hnFd6D/D1NM=","version":0},"amountSpent":"ATdk","sequence":"/////w==","sigwit":"AQ==","txid":"3W08WP4M2HKecxVFgwMH/N02YgwUvFmIMI4EhdI+pTw=","vout":1}],"txOut":[{"address":{"network":"dGI=","raw":"9HAvm/7kKw1Pm6Ql+YNDeTiT8vQ=","version":0},"amount":"AQ=="},{"address":{"network":"dGI=","raw":"xRwg0j+JWVKWbCY3hnFd6D/D1NM=","version":0},"amount":"ATbW"}],"version":"Ag=="}}'
}

@test "Sign the transaction" {
    cat <<EOF | zexe sign_transaction.zen create_transaction.out.json create_testnet_key.out.json
Given I have the 'keyring'
and I have a 'base64 dictionary' named 'testnet transaction'
When I sign the testnet transaction
and I create the testnet raw transaction
and I create the size of 'testnet raw transaction'
Then print the 'testnet raw transaction' as 'hex'
EOF
    save_output "sign_transaction.out.json"
    assert_output '{"testnet_raw_transaction":"020000000001013ca53ed285048e308859bc140c6236ddfc0703834515739e72d80cfe583c6ddd3100000000ffffffff020100000000000000160014f4702f9bfee42b0d4f9ba425f98343793893f2f4d636010000000000160014c51c20d23f895952966c263786715de83fc3d4d3024730440220776b58c34145c9553b5235fe211a6237c48b90b4784bc6d86660b0236af3bab2022059e44401a39f15dd7a671284fbe3c20e0d7e00c77037a2dbd118b421059dbf7b012102776b58c34145c9553b5235fe211a6237c48b90b4784bc6d86660b0236af3bab200000000"}'
}

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
