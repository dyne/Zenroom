load ../bats_setup
load ../bats_zencode
SUBDOC=w3c

@test "Create the keypair" {
    cat <<EOF | zexe W3C-VC_keygen.zen
Scenario 'ecdh': Create the keypair
Given that I am known as 'Alice'
When I create the ecdh key
Then print my keyring
EOF
    save_output 'W3C-VC_keypair.json'
    assert_output '{"Alice":{"keyring":{"ecdh":"B4rYTWx6UMbc2YPWRNpl4w2M6gY9jqSa637n8Kr2pPc="}}}'
}

@test "Create the issuer keypair" {
    cat <<EOF | zexe W3C-VC_issuerKeygen.zen
Scenario 'ecdh': Create the keypair
Given that I am known as 'Authority'
When I create the ecdh key
Then print my keyring
EOF
    save_output 'W3C-VC_issuerKeypair.json'
    assert_output '{"Authority":{"keyring":{"ecdh":"B4rYTWx6UMbc2YPWRNpl4w2M6gY9jqSa637n8Kr2pPc="}}}'
}

@test "Publish the public key" {
cat <<EOF | zexe W3C-VC_pubkey.zen W3C-VC_issuerKeypair.json
Scenario 'ecdh': Publish the public key
Given that I am known as 'Authority'
and I have my 'keyring'
When I create the ecdh public key
Then print my 'ecdh public key'
EOF
    save_output 'W3C-VC_pubkey.json'
    assert_output '{"Authority":{"ecdh_public_key":"BHdrWMNBRclVO1I1/iEaYjfEi5C0eEvG2GZgsCNq87qy8feZ74JEvnKK9FC07ThhJ8s4ON2ZQcLJ+8HpWMfKPww="}}'

}

@test "Sign JSON" {
    cat <<EOF | save_asset W3C-VC_unsigned.json
{"my-vc": {
  "@context": [
    "https://www.w3.org/2018/credentials/v1",
    "https://www.w3.org/2018/credentials/examples/v1"
  ],
  "id": "http://example.edu/credentials/1872",
  "type": ["VerifiableCredential", "AlumniCredential"],
  "issuer": "https://example.edu/issuers/565049",
  "issuanceDate": "2010-01-01T19:73:24Z",
  "credentialSubject": {
    "id": "did:example:ebfeb1f712ebc6f1c276e12ec21",
    "alumniOf": {
      "id": "did:example:c276e12ec21ebfeb1f712ebc6f1",
      "name": [{
        "value": "Example University",
        "lang": "en"
      }, {
        "value": "Exemple d'Université",
        "lang": "fr"
      }]
    }
  }
},
"pubkey_url": "https://dyne.org/verification/keys/1"
}
EOF
    cat <<EOF | zexe W3C-VC_sign.zen W3C-VC_unsigned.json W3C-VC_issuerKeypair.json
Scenario 'w3c': sign JSON
Scenario 'ecdh': (required)
Given that I am 'Authority'
Given I have my 'keyring'
Given I have a 'verifiable credential' named 'my-vc'
Given I have a 'string' named 'pubkey url'
When I sign the verifiable credential named 'my-vc'
When I set the verification method in 'my-vc' to 'pubkey url'
Then print 'my-vc' as 'string'
EOF
    save_output 'W3C-VC_signed.json'
# assert_output '{"my-vc":{"@context":["https://www.w3.org/2018/credentials/v1","https://www.w3.org/2018/credentials/examples/v1"],"credentialSubject":{"alumniOf":{"id":"did:example:c276e12ec21ebfeb1f712ebc6f1","name":[{"lang":"en","value":"Example University"},{"lang":"fr","value":"Exemple d\'Université"}]},"id":"did:example:ebfeb1f712ebc6f1c276e12ec21"},"id":"http://example.edu/credentials/1872","issuanceDate":"2010-01-01T19:73:24Z","issuer":"https://example.edu/issuers/565049","proof":{"jws":"eyJhbGciOiJFUzI1NksiLCJiNjQiOnRydWUsImNyaXQiOiJiNjQifQ..d2tYw0FFyVU7UjX-IRpiN8SLkLR4S8bYZmCwI2rzurL4PSg3yTWLzLA5JEW2zWlmz6qMA2MkjmVKbkr5DmMttA","proofPurpose":"authenticate","type":"Zenroom v3.0.0","verificationMethod":"https://dyne.org/verification/keys/1"},"type":["VerifiableCredential","AlumniCredential"]}}'
}

@test "verify signature" {
    cat <<EOF | zexe W3C-VC_verify.zen W3C-VC_signed.json W3C-VC_pubkey.json 
Scenario 'w3c': verify signature 
Scenario 'ecdh': (required)
Given I have a 'ecdh public key' inside 'Authority'
Given I have a 'verifiable credential' named 'my-vc'
When I verify the verifiable credential named 'my-vc'
Then print the string 'W3C CREDENTIAL IS VALID'
EOF
    save_output 'W3C-VC_output.json'
    assert_output '{"output":["W3C_CREDENTIAL_IS_VALID"]}'

}


@test "extract verification method" {
    cat <<EOF | zexe W3C-VC_extract.zen W3C-VC_signed.json 
Scenario 'w3c' : extract verification method
Given I have a 'verifiable credential' named 'my-vc'
When I get the verification method in 'my-vc'
Then print 'verification method' as 'string'
EOF
    save_output 'W3C-VC_extracted_verification_method.json'
    assert_output '{"verification_method":"https://dyne.org/verification/keys/1"}'
}


@test "When I create the jws signature of ''" {
    cat <<EOF | save_asset simple_string.json
{ "simple": "once upon a time... there was a wolf" }
EOF

cat <<EOF | zexe W3C-jws_sign.zen simple_string.json W3C-VC_issuerKeypair.json
Scenario 'w3c': sign JSON
Scenario 'ecdh': (required)
Given that I am 'Authority'
Given I have my 'keyring'
Given I have a 'string' named 'simple'
When I create the jws signature of 'simple'
Then print the 'jws'
and print the 'simple'
EOF
    save_output 'W3C-jws_signed.json'
    assert_output '{"jws":"eyJhbGciOiJFUzI1NksiLCJiNjQiOnRydWUsImNyaXQiOiJiNjQifQ..d2tYw0FFyVU7UjX-IRpiN8SLkLR4S8bYZmCwI2rzurJTP4L6hseBhAMa0UR05xHREChrzQeeTAhRh9sWQX1Hwg","simple":"once upon a time... there was a wolf"}'
}

