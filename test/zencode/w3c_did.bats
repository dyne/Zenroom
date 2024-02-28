load ../bats_setup
load ../bats_zencode

SUBDOC=w3c

# How it works:
# - The User creates private and public keys
# - The User creates its did document and send it to the admin that notarize it
# - The User can sign documents using its keys
# - Everyone with the did-document can verify the signatures


@test "Generate user private keys" {
    cat <<EOF | save_asset controller.json
    {
        "controller": "test_user"
    }
EOF
    cat <<EOF | zexe privatekey_gen.zen controller.json
Scenario 'ecdh': Create the key
Scenario 'ethereum': Create the key
Scenario 'reflow': Create the key
Scenario 'eddsa' : Create the key
Scenario 'credential': Create the key
Scenario 'bbs': Create the key
Scenario 'es256': Create the key

Given my name is in a 'string' named 'controller'

# Here we are creating the keys
When I create the ecdh key
When I create the eddsa key
When I create the ethereum key
When I create the reflow key
When I create the bitcoin key
When I create the issuer key
When I create the bbs key
When I create the es256 key

Then print my 'keyring'
and print my name in 'controller'
EOF
    save_output "privatekey_gen.json"
    assert_output '{"controller":"test_user","test_user":{"keyring":{"bbs":"IIgvxyNObnFBbXBDe1Gby9KU2T5ELMUP3Awh54Wt8dM=","bitcoin":"L1ipn47zzKEDFhbHgJ3ef4Hwpf3ACu4CHEzDGXdJ4Wh6DtjV1woo","ecdh":"B4rYTWx6UMbc2YPWRNpl4w2M6gY9jqSa637n8Kr2pPc=","eddsa":"GSoD2BSdjy3fZXn1ERtaURhvn3WT86ZFu94VRXZQVgP9","es256":"RBaI7NPhXzsdBwMQ7K96zWSzAk+xvIdIZVzVvzfUFGE=","ethereum":"8ae6a6434a8e0122da02b627e18f3524a2827604701348dd84c15202bda1d5c8","issuer":{"x":"Pq6nwFvBUkZ7CeU2W9jdyzNbOCpV/EBZ8EPVcKC07jI=","y":"ZzcTAX/2tXQYOwEWt/P/jF8Qu3HGQLNveqoA1rzcPNY="},"reflow":"TnrC8yQs+TxWOOKrrYjRsynhmotwvI/WsiLxag7/X20="}}}'
}

@test "Generate user public keys/address" {
    cat <<EOF | zexe pubkey_gen.zen privatekey_gen.json
rule output encoding base58
Scenario 'ecdh': Create the key
Scenario 'ethereum': Create the key
Scenario 'reflow': Create the key
Scenario 'eddsa' : Create the key
Scenario 'credential': Create the key
Scenario 'bbs': Create the key
Scenario 'es256': Create the key

Given my name is in a 'string' named 'controller'
and I have my 'keyring'

When I create the ecdh public key
and I create the eddsa public key
and I create the ethereum address
and I create the bitcoin public key
and I create the reflow public key
and I create the issuer public key
and I create the bbs public key
and I create the es256 public key

Then I print the 'eddsa public key'
and I print the 'ethereum address'
and I print the 'ecdh public key'
and I print the 'bitcoin public key'
and I print the 'reflow public key'
and I print the 'issuer public key' as 'compressed issuer public key'
and I print the 'bbs public key'
and I print the 'es256 public key'
and I print my name in 'identity'
EOF
    save_output "pubkey_gen.json"
    assert_output '{"bbs_public_key":"ykbNb4QcyqA4EmRVa8AP2gAu5kWwzmnhXwCZ421XQnYPC3m7gXZ29yEnkToitHgnc3y1TWscseCd9G3hSvh7tp9QKSyGxDM15KQjGaQUekwZQ9Z1BXW2iATYD9uVEkM2wHu","bitcoin_public_key":"gR5grNVtEvyM7Uy1L455q1WLkr5piE4yocyQ2stsMPiu","ecdh_public_key":"Prv7EbvuXevABNJytdsoXPqjJFJxnuiHVk3QqcuWHtn7yzEQHkctuEgezzjG9tCCNriD4HsmFNnFPFDcGfMs3kmR","eddsa_public_key":"DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","es256_public_key":"3Gjh6x5oHB3e14VXMtN74PEPwMSDDFxQEr3W88STaGXFHXhVZDH4AP85sU2rJ95o3aqkUuYzLDfR4jYCqHh6jakP","ethereum_address":"0x03379e512Bb00f0F8669EAeC392225DDE018FA6C","identity":"test_user","issuer_public_key":"2eeoyWMdUh1KxbLNydhZxpbNDqh1aGiJaCMwMWP4PpqyD1oEBW9rmBaET5ZugQvocw3w5NzL1znB2SmSJLmd5J13QNnP4xGtmT8itf3j7jyakGBLmy3zg2sXJvkqZLsDySoHEfjJLGP8c5CbZvQCSydphNo4NWoi6s2RXBLotSXMQ2NsrcL6HoYsnJxTFcEDcFMuYiDGyyzpATPLBBNEVQ4VypdKtwrzgqwkMk1SDjiEqhwy61hYHknCJM6bDhirnjptpxL","reflow_public_key":"aeEZAeKXLcuWLEgCY3q8L7kN9qyakvnNeZCS4TzYgVM8LqeuJaZQjVffAZB4QYxk33Cw2bTtXRUmBBBGPFMtMFVCKNhTbMgwUQwwXPoq8YFg6ENMKMCRhHxCfpXd8Ta5WEn2itA1gp8zZnsu8Gj37tDUDHA9twiszDxV7KPWdYNdD4at1shUcSyovuNuUcXwtLCdF9QPKWm5uQ6qrcbk6wimhpT6yNZQtWiZrCXMWrKyk14Yi4kXxaJwquvzUkHL87hZT"}'
}

