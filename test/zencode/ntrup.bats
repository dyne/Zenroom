load ../bats_setup
load ../bats_zencode
SUBDOC=ntrup

@test "When I create the kyber key" {
    cat <<EOF | save_asset ntrup_readsecretkeys.keys
{
"private_key":"84a4461456555106599568544545599566250455564095454949545551a446594569964625259559215a1655551096550955059151145656416058055255549516595652a144556911559645556152465055a55184664515458515565965194106194556442158595592556511155655a891169286444a654145509425551559a565955564596554444148599565859550585551965281959616519445955595a54415505654551555544465551596549658526986568654555699556455025025018502424492a596660545192a924a460a195901295960458212a45429646245048a6986a9028a00912010a60465922a09968848a8485548819002562aa1a2481415aa92296918994260059284a48a5a5a50816625198a04a900119a005696a65040821a5690006420464a421025a228994606a6952a99889204aaa048054049a5aaa665481214164902a9845892951528128160a6120561a2466a868852595a6818694148090418458646a6aa569116119228892655250459924a11003c3241bf1a4c1952f2408f9cc4f726fbf292a7c2b94e2d07decbeae4d6d8853283e7c053ca85e7bf1eb75389ae2cad2d4b7efee5dadef768afebbe896f6bc40d478f15dd3ed5ab384c09ce809eb1bcb098e01bcd8b69393a304ef5cdabbe27aff9dced9b9e34d08da2bd055891e3e98a9b351e499e7614a0f42d24cc7c67c6dfd6388bb49af7678700091fbb4ba53488c87e62b808a365abeb421509244f81a5ad2d84fe9fe955fc707af514341c7559a5076aa146a5401ce9621fc84ecf8fe2fa11c25615d184a20823974f6cc6840e83b3742c30efc524519f7864e1653503e8a96816b44c172a606eb144f1d61aa39da70859dc29db5ade80904aa554d290a5f98154610290d1bcb0fe7c8464337a0faf5fb466bcbe9c598f134d5d310e3c2a2f56aaabb70931467dacbacac5d4eec976f0cc4cf252df5ca40cc1070e3a856ae5dd156b328503850a62d2cf7234c723768d43163696536e2a72c5996e41c18b8c5ba390c71a451b8801e355c13862d0bd570054cd804a0476046ea498b6b27bba3af2144ab359c7e31e5d3bc10c6e5de6ee807752cc7dfbf9eec540610cc7a7ddff4f27b7895adaa95fccfa00f5f01ee64122fae77fa89aa1dbf7f4d01934478a1dcb021d0d70a46fee2069402e44e4130d067c1c9c334fe6fb350cd4285d284ff3f8a4e6481297399b02ad5d3e2778dc01ead2ccaab4ad0841be251d1829102146f26c314d88f37e046896def635e13cc5b878c75ebef5b81dcfc0bcfced10ec35d3657f0dc6b8fa998bdc7412f9f1fb487e70d73d3bc05ee0abeccebedf7e4d843b1379e6f8c9079a69d789f58314ff2906a55c170d79bb6d8c77c0f835a2e263b4d25e5a37e07dd9f3148bd68c6ae6c0cf8e14148efa5943fced31595a391eecb2dac4dc73b70817de27e09ac5ad6a5e6192017d275fc647bee4d2a5b338d615459aa21cd07ed313280613aa27761945ee1eb5119e13f0bb88b8820e40c9e01660dbe76133e71ffcc2f2cb0292ffa90c2c8cd3f198f66914350cf4918269703a5cb5aa383822acfad2b98753f58e0e42afea70ce278a4979587e1417491d8e67086adf120d3b00db2576e46451465f2779c4b10dfb15ce2d42683b0ecc6a0e7d8f30719fe99a6eb13ad08ad9e87a085ac3ae8144714c9e91dbeeb8519e30f4c0d9f6ab2b08bf7b0ddad6f4f33ca7d178ec7f2a2c8acbe9e1d04fb704536d0818b80dee28bca2defbdb6c443b7654b3a29b5abd07a34e59dca5f574094abaa7362b12bab7753c2ae8711c317f552ed63a97fb0071c82b428b171ee7cde29682503d2214887548992825055e83d5c56bf393e559e7928b6aa5513568ce66a25f52de0bcc47dd19ed067f85f4547b966c2d9e527e108548c6a39c91d4f3c6aca00567ea7968b3f7236704cb54dca2995950bfd56a14e69bb945485ad0f55e3f3c05032aaa0f2fde15938979c8a71358b7fe38d7c7a98f2f2d0cf653cfdb516adcb49353db57c8ca42ca00d9e2e531716c4a5157b002776ffb3f416afe720341c3a51a64fd0cdd0d56c4319f9015cb6a0bd61799c834cbddda2693ac2ded11591a9adb3e08aef966476337e1eec35bcb1a4367d571ff965060e6d44f2ae5f12626b1511e036f576f057cbdb06db464681b5597f6d51529bbbde997479338e35ccee8955822fbcdf8db2e5e491eb7a8550f122c76ac7321d18edd94568103b548be1842b664871d1fff289c6127b089bbb50edfcb1245224d85f683d0c08a9c498c3c2fde9f058d650780512e0cbe662312712b67dbecd65ced91eb5ebb6472239e5036a683525f6c53c5a62faa5fef71084fc7c579bd24f02846e93e48808921d775e1f4bef231de99d5507902a5db985da823e4e3895cc34e39071b11b3eac113ad86acb300d71ddcb0a1eda8056f382c0d0f4937ae9d471bec6b990d7a2add8ba2923d"
}
EOF

    cat <<EOF | zexe ntrup_createprivatekey.zen
Rule check version 2.0.0
Scenario qp : Create the ntrup private key
Given I am 'Alice'
When I create the ntrup key
Then print the 'keyring'
EOF
    save_output 'Alice_ntrup_privatekey.keys'
}