@test "When I verify the jws signature of ''" {
    cat <<EOF | zexe W3C-jws_verify.zen W3C-jws_signed.json W3C-VC_pubkey.json
Scenario 'w3c': verify signature
Scenario 'ecdh': (required)
Given I have a 'ecdh public key' inside 'Authority'
and I have a 'string' named 'jws'
and I have a 'string' named 'simple'
When I verify the jws signature of 'simple'
Then print the string 'W3C JWS IS VALID'
EOF
    save_output 'W3C-jws_verify.out'
    assert_output '{"output":["W3C_JWS_IS_VALID"]}'


}

@test "When I create the jws signature using the ecdh signature in ''" {
    cat <<EOF | save_asset simple_json.json
{
   "simple": {
      "tale": "once upon a time... there was a wolf",
      "ending": "it didn't went well"
   }
}
EOF

cat <<EOF | zexe W3C-jws__crafted_signature.zen simple_json.json W3C-VC_issuerKeypair.json
Scenario 'w3c': sign JSON
Scenario 'ecdh': (required)
Given that I am 'Authority'
Given I have my 'keyring'
Given I have a 'string dictionary' named 'simple'
When I create the json of 'simple'
and I create the ecdh signature of 'json'
and I create the jws signature using the ecdh signature in 'ecdh signature'
Then print the 'json'
Then print the 'jws'
and print the 'simple'
EOF
    save_output 'W3C-jws_crafter_sigature.json'
cat <<EOF | zexe W3C-jws_crafted_verify.zen W3C-jws_crafter_sigature.json W3C-VC_pubkey.json
Scenario 'w3c': verify signature
Scenario 'ecdh': (required)
Given I have a 'ecdh public key' inside 'Authority'
and I have a 'string' named 'jws'
and I have a 'string dictionary' named 'simple'
When I verify the jws signature of 'simple'
Then print the string 'W3C JWS IS VALID'
EOF
    save_output 'W3C-jws_crafted_verify.out'
    assert_output '{"output":["W3C_JWS_IS_VALID"]}'
}