@test "The user creates its did document request" {
    cat <<EOF | save_asset context_data.json
{
    "@context":[
        "https://www.w3.org/ns/did/v1",
        "https://w3id.org/security/suites/ed25519-2018/v1",
        "https://w3id.org/security/suites/secp256k1-2019/v1",
        "https://w3id.org/security/suites/secp256k1-2020/v1",
        "https://dyne.github.io/W3C-DID/specs/ReflowBLS12381.json",
        "https://dyne.github.io/W3C-DID/specs/Bbs.json",
        "https://dyne.github.io/W3C-DID/specs/EcdsaSecp256r1.json",
        "https://dyne.github.io/W3C-DID/specs/Coconut.json",
        {
            "description":"https://schema.org/description",
        }
    ],
    "did_spec": "sandbox.zenroomtest"
}
EOF
    cat <<EOF | zexe did_doc_gen.zen context_data.json pubkey_gen.json
Rule input encoding base58
Rule output encoding base58

Scenario 'ecdh': Use the key
Scenario 'ethereum': Use the key
Scenario 'reflow': Use the key
Scenario 'eddsa' : Use the key
Scenario 'credential': Use the key
Scenario 'bbs': Use the key
Scenario 'es256': Use the key

# load the request settings
Given I have a 'string array' named '@context'

# load the new identity public keys and description
Given I have a 'string' named 'did_spec'
Given I have a 'string' named 'identity'
and I rename 'identity' to 'description'
and I have a 'eddsa_public_key'
and I rename 'eddsa_public_key' to 'identity pk'
Given I have a 'ethereum_address'
Given I have a 'ecdh_public_key'
Given I have a 'reflow_public_key'
Given I have a 'bbs public key'
Given I have a 'es256 public key'
Given I have a 'base58' named 'bitcoin public key'
# import as a key for crypto checks (then transofrmed into table in zenroom)
Given I have a 'issuer public key'
and I rename 'issuer public key' to 'table issuer public key'
# import as a base58 to be then inserted easily in the did doc
Given I have a 'base58' named 'issuer public key'

#TODO: validate eddsa public key

### Formulate the DID creation request
When I create the 'string dictionary' named 'did document'
and I move '@context' in 'did document'
and I move 'description' in 'did document'

## did spec and id
When I set 'did:dyne:' to 'did:dyne:' as 'string'
and I append 'did_spec' to 'did:dyne:'
and I append the string ':' to 'did:dyne:'
and I append the 'base58' of 'identity pk' to 'did:dyne:'
and I copy the 'did:dyne:' to 'id' in 'did document'

## veririfcationMethod
When I create the 'string array' named 'verificationMethod'

# 1-ecdsa public key
When I create the 'string dictionary' named 'verification-key'
# pk
When I create the 'base58' string of 'ecdh public key'
When I move the 'base58' to 'publicKeyBase58' in 'verification-key'
# type
When I set 'type' to 'EcdsaSecp256k1VerificationKey2019' as 'string'
When I move 'type' in 'verification-key'
# id
When I copy 'did:dyne:' to 'id'
When I append the string '#ecdh_public_key' to 'id'
When I move 'id' in 'verification-key'
# controller
When I copy the 'did:dyne:' to 'controller' in 'verification-key'
When I move 'verification-key' in 'verificationMethod'

# 2-reflow public key
When I create the 'string dictionary' named 'verification-key'
# pk
When I create the 'base58' string of 'reflow public key'
When I move the 'base58' to 'publicKeyBase58' in 'verification-key'
# type
When I set 'type' to 'ReflowBLS12381VerificationKey' as 'string'
When I move 'type' in 'verification-key'
# id
When I copy 'did:dyne:' to 'id'
When I append the string '#reflow_public_key' to 'id'
When I move 'id' in 'verification-key'
# controller
When I copy the 'did:dyne:' to 'controller' in 'verification-key'
When I move 'verification-key' in 'verificationMethod'

# 3-bitcoin public key
When I create the 'string dictionary' named 'verification-key'
# pk
When I create the 'base58' string of 'bitcoin public key'
and I move the 'base58' to 'publicKeyBase58' in 'verification-key'
# type
When I set 'type' to 'EcdsaSecp256k1VerificationKey2019' as 'string'
When I move 'type' in 'verification-key'
# id
When I copy 'did:dyne:' to 'id'
When I append the string '#bitcoin_public_key' to 'id'
When I move 'id' in 'verification-key'
# controller
When I copy the 'did:dyne:' to 'controller' in 'verification-key'
When I move 'verification-key' in 'verificationMethod'

# 4-eddsa public key
When I create the 'string dictionary' named 'verification-key'
# pk
When I create the 'base58' string of 'identity pk'
and I move the 'base58' to 'publicKeyBase58' in 'verification-key'
# type
When I set 'type' to 'Ed25519VerificationKey2018' as 'string'
When I move 'type' in 'verification-key'
# id
When I copy 'did:dyne:' to 'id'
When I append the string '#eddsa_public_key' to 'id'
When I move 'id' in 'verification-key'
# controller
When I copy the 'did:dyne:' to 'controller' in 'verification-key'
When I move 'verification-key' in 'verificationMethod'

# 5-ethereum address
When I create the 'string dictionary' named 'verification-key'
# address
# this follows the CAIP-10(https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-10.md) spec
# thus it is: namespace + ":" + chain_id + ":" + address
When I set 'blockchainAccountId' to 'eip155:1:0x' as 'string'
When I append the 'hex' of 'ethereum address' to 'blockchainAccountId'
When I move 'blockchainAccountId' in 'verification-key'
# type
When I set 'type' to 'EcdsaSecp256k1RecoveryMethod2020' as 'string'
When I move 'type' in 'verification-key'
# id
When I copy 'did:dyne:' to 'id'
When I append the string '#ethereum_address' to 'id'
When I move 'id' in 'verification-key'
# controller
When I copy the 'did:dyne:' to 'controller' in 'verification-key'
When I move 'verification-key' in 'verificationMethod'

# 6-es256 public key
When I create the 'string dictionary' named 'verification-key'
# pk
When I create the 'base58' string of 'es256 public key'
and I move the 'base58' to 'publicKeyBase58' in 'verification-key'
# type
When I set 'type' to 'EcdsaSecp256r1VerificationKey' as 'string'
When I move 'type' in 'verification-key'
# id
When I copy 'did:dyne:' to 'id'
When I append the string '#es256_public_key' to 'id'
When I move 'id' in 'verification-key'
# controller
When I copy the 'did:dyne:' to 'controller' in 'verification-key'
When I move 'verification-key' in 'verificationMethod'

# 7-bbs public key
When I create the 'string dictionary' named 'verification-key'
# pk
When I create the 'base58' string of 'bbs public key'
and I move the 'base58' to 'publicKeyBase58' in 'verification-key'
# type
When I set 'type' to 'BbsVerificationKey' as 'string'
When I move 'type' in 'verification-key'
# id
When I copy 'did:dyne:' to 'id'
When I append the string '#bbs_public_key' to 'id'
When I move 'id' in 'verification-key'
# controller
When I copy the 'did:dyne:' to 'controller' in 'verification-key'
When I move 'verification-key' in 'verificationMethod'

# 8-issuer public key
When I create the 'string dictionary' named 'verification-key'
# pk
When I create the 'base58' string of 'issuer public key'
and I move the 'base58' to 'publicKeyBase58' in 'verification-key'
# type
When I set 'type' to 'CoconutVerificationKey' as 'string'
When I move 'type' in 'verification-key'
# id
When I copy 'did:dyne:' to 'id'
When I append the string '#issuer_public_key' to 'id'
When I move 'id' in 'verification-key'
# controller
When I copy the 'did:dyne:' to 'controller' in 'verification-key'
When I move 'verification-key' in 'verificationMethod'

When I move 'verificationMethod' in 'did document'
### DID-Document ended

# print did document
Then print the 'did document' as 'string' in 'request'
EOF
    save_output "did_document.json"
    assert_output '{"request":{"did_document":{"@context":["https://www.w3.org/ns/did/v1","https://w3id.org/security/suites/ed25519-2018/v1","https://w3id.org/security/suites/secp256k1-2019/v1","https://w3id.org/security/suites/secp256k1-2020/v1","https://dyne.github.io/W3C-DID/specs/ReflowBLS12381.json","https://dyne.github.io/W3C-DID/specs/Bbs.json","https://dyne.github.io/W3C-DID/specs/EcdsaSecp256r1.json","https://dyne.github.io/W3C-DID/specs/Coconut.json",{"description":"https://schema.org/description"}],"description":"test_user","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","verificationMethod":[{"controller":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu#ecdh_public_key","publicKeyBase58":"Prv7EbvuXevABNJytdsoXPqjJFJxnuiHVk3QqcuWHtn7yzEQHkctuEgezzjG9tCCNriD4HsmFNnFPFDcGfMs3kmR","type":"EcdsaSecp256k1VerificationKey2019"},{"controller":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu#reflow_public_key","publicKeyBase58":"aeEZAeKXLcuWLEgCY3q8L7kN9qyakvnNeZCS4TzYgVM8LqeuJaZQjVffAZB4QYxk33Cw2bTtXRUmBBBGPFMtMFVCKNhTbMgwUQwwXPoq8YFg6ENMKMCRhHxCfpXd8Ta5WEn2itA1gp8zZnsu8Gj37tDUDHA9twiszDxV7KPWdYNdD4at1shUcSyovuNuUcXwtLCdF9QPKWm5uQ6qrcbk6wimhpT6yNZQtWiZrCXMWrKyk14Yi4kXxaJwquvzUkHL87hZT","type":"ReflowBLS12381VerificationKey"},{"controller":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu#bitcoin_public_key","publicKeyBase58":"gR5grNVtEvyM7Uy1L455q1WLkr5piE4yocyQ2stsMPiu","type":"EcdsaSecp256k1VerificationKey2019"},{"controller":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu#eddsa_public_key","publicKeyBase58":"DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","type":"Ed25519VerificationKey2018"},{"blockchainAccountId":"eip155:1:0x03379e512bb00f0f8669eaec392225dde018fa6c","controller":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu#ethereum_address","type":"EcdsaSecp256k1RecoveryMethod2020"},{"controller":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu#es256_public_key","publicKeyBase58":"3Gjh6x5oHB3e14VXMtN74PEPwMSDDFxQEr3W88STaGXFHXhVZDH4AP85sU2rJ95o3aqkUuYzLDfR4jYCqHh6jakP","type":"EcdsaSecp256r1VerificationKey"},{"controller":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu#bbs_public_key","publicKeyBase58":"ykbNb4QcyqA4EmRVa8AP2gAu5kWwzmnhXwCZ421XQnYPC3m7gXZ29yEnkToitHgnc3y1TWscseCd9G3hSvh7tp9QKSyGxDM15KQjGaQUekwZQ9Z1BXW2iATYD9uVEkM2wHu","type":"BbsVerificationKey"},{"controller":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu#issuer_public_key","publicKeyBase58":"2eeoyWMdUh1KxbLNydhZxpbNDqh1aGiJaCMwMWP4PpqyD1oEBW9rmBaET5ZugQvocw3w5NzL1znB2SmSJLmd5J13QNnP4xGtmT8itf3j7jyakGBLmy3zg2sXJvkqZLsDySoHEfjJLGP8c5CbZvQCSydphNo4NWoi6s2RXBLotSXMQ2NsrcL6HoYsnJxTFcEDcFMuYiDGyyzpATPLBBNEVQ4VypdKtwrzgqwkMk1SDjiEqhwy61hYHknCJM6bDhirnjptpxL","type":"CoconutVerificationKey"}]}}}'
}