@test "Read keys" {
    cat <<EOF | zexe ntrup_readkeys.zen Alice_ntrup_privatekey.keys
Rule check version 2.0.0
Scenario qp : Upload the ntrup private key
Given I am 'Alice'
and I have the 'keyring'
Then print my 'keyring'
EOF
    save_output 'ntrup_readkeys.out'
}


@test "Create public key" {
    cat <<EOF | zexe ntrup_createpublickey.zen Alice_ntrup_privatekey.keys
Rule check version 2.0.0
Scenario qp : Create the ntrup public key
Given I am 'Alice'
and I have the 'keyring'
When I create the ntrup public key
Then print my 'ntrup public key'
EOF
    save_output 'Alice_ntrup_pubkey.json'
}


@test "Create and publish the ntrup public key" {
    cat <<EOF | zexe ntrup_createpublickey2.zen ntrup_readsecretkeys.keys
Rule check version 2.0.0
Scenario qp : Create and publish the ntrup public key
Given I am 'Alice'
and I have a 'hex' named 'private key'
When I create the ntrup public key with secret key 'private key'
Then print my 'ntrup public key'
EOF
    save_output 'ntrup_createpublickey2.out'
    assert_output '{"Alice":{"ntrup_public_key":"PDJBvxpMGVLyQI+cxPcm+/KSp8K5Ti0H3svq5NbYhTKD58BTyoXnvx63U4muLK0tS37+5dre92iv676Jb2vEDUePFd0+1as4TAnOgJ6xvLCY4BvNi2k5OjBO9c2rviev+dztm5400I2ivQVYkePpips1HkmedhSg9C0kzHxnxt/WOIu0mvdnhwAJH7tLpTSIyH5iuAijZavrQhUJJE+Bpa0thP6f6VX8cHr1FDQcdVmlB2qhRqVAHOliH8hOz4/i+hHCVhXRhKIII5dPbMaEDoOzdCww78UkUZ94ZOFlNQPoqWgWtEwXKmBusUTx1hqjnacIWdwp21regJBKpVTSkKX5gVRhApDRvLD+fIRkM3oPr1+0Zry+nFmPE01dMQ48Ki9Wqqu3CTFGfay6ysXU7sl28MxM8lLfXKQMwQcOOoVq5d0VazKFA4UKYtLPcjTHI3aNQxY2llNuKnLFmW5BwYuMW6OQxxpFG4gB41XBOGLQvVcAVM2ASgR2BG6kmLaye7o68hRKs1nH4x5dO8EMbl3m7oB3Usx9+/nuxUBhDMen3f9PJ7eJWtqpX8z6APXwHuZBIvrnf6iaodv39NAZNEeKHcsCHQ1wpG/uIGlALkTkEw0GfBycM0/m+zUM1ChdKE/z+KTmSBKXOZsCrV0+J3jcAerSzKq0rQhBviUdGCkQIUbybDFNiPN+BGiW3vY14TzFuHjHXr71uB3PwLz87RDsNdNlfw3GuPqZi9x0Evnx+0h+cNc9O8Be4Kvszr7ffk2EOxN55vjJB5pp14n1gxT/KQalXBcNebttjHfA+DWi4mO00l5aN+B92fMUi9aMaubAz44UFI76WUP87TFZWjke7LLaxNxztwgX3ifgmsWtal5hkgF9J1/GR77k0qWzONYVRZqiHNB+0xMoBhOqJ3YZRe4etRGeE/C7iLiCDkDJ4BZg2+dhM+cf/MLyywKS/6kMLIzT8Zj2aRQ1DPSRgmlwOly1qjg4Iqz60rmHU/WODkKv6nDOJ4pJeVh+FBdJHY5nCGrfEg07ANslduRkUUZfJ3nEsQ37Fc4tQmg7DsxqDn2PMHGf6ZpusTrQitnoeghaw66BRHFMnpHb7rhRnjD0wNn2qysIv3sN2tb08zyn0Xjsfyosisvp4dBPtwRTbQgYuA3uKLyi3vvbbEQ7dlSzoptavQejTlncpfV0CUq6pzYrErq3dTwq6HEcMX9VLtY6l/sAccgrQosXHufN4paCUD0iFIh1SJkoJQVeg9XFa/OT5VnnkotqpVE1aM5mol9S3gvMR90Z7QZ/hfRUe5ZsLZ5SfhCFSMajnJHU88asoAVn6nlos/cjZwTLVNyimVlQv9VqFOabuUVIWtD1Xj88BQMqqg8v3hWTiXnIpxNYt/4418epjy8tDPZTz9tRaty0k1PbV8jKQsoA2eLlMXFsSlFXsAJ3b/s/QWr+cgNBw6UaZP0M3Q1WxDGfkBXLagvWF5nINMvd2iaTrC3tEVkamts+CK75ZkdjN+Huw1vLGkNn1XH/llBg5tRPKuXxJiaxUR4D"}}'


}


