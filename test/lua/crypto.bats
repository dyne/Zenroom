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
}