@test "An Admin sign the did document" {
    cat <<EOF | save_asset admin_fake_keyring.json
    {
        "timestamp": "1703064997357",
        "controller": "fake admin",
        "fake_admin": {
            "keyring": {
                "ecdh": "P+R97TQnLIhaTkATxwQT661sLiOxSYLDvetSt57CNCo=",
                "eddsa": "Bbad7evauGKhpgrCjAyTJMpdLZSQY2pL7vi8ySJurYVG"
            }
        },
        "signer_did_spec": "sandbox.zenroomtest_A",
        "header": {
                  "alg": "ES256K"
        }
    }
EOF
    cat <<EOF | zexe did_doc_sign.zen admin_fake_keyring.json did_document.json
rule input encoding base58
rule output encoding base58

Scenario ecdh
Scenario eddsa
Scenario w3c

# timestamp
Given I have a 'string' named 'timestamp'

# load the spec admin keyring to sign the request
Given my name is in a 'string' named 'controller'
and I have my 'keyring'

# did document and signer_idspec
Given I have a 'string dictionary' named 'request'
and I have a 'string' named 'signer_did_spec'

Given I have a 'string dictionary' named 'header'

If I verify 'did_document' is found in 'request'
When I pickup from path 'request.did_document'

# signature with timestamp
When I create the 'string dictionary' named 'result'
and I copy 'did document' in 'result'
and I copy 'timestamp' in 'result'
and I create the json escaped string of 'result'
and I create the eddsa signature of 'json escaped string'
and I remove 'json escaped string'

When I copy 'did_document' to 'payload'

Then print the 'did document'
and print the 'timestamp'
and print the 'eddsa signature'
EndIf

If I verify 'deactivate_id' is found in 'request'
When I create the 'string dictionary' named 'payload'
and I copy the 'deactivate_id' from 'request' to 'deactivate_id'
and I copy the 'deactivate_id' in 'payload'

Then print the 'deactivate_id' from 'request'
EndIf

When I verify 'payload' is found

# did document signature
When I create the jws detached signature with header 'header' and payload 'payload'

# signer id
When I create the eddsa public key
and I set 'id' to 'did:dyne:' as 'string'
and I append 'signer_did_spec' to 'id'
and I append the string ':' to 'id'
and I append the 'base58' of 'eddsa public key' to 'id'

Then print the 'jws detached'
Then print the 'id'
EOF
    save_output "did_document_signed.json"
    assert_output '{"did_document":{"@context":["https://www.w3.org/ns/did/v1","https://w3id.org/security/suites/ed25519-2018/v1","https://w3id.org/security/suites/secp256k1-2019/v1","https://w3id.org/security/suites/secp256k1-2020/v1","https://dyne.github.io/W3C-DID/specs/ReflowBLS12381.json","https://dyne.github.io/W3C-DID/specs/Bbs.json","https://dyne.github.io/W3C-DID/specs/EcdsaSecp256r1.json","https://dyne.github.io/W3C-DID/specs/Coconut.json",{"description":"https://schema.org/description"}],"description":"test_user","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","verificationMethod":[{"controller":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu#ecdh_public_key","publicKeyBase58":"Prv7EbvuXevABNJytdsoXPqjJFJxnuiHVk3QqcuWHtn7yzEQHkctuEgezzjG9tCCNriD4HsmFNnFPFDcGfMs3kmR","type":"EcdsaSecp256k1VerificationKey2019"},{"controller":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu#reflow_public_key","publicKeyBase58":"aeEZAeKXLcuWLEgCY3q8L7kN9qyakvnNeZCS4TzYgVM8LqeuJaZQjVffAZB4QYxk33Cw2bTtXRUmBBBGPFMtMFVCKNhTbMgwUQwwXPoq8YFg6ENMKMCRhHxCfpXd8Ta5WEn2itA1gp8zZnsu8Gj37tDUDHA9twiszDxV7KPWdYNdD4at1shUcSyovuNuUcXwtLCdF9QPKWm5uQ6qrcbk6wimhpT6yNZQtWiZrCXMWrKyk14Yi4kXxaJwquvzUkHL87hZT","type":"ReflowBLS12381VerificationKey"},{"controller":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu#bitcoin_public_key","publicKeyBase58":"gR5grNVtEvyM7Uy1L455q1WLkr5piE4yocyQ2stsMPiu","type":"EcdsaSecp256k1VerificationKey2019"},{"controller":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu#eddsa_public_key","publicKeyBase58":"DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","type":"Ed25519VerificationKey2018"},{"blockchainAccountId":"eip155:1:0x03379e512bb00f0f8669eaec392225dde018fa6c","controller":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu#ethereum_address","type":"EcdsaSecp256k1RecoveryMethod2020"},{"controller":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu#es256_public_key","publicKeyBase58":"3Gjh6x5oHB3e14VXMtN74PEPwMSDDFxQEr3W88STaGXFHXhVZDH4AP85sU2rJ95o3aqkUuYzLDfR4jYCqHh6jakP","type":"EcdsaSecp256r1VerificationKey"},{"controller":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu#bbs_public_key","publicKeyBase58":"ykbNb4QcyqA4EmRVa8AP2gAu5kWwzmnhXwCZ421XQnYPC3m7gXZ29yEnkToitHgnc3y1TWscseCd9G3hSvh7tp9QKSyGxDM15KQjGaQUekwZQ9Z1BXW2iATYD9uVEkM2wHu","type":"BbsVerificationKey"},{"controller":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu#issuer_public_key","publicKeyBase58":"2eeoyWMdUh1KxbLNydhZxpbNDqh1aGiJaCMwMWP4PpqyD1oEBW9rmBaET5ZugQvocw3w5NzL1znB2SmSJLmd5J13QNnP4xGtmT8itf3j7jyakGBLmy3zg2sXJvkqZLsDySoHEfjJLGP8c5CbZvQCSydphNo4NWoi6s2RXBLotSXMQ2NsrcL6HoYsnJxTFcEDcFMuYiDGyyzpATPLBBNEVQ4VypdKtwrzgqwkMk1SDjiEqhwy61hYHknCJM6bDhirnjptpxL","type":"CoconutVerificationKey"}]},"eddsa_signature":"2xZcwdTTetbk8vwNtSZ452mthAR6qcsZACR6HXNxcjwQvMm5CYkirtyuZrC6M1czRSqjcV8p3ZeTZY1pNR9fA8k7","id":"did:dyne:sandbox.zenroomtest_A:HCA7GceXsWmHaZJQCfHNPF1PdNKpr3o1fpnWjEDUzDsv","jws_detached":"eyJhbGciOiJFUzI1NksifQ..d2tYw0FFyVU7UjX-IRpiN8SLkLR4S8bYZmCwI2rzurLXlf19-Z2n8wUNoVhf99s5W_MnhimXM4YYAxY2aaU0lA","timestamp":"1703064997357"}'
}

