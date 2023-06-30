load ../bats_setup
load ../bats_zencode
SUBDOC=ethereum

newaddr() {
    name="$1"
    cat <<EOF | zexe ${name}_keygen.zen
Scenario ethereum
Given nothing
When I create the ethereum key
Then print the 'keyring'
EOF
    save_output "${name}_keys.json"
    rm $TMP/out

# cat <<EOF | zexe pubgen.zen -k keys.json | save $SUBDOC pubkey.json
# Given I have the 'keyring'
# When I create the ethereum public key
# Then print the 'ethereum public key'
# EOF

    cat <<EOF | zexe ${name}_addrgen.zen ${name}_keys.json
Scenario ethereum
Given I am known as '$name'
and I have the 'keyring'
When I create the ethereum address
Then print my 'ethereum address'
EOF
    save_output "${name}_address.json"
# any address is an hash keccak 256 of public key, cut to 20 bytes
}


@test "Create addresses" {
    newaddr "alice"
    newaddr "bob"
}


# rename does not change the encoding anymore,
# maybe create new functions for these operations

#cat <<EOF > ethval.json
#{"ethereum_value":"1"}
#EOF
#cat <<EOF > gweival.json
#{"gwei_value":"1000000000"}
#EOF
#cat <<EOF > weival.json
#{"wei_value":"1000000000000000000"}
#EOF
#cat <<EOF | zexe eth2wei.zen -a ethval.json \
#    > conv_weival.json
#Scenario ethereum
#Given I have the 'ethereum value'
#When I rename 'ethereum value' to 'wei value'
#Then I print 'wei value'
#EOF
# diff conv_weival.json weival.json
#cat <<EOF | zexe eth2gwei.zen -a ethval.json \
#    > conv_gweival.json
#Scenario ethereum
#Given I have the 'ethereum value'
#When I rename 'ethereum value' to 'gwei value'
#Then I print 'gwei value'
#EOF
# diff conv_gweival.json gweival.json
#
#cat <<EOF | zexe gwei2eth.zen -a gweival.json \
#    > conv_ethval.json
#Scenario ethereum
#Given I have the 'gwei value'
#When I rename 'gwei value' to 'ethereum value'
#Then I print 'ethereum value'
#EOF
# diff conv_ethval.json ethval.json
#cat <<EOF | zexe gwei2wei.zen -a gweival.json \
#    > conv_weival.json
#Scenario ethereum
#Given I have the 'gwei value'
#When I rename 'gwei value' to 'wei value'
#Then I print 'wei value'
#EOF
# diff conv_weival.json weival.json
#
#cat <<EOF | zexe wei2eth.zen -a weival.json \
#    > conv_ethval.json
#Scenario ethereum
#Given I have the 'wei value'
#When I rename 'wei value' to 'ethereum value'
#Then I print 'ethereum value'
#EOF
# diff conv_ethval.json ethval.json
#cat <<EOF | zexe wei2gwei.zen -a weival.json \
#    > conv_gweival.json
#Scenario ethereum
#Given I have the 'wei value'
#When I rename 'wei value' to 'gwei value'
#Then I print 'gwei value'
#EOF
# diff conv_gweival.json gweival.json

function getnonce() (
    curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_getTransactionCount","params":["'"$1"'", "latest"],"id":42}' $HOST
    sleep 1
)
@test "When I create the ethereum transaction of '' to ''" {
    HOST=http://test.fabchain.net:8545

    alice_address=`cat $BATS_FILE_TMPDIR/alice_address.json | cut -d'"' -f6`
    echo "Alice address: 0x${alice_address}"
    # getnonce "0x${alice_address}"

    NONCE=`getnonce 0x${alice_address} | jq -r '.result'`
    cat <<EOF | save_asset alice_nonce_eth.json
{ "ethereum nonce": "`printf "%d" ${NONCE}`",
  "gas price": "100000000000",
  "gas limit": "300000",
  "gwei value": "10"
}
EOF

    cat <<EOF | zexe transaction.zen alice_nonce_eth.json bob_address.json
Scenario ethereum
Given I have a 'ethereum address' inside 'bob'
# ?? restroom: and I have a nonce ??
# nonce is given via RPC input alice's address
and a 'gas price'
and a 'gas limit'
and an 'ethereum nonce'
and a 'gwei value'
# and a 'wei value'
# 1 eth is 10^18 wei
# 1 eth is 10^9 gwei
When I create the ethereum transaction of 'gwei value' to 'ethereum address'
Then print the 'ethereum transaction'
EOF
    save_output 'alice_to_bob_transaction.json'
}

