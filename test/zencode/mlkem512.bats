load ../bats_setup
load ../bats_zencode
SUBDOC=mlkem512

@test "When I create the mlkem512 key" {
    cat <<EOF | save_asset mlkem512_readsecretkeys.keys
{
"private_key":"7FE4206F26BEDB64C1ED0009615245DC98483F663ACC617E65898D596A8836C49FBD3B4A849759AA1546BDA835CAF175642C28280892A7878CC318BCC75B834CB29FDF5360D7F982A52C88AE914DBF02B58BEB8BA887AE8FAB5EB78731C6757805471EBCEC2E38DB1F4B8310D288920D8A492795A390A74BCD55CD8557B4DAABA82C28CB3F152C5231196193A66A8CCF34B80E1F6942C32BCFF96A6E3CF3939B7B942498CC5E4CB8E8468E702759852AA229C0257F02982097338607C0F0F45446FAB4267993B8A5908CAB9C46780134804AE18815B1020527A222EC4B39A3194E661737791714122662D8B9769F6C67DE625C0D483C3D420FF1BB889A727E756281513A70047648D29C0C30F9BE52EC0DEB977CF0F34FC2078483456964743410638C57B5539577BF85669078C356B3462E9FA5807D49591AFA41C1969F65E3405CB64DDF163F26734CE348B9CF4567A33A5969EB326CFB5ADC695DCA0C8B2A7B1F4F404CC7A0981E2CC24C1C23D16AA9B4392415E26C22F4A934D794C1FB4E5A67051123CCD153764DEC99D553529053C3DA550BCEA3AC54136A26A676D2BA8421067068C6381C2A62A727C933702EE5804A31CA865A45588FB74DE7E2223D88C0608A16BFEC4FAD6752DB56B48B8872BF26BA2FFA0CEDE5343BE8143689265E065F41A6925B86C892E62EB0772734F5A357C75CA1AC6DF78AB1B8885AD0819615376D33EBB98F8733A6755803D977BF51C12740424B2B49C28382A6917CBFA034C3F126A38C216C03C35770AD481B9084B5588DA65FF118A74F932C7E537ABE5863FB29A10C09701B441F8399C1F8A637825ACEA3E93180574FDEB88076661AB46951716A500184A040557266598CAF76105E1C1870B43969C3BCC1A04927638017498BB62CAFD3A6B082B7BF7A23450E191799619B925112D072025CA888548C791AA42251504D5D1C1CDDB213303B049E7346E8D83AD587836F35284E109727E66BBCC9521FE0B191630047D158F75640FFEB5456072740021AFD15A45469C583829DAAC8A7DEB05B24F0567E4317B3E3B33389B5C5F8B04B099FB4D103A32439F85A3C21D21A71B9B92A9B64EA0AB84312C77023694FD64EAAB907A43539DDB27BA0A853CC9069EAC8508C653E600B2AC018381B4BB4A879ACDAD342F91179CA8249525CB1968BBE52F755B7F5B43D6663D7A3BF0F3357D8A21D15B52DB3818ECE5B402A60C993E7CF436487B8D2AE91E6C5B88275E75824B0007EF3123C0AB51B5CC61B9B22380DE66C5B20B060CBB986F8123D94060049CDF8036873A7BE109444A0A1CD87A48CAE54192484AF844429C1C58C29AC624CD504F1C44F1E1347822B6F221323859A7F6F754BFE710BDA60276240A4FF2A5350703786F5671F449F20C2A95AE7C2903A42CB3B303FF4C427C08B11B4CD31C418C6D18D0861873BFA0332F11271552ED7C035F0E4BC428C43720B39A65166BA9C2D3D770E130360CC2384E83095B1A159495533F116C7B558B650DB04D5A26EAAA08C3EE57DE45A7F88C6A3CEB24DC5397B88C3CEF003319BB0233FD692FDA1524475B351F3C782182DECF590B7723BE400BE14809C44329963FC46959211D6A623339537848C251669941D90B130258ADF55A720A724E8B6A6CAE3C2264B1624CCBE7B456B30C8C7393294CA5180BC837DD2E45DBD59B6E17B24FE93052EB7C43B27AC3DC249CA0CBCA4FB5897C0B744088A8A0779D32233826A01DD6489952A4825E5358A700BE0E179AC197710D83ECC853E52695E9BF87BB1F6CBD05B02D4E679E3B88DD483B0749B11BD37B383DCCA71F9091834A1695502C4B95FC9118C1CFC34C84C2265BBBC563C282666B60AE5C7F3851D25ECBB5021CC38CB73EB6A3411B1C29046CA66540667D136954460C6FCBC4BC7C049BB047FA67A63B3CC1111C1D8AC27E8058BCCA4A15455858A58358F7A61020BC9C4C17F8B95C268CCB404B9AAB4A272A21A70DAF6B6F15121EE01C156A354AA17087E07702EAB38B3241FDB553F657339D5E29DC5D91B7A5A828EE959FEBB90B07229F6E49D23C3A190297042FB43986955B69C28E1016F77A58B431514D21B888899C3608276081B75F568097CDC1748F32307885815F3AEC9651819AA6873D1A4EB83B1953843B93422519483FEF0059D36BB2DB1F3D468FB068C86E8973733C398EAF00E1702C6734AD8EB3B620130D6C2B8C904A3BB9307BE5103F8D814505FB6A60AF7937EA6CAA117315E84CC9121AE56FBF39E67ADBD83AD2D3E3BB80843645206BDD9F2F629E3CC49B7"
}
EOF

    cat <<EOF | zexe mlkem512_createprivatekey.zen
Rule check version 4.37.0
Scenario qp : Create the mlkem512 private key
Given I am 'Alice'
When I create the mlkem512 key
Then print the 'keyring'
EOF
    save_output 'Alice_mlkem512_privatekey.keys'
}