@test "Server accept did document (not the real contract only crypto checks)" {
    cat <<EOF | save_asset admin_fake_did_doc.json
    {
        "signer_did_document": {
            "@context": [
                "https://www.w3.org/ns/did/v1",
                "https://w3id.org/security/suites/ed25519-2018/v1",
                "https://w3id.org/security/suites/secp256k1-2019/v1",
                "https://w3id.org/security/suites/secp256k1-2020/v1",
                "https://dyne.github.io/W3C-DID/specs/ReflowBLS12381.json",
                {
                    "description": "https://schema.org/description"
                }
            ],
            "description": "fake zenroom admin",
            "id": "did:dyne:sandbox.zenroomtest_A:HCA7GceXsWmHaZJQCfHNPF1PdNKpr3o1fpnWjEDUzDsv",
            "proof": {
                "created": "1702392905808",
                "jws": "eyJhbGciOiJFUzI1NksiLCJiNjQiOnRydWUsImNyaXQiOiJiNjQifQ..F-PQHuTvFzhzLqBKIpeErFp9jo1-bVa64S-HivtwuB58d98_XQXcFSF1F3p5pOeTbSYbDINTFjz10oLn7Wb2Dg",
                "proofPurpose": "assertionMethod",
                "type": "EcdsaSecp256k1Signature2019",
                "verificationMethod": "did:dyne:sandbox_A:9nDiX3vDGTzACi2fxbs9rGnhF5KGNv3H5QXEHDt3ov8u#ecdh_public_key"
            },
            "verificationMethod": [
                {
                    "controller": "did:dyne:sandbox.zenroomtest_A:HCA7GceXsWmHaZJQCfHNPF1PdNKpr3o1fpnWjEDUzDsv",
                    "id": "did:dyne:sandbox.zenroomtest_A:HCA7GceXsWmHaZJQCfHNPF1PdNKpr3o1fpnWjEDUzDsv#ecdh_public_key",
                    "publicKeyBase58": "SXrERoKV5jSxD2fGko16WfUXWhZczQDd7waQMn7nBpgfQDhK2Zs55GytEEv1bKbKDLN6uMp9eA2t6MDgiEpzksbT",
                    "type": "EcdsaSecp256k1VerificationKey2019"
                },
                {
                    "controller": "did:dyne:sandbox.zenroomtest_A:HCA7GceXsWmHaZJQCfHNPF1PdNKpr3o1fpnWjEDUzDsv",
                    "id": "did:dyne:sandbox.zenroomtest_A:HCA7GceXsWmHaZJQCfHNPF1PdNKpr3o1fpnWjEDUzDsv#eddsa_public_key",
                    "publicKeyBase58": "HCA7GceXsWmHaZJQCfHNPF1PdNKpr3o1fpnWjEDUzDsv",
                    "type": "Ed25519VerificationKey2018"
                }
            ]
        },
        "proof":{
            "type":"EcdsaSecp256k1Signature2019",
            "proofPurpose":"assertionMethod"
        }
    }
EOF
    cat <<EOF | zexe did_doc_sign.zen did_document_signed.json admin_fake_did_doc.json
    Rule input encoding base58
    Scenario 'w3c': did doc
    Scenario 'eddsa': verify signature
    Scenario 'ecdh': verify signature

    Given I have a 'string dictionary' named 'did document'
    and I have a 'string' named 'timestamp'
    and I have a 'eddsa signature'
    and I have a 'string' named 'jws detached'
    and I have a 'string' named 'id'

    Given I have a 'string dictionary' named 'proof'
    and I have a 'did document' named 'signer_did_document' 

    # extract signer pks
    When I create the 'ecdh' public key from did document 'signer_did_document'
    and I create the 'eddsa' public key from did document 'signer_did_document'

    # verify eddsa
    When I create the 'string dictionary' named 'signed_by_eddsa'
    and I copy 'did document' in 'signed_by_eddsa'
    and I copy 'timestamp' in 'signed_by_eddsa'
    and I create the json escaped string of 'signed_by_eddsa'
    and I verify the 'json escaped string' has a eddsa signature in 'eddsa signature' by 'eddsa public key'
    and I remove 'json escaped string'

    # verify ecdsa
    When I verify the 'did document' has a jws signature in 'jws detached'

    # create proof
    and I move 'jws detached' to 'jws' in 'proof'
    and I copy the 'timestamp' to 'created' in 'proof'

    # proof's verification method
    When I copy 'id' to 'verificationMethod'
    and I append the string '#ecdh_public_key' to 'verificationMethod'
    and I move 'verificationMethod' in 'proof'
    and I move 'proof' in 'did document'

    Then print the 'did document'
EOF
    save_output "accepted_did_document.json"
    assert_output '{"did_document":{"@context":["https://www.w3.org/ns/did/v1","https://w3id.org/security/suites/ed25519-2018/v1","https://w3id.org/security/suites/secp256k1-2019/v1","https://w3id.org/security/suites/secp256k1-2020/v1","https://dyne.github.io/W3C-DID/specs/ReflowBLS12381.json","https://dyne.github.io/W3C-DID/specs/Bbs.json","https://dyne.github.io/W3C-DID/specs/EcdsaSecp256r1.json","https://dyne.github.io/W3C-DID/specs/Coconut.json",{"description":"https://schema.org/description"}],"description":"test_user","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","proof":{"created":"1703064997357","jws":"eyJhbGciOiJFUzI1NksifQ..d2tYw0FFyVU7UjX-IRpiN8SLkLR4S8bYZmCwI2rzurLXlf19-Z2n8wUNoVhf99s5W_MnhimXM4YYAxY2aaU0lA","proofPurpose":"assertionMethod","type":"EcdsaSecp256k1Signature2019","verificationMethod":"did:dyne:sandbox.zenroomtest_A:HCA7GceXsWmHaZJQCfHNPF1PdNKpr3o1fpnWjEDUzDsv#ecdh_public_key"},"verificationMethod":[{"controller":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu#ecdh_public_key","publicKeyBase58":"Prv7EbvuXevABNJytdsoXPqjJFJxnuiHVk3QqcuWHtn7yzEQHkctuEgezzjG9tCCNriD4HsmFNnFPFDcGfMs3kmR","type":"EcdsaSecp256k1VerificationKey2019"},{"controller":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu#reflow_public_key","publicKeyBase58":"aeEZAeKXLcuWLEgCY3q8L7kN9qyakvnNeZCS4TzYgVM8LqeuJaZQjVffAZB4QYxk33Cw2bTtXRUmBBBGPFMtMFVCKNhTbMgwUQwwXPoq8YFg6ENMKMCRhHxCfpXd8Ta5WEn2itA1gp8zZnsu8Gj37tDUDHA9twiszDxV7KPWdYNdD4at1shUcSyovuNuUcXwtLCdF9QPKWm5uQ6qrcbk6wimhpT6yNZQtWiZrCXMWrKyk14Yi4kXxaJwquvzUkHL87hZT","type":"ReflowBLS12381VerificationKey"},{"controller":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu#bitcoin_public_key","publicKeyBase58":"gR5grNVtEvyM7Uy1L455q1WLkr5piE4yocyQ2stsMPiu","type":"EcdsaSecp256k1VerificationKey2019"},{"controller":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu#eddsa_public_key","publicKeyBase58":"DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","type":"Ed25519VerificationKey2018"},{"blockchainAccountId":"eip155:1:0x03379e512bb00f0f8669eaec392225dde018fa6c","controller":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu#ethereum_address","type":"EcdsaSecp256k1RecoveryMethod2020"},{"controller":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu#es256_public_key","publicKeyBase58":"3Gjh6x5oHB3e14VXMtN74PEPwMSDDFxQEr3W88STaGXFHXhVZDH4AP85sU2rJ95o3aqkUuYzLDfR4jYCqHh6jakP","type":"EcdsaSecp256r1VerificationKey"},{"controller":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu#bbs_public_key","publicKeyBase58":"ykbNb4QcyqA4EmRVa8AP2gAu5kWwzmnhXwCZ421XQnYPC3m7gXZ29yEnkToitHgnc3y1TWscseCd9G3hSvh7tp9QKSyGxDM15KQjGaQUekwZQ9Z1BXW2iATYD9uVEkM2wHu","type":"BbsVerificationKey"},{"controller":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu","id":"did:dyne:sandbox.zenroomtest:DBzNYB3ft2ncfeGaVV8aR5x95tU5hKUqGLYpDJifEVwu#issuer_public_key","publicKeyBase58":"2eeoyWMdUh1KxbLNydhZxpbNDqh1aGiJaCMwMWP4PpqyD1oEBW9rmBaET5ZugQvocw3w5NzL1znB2SmSJLmd5J13QNnP4xGtmT8itf3j7jyakGBLmy3zg2sXJvkqZLsDySoHEfjJLGP8c5CbZvQCSydphNo4NWoi6s2RXBLotSXMQ2NsrcL6HoYsnJxTFcEDcFMuYiDGyyzpATPLBBNEVQ4VypdKtwrzgqwkMk1SDjiEqhwy61hYHknCJM6bDhirnjptpxL","type":"CoconutVerificationKey"}]}}'
}