@test "reading did documents" {
    cat <<EOF | save_asset did_document.json
{
   "did document":{
      "@context":[
         "https://www.w3.org/ns/did/v1",
         "https://w3id.org/security/suites/ed25519-2018/v1",
         "https://w3id.org/security/suites/secp256k1-2019/v1",
         "https://w3id.org/security/suites/secp256k1-2020/v1",
         "https://dyne.github.io/W3C-DID/specs/ReflowBLS12381.json",
         {
            "Country":"https://schema.org/Country",
            "State":"https://schema.org/State",
            "description":"https://schema.org/description",
            "url":"https://schema.org/url"
         }
      ],
      "Country":"de",
      "State":"NONE",
      "alsoKnownAs": "did:dyne:ganache:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK",
      "description":"restroom-mw",
      "id": "did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK",
      "service":[
         {
            "id":"did:dyne:zenswarm-api#zenswarm-oracle-announce",
            "serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-announce",
            "type":"LinkedDomains"
         },
         {
            "id":"did:dyne:zenswarm-api#ethereum-to-ethereum-notarization.chain",
            "serviceEndpoint":"http://172.104.233.185:28634/api/ethereum-to-ethereum-notarization.chain",
            "type":"LinkedDomains"
         },
         {
            "id":"did:dyne:zenswarm-api#zenswarm-oracle-get-identity",
            "serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-get-identity",
            "type":"LinkedDomains"
         },
         {
            "id":"did:dyne:zenswarm-api#zenswarm-oracle-http-post",
            "serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-http-post",
            "type":"LinkedDomains"
         },
         {
            "id":"did:dyne:zenswarm-api#zenswarm-oracle-key-issuance.chain",
            "serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-key-issuance.chain",
            "type":"LinkedDomains"
         },
         {
            "id":"did:dyne:zenswarm-api#zenswarm-oracle-ping.zen",
            "serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-ping.zen",
            "type":"LinkedDomains"
         },
         {
            "id":"did:dyne:zenswarm-api#sawroom-to-ethereum-notarization.chain",
            "serviceEndpoint":"http://172.104.233.185:28634/api/sawroom-to-ethereum-notarization.chain",
            "type":"LinkedDomains"
         },
         {
            "id":"did:dyne:zenswarm-api#zenswarm-oracle-get-timestamp.zen",
            "serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-get-timestamp.zen",
            "type":"LinkedDomains"
         },
         {
            "id":"did:dyne:zenswarm-api#zenswarm-oracle-update",
            "serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-update",
            "type":"LinkedDomains"
         }
      ],
      "url":"https://swarm2.dyne.org:20004",
      "verificationMethod": [
         {
            "controller": "did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK",
            "id": "did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#ecdh_public_key",
            "publicKeyBase58": "SJ3uY8Y5cKYsMqqvW3rZaX7h4s1ms5NpAYeHUi16A7jHMVtwSF3Gdzafh9XmvGz6uNksBnaU5fvarDw1mZF2Nkjz",
            "type": "EcdsaSecp256k1VerificationKey2019"
         },
         {
            "controller": "did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK",
            "id": "did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#reflow_public_key",
            "publicKeyBase58": "3LfL2v8qz2cmgy8LRqLPL4H12mt2rW3p7hrwJ6q1gqpHKyXWovkCutsJRsLxkrgHwQ233gouwWFmzshS5EnK9dah92855jzaqV4fD53svqLBrxdV2nt44aEMuWoXYSwA4dmTwHXpgsyQuCsn6uNewbF5VLcesqJubzHf4XvVF9249F1HVLmMR7oCKVBnCw3pTB2HrcmSJaSdKu88rJbzELTvdMLbXXyEcCvYDT3HhzGXNv9BBTo9ZXQGw1CSCCyDrCNMYe",
            "type": "ReflowBLS12381VerificationKey"
         },
         {
            "controller": "did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK",
            "id": "did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#bitcoin_public_key",
            "publicKeyBase58": "24FWY6sMx2MvH1EEoncuWr4dh4NJ7Pmo5WDNst4oztg7s",
            "type": "EcdsaSecp256k1VerificationKey2019"
         },
         {
            "controller": "did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK",
            "id": "did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#eddsa_public_key",
            "publicKeyBase58": "2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK",
            "type": "Ed25519VerificationKey2018"
         },
         {
            "blockchainAccountId": "eip155:1717658228:0x747846c15dfc79803265f953d003ac4251867cd7",
            "controller": "did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK",
            "id": "did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#ethereum_address",
            "type": "EcdsaSecp256k1RecoveryMethod2020"
         }
      ]
   }
}
EOF


    cat <<EOF | zexe did_document.zen did_document.json
Scenario 'w3c': did document manipulation

Given I have a 'did document'

When I create the verificationMethod of 'did document'
When I create the serviceEndpoint of 'did document'

Then print the 'verificationMethod'
Then print the 'serviceEndpoint'
Then print the 'did document'
EOF
    save_output 'did_document.out'
    assert_output '{"did_document":{"@context":["https://www.w3.org/ns/did/v1","https://w3id.org/security/suites/ed25519-2018/v1","https://w3id.org/security/suites/secp256k1-2019/v1","https://w3id.org/security/suites/secp256k1-2020/v1","https://dyne.github.io/W3C-DID/specs/ReflowBLS12381.json",{"Country":"https://schema.org/Country","State":"https://schema.org/State","description":"https://schema.org/description","url":"https://schema.org/url"}],"Country":"de","State":"NONE","alsoKnownAs":"did:dyne:ganache:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","description":"restroom-mw","id":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","service":[{"id":"did:dyne:zenswarm-api#zenswarm-oracle-announce","serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-announce","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#ethereum-to-ethereum-notarization.chain","serviceEndpoint":"http://172.104.233.185:28634/api/ethereum-to-ethereum-notarization.chain","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-get-identity","serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-get-identity","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-http-post","serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-http-post","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-key-issuance.chain","serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-key-issuance.chain","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-ping.zen","serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-ping.zen","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#sawroom-to-ethereum-notarization.chain","serviceEndpoint":"http://172.104.233.185:28634/api/sawroom-to-ethereum-notarization.chain","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-get-timestamp.zen","serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-get-timestamp.zen","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-update","serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-update","type":"LinkedDomains"}],"url":"https://swarm2.dyne.org:20004","verificationMethod":[{"controller":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","id":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#ecdh_public_key","publicKeyBase58":"SJ3uY8Y5cKYsMqqvW3rZaX7h4s1ms5NpAYeHUi16A7jHMVtwSF3Gdzafh9XmvGz6uNksBnaU5fvarDw1mZF2Nkjz","type":"EcdsaSecp256k1VerificationKey2019"},{"controller":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","id":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#reflow_public_key","publicKeyBase58":"3LfL2v8qz2cmgy8LRqLPL4H12mt2rW3p7hrwJ6q1gqpHKyXWovkCutsJRsLxkrgHwQ233gouwWFmzshS5EnK9dah92855jzaqV4fD53svqLBrxdV2nt44aEMuWoXYSwA4dmTwHXpgsyQuCsn6uNewbF5VLcesqJubzHf4XvVF9249F1HVLmMR7oCKVBnCw3pTB2HrcmSJaSdKu88rJbzELTvdMLbXXyEcCvYDT3HhzGXNv9BBTo9ZXQGw1CSCCyDrCNMYe","type":"ReflowBLS12381VerificationKey"},{"controller":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","id":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#bitcoin_public_key","publicKeyBase58":"24FWY6sMx2MvH1EEoncuWr4dh4NJ7Pmo5WDNst4oztg7s","type":"EcdsaSecp256k1VerificationKey2019"},{"controller":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","id":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#eddsa_public_key","publicKeyBase58":"2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","type":"Ed25519VerificationKey2018"},{"blockchainAccountId":"eip155:1717658228:0x747846c15dfc79803265f953d003ac4251867cd7","controller":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","id":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#ethereum_address","type":"EcdsaSecp256k1RecoveryMethod2020"}]},"serviceEndpoint":{"ethereum-to-ethereum-notarization.chain":"http://172.104.233.185:28634/api/ethereum-to-ethereum-notarization.chain","sawroom-to-ethereum-notarization.chain":"http://172.104.233.185:28634/api/sawroom-to-ethereum-notarization.chain","zenswarm-oracle-announce":"http://172.104.233.185:28634/api/zenswarm-oracle-announce","zenswarm-oracle-get-identity":"http://172.104.233.185:28634/api/zenswarm-oracle-get-identity","zenswarm-oracle-get-timestamp.zen":"http://172.104.233.185:28634/api/zenswarm-oracle-get-timestamp.zen","zenswarm-oracle-http-post":"http://172.104.233.185:28634/api/zenswarm-oracle-http-post","zenswarm-oracle-key-issuance.chain":"http://172.104.233.185:28634/api/zenswarm-oracle-key-issuance.chain","zenswarm-oracle-ping.zen":"http://172.104.233.185:28634/api/zenswarm-oracle-ping.zen","zenswarm-oracle-update":"http://172.104.233.185:28634/api/zenswarm-oracle-update"},"verificationMethod":{"bitcoin_public_key":"A44Qbji6hIYanQsVMuVLeCv/8YZ+FqeIclcu0L8wrhmS","ecdh_public_key":"BPEg2X6/Y+68oolE6ocCPDlLWQZLqdaBV00d/jJ5f0dRNQNBUcIh/JHGgfDotpM4p682MPZ5PKoC3vsjhI88OeE=","eddsa_public_key":"2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","ethereum_address":"747846c15dfc79803265f953d003ac4251867cd7","reflow_public_key":"BHc+xaGc6KB+HpqNzQF9JJz4ih8TPsArOlListFLsUCmBfw7VnCY1alv4DO5tTKLF+UQZ0L0NT9usLNR1+Uizj1f0GumXOnpg1Iz4mS6dc6tCtAlWtv74zPpeBvKK71NBaqLCk1uWTKwwTH6Sg+sIxh31Hd1csQP8zxtpQOBeR5LFRJQH6uZNd8qTF+IPHLvBtnayRv+4wGxtHhBSEJU50hMzkQUVza/tmE20Z+8yQDrDOghrBi40C4m/rZoTEKT"}}'
}

