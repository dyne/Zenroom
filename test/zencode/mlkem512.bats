load ../bats_setup
load ../bats_zencode
SUBDOC=mlkem512

@test "When I create the mlkem512 key" {
    cat <<EOF | save_asset mlkem512_readsecretkeys.keys
{
"private_key":"37EC477E217BFB40384C850E51C1837158BDBC23A31832BC25C91B3121444AD4533733BAFF07CA817B64B2CA4299AA26454CBAFB35B6ABE1185CB47C4CD61AF98383C4814B20AB8754FC514F23074114C3E5A810A453B855AA7F1310C74B0B01E5AAB2E871738FAC2786C7A05D6B3B32A050D0FB223956C95CA0C2C1D54154A77BD33737A49A0065D1424A2ABAFD52AA934C9804939208F05CCF8B8B8086316E0943A08710500C918A2B218D37B85AE28022CB0134FB49F5C45D98D3C04B755A60880422668E2B301B18D5194DE991B265BF94697E6A4B8150C8B852033915635E30665BDA2191DAA505D43344FD29C9FCC1C507691D475B617C948FCC84B1B08A1C638C3E13580CE359789A9860E5469CC754B08EE33F0921BDEF15A906969F2DC57A25E80CE4C45F11E04A519AB08B9B927C3A13A081CFFA110FACCC5E8DC29495978B5553104D473A175918AD5B5487BBA69712AE93F615C60A8D387BCE3F651E56880A522B2DB86351CAB65D13B4693DB0B2C80936FAD1CE67925E6BB7C110C43E83247D22608D8C1023431CB69290A4F8A9593BF1241D737C0CD16D75EB50C6842CE0A21DCE494036824CE63252E9325F05B734452B129132B196084A3788BBB1F20A37D2C2B3F90E0DD7A274C9B1A9F02EC7E721F4A43D409A25FBC99A44D4763107C787620941761ED48C932924BA620986CF277A23471C7B13333D936C0DD49E0FF34CA3AB8234C42AEBE459C612052B9716E96B20BEC718126040A9091F6BA9445F45806AEB6E3816710F7CBFED1101461284DD962B7B12047C0A0A906A0589B4A9A426469BDA3946091A375B1952A91C231C0FE6B57F7CC97EFED0BC1001367823BE1886308B3A21452B7E455066719CCCEAF6A726FC22BC8399F54BBFCAF7CA63BA73173C7AA8619A3F485C3E330421006766746F4EF6653E440E5CDC59534018C352C023584CBB374EB7A9B7836832BE53AF272A069755CE2FF29CD8B394C52422B3470E27415F41B397535959F160003B452CF49697B7A53689852BBE6CCFDFB40B48E9328DE11522D0A431B115A5C0C2F4307D9862C0DD1B40C65A1D9D479777E6905A91A5CB24551C8B1E52A3C77B63313FFC8B5817815259A6ADB59645DC4BB1436D51E62A096834AF43772510C4EDF34CDE0A5B57C145E687CB87162F001C21C9E1934AC11AAFA70FF810732650B32A3018A7C50CD736796222C8AB821A9283BE1CC204C3F1630D3CCCDB0A9A3D17552B9158C0664E5D6A04B0FA36DE45862A46A39EC597AE42C311C4AC224A72D6F253BB5235F7A2B8B0F24D1376AF588746F3BB8E0365078761CAB983A4A6A940A3D997047A8F36A731E8965236C37BF200082F821DCA7716C444A90BEC53074BBA58C132BFB9A2ACE2CEC9AA658EAC1232CCCA3C817A92C1195C05C0E1D6639FD2ADE531607D488B74A747CFF47FCA5C8B2163CA03C545ED103278430C60B2381A09427FD130F859BF5DB776DA095DCA5804FA63B0D7D87FA9415C72FB51872A989F466C984BC74C29B8632019CA040C9CA35E22608DAA70357AE2C3AD83631FAA174E0ACDF5DBBF3CF68A05B6543AB6268E1A51B0932C17B00A1371B2DAB241F92A43FFB456D0A8C8860A8E28A61A21307CC0456DA4242905CB1D3D0BBD81BB8EE274A43C76C310019515FCC140467C33370C86808ECAA58E3BA93A2C1190461C1DFA11302001BBAB4CB1E3642EF8CB26309B60523BC21887B07F898CE562A6CA778EA01505851378CEA8BB7FC09D11961B6C596F93542A9904864EB10CD0A703DBA98921861A87B056525C71A843553E6400777437C95CCC8085CC0C477D665A4479019D4CD442F74A3CD8169F4262B8271B5D5A67C8C1611AAE7B3D0534C0859716FDF0BB68949094C06A1B73C9AA1CBDF331543DE002A8C06F94E8810A5CB373832745D720683B574875A666946D0296893F2B59E907488D8C8489D474D929A05A573ED667490371A46D4556CBB68AAA79CC3EC6653413576C228E379A14CB90B7B7591B19A7BD37A1C4D37859892219442BB0B9B9BA67BA3BC0D095C8803CEBE97AFF0B1C153578A130CD8157CF745946C2F5726D9C11273575505291346528EE0BAC047CC984538B97BBABFCC357DCB8A98FB857C9C52D1B786749CA61892B09759980520091B9B477C70E6C46586B1CCEBE87BCF6DF03C2B27CB09FA03F63160958383BE636C0ECC8DDAE8B594A14037868BEC0B22300DEFDFAA1D973AC5CEC84AE4386B8FBCD119AFDC8559442424A87C13EA101E29FCA11881869077E4092E751BEDCA8BC"
}
EOF

    cat <<EOF | zexe mlkem512_createprivatekey.zen
Rule check version 2.0.0
Scenario qp : Create the mlkem512 private key
Given I am 'Alice'
When I create the mlkem512 key
Then print the 'keyring'
EOF
    save_output 'Alice_mlkem512_privatekey.keys'
}