@test "now the User sign different documents with its keys" {
    cat <<EOF | save_asset to_sign.json
{
    "json": {
        "simple message": "hello world",
        "simple dictionary": { "hello" : "world" },
        "simple array": [ "hello", "world" ]
    },
    "Alice": {
        "credential_request": {
            "commit": "AgxaE6cXstFWa7aMZ8xnhaFFhsNx+M425Oze3eQRBGz875bTCkX1/9bPjEn0Lu0O0w==",
            "pi_s": {
                "commit": "CnOREb3Rx6Kf552vZfN8tzrNIn+palJ+6PdbhHOIdco=",
                "rk": "UE/pxMeN6hA4lUhYB3/zkan28cjTMPu0VyvDhEKGX1Y=",
                "rm": "cWkRLdKYyTYLq8leeOlAw1yQEJopHv8/2JGcmOQl1bQ=",
                "rr": "UoSW5ojkyLofT5cW+4f2GAYihUTPrtBnwh7bDFDzKHs="
            },
            "public": "AhYCP1Ct2ZapJuTYNTzWMUIlgPwFNweJFTrJ/0UWg9a/UwvY8g/9VPTgRJCV0X1SXA==",
            "sign": {
                "a": "AwtH8piZkVF/uPhjvzHFIjWWYee0HLBVtJ/UaSaUaBJJZrkiSibB4kvOCQAvmUpK9Q==",
                "b": "AgBioegDQ1mmgsphlFPCq61bASzVPi6ugpixwOuIUZP11z9aX51WzeU/cp8bw82SEw=="
            }
        }
    },
    "reflow_seal": {
        "SM": "AgszTl/cnllWhVbD9gtJal2fVDhdeW4seLbtvwUHEu2qOG7EkXx/0pwhfuABLIorog==",
        "identity": "Agy3w73Mu1b155J5FD5CsUIdx3YQ5C5m8qvHABelVjdvIDF+j79mJ+4iosp1waOMAA==",
        "verifier": "Ba76hy9H7Gkrpr0Pa+HQBWL6wefi7XLKNeV42YF/NOFwaOPHIvzwlUwrZT9big73EF60VEoPQqLBw9SnXsGRFAfpoW+4zDXZu1xHkNGxg7oRphsKNY4n7i7LhVcshPyPCjW2PrEyh3+2fBaGK4v05GfxWUoJSv7kXvUgC/VWT3/kYuBcNE/JpkPWggbMnNYLDvq+fLfO/75+TGG1wNq4JdJ4lye4idTftUV0takDxxozzNPrzosAgkXnxJ1ek4yA"
    },
    "issuer_public_key": "2eeoyWMdUh1KxbLNydhZxpbNDqh1aGiJaCMwMWP4PpqyD1oEBW9rmBaET5ZugQvocw3w5NzL1znB2SmSJLmd5J13QNnP4xGtmT8itf3j7jyakGBLmy3zg2sXJvkqZLsDySoHEfjJLGP8c5CbZvQCSydphNo4NWoi6s2RXBLotSXMQ2NsrcL6HoYsnJxTFcEDcFMuYiDGyyzpATPLBBNEVQ4VypdKtwrzgqwkMk1SDjiEqhwy61hYHknCJM6bDhirnjptpxL"
}
EOF
    cat <<EOF | zexe oracle_signature.zen privatekey_gen.json to_sign.json
Scenario 'ecdh': sign
Scenario 'eddsa': sign
Scenario 'ethereum': sign
Scenario 'reflow': sign
Scenario 'credential': sign
Scenario 'bbs': sign
Scenario 'es256': sign

Given my name is in a 'string' named 'controller'
and I have my 'keyring'
Given I have a 'string dictionary' named 'json'
and I have a 'string' named 'simple message' in 'json'
and I have a 'credential request' inside 'Alice'
# and I have a 'reflow seal'
# and I have a 'issuer public key'

When I create the ecdh signature of 'json'
When I create the eddsa signature of 'json'
When I create the es256 signature of 'json'

# do not sign nested tables strings
When I create the ethereum signature of 'simple message'
When I create the bbs signature of 'simple message'

# participant credential request
When I create the credential signature
# reflow
# When I create the reflow signature

Then print the 'ecdh signature'
Then print the 'eddsa signature'
Then print the 'es256 signature'
Then print the 'bbs signature'
# Then print the 'reflow signature'
Then print the 'ethereum signature'
Then print the 'credential signature'
Then print the 'json'
EOF
    save_output "signed.json"
    assert_output '{"bbs_signature":"h+MszTbzjQ/gb8NYgSKDhjcYDSDyYO/TJ/7PYfQut/UeiOl9/6y1dmTjQgDZ9CmgBsbmrQSQkeAgnSYiiqLz1nGAHq3Fg1aGER9z5OxHX143/Qpn0LRHlERg6unrqUkAWx55zRmrp727UIBw6LtG6w==","credential_signature":{"a_tilde":"Awhly/tk9sKexvuK+e3F8zUqlSN4OyKsGMI15xtZ7sJFQt6wLXBfr+G+pExs7FH3Yg==","b_tilde":"Ag+KjcPOJuR56iNpOyCndff0gjWNYZRUXYvOQo0ZBb2TeJfpWVoRWfwVEuiw4g2qgg==","h":"AgxaE6cXstFWa7aMZ8xnhaFFhsNx+M425Oze3eQRBGz875bTCkX1/9bPjEn0Lu0O0w=="},"ecdh_signature":{"r":"d2tYw0FFyVU7UjX+IRpiN8SLkLR4S8bYZmCwI2rzurI=","s":"c2WtqHdx9a/2r4aJuZfACHxGCkgGeQpzHZUttAx+VFQ="},"eddsa_signature":"4SvE9ari9BUvBgxiUJDzqpjTuogXJ8F42qc9rXYHgGXADjspjW9r6SJfG1VW8pxm7yjKSmEUPbv5CxKMjKemGD88","es256_signature":"bRd93MYGuiVye/3QVLtvyxGmyGejx/HXQcC+z3m/PtjyOX+wkgvZn+MpBgUZe4fvoPsj0tSkvK5VKz6zlGFgDw==","ethereum_signature":"0x904a3a6e4b685f93cf65f700493397cc35f1783beac55f29bcd903fa4d28975903fee504b28c64588df6182af8e6994499b1aea202287198f6a94a973ce6829a1b","json":{"simple_array":["hello","world"],"simple_dictionary":{"hello":"world"},"simple_message":"hello world"}}'
}