@test "ntrup KEM" {
    cat <<EOF | zexe ntrup_enc.zen Alice_ntrup_pubkey.json
Rule check version 2.0.0
Scenario qp : Bob create the ntrup secret for Alice
# Here I declare my identity
Given I am 'Bob'

# Here I load the receiver public key
# that will be needed to create the ciphertext
and I have a 'ntrup public key' from 'Alice'

# Here we create the KEM (key encapsulation mechanism)
# The kem contains the 'ntrup_cyphertext' that will be sent to other party
# and the 'ntrup_secret' which is random number of a defined length
# the 'ntrup_secret' needs to be stored separately
When I create the ntrup kem for 'Alice'

Then print the 'ntrup ciphertext' from 'ntrup kem'
Then print the 'ntrup secret' from 'ntrup kem'
EOF
    save_output 'ntrup_Kem.json'

    jq 'del(.ntrup_secret)' $BATS_SUITE_TMPDIR/ntrup_Kem.json | save_asset ntrup_ciphertext.json
}

@test "When I create the ntrup secret from ''" {
    cat <<EOF | zexe ntrup_dec.zen Alice_ntrup_privatekey.keys ntrup_ciphertext.json
Rule check version 2.0.0
Scenario qp : Alice create the ntrup secret

# Here I declare my identity
Given that I am known as 'Alice'
# Here I load my keyring and the ciphertext
and that I have the 'keyring'
and I have a 'ntrup ciphertext'

# Here I recreate the secret starting from the ciphertext
When I create the ntrup secret from 'ntrup ciphertext'
Then print the 'ntrup secret'
EOF
    save_output 'ntrup_secret.json'
}

#--- Creating together ntrup and kyber private and public keys ---#
@test "generating the private keys for ECDH and ntrup" {
        cat << EOF |zexe Carl_ntrup_kyber_secretkeys.zen
Rule check version 2.0.0
Scenario qp : Create the private keys
Given I am known as 'Carl'
When I create the kyber key
and I create the ntrup key
Then print my 'keyring'
EOF
    save_output 'Carl_secretkeys.keys'
}

@test "generating the public keys for kyber and ntrup" {
    cat << EOF | zexe Carl_ECDH_ntrup_pubkeys.zen Carl_secretkeys.keys
Rule check version 2.0.0
Scenario qp : Create the public keys
Given I am known as 'Carl'
and I have my 'keyring'
When I create the kyber public key
and I create the ntrup public key
Then print my 'ntrup public key'
and print my 'kyber public key'
EOF
    save_output 'Carl_pubkeys.json'
}

#--- creating a secret and its ciphertext with ntrup and kyber ---#
@test "creating a secret and its ciphertext with ntrup and kyber" {
    cat <<EOF | zexe Carl_ntrup_ECDH_enc.zen Carl_pubkeys.json
Rule check version 2.0.0
Scenario qp : Bob creates secret and its ciphertext for Carl with Kyber and ntrup
Given I am 'Bob'
and I have a 'ntrup public key' from 'Carl'
and I have a 'kyber public key' from 'Carl'
When I create the ntrup kem for 'Carl'
and I create the kyber kem for 'Carl'
Then print the 'ntrup ciphertext' from 'ntrup kem'
and print the 'ntrup secret' from 'ntrup kem'
Then print the 'kyber ciphertext' from 'kyber kem'
and print the 'kyber secret' from 'kyber kem'
EOF
    save_output 'Ciphertexts.json'

}


@test "" {
    cat <<EOF | zexe Carl_dec.zen Carl_secretkeys.keys Ciphertexts.json
Rule check version 2.0.0
Scenario qp : Carl creates the ntrup and kyber secrets
Given that I am known as 'Carl'
and I have my 'keyring'
and I have a 'ntrup ciphertext'
and I have a 'ntrup secret'
and I have a 'kyber ciphertext'
and I have a 'kyber secret'

When I rename the 'ntrup secret' to 'Bob ntrup secret'
and I create the ntrup secret from 'ntrup ciphertext'

When I rename the 'kyber secret' to 'Bob kyber secret'
and I create the kyber secret from 'kyber ciphertext'

If I verify 'Bob ntrup secret' is equal to 'ntrup secret'
If I verify 'Bob kyber secret' is equal to 'kyber secret'
Then print string 'Success!!!'
Endif
EOF
    save_output 'Carl_dec.out'
    assert_output '{"output":["Success!!!"]}'

}