@test "Sign did document" {
cat <<EOF | zexe did_document-jws_sign.zen did_document.json W3C-VC_issuerKeypair.json
Scenario 'w3c': sign JSON
Scenario 'ecdh': (required)
Given that I am 'Authority'
Given I have my 'keyring'
Given I have a 'string dictionary' named 'did document'

When I create the jws signature of 'did document'
When I create the 'string dictionary' named 'proof'
When I insert 'jws' in 'proof'
When I insert 'proof' in 'did document'

Then print the 'did document'
EOF
    save_output 'did_document_signed.json'
}

@test "Verify did document" {
    cat <<EOF | zexe did_document-jws_verify.zen did_document_signed.json W3C-VC_pubkey.json
Scenario 'w3c': verify signature
Scenario 'ecdh': (required)
Given I have a 'ecdh public key' inside 'Authority'
and I have a 'string dictionary' named 'did document'

When I verify the did document named 'did document'

Then print the string 'W3C JWS IS VALID'
EOF
    save_output 'did_document-jws_verify.out'
    assert_output '{"output":["W3C_JWS_IS_VALID"]}'
}

@test "Create JSON" {
    cat <<EOF | zexe did_document.zen did_document.json
Scenario 'w3c': did document manipulation

Given I have a 'did document'
When I create the json of 'did document'
Then print data

EOF
    save_output 'did_document.out'
    assert_output '{"did_document":{"@context":["https://www.w3.org/ns/did/v1","https://w3id.org/security/suites/ed25519-2018/v1","https://w3id.org/security/suites/secp256k1-2019/v1","https://w3id.org/security/suites/secp256k1-2020/v1","https://dyne.github.io/W3C-DID/specs/ReflowBLS12381.json",{"Country":"https://schema.org/Country","State":"https://schema.org/State","description":"https://schema.org/description","url":"https://schema.org/url"}],"Country":"de","State":"NONE","alsoKnownAs":"did:dyne:ganache:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","description":"restroom-mw","id":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","service":[{"id":"did:dyne:zenswarm-api#zenswarm-oracle-announce","serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-announce","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#ethereum-to-ethereum-notarization.chain","serviceEndpoint":"http://172.104.233.185:28634/api/ethereum-to-ethereum-notarization.chain","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-get-identity","serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-get-identity","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-http-post","serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-http-post","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-key-issuance.chain","serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-key-issuance.chain","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-ping.zen","serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-ping.zen","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#sawroom-to-ethereum-notarization.chain","serviceEndpoint":"http://172.104.233.185:28634/api/sawroom-to-ethereum-notarization.chain","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-get-timestamp.zen","serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-get-timestamp.zen","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-update","serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-update","type":"LinkedDomains"}],"url":"https://swarm2.dyne.org:20004","verificationMethod":[{"controller":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","id":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#ecdh_public_key","publicKeyBase58":"SJ3uY8Y5cKYsMqqvW3rZaX7h4s1ms5NpAYeHUi16A7jHMVtwSF3Gdzafh9XmvGz6uNksBnaU5fvarDw1mZF2Nkjz","type":"EcdsaSecp256k1VerificationKey2019"},{"controller":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","id":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#reflow_public_key","publicKeyBase58":"3LfL2v8qz2cmgy8LRqLPL4H12mt2rW3p7hrwJ6q1gqpHKyXWovkCutsJRsLxkrgHwQ233gouwWFmzshS5EnK9dah92855jzaqV4fD53svqLBrxdV2nt44aEMuWoXYSwA4dmTwHXpgsyQuCsn6uNewbF5VLcesqJubzHf4XvVF9249F1HVLmMR7oCKVBnCw3pTB2HrcmSJaSdKu88rJbzELTvdMLbXXyEcCvYDT3HhzGXNv9BBTo9ZXQGw1CSCCyDrCNMYe","type":"ReflowBLS12381VerificationKey"},{"controller":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","id":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#bitcoin_public_key","publicKeyBase58":"24FWY6sMx2MvH1EEoncuWr4dh4NJ7Pmo5WDNst4oztg7s","type":"EcdsaSecp256k1VerificationKey2019"},{"controller":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","id":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#eddsa_public_key","publicKeyBase58":"2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","type":"Ed25519VerificationKey2018"},{"blockchainAccountId":"eip155:1717658228:0x747846c15dfc79803265f953d003ac4251867cd7","controller":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","id":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#ethereum_address","type":"EcdsaSecp256k1RecoveryMethod2020"}]},"json":"{\"@context\":[\"https://www.w3.org/ns/did/v1\",\"https://w3id.org/security/suites/ed25519-2018/v1\",\"https://w3id.org/security/suites/secp256k1-2019/v1\",\"https://w3id.org/security/suites/secp256k1-2020/v1\",\"https://dyne.github.io/W3C-DID/specs/ReflowBLS12381.json\",{\"Country\":\"https://schema.org/Country\",\"State\":\"https://schema.org/State\",\"description\":\"https://schema.org/description\",\"url\":\"https://schema.org/url\"}],\"Country\":\"de\",\"State\":\"NONE\",\"alsoKnownAs\":\"did:dyne:ganache:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK\",\"description\":\"restroom-mw\",\"id\":\"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK\",\"service\":[{\"id\":\"did:dyne:zenswarm-api#zenswarm-oracle-announce\",\"serviceEndpoint\":\"http://172.104.233.185:28634/api/zenswarm-oracle-announce\",\"type\":\"LinkedDomains\"},{\"id\":\"did:dyne:zenswarm-api#ethereum-to-ethereum-notarization.chain\",\"serviceEndpoint\":\"http://172.104.233.185:28634/api/ethereum-to-ethereum-notarization.chain\",\"type\":\"LinkedDomains\"},{\"id\":\"did:dyne:zenswarm-api#zenswarm-oracle-get-identity\",\"serviceEndpoint\":\"http://172.104.233.185:28634/api/zenswarm-oracle-get-identity\",\"type\":\"LinkedDomains\"},{\"id\":\"did:dyne:zenswarm-api#zenswarm-oracle-http-post\",\"serviceEndpoint\":\"http://172.104.233.185:28634/api/zenswarm-oracle-http-post\",\"type\":\"LinkedDomains\"},{\"id\":\"did:dyne:zenswarm-api#zenswarm-oracle-key-issuance.chain\",\"serviceEndpoint\":\"http://172.104.233.185:28634/api/zenswarm-oracle-key-issuance.chain\",\"type\":\"LinkedDomains\"},{\"id\":\"did:dyne:zenswarm-api#zenswarm-oracle-ping.zen\",\"serviceEndpoint\":\"http://172.104.233.185:28634/api/zenswarm-oracle-ping.zen\",\"type\":\"LinkedDomains\"},{\"id\":\"did:dyne:zenswarm-api#sawroom-to-ethereum-notarization.chain\",\"serviceEndpoint\":\"http://172.104.233.185:28634/api/sawroom-to-ethereum-notarization.chain\",\"type\":\"LinkedDomains\"},{\"id\":\"did:dyne:zenswarm-api#zenswarm-oracle-get-timestamp.zen\",\"serviceEndpoint\":\"http://172.104.233.185:28634/api/zenswarm-oracle-get-timestamp.zen\",\"type\":\"LinkedDomains\"},{\"id\":\"did:dyne:zenswarm-api#zenswarm-oracle-update\",\"serviceEndpoint\":\"http://172.104.233.185:28634/api/zenswarm-oracle-update\",\"type\":\"LinkedDomains\"}],\"url\":\"https://swarm2.dyne.org:20004\",\"verificationMethod\":[{\"controller\":\"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK\",\"id\":\"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#ecdh_public_key\",\"publicKeyBase58\":\"SJ3uY8Y5cKYsMqqvW3rZaX7h4s1ms5NpAYeHUi16A7jHMVtwSF3Gdzafh9XmvGz6uNksBnaU5fvarDw1mZF2Nkjz\",\"type\":\"EcdsaSecp256k1VerificationKey2019\"},{\"controller\":\"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK\",\"id\":\"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#reflow_public_key\",\"publicKeyBase58\":\"3LfL2v8qz2cmgy8LRqLPL4H12mt2rW3p7hrwJ6q1gqpHKyXWovkCutsJRsLxkrgHwQ233gouwWFmzshS5EnK9dah92855jzaqV4fD53svqLBrxdV2nt44aEMuWoXYSwA4dmTwHXpgsyQuCsn6uNewbF5VLcesqJubzHf4XvVF9249F1HVLmMR7oCKVBnCw3pTB2HrcmSJaSdKu88rJbzELTvdMLbXXyEcCvYDT3HhzGXNv9BBTo9ZXQGw1CSCCyDrCNMYe\",\"type\":\"ReflowBLS12381VerificationKey\"},{\"controller\":\"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK\",\"id\":\"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#bitcoin_public_key\",\"publicKeyBase58\":\"24FWY6sMx2MvH1EEoncuWr4dh4NJ7Pmo5WDNst4oztg7s\",\"type\":\"EcdsaSecp256k1VerificationKey2019\"},{\"controller\":\"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK\",\"id\":\"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#eddsa_public_key\",\"publicKeyBase58\":\"2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK\",\"type\":\"Ed25519VerificationKey2018\"},{\"blockchainAccountId\":\"eip155:1717658228:0x747846c15dfc79803265f953d003ac4251867cd7\",\"controller\":\"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK\",\"id\":\"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#ethereum_address\",\"type\":\"EcdsaSecp256k1RecoveryMethod2020\"}]}"}'
}

