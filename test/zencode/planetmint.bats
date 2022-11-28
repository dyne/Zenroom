load ../bats_setup
load ../bats_zencode
SUBDOC=planetmint

@test "Generate signature list for simple tx" {
    cat <<EOF | save_asset transfer_tx.json
{
  "keyring": {
    "eddsa": "5TADqG617sFWyv1iCv11nvWBmzHuAtEcdxKN3Jzq9Dkd"
  },
    "ed25519_public_key": "2HBqpyHGncBsKM83dWSWaTGDEWmaWseBoQ4A2shQWKwg",
    "planetmint_transaction": "{\"asset\":{\"data\":{\"city\":\"Berlin\",\"temperature\":\"22\"}},\"id\":null,\"inputs\":[{\"fulfillment\":null,\"fulfills\":null,\"owners_before\":[\"2HBqpyHGncBsKM83dWSWaTGDEWmaWseBoQ4A2shQWKwg\"]}],\"metadata\":null,\"operation\":\"CREATE\",\"outputs\":[{\"amount\":\"1\",\"condition\":{\"details\":{\"public_key\":\"2HBqpyHGncBsKM83dWSWaTGDEWmaWseBoQ4A2shQWKwg\",\"type\":\"ed25519-sha-256\"},\"uri\":\"ni:\/\/\/sha-256;_GEZ1UiLdzeQDd3GEloMU-krKbEOO7W4_d_CQiYoW1k?fpt=ed25519-sha-256&cost=131072\"},\"public_keys\":[\"2HBqpyHGncBsKM83dWSWaTGDEWmaWseBoQ4A2shQWKwg\"]}],\"version\":\"2.0\"}"
}
EOF

    cat <<EOF | zexe transfer_tx.zen transfer_tx.json
Scenario 'planetmint': sign outputs
Given I have the 'keyring'
Given I have a 'string' named 'planetmint transaction'
When I create the planetmint signatures of 'planetmint transaction'
Then print the data
EOF
    save_output "transfer_tx.out"
    assert_output '{"planetmint_signatures":["19dbc4b385d4f509ed9879a5a4d8788bcd2f25ba87ba69d17f43ab5e3af5b12860593034b948d84c19c76f4838f1c92e58a23ce67ff6104d47336e1c59202a0f"],"planetmint_transaction":"{\"asset\":{\"data\":{\"city\":\"Berlin\",\"temperature\":\"22\"}},\"id\":null,\"inputs\":[{\"fulfillment\":null,\"fulfills\":null,\"owners_before\":[\"2HBqpyHGncBsKM83dWSWaTGDEWmaWseBoQ4A2shQWKwg\"]}],\"metadata\":null,\"operation\":\"CREATE\",\"outputs\":[{\"amount\":\"1\",\"condition\":{\"details\":{\"public_key\":\"2HBqpyHGncBsKM83dWSWaTGDEWmaWseBoQ4A2shQWKwg\",\"type\":\"ed25519-sha-256\"},\"uri\":\"ni:///sha-256;_GEZ1UiLdzeQDd3GEloMU-krKbEOO7W4_d_CQiYoW1k?fpt=ed25519-sha-256&cost=131072\"},\"public_keys\":[\"2HBqpyHGncBsKM83dWSWaTGDEWmaWseBoQ4A2shQWKwg\"]}],\"version\":\"2.0\"}"}'
}

