load ../bats_setup
load ../bats_zencode
SUBDOC=kyber

@test "When I create the kyber key" {
    cat <<EOF | save_asset Kyber_readsecretkeys.keys
{
"private_key":"6C892B0297A9C7641493F87DAF3533EED61F07F4652066337ED74046DCC71BA03F30960103161F7DEB53A71B11617263FE2A809769CE6D70A85FE600ECE29D7F36A16D331B8B2A9E1DB8C090742DF0739FF060CEB4ECC5AB1C5E55AC97BB66A7F895105D57782B229538E3421544A3421408DBF44910934CC423774F1676FF1C306F97555F57B4AED7A6BAB950A8163C8D318DEA62751BD6ABC5069C06C88F330026A19806A03B97A7696B56DA21827BB4E8DC031152B41B892A9E99ADF6E1963E96578828154F467033846920FBB4B80544E7E8A81AE963CF368C9BA037A8C2AD62E32B6E61C91D75CE005AB30F8099A1F29D7B6305B4DC06E25680BB00992F717FE6C115A8084231CC79DD700EA6912AC7FA0D937BB6A756662230470C189B5AA1653DEB937D5A9C25A21D93B19074FC239D8153539797C7D4AB62649D76AA553736A949022C22C52BAEEC605B32CE9E5B9384903558CA9D6A3ABA90423EEDA01C94198B192A8BA9063497A0C5013307DDD863526471A4D99523EB417F291AAC0C3A581B6DA00732E5E81B1F7C879B1693C13B6F9F7931622429E542AF4069222F045544E0CC4FB24D4448CF2C6596F5CB08624B1185013B6B020892F96BDFD4ADA9179DE727B8D9426E0996B5D34948CE02D0C369B37CBB54D3479ED8B582E9E728929B4C71C9BE11D45B20C4BDC3C74313223F58274E8BA5244447C495950B84CB0C3C273640108A3397944573279328996CDC0C913C958AD620BA8B5E5ECBBB7E13CB9C70BD5AB30EB7488C97001C20498F1D7CC06DA76BF520C658CCADFA2956424557ABEA8AB89239C17833DC3A49B36A9AE9A486940540EB444F97152357E02035939D75A3C025F41A40082382A0733C39B0622B740E407592C62ECAEB1432C445B3703A86F6981A278157EA95A6E92D55E4B972F936C2F0A658280EA2B07A48992DF8937E0A2AC1DCC974FE00AAE1F561FA258E2D259C3E861DCE236039127606FC1CE009003A7BAC942101DCB822B1F3C12BF73238F546E01C36B5A6936192995CC69C63237409CB53C2E35D74890D18885376FA5503B107A2A392115ACE0E64677CBB7DCFC93C16D3A305F67615A488D711AA56698C5663AB7AC9CE66D547C0595F98A43F4650BBE08C364D976789117D34F6AE51AC063CB55C6CA32558227DFEF807D19C30DE414424097F6AA236A1053B4A07A76BE372A5C6B6002791EBE0AFDAF54E1CA237FF545BA68343E745C04AD1639DBC590346B6B9569B56DBBFE53151913066E5C85527DC9468110A136A411497C227DCB8C9B25570B7A0E42AADA6709F23208F5D496EBAB7843F6483BF0C0C73A40296EC2C6440001394C99CA173D5C775B7F415D02A5A26A07407918587C41169F2B7178755ACC27FC8B19C4C4B3FCD41053F2C74C8A10A8321241B2802432875AE808B9EF1365C7B8A52902F1317BA2FB0269F47930672107B4726FEF64547394D3320C8F120B3C2F4725B0305FAB88CC7981FCB09A76A1CBF7F179F43BB0A4C8B0590857F1E69708466C7F8607391E7BC5268BFD3D7A1DFFCB4ECA2A1C9B597593013D5FC4202EC2B74E57AB76BBCF3632BBAF97CDC418A6F16392838CA9BF45DDF023777B7561833C105190F94F302C59B531900BBC816361FAA5B3380CA3A893104CA7388B185671B3E5FE3790E9A626EC46D9B0B33C7A419AF7B32B6859894F575D82AC5456B5490A7AF8FE61046360589ECBA7244236F4123116B6174AA179249A49195B356C72FC6641F0251812EAA98570B046699070E0819DC2713F469137DFC6A3D7B92B298995EE780369153AC366B06D7249CD09E1B3378FB04399CECB8650581D637C79AE67D6F2CAF6ABACF598159A7792CB3C971D1499D2373AD20F63F03BB59ED137384AC61A7155143B8CA4932612EC915E4CA346A9BCE5DD60417C6B2A89B1CC435643F875BDC5A7E5B3481CF919EA09172FEBC46D4FC3FB0CB9591704EE2DBB61844B2F3314A06BB6C6D34005E485CE667BDC7D098586928D2D91340F00419EA401351A240A0B041058BEFB0C2FD32645B7A2DF8F5CBFD873327C978D7B351A28088438837024C52B9C295CD713646FB5D6C0CCFB470734AC2B2BC8123C2C13DF6938E92455A862639FEB8A64B85163E32707E037B38D8AC3922B45187BB65EAFD465FC64A0C5F8F3F9003489415899D59A543D8208C54A3166529B539227FFAD1BC8AF73B7E874956B81C2A2EF0BFABE8DC93D77B2FBC9E0C64EFA01E848626ED79D451140800E03B59B956F8210E556067407D13DC90FA9E8B872BFB8F"
}
EOF

    cat <<EOF | zexe Kyber_createprivatekey.zen
Rule check version 2.0.0
Scenario qp : Create the kyber private key
Given I am 'Alice'
When I create the kyber key
Then print the 'keyring'
EOF
    save_output 'Alice_Kyber_privatekey.keys'
}