@test "Read keys" {
    cat <<EOF | zexe mlkem512_readkeys.zen Alice_mlkem512_privatekey.keys
Rule check version 4.37.0
Scenario qp : Upload the mlkem512 private key
Given I am 'Alice'
and I have the 'keyring'
Then print my data
Then print my 'keyring'
EOF
    save_output 'mlkem512_readkeys.out'
}


@test "Create public key" {
    cat <<EOF | zexe mlkem512_createpublickey.zen Alice_mlkem512_privatekey.keys
Rule check version 4.37.0
Scenario qp : Create the mlkem512 public key
Given I am 'Alice'
and I have the 'keyring'
When I create the mlkem512 public key
Then print my 'mlkem512 public key'
EOF
    save_output 'Alice_mlkem512_pubkey.json'
}


@test "Create and publish the mlkem512 public key" {
    cat <<EOF | zexe mlkem512_createpublickey2.zen mlkem512_readsecretkeys.keys
Rule check version 4.37.0
Scenario qp : Create and publish the mlkem512 public key
Given I am 'Alice'
#and I have a 'mlkem512 private key'
and I have a 'hex' named 'private key'
When I create the mlkem512 public key with secret key 'private key'
Then print my 'mlkem512 public key'
EOF
    save_output 'mlkem512_createpublickey2.out'
    assert_output '{"Alice":{"mlkem512_public_key":"oyQ5+Fo8IdIacbm5Kptk6gq4QxLHcCNpT9ZOqrkHpDU53bJ7oKhTzJBp6shQjGU+YAsqwBg4G0u0qHms2tNC+RF5yoJJUlyxlou+UvdVt/W0PWZj16O/DzNX2KIdFbUts4GOzltAKmDJk+fPQ2SHuNKukebFuIJ151gksAB+8xI8CrUbXMYbmyI4DeZsWyCwYMu5hvgSPZQGAEnN+ANoc6e+EJREoKHNh6SMrlQZJISvhEQpwcWMKaxiTNUE8cRPHhNHgitvIhMjhZp/b3VL/nEL2mAnYkCk/ypTUHA3hvVnH0SfIMKpWufCkDpCyzswP/TEJ8CLEbTNMcQYxtGNCGGHO/oDMvEScVUu18A18OS8QoxDcgs5plFmupwtPXcOEwNgzCOE6DCVsaFZSVUz8RbHtVi2UNsE1aJuqqCMPuV95Fp/iMajzrJNxTl7iMPO8AMxm7AjP9aS/aFSRHWzUfPHghgt7PWQt3I75AC+FICcRDKZY/xGlZIR1qYjM5U3hIwlFmmUHZCxMCWK31WnIKck6LamyuPCJksWJMy+e0VrMMjHOTKUylGAvIN90uRdvVm24Xsk/pMFLrfEOyesPcJJygy8pPtYl8C3RAiKigd50yIzgmoB3WSJlSpIJeU1inAL4OF5rBl3ENg+zIU+Umlem/h7sfbL0FsC1OZ547iN1IOwdJsRvTezg9zKcfkJGDShaVUCxLlfyRGMHPw0yEwiZbu8VjwoJma2CuXH84UdJey7UCHMOMtz62o0EbHCkEbKZlQGZ9E2lURgxvy8S8fASbsEf6Z6Y7PMERHB2Kwn6AWLzKShVFWFilg1j3phAgvJxMF/i5XCaMy0BLmqtKJyohpw2va28VEh7gHBVqNUqhcIfgdwLqs4syQf21U/ZXM51eKdxdkbelqCjulZ/ruQsHIp9uSdI8OhkClwQvtDmGlVtpwo4QFvd6WLQxUU0huIiJnDYIJ2CBt19WgJfNwXSPMjB4hYFfOuyWUYGapoc9Gk64OxlThDuTQiUZSD/vAFnTa7LbHz1Gj7BoyG6Jc3M8OY6vAOFwLGc0rY6zs="}}'


}


