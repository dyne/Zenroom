load ../bats_setup
load ../bats_zencode
SUBDOC=pack

@test "Serialize new block" {
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

    cat << EOF | zexe newblock.zen L1_newheads_ethereum.json
Given I have a 'hex dictionary' named 'result' in 'params'
When I create the 'hex dictionary' named 'newblock'
When I move 'hash' from 'result' to 'newblock'
When I move 'number' from 'result' to 'newblock'
When I move 'parentHash' from 'result' to 'newblock'
When I move 'timestamp' from 'result' to 'newblock'
Then print the 'newblock'
EOF
    save_output "newblock.json"
    assert_output '{"newblock":{"hash":"75e602c49a900cf3b92113f4c09db2cd543345347c83986524b694262310e74c","number":"011bf3","parentHash":"7ecfebbf3af7d1a93bbcf5dbd2c756de2cad823708fea8e10e3e811950d7726a","timestamp":"627ba95c"}}'
}

@test "Unpack block" {
    cat << EOF | zexe newheads_message.zen newblock.json
Given I have a 'hex dictionary' named 'newblock'
When I create the mpack of 'newblock'
Then print the 'mpack'
EOF
    save_output "mpack.json"
    assert_output '{"mpack":"hKRoYXNoxwAAACtkZVlDeEpxUURQTzVJUlAwd0oyeXpWUXpSVFI4ZzVobEpMYVVKaU1RNTB3pm51bWJlcscAAAAEQVJ2eqpwYXJlbnRIYXNoxwAAACtmc19ydnpyMzBhazd2UFhiMHNkVzNpeXRnamNJX3FqaERqNkJHVkRYY21vqXRpbWVzdGFtcMcAAAAGWW51cFhB"}'

}


@test "Mpack decode" {
    cat << EOF | zexe newblock_unpack.zen newblock.json mpack.json
Given I have a 'base64' named 'mpack'
and I have a 'hex dictionary' named 'newblock'
When I create the 'decoded' decoded from mpack 'mpack'
and I verify 'decoded' is equal to 'newblock'
Then print the string 'MPACK SUCCESS'
EOF
    save_output 'newblock_unpack.out'
    assert_output '{"output":["MPACK_SUCCESS"]}'
}


# TODO: ZPACK
@test "Create the zpack" {
    cat << EOF | zexe zpack.zen newblock.json
Given I have a 'hex dictionary' named 'newblock'
When I create the zpack of 'newblock'
Then print the 'zpack' as 'base64'
EOF
    save_output 'zpack.json'
    assert_output '{"zpack":"KLUv/SD19QYAco0yLkBr3cMwxo+KSNQxDMCkRvftdxe/28dvX3Ny7Mk3OxeNVdBySHkjdapchuFLBySNauMsBGCrrvNXqitujRX0QDAYyKCZSSxHzDANUudB5uaqpI4g4o2Dd4etDJGg7WPfLrujGgz8V+UsxWueaYFGDq4QafPBCqgGak+PDQpEXiNRjodBgiZJ9B1AXgYwDHMxs89QwrXL8GJ/V0Ds9lIdqbS+nxZef8ZMicSrXd5by1e34WuX68lvoHZOq3w/KTBL5Y32LRPx5Y2TiAUA1TVATqAXtArH5spSLWUG"}'
}

@test "Zunpack" {
    cat << EOF | zexe zunpack.zen newblock.json zpack.json
Given I have a 'base64' named 'zpack'
and I have a 'hex dictionary' named 'newblock'
When I create the 'decoded' decoded from zpack 'zpack'
and I verify 'decoded' is equal to 'newblock'
Then print the string 'ZPACK SUCCESS'
EOF
    save_output "zunpack.out"
    assert_output '{"output":["ZPACK_SUCCESS"]}'

}