@test "Read keys" {
    cat <<EOF | zexe Kyber_readkeys.zen Alice_Kyber_privatekey.keys
Rule check version 2.0.0
Scenario qp : Upload the kyber private key
Given I am 'Alice'
and I have the 'keyring'
Then print my data
Then print my 'keyring'
EOF
    save_output 'Kyber_readkeys.out'
}


@test "Create public key" {
    cat <<EOF | zexe Kyber_createpublickey.zen Alice_Kyber_privatekey.keys
Rule check version 2.0.0
Scenario qp : Create the kyber public key
Given I am 'Alice'
and I have the 'keyring'
When I create the kyber public key
Then print my 'kyber public key'
EOF
    save_output 'Alice_Kyber_pubkey.json'
}


@test "Create and publish the kyber public key" {
    cat <<EOF | zexe Kyber_createpublickey2.zen Kyber_readsecretkeys.keys
Rule check version 2.0.0
Scenario qp : Create and publish the kyber public key
Given I am 'Alice'
#and I have a 'kyber private key'
and I have a 'hex' named 'private key'
When I create the kyber public key with secret key 'private key'
Then print my 'kyber public key'
EOF
    save_output 'Kyber_createpublickey2.out'
    assert_output '{"Alice":{"kyber_public_key":"EVrODmRnfLt9z8k8FtOjBfZ2FaSI1xGqVmmMVmOresnOZtVHwFlfmKQ/RlC74Iw2TZdniRF9NPauUawGPLVcbKMlWCJ9/vgH0Zww3kFEJAl/aqI2oQU7Sgena+Nypca2ACeR6+Cv2vVOHKI3/1RbpoND50XAStFjnbxZA0a2uVabVtu/5TFRkTBm5chVJ9yUaBEKE2pBFJfCJ9y4ybJVcLeg5CqtpnCfIyCPXUluureEP2SDvwwMc6QCluwsZEAAE5TJnKFz1cd1t/QV0CpaJqB0B5GFh8QRafK3F4dVrMJ/yLGcTEs/zUEFPyx0yKEKgyEkGygCQyh1roCLnvE2XHuKUpAvExe6L7Amn0eTBnIQe0cm/vZFRzlNMyDI8SCzwvRyWwMF+riMx5gfywmnahy/fxefQ7sKTIsFkIV/HmlwhGbH+GBzkee8Umi/09eh3/y07KKhybWXWTAT1fxCAuwrdOV6t2u882Mruvl83EGKbxY5KDjKm/Rd3wI3d7dWGDPBBRkPlPMCxZtTGQC7yBY2H6pbM4DKOokxBMpziLGFZxs+X+N5DppibsRtmwszx6QZr3sytoWYlPV12CrFRWtUkKevj+YQRjYFiey6ckQjb0EjEWthdKoXkkmkkZWzVscvxmQfAlGBLqqYVwsEZpkHDggZ3CcT9GkTffxqPXuSspiZXueANpFTrDZrBtcknNCeGzN4+wQ5nOy4ZQWB1jfHmuZ9byyvarrPWYFZp3kss8lx0UmdI3OtIPY/A7tZ7RNzhKxhpxVRQ7jKSTJhLskV5Mo0apvOXdYEF8ayqJscxDVkP4db3Fp+WzSBz5GeoJFy/rxG1Pw/sMuVkXBO4tu2GESy8zFKBrtsbTQAXkhc5me9x9CYWGko0tkTQPAEGepAE1GiQKCwQQWL77DC/TJkW3ot+PXL/YczJ8l417NRooCIQ4g3AkxSucKVzXE2RvtdbAzPtHBzSsKyvIEjwsE99pOOkkVahiY5/rimS4UWPjJwfgN7ONisOSK0UYe7Zer9Rl/GSgxfjz+QA0iUFYmdWaVD2CCMVKMWZSm1OSI="}}'


}


