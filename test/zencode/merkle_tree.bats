load ../bats_setup
load ../bats_zencode
SUBDOC=merkle_tree

@test "merkle root: array" {
    cat <<EOF | save_asset merkle_root_array.data.json
{
    "data": [
        "data1",
        "data2",
        "data3",
        "data4"
    ]
}
EOF
    cat <<EOF | zexe merkle_root_array.zen merkle_root_array.data.json
Scenario 'merkle': create merkle root
Given I have a 'string array' named 'data'

When I create the merkle root of 'data'

Then print the 'merkle root'
EOF
    save_output merkle_root_array.out.json
    assert_output '{"merkle_root":"1Fu3eBfOGVlDihcanmfcZj45yuy4Z3/SrSq1iupzD/Q="}'
}

@test "merkle root: from dictionary path" {
    cat <<EOF | save_asset merkle_root_path.data.json
{
    "data": {
        "data1": [
            "data1",
            "data2",
            "data3",
            "data4"
        ],
        "data2":"data2"
    }
}
EOF
    cat <<EOF | zexe merkle_root_path.zen merkle_root_path.data.json
Scenario 'merkle': create merkle root
Given I have a 'string dictionary' named 'data'

When I create the merkle root of dictionary path 'data.data1'

Then print the 'merkle root'
EOF
    save_output merkle_root_path.out.json
    assert_output '{"merkle_root":"1Fu3eBfOGVlDihcanmfcZj45yuy4Z3/SrSq1iupzD/Q="}'
}