@test "participant create credential proof" {
    cat <<EOF | save_asset participant.json
{
	"Participant": {
		"keyring": {
			"credential": "OKjpJsVG3es9KpFXdQDNS+tFc1LdGziRxwYZpd+YMKM="
		}
	},
    "issuer_public_key": "tqCtdVUttGpPAfHcmrHF4zYDzNPZLzLyqoX9oMkf4Y3FtYWEq1+pQIMgdkooSaogGHxdKQYZb78EQyAChMbxbiguBOcSLP2JjIz1s5KZLotGI+ghA5LMxa3CVe0c39h2gIc/0PH9+xrzVrTGQNwwr3MoyWBZMbODSYWS1XZDHWClw0DRp6miZd+kUzFQGTEeBZkGgDaWWsJUkkyeOQ5vjJuqOX3xcfb7H7OfBNO9129ojTOoyDNDa0gA4OjfuKMN"
}
EOF
    cat <<EOF | zexe oracle_signature.zen signed.json participant.json
Scenario 'ecdh': sign
Scenario 'eddsa': sign
Scenario 'ethereum': sign
Scenario 'reflow': sign
Scenario 'credential': sign
Scenario 'bbs': sign
Scenario 'es256': sign

# Here we load the the keyring of the participant, containing their secret key
Given that I am known as 'Participant'
Given I have my 'keyring'

Given I have a 'credential signature'
and I have a 'issuer public key'

# other signatures
Given I have a 'string dictionary' named 'json'
Given I have a 'ecdh signature'
Given I have a 'eddsa signature'
Given I have a 'es256 signature'
Given I have a 'bbs signature'
# Given I have a 'reflow signature'
Given I have a 'ethereum signature'

When I aggregate all the issuer public keys
When I create the credentials
When I create the credential proof

Then print the 'credential proof'
Then print the 'ecdh signature'
Then print the 'eddsa signature'
Then print the 'es256 signature'
Then print the 'bbs signature'
# Then print the 'reflow signature'
Then print the 'ethereum signature'
Then print the 'json'
EOF
    save_output "sign_and_proof.json"
    assert_output '{"bbs_signature":"h+MszTbzjQ/gb8NYgSKDhjcYDSDyYO/TJ/7PYfQut/UeiOl9/6y1dmTjQgDZ9CmgBsbmrQSQkeAgnSYiiqLz1nGAHq3Fg1aGER9z5OxHX143/Qpn0LRHlERg6unrqUkAWx55zRmrp727UIBw6LtG6w==","credential_proof":{"kappa":"GUSmv59MQMHsQLpJ/Dwi0IHjz1jaL67Gc4N8Cy9/S7WLWh8IRbMGxnESUfgTRKDEEIR3OmscHitO5ePffc8Y6BYeBTTUt/bx2sx1+ieslKnHryORfr4hQF4zvK5U6p/QCAD8pJDAf2scR5LVvS+pe0dqen17vznUORUcSbcZcysePYHlLF8uhRsroQYGP7/hEcXJyx/O8JTr6lBEptUpjwGELJpXTF77QT5XMhhchh35Q3d3gXQTn+f/vLz6C64Y","nu":"AhIwE+dgi1tzShob5gPZpqGhgN/7H2rTSVr84OhLSFk8It1RDEABvRJ/Wqho4hYpMQ==","pi_v":{"c":"DqjqxudiEEuCoJhv8MiVht2/u30CiM5rLwKtbabGcZU=","rm":"CrTepSf2RUVxAwp2s6/aL7bAtQc3Dnm0JIX/5fMxFiY=","rr":"WvEtYhUN5blxdOvGq0D8mZCOCrdI+WEMKLqxD66Jn7E="},"sigma_prime":{"h_prime":"Axl2kddFpvkI72HODi/xGZEJU+nTMWSfnDk4AD02FfKU4c0lUi+xi27/lndBQFfJGw==","s_prime":"AgQZlr5s05CMVeIwzcvZQolMCmsjI0pv5FXVGbpPyANpWt01aNG2jF1awG8Q3DAhKQ=="}},"ecdh_signature":{"r":"d2tYw0FFyVU7UjX+IRpiN8SLkLR4S8bYZmCwI2rzurI=","s":"c2WtqHdx9a/2r4aJuZfACHxGCkgGeQpzHZUttAx+VFQ="},"eddsa_signature":"4SvE9ari9BUvBgxiUJDzqpjTuogXJ8F42qc9rXYHgGXADjspjW9r6SJfG1VW8pxm7yjKSmEUPbv5CxKMjKemGD88","es256_signature":"bRd93MYGuiVye/3QVLtvyxGmyGejx/HXQcC+z3m/PtjyOX+wkgvZn+MpBgUZe4fvoPsj0tSkvK5VKz6zlGFgDw==","ethereum_signature":"0x904a3a6e4b685f93cf65f700493397cc35f1783beac55f29bcd903fa4d28975903fee504b28c64588df6182af8e6994499b1aea202287198f6a94a973ce6829a1b","json":{"simple_array":["hello","world"],"simple_dictionary":{"hello":"world"},"simple_message":"hello world"}}'
}

