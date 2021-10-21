function genagent() {

    cat <<EOF | zexe ${1}-keygen.zen | save bitcoin ${1}-keys.json
Scenario bitcoin
Given I am known as '${1}'
When I create the bitcoin key
Then print my 'keys'
EOF

    cat <<EOF | zexe ${1}-pubkey.zen -k ${1}-keys.json | save bitcoin ${1}-address.json
Scenario bitcoin
Given I am known as '${1}'
and I have my 'keys'
When I create the bitcoin public key
and I create the bitcoin address
and I write string 'tb' in 'network'
and I write number '0' in 'version'
and I move 'version' in 'bitcoin address'
and I move 'network' in 'bitcoin address'
Then print 'bitcoin address'
EOF

    cat <<EOF | zexe ${1}-wifkey.zen -k ${1}-keys.json | save bitcoin ${1}-wif.json
Scenario bitcoin
Given I am known as '${1}'
and I have my 'keys'
When I create the bitcoin testnet wif key
Then print my 'bitcoin testnet wif key' as 'base58'
EOF

}

function genwallet() {
    electrum --testnet close_wallet
    rm -f ~/.electrum/testnet/wallets/default_wallet

    wif="p2wpkh:`cat ${1}-wif.json | jq ".${1}" | sed 's/\"//g'`"
    echo "WIF: $wif"
    electrum --testnet restore $wif

    addr=`cat ${1}-address.json | jq '.bitcoin_address' | sed 's/\"//g'`

    electrum --testnet setconfig rpcuser     zenroom
    electrum --testnet setconfig rpcpassword zencode
    electrum --testnet load_wallet
}