@test "Kyber KEM" {
    cat <<EOF | zexe Kyber_enc.zen Alice_Kyber_pubkey.json
Rule check version 2.0.0
Scenario qp : Bob create the kyber secret for Alice

# Here I declare my identity
Given I am 'Bob'
# Here I load the receiver public key
# that will be needed to create the ciphertext
and I have a 'kyber public key' from 'Alice'

# Here we create the KEM (key encapsulation mechanism)
# The kem contains the 'kyber_cyphertext' that will be sent to other party
# and the 'kyber_secret' which is random number of a defined length
# the 'kyber_secret' needs to be stored separately
When I create the kyber kem for 'Alice'


Then print the 'kyber ciphertext' from 'kyber kem'
Then print the 'kyber secret' from 'kyber kem'
EOF
    save_output 'Kyber_Kem.json'

    jq 'del(.kyber_secret)' $BATS_SUITE_TMPDIR/Kyber_Kem.json | save_asset Kyber_ciphertext.json
}

@test "When I create the kyber secret from ''" {
    cat <<EOF | zexe Kyber_dec.zen Alice_Kyber_privatekey.keys Kyber_ciphertext.json
Rule check version 2.0.0
Scenario qp : Alice create the kyber secret

# Here I declare my identity
Given that I am known as 'Alice'
# Here I load my keyring and the ciphertext
and I have the 'keyring'
and I have a 'kyber ciphertext'

# Here I recreate the secret starting from the ciphertext
When I create the kyber secret from 'kyber ciphertext'

Then print the 'kyber secret'
EOF
    save_output 'Kyber_secret.json'
}

#--- Creating together Kyber and ECDH private and public keys ---#
@test "generating the private keys for ECDH and Kyber" {
        cat << EOF |zexe Carl_ECDH_Kyber_secretkeys.zen
Rule check version 2.0.0
Scenario ecdh : Create the private key
Scenario qp : Create the private key
Given I am known as 'Carl'
When I create the ecdh key
and I create the kyber key
Then print my 'keyring'
EOF
    save_output 'Carl_secretkeys.keys'
}

@test "generating the public keys for ECDH and Kyber" {
    cat << EOF | zexe Carl_ECDH_Kyber_pubkeys.zen Carl_secretkeys.keys
Rule check version 2.0.0
Scenario ecdh : Create the public key
Scenario qp : Create the public key
Given I am known as 'Carl'
and I have my 'keyring'
When I create the ecdh public key
and I create the kyber public key
Then print my 'kyber public key'
and print my 'ecdh public key'
EOF
    save_output 'Carl_pubkeys.json'
}

#--- Encrypting and decrypting together Kyber and ECDH secret messages ---#
@test "encrypting a message with ECDH while creating a secret and its ciphertext with Kyber" {
    cat <<EOF | zexe Carl_Kyber_ECDH_enc.zen Carl_pubkeys.json
Rule check version 2.0.0
Scenario ecdh : Bob encrypts a secret message for Carl
Scenario qp : Bob creates a secret and its ciphertext for Carl
Given I am 'Bob'
and I have a 'kyber public key' from 'Carl'
and I have a 'ecdh public key' from 'Carl'
When I create the kyber kem for 'Carl'
and I create the ecdh key
and I write string 'This is my secret message.' in 'message'
and I write string 'This is the header' in 'header'
and I encrypt the secret message of 'message' for 'Carl'
and I rename the 'ecdh public key' to 'Carl ecdh public key'
and I create the ecdh public key
Then print the 'secret message'
and print the 'message'
and print my 'ecdh public key'
and print the 'kyber ciphertext' from 'kyber kem'
and print the 'kyber secret' from 'kyber kem'
EOF
    save_output 'Ciphertexts.json'

}


@test "" {
    cat <<EOF | zexe Carl_dec.zen Carl_secretkeys.keys Ciphertexts.json
Rule check version 2.0.0
Scenario ecdh : Carl decrypts the secret message from Bob using ECDH
Scenario qp : Carl creates the kyber secret
Given that I am known as 'Carl'
and I have my 'keyring'
and I have a 'ecdh public key' from 'Bob'
and I have a 'secret message'
and I have a 'string' named 'message'
and I have a 'kyber ciphertext'
and I have a 'kyber secret'
When I rename the 'kyber secret' to 'Bob kyber secret'
and I rename the 'message' to 'Dave message'
and I decrypt the text of 'secret message' from 'Bob'
and I create the kyber secret from 'kyber ciphertext'
If I verify 'Bob kyber secret' is equal to 'kyber secret'
If I verify 'Dave message' is equal to 'text'
Then print string 'Success!!!'
Endif
EOF
    save_output 'Carl_dec.out'
    assert_output '{"output":["Success!!!"]}'

}