@test "parsing did documents ids" {
    # scheme must be 'did'
    cat <<EOF > invalid_scheme.json
{
   "did document":{
      "@context":[
         "https://www.w3.org/ns/did/v1"
      ],
      "id": "DiD:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK"
   }
}
EOF
    # only lowercase char and digits are allowed in method name
    cat <<EOF > invalid_method_name.json
{
   "did document":{
      "@context":[
         "https://www.w3.org/ns/did/v1"
      ],
      "id": "did:Dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK"
   }
}
EOF
    # * not allowed
    cat <<EOF > invalid_method_specific_identifier.json
{
   "did document":{
      "@context":[
         "https://www.w3.org/ns/did/v1"
      ],
      "id": "did:dyne:zenflows:2s5wmQjZeYtpckyHakLi*P5ujWKDL1M2b8CiP6vwajNrK"
   }
}
EOF
    # % only allowed if followed by 2 HEXDIG
    cat <<EOF > invalid_method_specific_identifier2.json
{
   "did document":{
      "@context":[
         "https://www.w3.org/ns/did/v1"
      ],
      "id": "did:dyne:zenflows:2s5wmQjZeYtpckyHakLi%9zP5ujWKDL1M2b8CiP6vwajNrK"
   }
}
EOF
    # scheme: did
    # method name: a-z/0-9
    # method specific identifier: a-z/A-Z/0-9/"."/"-"/"_"/"%" HEXDIG HEXDIG
    cat <<EOF > valid_id.json
{
   "did document":{
      "@context":[
         "https://www.w3.org/ns/did/v1"
      ],
      "id": "did:0d1y2n3e4:1.ze_n-fl4.o%0Aws:...2s5wm---QjZeYtpcky111HakLiP%9B5ujWKDL1M2..b18CiP6vwajNrK"
   }
}
EOF

    cat <<EOF > did_document_parsing.zen
Scenario 'w3c': did document
Given I have a 'did document'
Then print the 'did document'
EOF
    run $ZENROOM_EXECUTABLE -a invalid_scheme.json -z did_document_parsing.zen
    assert_failure
    run $ZENROOM_EXECUTABLE -a invalid_method_name.json -z did_document_parsing.zen
    assert_failure
    run $ZENROOM_EXECUTABLE -a invalid_method_specific_identifier.json -z did_document_parsing.zen
    assert_failure
    run $ZENROOM_EXECUTABLE -a invalid_method_specific_identifier2.json -z did_document_parsing.zen
    assert_failure
    run $ZENROOM_EXECUTABLE -a valid_id.json -z did_document_parsing.zen
    assert_success
}