@test "When I create the signed ethereum transaction" {
    cat <<eof | zexe sign_transaction.zen alice_to_bob_transaction.json alice_keys.json
scenario ethereum
given I have the 'keyring'
and I have a 'ethereum transaction'
# tx["v"] = int.new(1337) <- chain id
# tx["r"] = o.new()
# tx["s"] = o.new()
# encodedtx = eth.encodesignedtransaction(from, tx)
when I create the signed ethereum transaction
#for chain 'fab'
# needs keys.ethereum and valid eth transaction
then print the 'signed ethereum transaction'
eof
    save_output 'sign_transaction.json'
}


@test "When I create the signed ethereum transaction for chain ''" {
    cat <<eof | zexe sign_transaction_chainid.zen alice_to_bob_transaction.json alice_keys.json
scenario ethereum
given I have the 'keyring'
and I have a 'ethereum transaction'
when I create the signed ethereum transaction for chain 'fabt'
then print the 'signed ethereum transaction'
eof

    save_output 'sign_transaction.json'
}

@test "When I use the ethereum transaction to store 'random object'" {
    cat <<EOF | save_asset storage_contract.json
{ "storage_contract": "d01394Ade77807B3fE7DAE6f54462dE453Cc8741" }
EOF

    cat <<EOF | zexe transaction_storage.zen alice_nonce_eth.json storage_contract.json
Scenario ethereum
Given I have a 'ethereum address' named 'storage contract'
# here we assume bob is a storage contract
and a 'gas price'
and a 'gas limit'
and an 'ethereum nonce'
When I create the ethereum transaction to 'storage contract'
and I create the random object of '256' bits
and I use the ethereum transaction to store 'random object'
Then print the 'ethereum transaction'
EOF
    save_output 'alice_storage_tx.json'
}

@test "When I use the ethereum transaction to store ecp point" {
    cat <<EOF | zexe transaction_storage_ecp.zen alice_nonce_eth.json storage_contract.json
Scenario ethereum
Given I have a 'ethereum address' named 'storage contract'
# here we assume bob is a storage contract
and I have a 'gas price'
and I have a 'gas limit'
and I have an 'ethereum nonce'
When I set 'data' to 'Hello, it is me Mario!' as 'string'
When I create the hash to point 'ecp' of 'data'
When I create the ethereum transaction to 'storage contract'
and I use the ethereum transaction to store 'hash to point'
Then print the 'ethereum transaction'
EOF
    save_output 'alice_storage_tx.json'
}

@test "When I create the signed ethereum transaction for chain '' (again)" {
    cat <<eof | zexe sign_transaction_chainid.zen alice_storage_tx.json alice_keys.json
scenario ethereum
given I have the 'keyring'
and I have a 'ethereum transaction'
when I create the signed ethereum transaction for chain 'fabt'
then print the 'signed ethereum transaction'
eof
NONCE=`getnonce 0x${alice_address} | jq -r '.result'`
cat <<EOF | save_asset alice_nonce_data.json
{ "ethereum nonce": "`printf "%d" ${NONCE}`",
"gas price": "100000000000",
"gas limit": "300000",
"storage_contract": "0xE54c7b475644fBd918cfeDC57b1C9179939921E6"
}
EOF
}
# Store complex object
# NONCE=`getnonce 0x${alice_address} | jq -r '.result'`
# cat <<EOF | save $SUBDOC alice_nonce_data.json
# { "ethereum nonce": "`printf "%d" ${NONCE}`",
# "gas price": "100000000000",
# "gas limit": "300000",
# "storage_contract": "E54c7b475644fBd918cfeDC57b1C9179939921E6"
# }
# EOF
# cat <<EOF | zexe store_complex_object.zen -a alice_nonce_data.json -k alice_keys.json
# Scenario ethereum
# Given I have the 'keys'
# Given I have a 'ethereum address' named 'storage contract'
# Given I have a 'ethereum nonce'
# and a 'gas price'
# and a 'gas limit'
# When I create the array of '12' random objects
# When I create the ethereum transaction to 'storage contract'
# and I use the ethereum transaction to store 'array'