@test "Everyone that has the did document can now verify the signatures or the proof" {
    cat <<EOF | zexe verify_signatures.zen accepted_did_document.json sign_and_proof.json
Scenario 'w3c': did document
Scenario 'ecdh': verify sign
Scenario 'eddsa': verify sign
Scenario 'ethereum': verify sign
Scenario 'reflow': verify sign
Scenario 'credential': verify sign
Scenario 'bbs': verify sign
Scenario 'es256': verify sign

# load did document and signatures
Given I have a 'did document'
and I have a 'ecdh signature'
and I have a 'eddsa signature'
and I have a 'ethereum signature'
# and I have a 'reflow signature'
and I have a 'bbs signature'
and I have a 'es256 signature'
and I have a 'string dictionary' named 'json'
and I have a 'string' named 'simple message' in 'json'

# proof
Given and I have a 'credential proof'

# Here I retrieve all the public keys/address from
# the verififcationMethod
When I create the verificationMethod of 'did document'

# Here I use the publc keys to verify the sgnatures

When I pickup from path 'verificationMethod.ecdh_public_key'
When I verify the 'json' has a ecdh signature in 'ecdh signature' by 'ecdh public key'

When I pickup from path 'verificationMethod.eddsa_public_key'
When I verify the 'json' has a eddsa signature in 'eddsa signature' by 'eddsa public key'

When I pickup from path 'verificationMethod.ethereum_address'
When I verify the 'simple message' has a ethereum signature in 'ethereum signature' by 'ethereum_address'

When I pickup from path 'verificationMethod.bbs_public_key'
When I verify the 'simple message' has a bbs signature in 'bbs signature' by 'bbs public key'

When I pickup from path 'verificationMethod.es256_public_key'
When I verify the 'json' has a es256 signature in 'es256 signature' by 'es256 public key'

When I pickup a 'issuer public key' from path 'verificationMethod.issuer_public_key'
When I aggregate all the issuer public keys
When I verify the credential proof

# verification is succesfull
Then print the string 'signature verified!!!'
EOF
    save_output 'verify_signatures.json'
    assert_output '{"output":["signature_verified!!!"]}'
}