@test "create the 'public key' from 'did document'" {
    cat <<EOF > did_document.json
    {
    "didDocument":{
      "@context":[
         "https://www.w3.org/ns/did/v1",
         "https://w3id.org/security/suites/ed25519-2018/v1",
         "https://w3id.org/security/suites/secp256k1-2019/v1",
         "https://w3id.org/security/suites/secp256k1-2020/v1",
         "https://dyne.github.io/W3C-DID/specs/ReflowBLS12381.json",
         {
            "description":"https://schema.org/description"
         }
      ],
      "description":"fake sandbox-admin",
      "id":"did:dyne:sandbox.A:8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ",
      "verificationMethod":[
         {
            "controller":"did:dyne:sandbox.A:8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ",
            "id":"did:dyne:sandbox.A:8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ#ecdh_public_key",
            "publicKeyBase58":"S1bs1YRaGcfeUjAQh3jigvAXuV8bff2AHjERoHaBPKtBLnXLKDcGPrnB4j5bY8ZHVu9fQGkUW5XzDa9bdhGYbjPf",
            "type":"EcdsaSecp256k1VerificationKey2019"
         },
         {
            "controller":"did:dyne:sandbox.A:8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ",
            "id":"did:dyne:sandbox.A:8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ#reflow_public_key",
            "publicKeyBase58":"9kPV92zSUok2Do2RJKx3Zn7ZY9WScvBZoorMQ8FRcoH7m1eo3mAuGJcrSpaw1YrSKeqAhJnpcFdQjLhTBEve3qvwGe7qZsam3kLo85CpTM84TaEnxVyaTZVYxuY4ytmGX2Yz1scayfSdJYASvn9z12VnmC8xM3D1cXMHNDN5zMkLZ29hgq631ssT55UQif6Pj371HUC5g6u2xYQ2mGYiQ6bQt1NWSMJDzzKTr9y7bEMPKq5bDfYEBab6a4fzk6Aqixr1P3",
            "type":"ReflowBLS12381VerificationKey"
         },
         {
            "controller":"did:dyne:sandbox.A:8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ",
            "id":"did:dyne:sandbox.A:8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ#bitcoin_public_key",
            "publicKeyBase58":"rjXTCrGHFMtQhfnPMZz5rak6DDAtavVTrv2AEMXvZSBj",
            "type":"EcdsaSecp256k1VerificationKey2019"
         },
         {
            "controller":"did:dyne:sandbox.A:8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ",
            "id":"did:dyne:sandbox.A:8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ#eddsa_public_key",
            "publicKeyBase58":"8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ",
            "type":"Ed25519VerificationKey2018"
         },
         {
            "blockchainAccountId":"eip155:1:0xd3765bb6f5917d1a91adebadcfad6c248e721294",
            "controller":"did:dyne:sandbox.A:8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ",
            "id":"did:dyne:sandbox.A:8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ#ethereum_address",
            "type":"EcdsaSecp256k1RecoveryMethod2020"
         }
      ]
    }
}
EOF
    cat <<EOF | zexe pk_from_doc.zen did_document.json
Scenario 'w3c': did document manipulation
Scenario 'ecdh': ecdh pk
Scenario 'eddsa': eddsa pk
Scenario 'reflow': reflow pk
Scenario 'ethereum': ethereum add

Given I have a 'did document' named 'didDocument'

When I create the 'ecdh' public key from did document 'didDocument'
When I create the 'reflow' public key from did document 'didDocument'
When I create the 'bitcoin' public key from did document 'didDocument'
When I create the 'eddsa' public key from did document 'didDocument'

When I remove 'didDocument'

Then print the data
EOF
    save_output pk_from_doc.json
    assert_output '{"bitcoin_public_key":"AuLxfD6ec7hwAwX2TmHiZJa/+vfGxA+BCiVEjLh0X/GC","ecdh_public_key":"BOLxfD6ec7hwAwX2TmHiZJa/+vfGxA+BCiVEjLh0X/GCXfYCH39vIGurbqpW2SzIQQ/6wkBpNCwaJio73SP3eao=","eddsa_public_key":"8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ","reflow_public_key":"ELPfkkW1UMdCeN6Q/e58J0C9CFAVZ/H5S+RBZpTK5i4QY7QSo4+dz21VQhuuOY9/CBMvYX8rdLldfJ6QaWZe7J9D7Ut9r01YZ6Do7cleVHLp77Z4jr/UyqNCi12xofzLBCpA6vJUd+udreSzKtomYxd0M/XzqUbd96v5Nc0SEsb3UxusIQyMDp0hG1eYw28UDcCaV6yYKZFM4pb2p571+aGNt9ziupy9ZydgxuKx5245jCw8CNoHBbgn+XwrwP02"}'

cat <<EOF > pk_from_doc_not_exist.zen
Scenario 'w3c': did document manipulation
Scenario 'schnorr': schnorr pk

Given I have a 'did document' named 'didDocument'

When I create the 'schnorr' public key from did document 'didDocument'

Then print the data
EOF
    run $ZENROOM_EXECUTABLE -a did_document.json -z pk_from_doc_not_exist.zen
    assert_failure
}