# When I create the signed ethereum transaction for chain 'fabt'
# Then print the 'signed ethereum transaction'
# Then print data
# EOF

@test "Decode data: when I create the string from the ethereum bytes named ''" {
# Decode data stored
    cat <<EOF | save_asset read_stored_string.data
{
  "data": "000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000674e656c206d657a7a6f2064656c2063616d6d696e206469206e6f7374726120766974610a6d6920726974726f7661692070657220756e612073656c7661206f73637572612c0a6368c3a9206c612064697269747461207669612065726120736d6172726974612e00000000000000000000000000000000000000000000000000"
}
EOF

    cat <<EOF | zexe read_stored_string.zen read_stored_string.data
Scenario ethereum
Given I have a 'hex' named 'data'
When I create the string from the ethereum bytes named 'data'
Then print data
EOF
    save_output 'read_stored_string.json'
}


@test "Transfer erc20 tokens" {
    NONCE=`getnonce "0xef5dca69e9c573f6acce1b4c641b2b526217328f" | jq -r '.result'`
    cat <<EOF | save_asset send_tokens.json
{
	"keyring": {
		   "ethereum": "634f3f80fc087ad90866012d74c41ccc698b43592dee7ed27ecb89333c2e3d1c"
	},
	"gas price": "100000000000",
	"gas limit": "100000",
	"token value": "1",
	"erc20": "0x1e30e53E87869aaD8dC5A1A9dAc31a8dD3559460",
	"receiver": "0x828bddf0231656fb736574dfd02b7862753de64b",
	"ethereum nonce": "`echo $(($NONCE))`"
}
EOF

    cat <<EOF | zexe send_tokens.zen send_tokens.json
Scenario ethereum

# load the JSON file
Given I have the 'keyring'
Given I have a 'ethereum address' named 'receiver'
Given I have a 'ethereum address' named 'erc20'
Given I have a 'ethereum nonce'
and a 'gas price'
and a 'gas limit'
# load the number of tokens that will be transferred
and a 'number' named 'token value'

# create the transaction for the erc20 token contract
When I create the ethereum transaction to 'erc20'
# here we fill the data field with all the information needed by the erc20 token contract
and I use the ethereum transaction to transfer 'token value' erc20 tokens to 'receiver'
# then i sign it, and it is ready to be broadcast to a node
When I create the signed ethereum transaction for chain 'fabt'

# print the signed ethereum transaction
Then print the 'signed ethereum transaction'
EOF
    save_output 'send_tokens_signed_tx.json'
}

# TODO: verify tx using Alice's public key (not the address)

# local ERC20_SIGNATURES = {
#    balanceOf         = { view=true, i={'address'}, o={'uint256'} },
#    transfer          = {            i={'address', 'uint256'}, o={'bool'} },
#    approve           = {            i={'address', 'uint256'}, o={'bool'} },
#    allowance         = { view=true, i={'address', 'address'}, o={'uint256'} },
#    transferFrom      = {            i={'address', 'address', 'uint256'}, o={'bool'} },
#    decimals          = { view=true, o={'uint8'} },
#    name              = { view=true, o={'string'} },
#    symbol            = { view=true, o={'string'} },
#    totalSupply       = { view=true, o={'uint256'} },
# }

# # wishlist for Restroom
# Given I have the 'balance' of 'address' for erc20 'contract address'
# Given I have the 'balance' of 'address' for erc20 'contract address' named 'variable name'
# Given I have the 'decimals' for erc20 'contract address' ( named 'variable name' )
# Given I have the 'name'     for erc20 'contract address' ( named 'variable name' )
# Given I have the 'symbol'   for erc20 'contract address' ( named 'variable name' )
# Given I have the 'total supply' for erc20 'contract address' ( named 'variable name' )

@test "Used in documentation" {
    cat <<EOF | save_asset doc_key.json
{
	"ethereum private key": "150ad66741dd4f917d1e7877e2cb5d47ce1baa8e635b41675fa4f1ca51b681bb"
}
EOF
    cat <<EOF | zexe doc_key_upload.zen doc_key.json
Scenario ethereum
Given I have a 'hex' named 'ethereum private key'

# here we upload the key
When I create the ethereum key with secret key 'ethereum private key'
# an equivalent statement is
# When I create the ethereum key with secret 'ethereum private key'

Then print the keyring
EOF
    save_output 'doc_key_upload.json'
}