@test "Generate signature list for transfer" {
    cat <<EOF | save_asset transfer_tx.json
{
  "keyring": {
    "eddsa": "AeCvymMgC1RdzGMYVA34RuHsJNuVpgmhRa4eNKQkUPCN"
  },
    "ed25519_public_key": "8BHtEUgWHFDeap59BC6L6coa3qdH2fP23iXzG194q4ym",
    "planetmint_transaction": "{\"asset\":{\"id\":\"39be9f7f917dcb3d2244e5f71b68381d97180c32b54cf031aef8ad2acecea769\"},\"id\":null,\"inputs\":[{\"fulfillment\":null,\"fulfills\":{\"output_index\":0,\"transaction_id\":\"f527fa0e17addda7c8df4287a2f6fc6d56cebf71ed414cd7b96ac5dbf1750eb9\"},\"owners_before\":[\"8BHtEUgWHFDeap59BC6L6coa3qdH2fP23iXzG194q4ym\"]},{\"fulfillment\":null,\"fulfills\":{\"output_index\":1,\"transaction_id\":\"2bd8193229dff308f3f7e94b455695e9016a674f651ad0df03b98596b735884e\"},\"owners_before\":[\"8BHtEUgWHFDeap59BC6L6coa3qdH2fP23iXzG194q4ym\"]}],\"metadata\":null,\"operation\":\"TRANSFER\",\"outputs\":[{\"amount\":\"10000000000000000\",\"condition\":{\"details\":{\"public_key\":\"8BHtEUgWHFDeap59BC6L6coa3qdH2fP23iXzG194q4ym\",\"type\":\"ed25519-sha-256\"},\"uri\":\"ni:\/\/\/sha-256;87HfOFRmfv2UwmunAbNnxTLKX5tKR7mn23nS2DX6UsE?fpt=ed25519-sha-256&cost=131072\"},\"public_keys\":[\"8BHtEUgWHFDeap59BC6L6coa3qdH2fP23iXzG194q4ym\"]},{\"amount\":\"50000000000000000\",\"condition\":{\"details\":{\"public_key\":\"DRH8bHnstFroRQYtKf7rPjnxdCiG4xiVSnpudE17YcdC\",\"type\":\"ed25519-sha-256\"},\"uri\":\"ni:\/\/\/sha-256;R3YZD9PsRCcEeBh49rZ287QIOuEblbWUNiZu-aFsd_g?fpt=ed25519-sha-256&cost=131072\"},\"public_keys\":[\"DRH8bHnstFroRQYtKf7rPjnxdCiG4xiVSnpudE17YcdC\"]}],\"version\":\"2.0\"}"
}
EOF

    cat <<EOF | zexe transfer_tx.zen transfer_tx.json
Scenario 'planetmint': sign outputs
Given I have the 'keyring'
Given I have a 'string' named 'planetmint transaction'
When I create the planetmint signatures of 'planetmint transaction'
Then print the data
EOF
    save_output "transfer_tx.out"
    assert_output '{"planetmint_signatures":["b7e56a9aa4850669688329bd2f750b6d750c5fafabf346426edbaab94c5ea0c353372b31212cc7d5ded53a762c439a5a8420c91b682616cecfa92f923eb70006","f81946883ef3caa05a933034b9b16a639ececf8489bf69522e47cf2129693bf48ee15cfb3daadd72bc2bdf5163821784a20bce63cc640991aa989683d3f32407"],"planetmint_transaction":"{\"asset\":{\"id\":\"39be9f7f917dcb3d2244e5f71b68381d97180c32b54cf031aef8ad2acecea769\"},\"id\":null,\"inputs\":[{\"fulfillment\":null,\"fulfills\":{\"output_index\":0,\"transaction_id\":\"f527fa0e17addda7c8df4287a2f6fc6d56cebf71ed414cd7b96ac5dbf1750eb9\"},\"owners_before\":[\"8BHtEUgWHFDeap59BC6L6coa3qdH2fP23iXzG194q4ym\"]},{\"fulfillment\":null,\"fulfills\":{\"output_index\":1,\"transaction_id\":\"2bd8193229dff308f3f7e94b455695e9016a674f651ad0df03b98596b735884e\"},\"owners_before\":[\"8BHtEUgWHFDeap59BC6L6coa3qdH2fP23iXzG194q4ym\"]}],\"metadata\":null,\"operation\":\"TRANSFER\",\"outputs\":[{\"amount\":\"10000000000000000\",\"condition\":{\"details\":{\"public_key\":\"8BHtEUgWHFDeap59BC6L6coa3qdH2fP23iXzG194q4ym\",\"type\":\"ed25519-sha-256\"},\"uri\":\"ni:///sha-256;87HfOFRmfv2UwmunAbNnxTLKX5tKR7mn23nS2DX6UsE?fpt=ed25519-sha-256&cost=131072\"},\"public_keys\":[\"8BHtEUgWHFDeap59BC6L6coa3qdH2fP23iXzG194q4ym\"]},{\"amount\":\"50000000000000000\",\"condition\":{\"details\":{\"public_key\":\"DRH8bHnstFroRQYtKf7rPjnxdCiG4xiVSnpudE17YcdC\",\"type\":\"ed25519-sha-256\"},\"uri\":\"ni:///sha-256;R3YZD9PsRCcEeBh49rZ287QIOuEblbWUNiZu-aFsd_g?fpt=ed25519-sha-256&cost=131072\"},\"public_keys\":[\"DRH8bHnstFroRQYtKf7rPjnxdCiG4xiVSnpudE17YcdC\"]}],\"version\":\"2.0\"}"}'
}