@test "verify the did document named 'did_document' is signed by 'signer_did_document'" {
    cat <<EOF > did_documents.json
    {
    "did_document":{
      "@context":[
         "https://www.w3.org/ns/did/v1",
         "https://w3id.org/security/suites/ed25519-2018/v1",
         "https://w3id.org/security/suites/secp256k1-2019/v1",
         "https://w3id.org/security/suites/secp256k1-2020/v1",
         "https://dyne.github.io/W3C-DID/specs/ReflowBLS12381.json",
         {
            "description":"https://schema.org/description"
         }
      ],
      "description":"fake sandbox-admin",
      "id":"did:dyne:sandbox.A:8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ",
      "proof": {
         "created": "1671805668826",
         "jws": "eyJhbGciOiJFUzI1NksiLCJiNjQiOnRydWUsImNyaXQiOiJiNjQifQ..0RywWwpi-26gwNhPC4lBcTce80WMDDygtlYu8EzyXa-PZRrG64Bt46z-wp_QXhF-FIbtgf_zfIVHDBeR7sPGGw",
         "proofPurpose": "assertionMethod",
         "type": "EcdsaSecp256k1Signature2019",
         "verificationMethod": "did:dyne:admin:DMMYfDo7VpvKRHoJmiXvEpXrfbW3sCfhUBE4tBeXmNrJ#ecdh_public_key"
       },
      "verificationMethod":[
         {
            "controller":"did:dyne:sandbox.A:8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ",
            "id":"did:dyne:sandbox.A:8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ#ecdh_public_key",
            "publicKeyBase58":"S1bs1YRaGcfeUjAQh3jigvAXuV8bff2AHjERoHaBPKtBLnXLKDcGPrnB4j5bY8ZHVu9fQGkUW5XzDa9bdhGYbjPf",
            "type":"EcdsaSecp256k1VerificationKey2019"
         },
         {
            "controller":"did:dyne:sandbox.A:8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ",
            "id":"did:dyne:sandbox.A:8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ#reflow_public_key",
            "publicKeyBase58":"9kPV92zSUok2Do2RJKx3Zn7ZY9WScvBZoorMQ8FRcoH7m1eo3mAuGJcrSpaw1YrSKeqAhJnpcFdQjLhTBEve3qvwGe7qZsam3kLo85CpTM84TaEnxVyaTZVYxuY4ytmGX2Yz1scayfSdJYASvn9z12VnmC8xM3D1cXMHNDN5zMkLZ29hgq631ssT55UQif6Pj371HUC5g6u2xYQ2mGYiQ6bQt1NWSMJDzzKTr9y7bEMPKq5bDfYEBab6a4fzk6Aqixr1P3",
            "type":"ReflowBLS12381VerificationKey"
         },
         {
            "controller":"did:dyne:sandbox.A:8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ",
            "id":"did:dyne:sandbox.A:8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ#bitcoin_public_key",
            "publicKeyBase58":"rjXTCrGHFMtQhfnPMZz5rak6DDAtavVTrv2AEMXvZSBj",
            "type":"EcdsaSecp256k1VerificationKey2019"
         },
         {
            "controller":"did:dyne:sandbox.A:8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ",
            "id":"did:dyne:sandbox.A:8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ#eddsa_public_key",
            "publicKeyBase58":"8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ",
            "type":"Ed25519VerificationKey2018"
         },
         {
            "blockchainAccountId":"eip155:1:0xd3765bb6f5917d1a91adebadcfad6c248e721294",
            "controller":"did:dyne:sandbox.A:8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ",
            "id":"did:dyne:sandbox.A:8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ#ethereum_address",
            "type":"EcdsaSecp256k1RecoveryMethod2020"
         }
      ]
   },
   "signer_did_document":{
      "@context":[
         "https://www.w3.org/ns/did/v1",
         "https://w3id.org/security/suites/ed25519-2018/v1",
         "https://w3id.org/security/suites/secp256k1-2019/v1",
         "https://w3id.org/security/suites/secp256k1-2020/v1",
         "https://dyne.github.io/W3C-DID/specs/ReflowBLS12381.json",
         {
            "description":"https://schema.org/description"
         }
      ],
      "description":"did dyne admin",
      "id":"did:dyne:admin:DMMYfDo7VpvKRHoJmiXvEpXrfbW3sCfhUBE4tBeXmNrJ",
      "proof": {
         "created": "1671805540866",
         "jws": "eyJhbGciOiJFUzI1NksiLCJiNjQiOnRydWUsImNyaXQiOiJiNjQifQ..c-ZsQNm-thjXJZlUofx67h9IKoLUUBV4piL6_HBPShBoQeYcQbnZmuIYepYYkOdI8VoO9YGJScB0YLhExABO5g",
         "proofPurpose": "assertionMethod",
         "type": "EcdsaSecp256k1Signature2019",
         "verificationMethod": "did:dyne:admin:DMMYfDo7VpvKRHoJmiXvEpXrfbW3sCfhUBE4tBeXmNrJ#ecdh_public_key"
      },
      "verificationMethod":[
         {
            "controller":"did:dyne:admin:DMMYfDo7VpvKRHoJmiXvEpXrfbW3sCfhUBE4tBeXmNrJ",
            "id":"did:dyne:admin:DMMYfDo7VpvKRHoJmiXvEpXrfbW3sCfhUBE4tBeXmNrJ#ecdh_public_key",
            "publicKeyBase58":"RgeFFa3E245tR9fRTzUWDzn7VCX4NZQXuko69JaxPrN3wG59VYkjijzduHi3CBVXGejp5MgBUWPCYgaFmA4YUBGd",
            "type":"EcdsaSecp256k1VerificationKey2019"
         },
         {
            "controller":"did:dyne:admin:DMMYfDo7VpvKRHoJmiXvEpXrfbW3sCfhUBE4tBeXmNrJ",
            "id":"did:dyne:admin:DMMYfDo7VpvKRHoJmiXvEpXrfbW3sCfhUBE4tBeXmNrJ#reflow_public_key",
            "publicKeyBase58":"6haJ6HKw2WKuS6TzbxGyJFvDWwui3fWWchpXjuNhTRiivPGF3FQP4FF1bJBHd3cSsA7cnymmBgwRwLzdkVvTePLXbcje97ZSu1GrvvVYcfEfq5XQHbZFN9ThxUp4VApPMAY8DzufVcLJaMAqP29itvz5gSzXw4WvsJoBgtujBz5b4LT3CgX425CpmyLEwNDgNnhR3vXMxSDT2QxuwtKDAFUHUDCkULDcmFxkox5S2JTWmjEyMpmw97SrXKTcwRQdu9vr2M",
            "type":"ReflowBLS12381VerificationKey"
         },
         {
            "controller":"did:dyne:admin:DMMYfDo7VpvKRHoJmiXvEpXrfbW3sCfhUBE4tBeXmNrJ",
            "id":"did:dyne:admin:DMMYfDo7VpvKRHoJmiXvEpXrfbW3sCfhUBE4tBeXmNrJ#bitcoin_public_key",
            "publicKeyBase58":"yWG2QEZqPeAPez39qZf6vpCkmse8oz4UmhD4nWkyCT13",
            "type":"EcdsaSecp256k1VerificationKey2019"
         },
         {
            "controller":"did:dyne:admin:DMMYfDo7VpvKRHoJmiXvEpXrfbW3sCfhUBE4tBeXmNrJ",
            "id":"did:dyne:admin:DMMYfDo7VpvKRHoJmiXvEpXrfbW3sCfhUBE4tBeXmNrJ#eddsa_public_key",
            "publicKeyBase58":"DMMYfDo7VpvKRHoJmiXvEpXrfbW3sCfhUBE4tBeXmNrJ",
            "type":"Ed25519VerificationKey2018"
         },
         {
            "blockchainAccountId":"eip155:1:0x9a31eb5778e6105a252eee9214767828a72d5672",
            "controller":"did:dyne:admin:DMMYfDo7VpvKRHoJmiXvEpXrfbW3sCfhUBE4tBeXmNrJ",
            "id":"did:dyne:admin:DMMYfDo7VpvKRHoJmiXvEpXrfbW3sCfhUBE4tBeXmNrJ#ethereum_address",
            "type":"EcdsaSecp256k1RecoveryMethod2020"
         }
      ]
   },
   "not_signer_did_document": {
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
      "description": "Alice",
      "id": "did:dyne:sandbox:Vi4hPJiRikEBeB45pdb1FBQSEXmNiPe3CSk24KaGUC2",
      "proof": {
        "created": "1671820405629",
        "jws": "eyJhbGciOiJFUzI1NksiLCJiNjQiOnRydWUsImNyaXQiOiJiNjQifQ..8BAEgVTCR4H_8mzsGg5ty9tEvAByIaJRDk6d-R-d7wWVGcHDNAMUrt5kZ_WkTaSUmku0x8oYLzLXWwV9pmS1JA",
        "proofPurpose": "assertionMethod",
        "type": "EcdsaSecp256k1Signature2019",
        "verificationMethod": "did:dyne:sandbox.A:8REPQXUsFmaN6avGN6aozQtkhLNC9xUmZZNRM7u2UqEZ#ecdh_public_key"
      },
      "verificationMethod": [
        {
          "controller": "did:dyne:sandbox:Vi4hPJiRikEBeB45pdb1FBQSEXmNiPe3CSk24KaGUC2",
          "id": "did:dyne:sandbox:Vi4hPJiRikEBeB45pdb1FBQSEXmNiPe3CSk24KaGUC2#ecdh_public_key",
          "publicKeyBase58": "NSJpR4i2XF5vFRLW1r9V6Qt4q9rsZQDyV34bxdVUovmcR2k6eoQKWvhSFupAy3S7ie9pD74oXECNQauVLfqd2Yow",
          "type": "EcdsaSecp256k1VerificationKey2019"
        },
        {
          "controller": "did:dyne:sandbox:Vi4hPJiRikEBeB45pdb1FBQSEXmNiPe3CSk24KaGUC2",
          "id": "did:dyne:sandbox:Vi4hPJiRikEBeB45pdb1FBQSEXmNiPe3CSk24KaGUC2#reflow_public_key",
          "publicKeyBase58": "4g7G5RJRXiSPytBPPXgYstRMNm4t1tPFD9M99njKW6A2ggJr8N3bJjnML63xVXcMxwBoW3NtuoHeq17tLos88EngBHnfkDPZvPnQ9akC9TbG7u8kPx4YGd15Q7zqcn28PrhA64chMbjxeadXeMJZyfJ18AJMNB8VBWwpNH8GbA9W7Lvd1QkCoGBMSLDMs8zr83sA2NUGVuNYEpTXUccZdDqg4cvUgKb9xEWGJMwio6bmchDfU5Af6hXBBtHMhVoKLXP7WD",
          "type": "ReflowBLS12381VerificationKey"
        },
        {
          "controller": "did:dyne:sandbox:Vi4hPJiRikEBeB45pdb1FBQSEXmNiPe3CSk24KaGUC2",
          "id": "did:dyne:sandbox:Vi4hPJiRikEBeB45pdb1FBQSEXmNiPe3CSk24KaGUC2#bitcoin_public_key",
          "publicKeyBase58": "hQV8K74jNTMvN6mzXRHbgxHxsyGd1VAypqPQbJT4ZPSW",
          "type": "EcdsaSecp256k1VerificationKey2019"
        },
        {
          "controller": "did:dyne:sandbox:Vi4hPJiRikEBeB45pdb1FBQSEXmNiPe3CSk24KaGUC2",
          "id": "did:dyne:sandbox:Vi4hPJiRikEBeB45pdb1FBQSEXmNiPe3CSk24KaGUC2#eddsa_public_key",
          "publicKeyBase58": "Vi4hPJiRikEBeB45pdb1FBQSEXmNiPe3CSk24KaGUC2",
          "type": "Ed25519VerificationKey2018"
        },
        {
          "blockchainAccountId": "eip155:1:0x18ad3e39ee80842982c8a104b3cce8cb8720dd50",
          "controller": "did:dyne:sandbox:Vi4hPJiRikEBeB45pdb1FBQSEXmNiPe3CSk24KaGUC2",
          "id": "did:dyne:sandbox:Vi4hPJiRikEBeB45pdb1FBQSEXmNiPe3CSk24KaGUC2#ethereum_address",
          "type": "EcdsaSecp256k1RecoveryMethod2020"
        }
      ]
    }
}
EOF
    cat <<EOF | zexe verify_did_doc.zen did_documents.json
Scenario 'w3c': did document manipulation
Scenario 'ecdh': ecdh pk

Given I have a 'did document' named 'did_document'
Given I have a 'did document' named 'signer_did_document'

When I verify the did document named 'did_document' is signed by 'signer_did_document'

Then print the string 'did document verified'
EOF
    save_output verify_did_doc.json
    assert_output '{"output":["did_document_verified"]}'

cat <<EOF > verify_wrong_did_doc.zen
Scenario 'w3c': did document manipulation

Given I have a 'did document' named 'did_document'
Given I have a 'did document' named 'not_signer_did_document'

When I verify the did document named 'did_document' is signed by 'not_signer_did_document'

Then print the string 'should not be verified'
EOF
    run $ZENROOM_EXECUTABLE -a did_documents.json -z verify_wrong_did_doc.zen
    assert_failure
}