@test "Used in documentation (2)" {
    cat <<EOF | zexe doc_pubgen.zen alice_keys.json
Scenario ecdh
Scenario ethereum

# load the ethereum key
Given I have a 'hex' named 'ethereum' in 'keyring'

# create the ecdh public key
When I create the ecdh key with secret key 'ethereum'
When I create the ecdh public key
# rename it to ethereum public key
and I rename the 'ecdh public key' to 'ethereum public key'

# print the ethereum public key as hex
Then print the 'ethereum public key' as 'hex'
EOF
    save_output 'doc_pubgen.json'
}

@test "Used in documentation (3)" {
    NONCE=`getnonce 0x${alice_address} | jq -r '.result'`
    cat <<EOF | save_asset doc_tx_information.json
    { "ethereum nonce": "`printf "%d" ${NONCE}`",
      "gas price": "100000000000",
      "gas limit": "300000"
    }
EOF

    cat <<EOF | save_asset doc_alice_data.json
    {
      "data": "This is my first data stored on ethereum blockchain"
    }
EOF

    jq -s '.[0]*.[1]' "$BATS_FILE_TMPDIR/alice_nonce_eth.json" "$BATS_FILE_TMPDIR/bob_address.json" | save_asset doc_tx_information_eth.json
cat <<EOF | zexe doc_transaction.zen doc_tx_information_eth.json
Scenario ethereum

# Load the JSON file
Given I have a 'ethereum address' inside 'bob'
and a 'gas price'
and a 'gas limit'
and an 'ethereum nonce'
and a 'gwei value'

# Create the ethereum transaction
When I create the ethereum transaction of 'gwei value' to 'ethereum address'

Then print the 'ethereum transaction'
EOF
    save_output 'doc_alice_to_bob_transaction.json'
}

@test "Used in documentation (4)" {
    jq -s '.[0]*.[1]' "$BATS_FILE_TMPDIR/alice_nonce_data.json" "$BATS_FILE_TMPDIR/doc_alice_data.json" | save_asset doc_tx_information_data.json
cat <<EOF | zexe doc_transaction_storage.zen doc_tx_information_data.json
Scenario ethereum

# Load  the JSON file
Given I have a 'ethereum address' named 'storage contract'
and a 'gas price'
and a 'gas limit'
and an 'ethereum nonce'
and a 'string' named 'data'

# Create the ethereum transaction
When I create the ethereum transaction to 'storage contract'
# use it to store the data
and I use the ethereum transaction to store 'data'

Then print the 'ethereum transaction'
EOF
    save_output 'doc_alice_storage_tx.json'


}

@test "Used in documentation (5)" {
    cat <<EOF | zexe doc_sign_transaction.zen doc_alice_storage_tx.json alice_keys.json
scenario ethereum

# Load the private key and the transaction
given I have the 'keyring'
and I have a 'ethereum transaction'

# sign the transaction for the chain with chain id 'fabt'
when I create the signed ethereum transaction for chain 'fabt'

then print the 'signed ethereum transaction'
EOF
    save_output 'doc_signed_tx.json'
}

@test "Used in documentation (6)" {
    cat <<EOF | zexe doc_sign_transaction_local.zen doc_alice_storage_tx.json alice_keys.json
scenario ethereum

# Load the private key and the transaction
given I have the 'keyring'
and I have a 'ethereum transaction'

# sign the transaction for the local testnet
when I create the signed ethereum transaction

then print the 'signed ethereum transaction'
EOF
    save_output 'doc_sign_transaction_local.json'
}

@test "Used in documentation (7)" {
    cat <<EOF | save_asset doc_read_stored_string.json
{
  "data": "0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003354686973206973206d7920666972737420646174612073746f726564206f6e20657468657265756d20626c6f636b636861696e00000000000000000000000000"
}
EOF

    cat <<EOF | zexe doc_read_stored_string.zen doc_read_stored_string.json
Scenario ethereum
Given I have a 'hex' named 'data'
When I create the 'data retrieved' decoded from ethereum bytes 'data'
Then print the 'data retrieved' as 'string'
EOF
    save_output 'doc_retrieved_data.json'
}