@test "Read keys" {
    cat <<EOF | zexe mlkem512_readkeys.zen Alice_mlkem512_privatekey.keys
Rule check version 2.0.0
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
Rule check version 2.0.0
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
Rule check version 2.0.0
Scenario qp : Create and publish the mlkem512 public key
Given I am 'Alice'
#and I have a 'mlkem512 private key'
and I have a 'hex' named 'private key'
When I create the mlkem512 public key with secret key 'private key'
Then print my 'mlkem512 public key'
EOF
    save_output 'mlkem512_createpublickey2.out'
    assert_output '{"Alice":{"mlkem512_public_key":"xlodnUeXd+aQWpGlyyRVHIseUqPHe2MxP/yLWBeBUlmmrbWWRdxLsUNtUeYqCWg0r0N3JRDE7fNM3gpbV8FF5ofLhxYvABwhyeGTSsEar6cP+BBzJlCzKjAYp8UM1zZ5YiLIq4IakoO+HMIEw/FjDTzM2wqaPRdVK5FYwGZOXWoEsPo23kWGKkajnsWXrkLDEcSsIkpy1vJTu1I196K4sPJNE3avWIdG87uOA2UHh2HKuYOkpqlAo9mXBHqPNqcx6JZSNsN78gAIL4IdyncWxESpC+xTB0u6WMEyv7mirOLOyapljqwSMszKPIF6ksEZXAXA4dZjn9Kt5TFgfUiLdKdHz/R/ylyLIWPKA8VF7RAyeEMMYLI4GglCf9Ew+Fm/Xbd22gldylgE+mOw19h/qUFccvtRhyqYn0ZsmEvHTCm4YyAZygQMnKNeImCNqnA1euLDrYNjH6oXTgrN9du/PPaKBbZUOrYmjhpRsJMsF7AKE3Gy2rJB+SpD/7RW0KjIhgqOKKYaITB8wEVtpCQpBcsdPQu9gbuO4nSkPHbDEAGVFfzBQEZ8MzcMhoCOyqWOO6k6LBGQRhwd+hEwIAG7q0yx42Qu+MsmMJtgUjvCGIewf4mM5WKmyneOoBUFhRN4zqi7f8CdEZYbbFlvk1QqmQSGTrEM0KcD26mJIYYah7BWUlxxqENVPmQAd3Q3yVzMgIXMDEd9ZlpEeQGdTNRC90o82BafQmK4JxtdWmfIwWEarns9BTTAhZcW/fC7aJSQlMBqG3PJqhy98zFUPeACqMBvlOiBClyzc4MnRdcgaDtXSHWmZpRtApaJPytZ6QdIjYyEidR02SmgWlc+1mdJA3GkbUVWy7aKqnnMPsZlNBNXbCKON5oUy5C3t1kbGae9N6HE03hZiSIZRCuwubm6Z7o7wNCVyIA86+l6/wscFTV4oTDNgVfPdFlGwvVybZwRJzV1UFKRNGUo7gusBHzJhFOLl7ur/MNX3Lipj7hXycUtG3hnScphiSsJdZmAUgCRubR3xw5sRlhrHM6+h7z23wPCsnywn6A/YxYJWDg75jY="}}'


}


@test "mlkem512 KEM" {
    cat <<EOF | zexe mlkem512_enc.zen Alice_mlkem512_pubkey.json
Rule check version 2.0.0
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
Rule check version 2.0.0
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
Rule check version 2.0.0
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
Rule check version 2.0.0
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
Rule check version 2.0.0
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
Rule check version 2.0.0
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
EOF
    save_output 'Carl_ECDH_mlkem512_dec.out'
    assert_output '{"output":["Success!!!"]}'

}
