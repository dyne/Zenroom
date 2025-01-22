load ../bats_setup
load ../bats_zencode
SUBDOC=hash

@test "When I create the hash of 'string'" {
    cat <<EOF | zexe hash_string.zen
rule output encoding hex
Given nothing
When I write string 'a string to be hashed' in 'source'
and I create the hash of 'source'
Then print the 'hash'
EOF
    save_output "hex.json"
    assert_output '{"hash":"c24463f5e352da20cb79a43f97436cce57344911e1d0ec0008cbedb5fabcca33"}'
}

@test "Compare hash" {
    cat <<EOF | zexe hash_compare.zen hex.json
rule input encoding hex
rule input untagged
rule output encoding hex
Given I have a 'hex' named 'hash'
When I set 'myhash' to 'c24463f5e352da20cb79a43f97436cce57344911e1d0ec0008cbedb5fabcca33' as 'hex'
and I verify 'myhash' is equal to 'hash'
Then print the 'hash'
EOF
    save_output 'hash_compare.json'
    assert_output '{"hash":"c24463f5e352da20cb79a43f97436cce57344911e1d0ec0008cbedb5fabcca33"}'

}


@test "When I create the hash of '' using 'sha256'" {
    cat <<EOF | zexe hash_string256.zen
rule output encoding hex
Given nothing
When I write string 'a string to be hashed' in 'source'
and I create the hash of 'source' using 'sha256'
Then print the 'hash'
EOF
    save_output 'hash_string256.json'
    assert_output '{"hash":"c24463f5e352da20cb79a43f97436cce57344911e1d0ec0008cbedb5fabcca33"}'


}

@test "When I create the hash of '' using 'sha512'" {
    cat <<EOF | zexe hash_string512.zen
rule output encoding hex
Given nothing
When I write string 'a string to be hashed' in 'source'
and I create the hash of 'source' using 'sha512'
Then print the 'hash'
EOF
    save_output 'hash_string512.json'
    assert_output '{"hash":"bbe0ff105448bd2238f5b97856980dfe0f0c64507e95d669decd4b2dbd01862870d3208df58957f0a4e43e8acd3fea5d69bebfe662575c46bf70088e7b6a282c"}'
}

@test "Hash using default" {
    cat << EOF | zexe hash_default.zen
rule output encoding hex
Given nothing
When I create the random 'source'
and I create the hash of 'source'
Then print 'hash'
EOF
    save_output 'hash_default.json'
    assert_output '{"hash":"78d41911d3f217ec19045930c452734e0fa5e29388f0bc6789ac46f5be907c09"}'
}
@test "KDF default" {
    cat << EOF | zexe kdf_default.zen
rule output encoding hex
Given nothing
When I create the random 'source'
and I create the key derivation of 'source'
Then print 'key derivation'
EOF
    save_output 'kdf_default.json'
    assert_output '{"key_derivation":"e6f824c3ef20df31d9e02273e466de7229ae59e39b9fea23260a35a51ea412f8"}'
}

@test "KDF array" {
    cat <<EOF | save_asset kdf_array.data
{
	"source": [ "hello",
		    "world",
		    "I'm Alice"
	]
}
EOF

    cat << EOF | zexe kdf_array.zen kdf_array.data
rule output encoding hex
Given I have a 'string array' named 'source'
When I create the key derivations of each object in 'source'
Then print 'key derivations'
EOF
    save_output 'kdf_array.json'
    assert_output '{"key_derivations":["1f5439c835c0bde300a623af79b0890eff160180fb7cbc8aa45fbcc2a4226a36","e0079d6702325e9b57139b160e1de9875939a0676a432089c4352659f4153f9c","4dc08370dee6a30dc50c67f127b0c1a190acd47bffdb963dc48c728439ed302c"]}'
}

@test "PBKDF default" {
    cat << EOF | zexe pbkdf_default.zen
rule output encoding hex
Given nothing
When I create the random 'source'
and I write string 'my pbkdf password' in 'secret'
and I create the key derivation of 'source' with password 'secret'
Then print 'key derivation'
EOF
    save_output 'pbkdf_default.json'
    assert_output '{"key_derivation":"031ec0ce48a7d42be217d2aac3eb923233516bade07a2899e43e276e80dc85b4"}'
}

