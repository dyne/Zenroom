load ../bats_setup

@test "Lua crypto primitives tests" {
    Z octet.lua
    Z octet_conversion.lua
    Z multiformat.lua
    Z varint.lua
    Z big_arithmetics.lua
    Z hash.lua
    Z ecdh.lua
    Z ecdsa_p256.lua
    Z x509.lua
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
    Z hash_ripemd160.lua
    Z hdwallet.lua
    Z pbkdf2.lua
    Z rlp_encoding.lua
    Z satoshibtc.lua
    Z bech32.lua
    Z schnorr.lua
    Z w3c-vc.lua
    Z coconut_preference.lua
    Z ethereum.lua
    Z bbs.lua
    Z zcash.lua
    Z hkdf.lua
    Z fsp.lua
    Z uuid.lua
}

@test "Lua zk-circuit-lang tests" {
    Z zk-circuit-lang/01_simple_arithmetic.lua
    Z zk-circuit-lang/02_age_verification.lua
    Z zk-circuit-lang/03_range_proof.lua
    Z zk-circuit-lang/04_circuit_parameters.lua
    Z zk-circuit-lang/04_conditional_logic.lua
    Z zk-circuit-lang/05_bitwise_operations.lua
    Z zk-circuit-lang/06_sum_verification.lua
    Z zk-circuit-lang/07_multiplexer.lua
    Z zk-circuit-lang/08_field_arithmetic.lua
    Z zk-circuit-lang/09_mdoc_circuit.lua
    Z zk-circuit-lang/10_circuit_save_load.lua
}
