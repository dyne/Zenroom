load ../bats_setup
load ../bats_zencode
SUBDOC=zenswarm

@test "Create mpack of block" {
    cat << EOF | save_asset L1_newheads_ethereum.json
{
    "system_timestamp": "1652271067",
    "jsonrpc": "2.0",
    "method": "eth_subscription",
    "params": {
        "result": {
            "baseFeePerGas": null,
            "difficulty": "0x2",
            "extraData": "0xd683010a11846765746886676f312e3138856c696e75780000000000000000006ce62f0aa8d3272e4c33c0f2fc4036329b81c81b51e39a7846ac53edb49128d7522e6f66c4d7909e54b2834464da9256c814888fc05eb919c2701cddb3a3cc1b01",
            "gasLimit": "0x7a1200",
            "gasUsed": "0x0",
            "hash": "0x75e602c49a900cf3b92113f4c09db2cd543345347c83986524b694262310e74c",
            "logsBloom": "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "miner": "0x0000000000000000000000000000000000000000",
            "mixHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
            "nonce": "0x0000000000000000",
            "number": "0x11bf3",
            "parentHash": "0x7ecfebbf3af7d1a93bbcf5dbd2c756de2cad823708fea8e10e3e811950d7726a",
            "receiptsRoot": "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
            "sha3Uncles": "0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347",
            "stateRoot": "0x538d1d7d221791a768785afbee5d6d319d7d99a2cec2d3954f2909637c18af43",
            "timestamp": "0x627ba95c",
            "transactionsRoot": "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421"
        },
        "subscription": "0xecb27edfb3719c74308aa8a4ac3b9038"
    }
}
EOF

# if inside result the 'transactions' dictionary is not empty then list hash of transactions

    cat << EOF | zexe newheads_message.zen L1_newheads_ethereum.json
Given I have a 'hex dictionary' named 'result' in 'params'
# and I have a 'number' named 'system_timestamp'
When I create the 'string dictionary' named 'newblock'
When I move 'hash' from 'result' to 'newblock'
When I move 'number' from 'result' to 'newblock'
When I move 'parentHash' from 'result' to 'newblock'
When I move 'timestamp' from 'result' to 'newblock'
# When I insert 'system_timestamp' in 'newblock'
When I create the mpack of 'newblock'
Then print the 'mpack' as 'base64'
EOF
    save_output 'newblock.json'
    assert_output '{"mpack":"hKRoYXNoxwAAACtkZVlDeEpxUURQTzVJUlAwd0oyeXpWUXpSVFI4ZzVobEpMYVVKaU1RNTB3pm51bWJlcscAAAAEQVJ2eqpwYXJlbnRIYXNoxwAAACtmc19ydnpyMzBhazd2UFhiMHNkVzNpeXRnamNJX3FqaERqNkJHVkRYY21vqXRpbWVzdGFtcMcAAAAGWW51cFhB"}'
}


@test "Unpack block" {
    cat << EOF | zexe newblock_unpack.zen newblock.json
Given I have a 'base64' named 'mpack'
When I create the 'newblock' decoded from mpack 'mpack'
Then print the 'newblock' as 'hex'
EOF
    save_output 'newblock_unpack.out'
    assert_output '{"newblock":{"hash":"75e602c49a900cf3b92113f4c09db2cd543345347c83986524b694262310e74c","number":"011bf3","parentHash":"7ecfebbf3af7d1a93bbcf5dbd2c756de2cad823708fea8e10e3e811950d7726a","timestamp":"627ba95c"}}'


}

@test "Decode poem" {
    cat << EOF | save_asset poem_bytes.json
{ "poem_bytes": "0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000009984a974696d657374616d70c7000000075f324a37715167aa706172656e7448617368c70000002c5f7a437a7830533432627377733442477231694c7165316f392d66383254576f7849567269717744546b5936a66e756d626572c7000000044152766ea468617368c70000002c5f3577417679677362357971477039345a73474f4c2d32433570416e56614f52503167753678372d6a33536300000000000000" }
EOF

    cat << EOF | zexe poem_decode.zen poem_bytes.json
Scenario ethereum
Given I have a 'hex' named 'poem bytes'
When I create the 'poem' decoded from ethereum bytes 'poem bytes'
and I create the 'newblock' decoded from mpack 'poem'
Then print the 'newblock' as 'hex'
EOF
    save_output 'poem_decode.out'
    assert_output '{"newblock":{"hash":"ff9c00bf282c6f9caa1a9f7866c18e2fed82e6902755a3913f582eeb1efe8f749c","number":"011be7","parentHash":"ff30b3c744b8d9bb30b38046af588ba9ed68f7e7fcd935a8c4856b8aac034e463a","timestamp":"ff627ba908"}}'
}
