load ../bats_setup

@test "Lua crypto primitives tests" {
    Z octet.lua
    Z octet_conversion.lua
    Z big_arithmetics.lua
    Z hash.lua
    Z ecdh.lua
    Z dh_session.lua
    Z ecp_generic.lua
    Z elgamal.lua
    Z elgah.lua
    Z lagrange.lua
    Z bls_pairing.lua
    Z coconut_test.lua
    Z crypto_credential.lua
    Z mnemonic_encoding.lua
    Z qp.lua
}