@test "Import transaction" {
    cat <<EOF | save_asset 'import_tx.data'
{
    "keyring": {
		"bitcoin": "L44aGie6PCJY6drzVFszi9HPc7g98LQmcsJwDEGumBnMReX45xGK",
		"ecdh": "0L/FuN1ZaIG/imjoDBGgAvCpHMLL/WB2lX+DEQOSC4o=",
		"eddsa": "Cwj9CcqHNoBnXBo8iDfnhFkQeDun4Y4LStd2m3TEAYAg",
		"ethereum": "9ab36c2688502bd219eeea9e6021a056fb7f734f86ea727feec8ed96431bf6ad",
		"reflow": "OUaM/6vq37bVO8xRU7a/yh7mZZygU8aD+zWo5gRE6DA=",
		"schnorr": "ZQR+vMkjuRpcoqQ9bAcDowI3noEcjFVUmLLxyP1gPDg="
	},
    "ethereum_transaction": {
        "gas_limit": "50000",
        "gas_price": "2000000000",
        "nonce": "241",
        "to": "4806db98240cd10f9575737f6d0fc17afb50e936",
        "value": "500000"
    },
    "bigcid": "80",
    "strcid": "fabt",
    "numcid": "80"
}
EOF

    cat <<EOF | zexe import_tx.zen import_tx.data
scenario ethereum

given I have the 'keyring'
and I have a 'ethereum transaction'

given I have a 'string' named 'strcid'
given I have a 'string' named 'numcid'
given I have a 'integer' named 'bigcid'

When I create the signed ethereum transaction for chain 'fabt'
When I copy the 'v' in 'ethereum_transaction' to 'v0'
When I remove 'signed ethereum transaction'
When I create the signed ethereum transaction for chain 'strcid'
When I copy the 'v' in 'ethereum_transaction' to 'v1'
When I remove 'signed ethereum transaction'
When I create the signed ethereum transaction for chain '80'
When I copy the 'v' in 'ethereum_transaction' to 'v2'
When I remove 'signed ethereum transaction'
When I create the signed ethereum transaction for chain 'numcid'
When I copy the 'v' in 'ethereum_transaction' to 'v3'
When I remove 'signed ethereum transaction'
When I create the signed ethereum transaction for chain 'bigcid'
When I copy the 'v' in 'ethereum_transaction' to 'v4'
When I remove 'signed ethereum transaction'

then print the 'v0' as 'hex'
then print the 'v1' as 'hex'
then print the 'v2' as 'hex'
then print the 'v3' as 'hex'
then print the 'v4' as 'hex'
EOF
    save_output 'import_tx.json'
    assert_output '{"v0":"3435316491","v1":"3435316492","v2":"195","v3":"196","v4":"196"}'
}

@test "KECCAK256 on the abi encoding" {
    cat <<EOF | save_asset 'doc_keccak_abi.data'
{
    "address": "77c2f9730B6C3341e1B71F76ECF19ba39E88f247",
    "vote": "234",
    "typeSpec": ["address", "string"]
}
EOF
    cat <<EOF | zexe doc_keccak_abi.zen doc_keccak_abi.data
Scenario ethereum

Given I have a 'hex' named 'address'
Given I have a 'string' named 'vote'
Given I have a 'string array' named 'typeSpec'

When I create the new array
When I move 'address' in 'new array'
When I move 'vote' in 'new array'
When I create the ethereum abi encoding of 'new array' using 'typeSpec'
When I create the hash of 'ethereum abi encoding' using 'keccak256'

Then print the 'ethereum abi encoding'
Then print the 'hash'
EOF
    save_output 'doc_keccak_abi_out.json'
    assert_output '{"ethereum_abi_encoding":"00000000000000000000000077c2f9730b6c3341e1b71f76ecf19ba39e88f247000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000033233340000000000000000000000000000000000000000000000000000000000","hash":"pTFYbyovWkOT6CaHSRNCN7ySQ/AGbphs9WQnZ2JwPWQ="}'
}

