load setup

@test "Lua crypto tests" {
    Z octet.lua
    Z octet_conversion.lua
    Z hash.lua
    Z ecdh.lua
    Z dh_session.lua
    Z ecp_generic.lua
    Z elgamal.lua
    Z bls_pairing.lua
    Z coconut_test.lua
    Z crypto_credential.lua
    Z mnemonic_encoding.lua
    Z qp.lua
}

