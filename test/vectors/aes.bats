load ../bats_setup

@test "AES CBC" {
    Z aes_cbc.lua
}

@test "AES_CTR" {
    Z aes_ctr.lua
}

@test "AES GCM" {
    Z aes_gcm.lua
}