@test "Complex encoding" {
    cat <<EOF | save_asset 'encoding_with_bool.data'
{
    "typeSpec": [
        "address",
        "uint256",
        "string",
        "string",
        "bool"
    ],
	"parameter1": "E54c7b475644fBd918cfeDC57b1C9179939921E6",
	"parameter2": "1234567891234",
	"parameter3": "hello world, this is a string passed as parameter to a smart contract",
	"parameter3b": "false string doesn't work on remix",
	"parameter4": "false"
}
EOF
    cat <<EOF | zexe encoding_with_bool.zen encoding_with_bool.data
Scenario ethereum

Given I have a 'ethereum address' named 'parameter1'
Given I have a 'integer' named 'parameter2'
Given I have a 'string' named 'parameter3'
Given I have a 'string' named 'parameter3b'
Given I have a 'string' named 'parameter4'
Given I have a 'string array' named 'typeSpec'

When I create the new array
When I move 'parameter1' in 'new array'
When I move 'parameter2' in 'new array'
When I move 'parameter3' in 'new array'
When I move 'parameter3b' in 'new array'
When I move 'parameter4' in 'new array'
When I create the ethereum abi encoding of 'new array' using 'typeSpec'

Then print the 'ethereum abi encoding'
EOF
    save_output 'encoding_with_bool.json'
    assert_output '{"ethereum_abi_encoding":"000000000000000000000000e54c7b475644fbd918cfedc57b1c9179939921e60000000000000000000000000000000000000000000000000000011f71fb092200000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004568656c6c6f20776f726c642c2074686973206973206120737472696e672070617373656420617320706172616d6574657220746f206120736d61727420636f6e7472616374000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002266616c736520737472696e6720646f65736e277420776f726b206f6e2072656d6978000000000000000000000000000000000000000000000000000000000000"}'
}
@test "Create ethereum signature" {
    cat <<EOF | save_asset 'sk_sign.data'
{
    "ethereum_address": "0x380FfB13F42AfFBE88949643B27FA74Ba85B3977",
    "keyring": {
        "ethereum": "876f6d4554e91f6f4bdaf8c741eef18b28f580f01d9d1af43c5238b8fe6bac6b"
    }
}
EOF
    cat <<EOF | zexe doc_signtest.zen sk_sign.data doc_keccak_abi_out.json
Scenario ethereum

Given I have a 'ethereum address'
Given I have a 'keyring'
Given I have a 'base64' named 'hash'

When I create the ethereum signature of 'hash'

Then print the 'ethereum signature'
Then print the 'ethereum address'
Then print the 'hash'
EOF
    save_output 'doc_signtest_out.json'
}

@test "Verify a ethereum signature from an address" {
    cat <<EOF | zexe doc_verifytesteth.zen doc_signtest_out.json
Scenario ethereum

Given I have a 'ethereum signature'
Given I have a 'ethereum address'
Given I have a 'base64' named 'hash'

When I verify the 'hash' has a ethereum signature in 'ethereum signature' by 'ethereum address'

Then print the string 'The signature is valid'
EOF
    save_output doc_verifytesteth_out.json
    assert_output '{"output":["The_signature_is_valid"]}'
}

@test "Create ethereum signature of string" {
    cat <<EOF | save_asset 'sk_sign_str.json'
{
    "ethereum_address": "0x380FfB13F42AfFBE88949643B27FA74Ba85B3977",
    "myString": "I love the Beatles, all but 3",
    "keyring": {
        "ethereum": "876f6d4554e91f6f4bdaf8c741eef18b28f580f01d9d1af43c5238b8fe6bac6b"
    }
}
EOF
    cat <<EOF | zexe doc_signtest_str.zen sk_sign_str.json 
Scenario ethereum

Given I have a 'keyring'
Given I have a 'ethereum address'
Given I have a 'string' named 'myString'

When I create the ethereum signature of 'myString'

Then print the 'ethereum signature'
Then print the 'ethereum address'
Then print the 'myString'
EOF
    save_output 'doc_signtest_str_out.json'
}

@test "Print ethereum signature as table" {
        cat <<EOF | zexe doc_print_ethsig.zen doc_signtest_str_out.json
Scenario ethereum

Given I have a 'ethereum signature'

Then print the 'ethereum signature' as 'hex'

EOF
    save_output doc_print_ethsig_out.json
    assert_output '{"ethereum_signature":{"r":"19373b64e400e237dd7fb23e76621675f8691c0eb14aa171a82f69593b1a2a05","s":"36203582c38585754a785ca504f51e4178bab5cc3f566e985358eaf7cb5d7876","v":"27"}}'
}

@test "Import ethereum signature as table" {
        cat <<EOF | zexe import_ethsig.zen doc_print_ethsig_out.json
Scenario ethereum

Given I have a 'ethereum signature'

Then print the 'ethereum signature'

EOF
    save_output import_ethsig_out.json
    assert_output '{"ethereum_signature":"0x19373b64e400e237dd7fb23e76621675f8691c0eb14aa171a82f69593b1a2a0536203582c38585754a785ca504f51e4178bab5cc3f566e985358eaf7cb5d78761b"}'
}