@test "KDF rounds" {
    cat << EOF | zexe kdf_rounds.zen
rule output encoding hex
Given nothing
When I create the random 'source'
and I create the key derivation of 'source' with '1' rounds
Then print 'key derivation'
EOF
    save_output 'kdf_rounds.json'
    assert_output '{"key_derivation":"2a40e5fda8032b22b512da04769c79c249f96e04202f433474c3738f73ac56a5"}'

}

@test "PBKDF rounds" {
    cat << EOF | zexe pbkdf_rounds.zen
rule output encoding hex
Given nothing
When I create the random 'source'
and I write string 'my pbkdf password' in 'secret'
and I create the key derivation of 'source' with '5000' rounds with password 'secret'
Then print 'key derivation'
EOF
    save_output 'pbkdf_rounds.json'
    assert_output '{"key_derivation":"031ec0ce48a7d42be217d2aac3eb923233516bade07a2899e43e276e80dc85b4"}'
}

@test "HMAC default" {
    cat << EOF | zexe hmac_default.zen
rule output encoding hex
Given nothing
When I create the random 'source'
and I write string 'my HMAC key' in 'secret'
and I create the HMAC of 'source' with key 'secret'
Then print 'HMAC'
EOF
    save_output 'hmac_default.json'
    assert_output '{"HMAC":"935e1ffd4fdac7a9d36ad8cbbf0cea1ca3dc219496fa7b8fa8ba6a9feeb6d137"}'

}


@test "Hash SHA512" {
    cat << EOF | zexe hash_sha512.zen
rule output encoding hex
rule set hash sha512
Given nothing
When I create the random 'source'
and I create the hash of 'source'
Then print 'hash'
EOF
    save_output 'hash_sha512.json'
    assert_output '{"hash":"fafe7ced778593ce8735d6d0d8d0c04a6333a832fe95901e0fb4e74644c4e4ebfe44dac8e9c3c5a3533bc66bca3d0b6cd0b154e0f2ef305b316a822f9e36667d"}'
}


@test "Operations on random numbers" {
    cat <<EOF | zexe random_numbers.zen
# test hashing serialized tables
Given nothing
When I create the random array with '64' integers
and I create the hash of 'random_array'
and I rename the 'hash' to 'sha256'
and I create the hash of 'random array' using 'sha512'
and I rename the 'hash' to 'sha512'
and I set 'secret' to 'my password' as 'string'
and I create the key derivation of 'random array' with password 'secret'
and I create the HMAC of 'random array' with key 'secret'
Then print 'sha256'
Then print 'sha512'
Then print 'key derivation'
Then print 'HMAC'
EOF
    save_output 'array_random_nums.json'
    assert_output '{"HMAC":"dFGFO3vRONcS9DPewsSHoWdsx99vBatnzUVMVJ2W0sg=","key_derivation":"9geWtsqQwnvm/ukbHwMQ6rlKttjWvjAJJUNKdyihe5Y=","sha256":"c75TjcFMRKsBC8ZQHpQ5+Hp0PhZv2cl8LCGf6jEen2Q=","sha512":"0KKLgW/ZJDN4T7QZRfuFCKQMcWRoLUmkKkBIArvri27MXvVfWMb/oWuGyFYeqAAsvgy8y4eR1JKvoRsHhpq60g=="}'


}

@test "Hash to point ECP" {
    cat << EOF | zexe hash_to_point.zen
Given nothing
When I set 'string' to 'hello world!' as 'string'
and I create the hash to point 'ECP' of 'string'
and I rename 'hash to point' to 'hash to point ecp'
and I create the hash to point 'ECP2' of 'string'
and I rename 'hash to point' to 'hash to point ecp2'
Then print 'hash to point ecp'
Then print 'hash to point ecp2'
EOF
    save_output 'hash_to_point.json'
    assert_output '{"hash_to_point_ecp":"Awd+icZ7dJ55g2iQFzcwtdM/gLTU7HQ663RoAxj8d82YTtLuHIQAbPMDxMfP7/RFAg==","hash_to_point_ecp2":"AhTWpLtcBe+YX4hIBogbdhkQwj36Y+uhaqF0+BR3NeLs1bez+LIRclu9kxgAfeiVCLK3u/eYavyFEtQ2zyf8Mc+tbwRy18oGghnano/eGpkEbPqapfH3otxVeUcLdCb9AduV4iMLeGKydqkBilCrTWghg5JRDJxScA6uE1010azDNY9YnBJWi+Saxlxo7aIXDNv4skA1+VgT9GBzMb1EsfPhOsksJh+alnIF7ERyhF/blHf67toTzfjZlkhTJkeK"}'
}