@test "Everyone that has the did document can now verify the signatures or the proof with the other statement" {
    cat <<EOF | zexe verify_signatures.zen accepted_did_document.json sign_and_proof.json
Scenario 'w3c': did document
Scenario 'ecdh': verify sign
Scenario 'eddsa': verify sign
# Scenario 'ethereum': verify sign
Scenario 'reflow': verify sign
Scenario 'credential': verify sign
Scenario 'bbs': verify sign
Scenario 'es256': verify sign

# load did document and signatures
Given I have a 'did document'
and I have a 'ecdh signature'
and I have a 'eddsa signature'
# and I have a 'ethereum signature'
# and I have a 'reflow signature'
and I have a 'bbs signature'
and I have a 'es256 signature'
and I have a 'string dictionary' named 'json'
and I have a 'string' named 'simple message' in 'json'

# proof
Given and I have a 'credential proof'

# Here I use the publc keys to verify the sgnatures

When I create 'ecdh' public key from did document 'did document'
When I verify the 'json' has a ecdh signature in 'ecdh signature' by 'ecdh public key'

When I create 'eddsa' public key from did document 'did document'
When I verify the 'json' has a eddsa signature in 'eddsa signature' by 'eddsa public key'

When I create 'bbs' public key from did document 'did document'
When I verify the 'simple message' has a bbs signature in 'bbs signature' by 'bbs public key'

When I create 'es256' public key from did document 'did document'
When I verify the 'json' has a es256 signature in 'es256 signature' by 'es256 public key'

When I create 'issuer' public key from did document 'did document'
When I aggregate all the issuer public keys
When I verify the credential proof

# verification is succesfull
Then print the string 'signature verified!!!'
EOF
    save_output 'verify_signatures.json'
    assert_output '{"output":["signature_verified!!!"]}'
}