@test "Verify a ethereum signature of string from an address" {
    cat <<EOF | zexe doc_verifytesteth_str.zen doc_signtest_str_out.json
Scenario ethereum

Given I have a 'ethereum signature'
Given I have a 'ethereum address'
Given I have a 'string' named 'myString'

When I verify the 'myString' has a ethereum signature in 'ethereum signature' by 'ethereum address'

Then print the string 'The signature is valid'
EOF
    save_output doc_verifytesteth_str_out.json
    assert_output '{"output":["The_signature_is_valid"]}'
}

@test "Verify etherum address encoding" {
    cat <<EOF | save_asset checksum_enc.json
{
    "ethereum_address" : "0x1e30e53E87869aaD8dC5A1A9dAc31a8dD3559460"
}
EOF

    cat <<EOF | zexe doc_checksum_enc.zen checksum_enc.json
Scenario ethereum

# To verify the address you have to upload it as a string
Given I have a 'string' named 'ethereum address'
Given I rename 'ethereum address' to 'address string'

# To use it you simply write the following statement.
Given I have a 'ethereum address'

When I verify the ethereum address string 'address string' is valid
# Insert here other "When" statements which use 'ethereum address'

Then print the 'ethereum address'
Then print the string 'The address has a valid encoding'
EOF
    save_output 'doc_checksum_enc_output.json'
    assert_output '{"ethereum_address":"0x1e30e53E87869aaD8dC5A1A9dAc31a8dD3559460","output":["The_address_has_a_valid_encoding"]}'
}

@test "Wrong encoding raises warning or error" {
    cat <<EOF | save_asset checksum_fail.json
{
    "ethereum_address" : "0x1E30e53E87869aaD8dC5A1A9dAc31a8dD3559460"
}
EOF

    cat <<EOF | save_asset checksum_fail.zen
Scenario ethereum
Given I have a 'string' named 'ethereum address'
Given I rename 'ethereum address' to 'string address'

Given I have a 'ethereum address'
When I verify the ethereum address string 'string address' is valid

Then print the string 'This fails'
EOF
    run $ZENROOM_EXECUTABLE -z -a checksum_fail.json checksum_fail.zen
    assert_line '[W]  "Invalid encoding for ethereum address. Expected encoding: 0x1e30e53E87869aaD8dC5A1A9dAc31a8dD3559460"'
    assert_line '[W]  [!] The address has a wrong encoding'
}

@test "Call generic smart contract" {
    cat <<EOF | save_asset call_sc.data
{
	"myMethod": {
		"name": "myFantasticMethod",
		"input": [
			"address",
			"uint256",
                        "string"
		],
		"output": "bool"
	},
	"solidity address": "0xE54c7b475644fBd918cfeDC57b1C9179939921E6",
	"ethereum nonce": "0",
	"gas price": "100000000000",
	"gas limit": "300000",
	"parameter1": "E54c7b475644fBd918cfeDC57b1C9179939921E6",
	"parameter2": "1234567891234",
	"parameter3": "hello world, this is a string passed as parameter to a smart contract"
}
EOF
    cat <<EOF | zexe call_sc.zen call_sc.data
Scenario 'ethereum': call solidity

Given I have a 'ethereum method' named 'myMethod'
Given I have a 'ethereum address' named 'solidity address'

Given I have a  'gas price'
Given I have a 'gas limit'
Given I have an 'ethereum nonce'

Given I have an 'hex' named 'parameter1'
Given I have an 'integer' named 'parameter2'
Given I have an 'string' named 'parameter3'

When I create the ethereum transaction to 'solidity address'

When I create the new array
When I rename the 'new array' to 'myParams'

When I move 'parameter1' in 'myParams'
When I move 'parameter2' in 'myParams'
When I move 'parameter3' in 'myParams'

When I use the ethereum transaction to run 'myMethod' using 'myParams'

Then print the 'ethereum transaction'
Then print 'myMethod'
EOF
    save_output call_sc_out.json
    assert_output '{"ethereum_transaction":{"data":"483041db000000000000000000000000e54c7b475644fbd918cfedc57b1c9179939921e60000000000000000000000000000000000000000000000000000011f71fb09220000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000004568656c6c6f20776f726c642c2074686973206973206120737472696e672070617373656420617320706172616d6574657220746f206120736d61727420636f6e7472616374000000000000000000000000000000000000000000000000000000","gas_limit":"300000","gas_price":"100000000000","nonce":"0","to":"0xE54c7b475644fBd918cfeDC57b1C9179939921E6","value":"0"},"myMethod":{"input":["address","uint256","string"],"name":"myFantasticMethod","output":"bool"}}'
}