@test "mlkem512 KEM" {
    cat <<EOF | zexe mlkem512_enc.zen Alice_mlkem512_pubkey.json
Rule check version 4.37.0
Scenario qp : Bob create the mlkem512 secret for Alice

# Here I declare my identity
Given I am 'Bob'
# Here I load the receiver public key
# that will be needed to create the ciphertext
and I have a 'mlkem512 public key' from 'Alice'

# Here we create the KEM (key encapsulation mechanism)
# The kem contains the 'mlkem512_cyphertext' that will be sent to other party
# and the 'mlkem512_secret' which is random number of a defined length
# the 'mlkem512_secret' needs to be stored separately
When I create the mlkem512 kem for 'Alice'


Then print the 'mlkem512 ciphertext' from 'mlkem512 kem'
Then print the 'mlkem512 secret' from 'mlkem512 kem'
EOF
    save_output 'mlkem512_Kem.json'

    jq 'del(.mlkem512_secret)' $BATS_FILE_TMPDIR/mlkem512_Kem.json | save_asset mlkem512_ciphertext.json
}

@test "When I create the mlkem512 secret from ''" {
    cat <<EOF | zexe mlkem512_dec.zen Alice_mlkem512_privatekey.keys mlkem512_ciphertext.json
Rule check version 4.37.0
Scenario qp : Alice create the mlkem512 secret

# Here I declare my identity
Given that I am known as 'Alice'
# Here I load my keyring and the ciphertext
and I have the 'keyring'
and I have a 'mlkem512 ciphertext'

# Here I recreate the secret starting from the ciphertext
When I create the mlkem512 secret from 'mlkem512 ciphertext'

Then print the 'mlkem512 secret'
EOF
    save_output 'mlkem512_secret.json'
}

#--- Creating together mlkem512 and ECDH private and public keys ---#
@test "generating the private keys for ECDH and mlkem512" {
        cat << EOF |zexe Carl_ECDH_mlkem512_secretkeys.zen
Rule check version 4.37.0
Scenario ecdh : Create the private key
Scenario qp : Create the private key
Given I am known as 'Carl'
When I create the ecdh key
and I create the mlkem512 key
Then print my 'keyring'
EOF
    save_output 'Carl_secretkeys_ECDH_mlkem512.keys'
}

@test "generating the public keys for ECDH and mlkem512" {
    cat << EOF | zexe Carl_ECDH_mlkem512_pubkeys.zen Carl_secretkeys_ECDH_mlkem512.keys
Rule check version 4.37.0
Scenario ecdh : Create the public key
Scenario qp : Create the public key
Given I am known as 'Carl'
and I have my 'keyring'
When I create the ecdh public key
and I create the mlkem512 public key
Then print my 'mlkem512 public key'
and print my 'ecdh public key'
EOF
    save_output 'Carl_pubkeys_ECDH_mlkem512.json'
}

#--- Encrypting and decrypting together mlkem512 and ECDH secret messages ---#
@test "encrypting a message with ECDH while creating a secret and its ciphertext with mlkem512" {
    cat <<EOF | zexe Carl_ECDH_mlkem512_enc.zen Carl_pubkeys_ECDH_mlkem512.json
Rule check version 4.37.0
Scenario ecdh : Bob encrypts a secret message for Carl
Scenario qp : Bob creates a secret and its ciphertext for Carl
Given I am 'Bob'
and I have a 'mlkem512 public key' from 'Carl'
and I have a 'ecdh public key' from 'Carl'
When I create the mlkem512 kem for 'Carl'
and I create the ecdh key
and I write string 'This is my secret message.' in 'message'
and I write string 'This is the header' in 'header'
and I encrypt the secret message of 'message' for 'Carl'
and I rename the 'ecdh public key' to 'Carl ecdh public key'
and I create the ecdh public key
Then print the 'secret message'
and print the 'message'
and print my 'ecdh public key'
and print the 'mlkem512 ciphertext' from 'mlkem512 kem'
and print the 'mlkem512 secret' from 'mlkem512 kem'
EOF
    save_output 'Ciphertexts_ECDH_mlkem512.json'

}


@test "" {
    cat <<EOF | zexe Carl_ECDH_mlkem512_dec.zen Carl_secretkeys_ECDH_mlkem512.keys Ciphertexts_ECDH_mlkem512.json
Rule check version 4.37.0
Scenario ecdh : Carl decrypts the secret message from Bob using ECDH
Scenario qp : Carl creates the mlkem512 secret
Given that I am known as 'Carl'
and I have my 'keyring'
and I have a 'ecdh public key' from 'Bob'
and I have a 'secret message'
and I have a 'string' named 'message'
and I have a 'mlkem512 ciphertext'
and I have a 'mlkem512 secret'
When I rename the 'mlkem512 secret' to 'Bob mlkem512 secret'
and I rename the 'message' to 'Dave message'
and I decrypt the text of 'secret message' from 'Bob'
and I create the mlkem512 secret from 'mlkem512 ciphertext'
If I verify 'Bob mlkem512 secret' is equal to 'mlkem512 secret'
If I verify 'Dave message' is equal to 'text'
Then print string 'Success!!!'
Endif
Endif
EOF
    save_output 'Carl_ECDH_mlkem512_dec.out'
    assert_output '{"output":["Success!!!"]}'

}