@test "print a ethereum signature array and ethereum address dictionary" {
    cat <<EOF | save_asset eth_sign_arr_eth_add_dict.data
{
	"addresses": {
		"first": "0x2B8070975AF995Ef7eb949AE28ee7706B9039504",
		"second": "0x3028806AC293B5aC9b863B685c73813626311DaD",
		"third": "0xe1C2F1ACb2758c4D88EDb84e0306A0a96682E62a"
	},
    "signatures": [
		{
			"r": "ed8f36c71989f8660e8f5d4adbfd8f1c0288cca90d3a5330b7bf735d71ab52fe",
			"s": "7ba0a7827dc4ba707431f1c10babd389f658f8e208b89390a9be3c097579a2ff",
			"v": "27"
		},
		{
			"r": "40d305373c648bb6b2bbadebe02ada256a9d0b3d3c37367c0a2795e367b22f73",
			"s": "72e40dfc3497927764d1585783d058e4367bb4d24d2107777d7aa4ddcb6593c7",
			"v": "27"
		},
		{
			"r": "9e07477c31db612e8c99a950385162373ff41a5b8941470b1aeba43b76c53570",
			"s": "05fce6615567dc1944cc02fbed86202b09d92d79fbade425af0d74c328d8f6ae",
			"v": "28"
		}
	]
}
EOF
    cat <<EOF | zexe eth_sign_arr_eth_add_dict.zen eth_sign_arr_eth_add_dict.data
Scenario ethereum: array of signature and dictionary of address

Given I have a 'ethereum signature array' named 'signatures'
Given I have a 'ethereum address dictionary' named 'addresses'

Then print the data
EOF
    save_output eth_sign_arr_eth_add_dict_out.json
    assert_output '{"addresses":{"first":"0x2B8070975AF995Ef7eb949AE28ee7706B9039504","second":"0x3028806AC293B5aC9b863B685c73813626311DaD","third":"0xe1C2F1ACb2758c4D88EDb84e0306A0a96682E62a"},"signatures":["0xed8f36c71989f8660e8f5d4adbfd8f1c0288cca90d3a5330b7bf735d71ab52fe7ba0a7827dc4ba707431f1c10babd389f658f8e208b89390a9be3c097579a2ff1b","0x40d305373c648bb6b2bbadebe02ada256a9d0b3d3c37367c0a2795e367b22f7372e40dfc3497927764d1585783d058e4367bb4d24d2107777d7aa4ddcb6593c71b","0x9e07477c31db612e8c99a950385162373ff41a5b8941470b1aeba43b76c5357005fce6615567dc1944cc02fbed86202b09d92d79fbade425af0d74c328d8f6ae1c"]}'
}

@test "ABI decoding" {
    cat <<EOF | save_asset 'eth_abi_decoding.data'
{
    "typeSpec": [
        "uint256",
        "bytes32",
        "uint256"
    ],
    "encoded_data": "00000000000000000000000000000000000000000000000000000000000000c848656c6c6f20576f726c6400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d3"
}
EOF
    cat <<EOF | zexe eth_abi_decoding.zen eth_abi_decoding.data
Scenario ethereum

Given I have a 'hex' named 'encoded data'
Given I have a 'string array' named 'typeSpec'

When I create the ethereum abi decoding of 'encoded data' using 'typeSpec'
When I create the copy of element '1' in array 'ethereum abi decoding'
When I rename 'copy' to 'request_id'
When I create the copy of element '2' in array 'ethereum abi decoding'
When I rename 'copy' to 'data'
When I create the copy of element '3' in array 'ethereum abi decoding'
When I rename 'copy' to 'dao_vote_id'

Then print the 'request_id' as 'integer'
Then print the 'data' as 'hex'
Then print the 'dao_vote_id' as 'integer'
EOF
    save_output 'eth_abi_decoding.json'
    assert_output '{"dao_vote_id":"211","data":"48656c6c6f20576f726c64000000000000000000000000000000000000000000","request_id":"200"}'
}
