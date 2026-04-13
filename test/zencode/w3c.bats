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


@test "When I create jws detached signature of header '' and payload ''" {
    cat <<EOF | save_asset simple_string.json
{ "simple": { "simple": "once upon a time... there was a wolf" } }
EOF

cat <<EOF | zexe W3C-jws_sign.zen simple_string.json W3C-VC_issuerKeypair.json
Scenario 'w3c': sign JSON
Scenario 'ecdh': (required)
Given that I am 'Authority'
Given I have my 'keyring'
Given I have a 'string dictionary' named 'simple'
When I create the jws header for 'es256k' signature
When I create jws detached signature of header 'jws header' and payload 'simple'
Then print the 'jws detached signature'
and print the 'simple'
EOF
    save_output 'W3C-jws_signed.json'
    assert_output '{"jws_detached_signature":"eyJhbGciOiJFUzI1NksifQ..d2tYw0FFyVU7UjX-IRpiN8SLkLR4S8bYZmCwI2rzurJjDUpRUUIAZrK5HM4VgPSVGCdQ4-XQWBimu2mPMDmZ6w","simple":{"simple":"once upon a time... there was a wolf"}}'
}

@test "When I verify '' has a jws signature in ''" {
    cat <<EOF | zexe W3C-jws_verify.zen W3C-jws_signed.json W3C-VC_pubkey.json
Scenario 'w3c': verify signature
Scenario 'ecdh': (required)
Given I have a 'ecdh public key' inside 'Authority'
and I have a 'string' named 'jws detached signature'
and I have a 'string dictionary' named 'simple'
When I verify 'simple' has a jws signature in 'jws detached signature'
Then print the string 'W3C JWS IS VALID'
EOF
    save_output 'W3C-jws_verify.out'
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

When I create jws header for 'secp256k1' signature
When I create the jws detached signature of header 'jws header' and payload 'did document'
When I create the 'string dictionary' named 'proof'
When I move 'jws detached signature' to 'jws' in 'proof'
When I move 'proof' in 'did document'

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
When I create the json escaped string of 'did document'
Then print data

EOF
    save_output 'did_document.out'
    assert_output '{"did_document":{"@context":["https://www.w3.org/ns/did/v1","https://w3id.org/security/suites/ed25519-2018/v1","https://w3id.org/security/suites/secp256k1-2019/v1","https://w3id.org/security/suites/secp256k1-2020/v1","https://dyne.github.io/W3C-DID/specs/ReflowBLS12381.json",{"Country":"https://schema.org/Country","State":"https://schema.org/State","description":"https://schema.org/description","url":"https://schema.org/url"}],"Country":"de","State":"NONE","alsoKnownAs":"did:dyne:ganache:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","description":"restroom-mw","id":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","service":[{"id":"did:dyne:zenswarm-api#zenswarm-oracle-announce","serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-announce","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#ethereum-to-ethereum-notarization.chain","serviceEndpoint":"http://172.104.233.185:28634/api/ethereum-to-ethereum-notarization.chain","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-get-identity","serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-get-identity","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-http-post","serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-http-post","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-key-issuance.chain","serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-key-issuance.chain","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-ping.zen","serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-ping.zen","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#sawroom-to-ethereum-notarization.chain","serviceEndpoint":"http://172.104.233.185:28634/api/sawroom-to-ethereum-notarization.chain","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-get-timestamp.zen","serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-get-timestamp.zen","type":"LinkedDomains"},{"id":"did:dyne:zenswarm-api#zenswarm-oracle-update","serviceEndpoint":"http://172.104.233.185:28634/api/zenswarm-oracle-update","type":"LinkedDomains"}],"url":"https://swarm2.dyne.org:20004","verificationMethod":[{"controller":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","id":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#ecdh_public_key","publicKeyBase58":"SJ3uY8Y5cKYsMqqvW3rZaX7h4s1ms5NpAYeHUi16A7jHMVtwSF3Gdzafh9XmvGz6uNksBnaU5fvarDw1mZF2Nkjz","type":"EcdsaSecp256k1VerificationKey2019"},{"controller":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","id":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#reflow_public_key","publicKeyBase58":"3LfL2v8qz2cmgy8LRqLPL4H12mt2rW3p7hrwJ6q1gqpHKyXWovkCutsJRsLxkrgHwQ233gouwWFmzshS5EnK9dah92855jzaqV4fD53svqLBrxdV2nt44aEMuWoXYSwA4dmTwHXpgsyQuCsn6uNewbF5VLcesqJubzHf4XvVF9249F1HVLmMR7oCKVBnCw3pTB2HrcmSJaSdKu88rJbzELTvdMLbXXyEcCvYDT3HhzGXNv9BBTo9ZXQGw1CSCCyDrCNMYe","type":"ReflowBLS12381VerificationKey"},{"controller":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","id":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#bitcoin_public_key","publicKeyBase58":"24FWY6sMx2MvH1EEoncuWr4dh4NJ7Pmo5WDNst4oztg7s","type":"EcdsaSecp256k1VerificationKey2019"},{"controller":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","id":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#eddsa_public_key","publicKeyBase58":"2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","type":"Ed25519VerificationKey2018"},{"blockchainAccountId":"eip155:1717658228:0x747846c15dfc79803265f953d003ac4251867cd7","controller":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK","id":"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#ethereum_address","type":"EcdsaSecp256k1RecoveryMethod2020"}]},"json_escaped_string":"{\"@context\":[\"https://www.w3.org/ns/did/v1\",\"https://w3id.org/security/suites/ed25519-2018/v1\",\"https://w3id.org/security/suites/secp256k1-2019/v1\",\"https://w3id.org/security/suites/secp256k1-2020/v1\",\"https://dyne.github.io/W3C-DID/specs/ReflowBLS12381.json\",{\"Country\":\"https://schema.org/Country\",\"State\":\"https://schema.org/State\",\"description\":\"https://schema.org/description\",\"url\":\"https://schema.org/url\"}],\"Country\":\"de\",\"State\":\"NONE\",\"alsoKnownAs\":\"did:dyne:ganache:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK\",\"description\":\"restroom-mw\",\"id\":\"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK\",\"service\":[{\"id\":\"did:dyne:zenswarm-api#zenswarm-oracle-announce\",\"serviceEndpoint\":\"http://172.104.233.185:28634/api/zenswarm-oracle-announce\",\"type\":\"LinkedDomains\"},{\"id\":\"did:dyne:zenswarm-api#ethereum-to-ethereum-notarization.chain\",\"serviceEndpoint\":\"http://172.104.233.185:28634/api/ethereum-to-ethereum-notarization.chain\",\"type\":\"LinkedDomains\"},{\"id\":\"did:dyne:zenswarm-api#zenswarm-oracle-get-identity\",\"serviceEndpoint\":\"http://172.104.233.185:28634/api/zenswarm-oracle-get-identity\",\"type\":\"LinkedDomains\"},{\"id\":\"did:dyne:zenswarm-api#zenswarm-oracle-http-post\",\"serviceEndpoint\":\"http://172.104.233.185:28634/api/zenswarm-oracle-http-post\",\"type\":\"LinkedDomains\"},{\"id\":\"did:dyne:zenswarm-api#zenswarm-oracle-key-issuance.chain\",\"serviceEndpoint\":\"http://172.104.233.185:28634/api/zenswarm-oracle-key-issuance.chain\",\"type\":\"LinkedDomains\"},{\"id\":\"did:dyne:zenswarm-api#zenswarm-oracle-ping.zen\",\"serviceEndpoint\":\"http://172.104.233.185:28634/api/zenswarm-oracle-ping.zen\",\"type\":\"LinkedDomains\"},{\"id\":\"did:dyne:zenswarm-api#sawroom-to-ethereum-notarization.chain\",\"serviceEndpoint\":\"http://172.104.233.185:28634/api/sawroom-to-ethereum-notarization.chain\",\"type\":\"LinkedDomains\"},{\"id\":\"did:dyne:zenswarm-api#zenswarm-oracle-get-timestamp.zen\",\"serviceEndpoint\":\"http://172.104.233.185:28634/api/zenswarm-oracle-get-timestamp.zen\",\"type\":\"LinkedDomains\"},{\"id\":\"did:dyne:zenswarm-api#zenswarm-oracle-update\",\"serviceEndpoint\":\"http://172.104.233.185:28634/api/zenswarm-oracle-update\",\"type\":\"LinkedDomains\"}],\"url\":\"https://swarm2.dyne.org:20004\",\"verificationMethod\":[{\"controller\":\"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK\",\"id\":\"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#ecdh_public_key\",\"publicKeyBase58\":\"SJ3uY8Y5cKYsMqqvW3rZaX7h4s1ms5NpAYeHUi16A7jHMVtwSF3Gdzafh9XmvGz6uNksBnaU5fvarDw1mZF2Nkjz\",\"type\":\"EcdsaSecp256k1VerificationKey2019\"},{\"controller\":\"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK\",\"id\":\"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#reflow_public_key\",\"publicKeyBase58\":\"3LfL2v8qz2cmgy8LRqLPL4H12mt2rW3p7hrwJ6q1gqpHKyXWovkCutsJRsLxkrgHwQ233gouwWFmzshS5EnK9dah92855jzaqV4fD53svqLBrxdV2nt44aEMuWoXYSwA4dmTwHXpgsyQuCsn6uNewbF5VLcesqJubzHf4XvVF9249F1HVLmMR7oCKVBnCw3pTB2HrcmSJaSdKu88rJbzELTvdMLbXXyEcCvYDT3HhzGXNv9BBTo9ZXQGw1CSCCyDrCNMYe\",\"type\":\"ReflowBLS12381VerificationKey\"},{\"controller\":\"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK\",\"id\":\"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#bitcoin_public_key\",\"publicKeyBase58\":\"24FWY6sMx2MvH1EEoncuWr4dh4NJ7Pmo5WDNst4oztg7s\",\"type\":\"EcdsaSecp256k1VerificationKey2019\"},{\"controller\":\"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK\",\"id\":\"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#eddsa_public_key\",\"publicKeyBase58\":\"2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK\",\"type\":\"Ed25519VerificationKey2018\"},{\"blockchainAccountId\":\"eip155:1717658228:0x747846c15dfc79803265f953d003ac4251867cd7\",\"controller\":\"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK\",\"id\":\"did:dyne:zenflows:2s5wmQjZeYtpckyHakLiP5ujWKDL1M2b8CiP6vwajNrK#ethereum_address\",\"type\":\"EcdsaSecp256k1RecoveryMethod2020\"}]}"}'
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
    run $ZENROOM_EXECUTABLE -z -a invalid_scheme.json did_document_parsing.zen
    assert_line --partial 'Invalid DID document: invalid scheme'
    run $ZENROOM_EXECUTABLE -z -a invalid_method_name.json did_document_parsing.zen
    assert_line --partial 'Invalid DID document: invalid method-name'
    run $ZENROOM_EXECUTABLE -z -a invalid_method_specific_identifier.json did_document_parsing.zen
    assert_line --partial 'Invalid DID document: invalid method specific identifier'
    run $ZENROOM_EXECUTABLE -z -a invalid_method_specific_identifier2.json did_document_parsing.zen
    assert_line --partial 'Invalid DID document: invalid method specific identifier'
    run $ZENROOM_EXECUTABLE -z -a valid_id.json did_document_parsing.zen
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
    run $ZENROOM_EXECUTABLE -z -a did_document.json pk_from_doc_not_exist.zen
    assert_line --partial 'schnorr_public_key not found in the did document didDocument'
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
    run $ZENROOM_EXECUTABLE -z -a did_documents.json verify_wrong_did_doc.zen
    assert_line --partial 'The signer id in proof is different from the one in not_signer_did_document'
}
@test "JWT HS256 creation" {
    cat <<EOF | save_asset jwt_hs256.data
{
	"payload": {
        "iat": "15162",
        "name": "John Doe",
        "sub": "1234567890"
    },
	"password": "password"
}
EOF
    cat <<EOF | zexe jwt_hs256.zen jwt_hs256.data
Scenario 'w3c': did document manipulation
Given I have a 'string dictionary' named 'payload'
Given I have a 'string' named 'password'

When I create the json web token of 'payload' using 'password'
and debug
Then print the 'json web token'
EOF
    save_output jwt_hs256.json
    assert_output '{"json_web_token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOiIxNTE2MiIsIm5hbWUiOiJKb2huIERvZSIsInN1YiI6IjEyMzQ1Njc4OTAifQ.FyHC5dRXzneZ2gs4yU6jTuj0jDue3IlL25m8OgJ8IDA"}'
}

@test "JWT HS256 verify" {
    cat <<EOF | zexe jwt_hs256_verify.zen jwt_hs256.json
Scenario 'w3c': did document manipulation
Given I have a 'json web token'

When I verify the json web token in 'json web token' using 'password'

Then print the string 'ok'
EOF
    save_output jwt_hs256_verify.json
    assert_output '{"output":["ok"]}'
}

@test "JWS es256" {
    cat <<EOF | save_asset jws_es256.data
{
    "header": {
              "alg": "ES256",
              "b64": true,
              "crit": ["b64"]
    },
    "payload": {
               "iss": "joe",
               "http://example.com/is_root": true
    },
    "keyring": {
               "es256": "hqQUHoEbLJIqcoLEvEtu8kJ3WbhaskDb5Sl/ygPN220="
    }
}
EOF
    cat <<EOF | zexe jws_es256.zen jws_es256.data
Scenario 'w3c': did document manipulation
Scenario 'es256': signature

Given I have a 'string dictionary' named 'header'
Given I have a 'string dictionary' named 'payload'
Given I have a 'keyring'

When I create jws signature of header 'header' and payload 'payload'

Then print the 'jws signature'
EOF
    save_output jws_es256.json
    assert_output '{"jws_signature":"eyJhbGciOiJFUzI1NiIsImI2NCI6dHJ1ZSwiY3JpdCI6WyJiNjQiXX0.eyJodHRwOi8vZXhhbXBsZS5jb20vaXNfcm9vdCI6dHJ1ZSwiaXNzIjoiam9lIn0.gyvKONZZiFmTUbQseoJ6KdAYJPyFixv0rMXL2T39say1hkpC57hS3cqQliE3S1GaKrQKT6mUMpqLDf_rovjHMQ"}'
}

@test "verify JWS es256" {
    cat <<EOF | save_asset verify_jsw_es256.data
{
    "es256_public_key": "LzOheBTJ7wIcII4MWkzoETuGroDn9ihIGEeVSbByUig7mO264C94nBIqM6cU7Pa5Nq+GiLd+ibejPXnfwbEV6A==",
    "payload": {
               "iss": "joe",
               "http://example.com/is_root": true
    }
}
EOF
    cat <<EOF | zexe verify_jws_es256.zen jws_es256.json verify_jsw_es256.data
Scenario 'es256': signature verifcation
Scenario 'w3c': jws

Given I have a 'string' named 'jws signature'
and I have a 'es256 public key'
and I have a 'dictionary' named 'payload'

When I verify 'payload' has a jws signature in 'jws signature'
When I verify the jws signature in 'jws signature'

Then print the string 'signature verified'
EOF
    save_output verify_jws_es256.json
    assert_output '{"output":["signature_verified"]}'
}


@test "verify JWS es256 without external public key" {
    cat <<EOF | save_asset verify_jws_es256_alone.data
{
    "jws": "eyJ0eXAiOiJkcG9wK2p3dCIsImFsZyI6IkVTMjU2IiwiandrIjp7Imt0eSI6IkVDIiwieCI6Iml5dWFIZ2pzZWlXVGRLZF9FdWh4TzQzb2F5SzA1el93RWIyU2xzeG9mU28iLCJ5IjoiRUpCcmdaRV93cW0zUDBiUHV1WXBPLTV3YkViazl4eS04aGRPaVZPRGpPTSIsImNydiI6IlAtMjU2In19.eyJqdGkiOiJCV3NfOEU3cjRrZm5qWElLd0NmeVZnIiwiaHRtIjoiUE9TVCIsImh0dSI6Imh0dHBzOi8vc2VydmVyLmV4YW1wbGUuY29tL3Rva2VuIiwiaWF0IjoxNzA4OTY2NjY0ODczfQ.A5G12A0hEMg9E54ZvaERkP-xlnD1cWGUJc1WRM_G0Ge8EjEv7wjscxKHnbbcdy_ZOeo7MQiyBy90bmMc5pTFsg"
}
EOF
    cat <<EOF | zexe verify_jws_es256_alone.zen verify_jws_es256_alone.data
Scenario 'w3c': jws

Given I have a 'string' named 'jws'

When I verify the jws signature in 'jws'

Then print the string 'signature verified'
EOF
    save_output verify_jws_es256_alone.json
    assert_output '{"output":["signature_verified"]}'
}

# @test "JWS es256 with payload string fails" {
#     cat <<EOF | save_asset jws_es256_fail.data
# {
#     "header": {
#               "alg": "ES256"
#     },
#     "payload": "joe",
#     "keyring": {
#                "es256": "hqQUHoEbLJIqcoLEvEtu8kJ3WbhaskDb5Sl/ygPN220="
#     }
# }
# EOF
#     cat <<EOF | save_asset jws_es256_fail.zen
# Scenario 'w3c': did document manipulation
# Scenario 'es256': signature

# Given I have a 'string dictionary' named 'header'
# Given I have a 'string' named 'payload'
# Given I have a 'keyring'

# When I create jws signature of header 'header' and payload 'payload'

# Then print the 'jws signature'
# EOF
#     run $ZENROOM_EXECUTABLE -z -a jws_es256_fail.data jws_es256_fail.zen
#     assert_line --partial 'payload is not a json or an encoded json'
# }


@test "create jws header for es256 signature with public key" {
    cat <<EOF | zexe jws_header_with_pk.zen jws_es256.data
Scenario 'w3c': jws

Given I have a 'string dictionary' named 'payload'
Given I have a 'keyring'

When I create jws header for 'es256' signature with public key
When I create jws signature of header 'jws header' and payload 'payload'

Then print the 'jws signature'
and print the 'jws header'
EOF
    save_output jws_header_with_pk.json
    assert_output '{"jws_header":{"alg":"ES256","jwk":{"alg":"ES256","crv":"P-256","key_ops":["verify"],"kty":"EC","x":"LzOheBTJ7wIcII4MWkzoETuGroDn9ihIGEeVSbByUig","y":"O5jtuuAveJwSKjOnFOz2uTavhoi3fom3oz1538GxFeg"}},"jws_signature":"eyJhbGciOiJFUzI1NiIsImp3ayI6eyJhbGciOiJFUzI1NiIsImNydiI6IlAtMjU2Iiwia2V5X29wcyI6WyJ2ZXJpZnkiXSwia3R5IjoiRUMiLCJ4IjoiTHpPaGVCVEo3d0ljSUk0TVdrem9FVHVHcm9EbjlpaElHRWVWU2JCeVVpZyIsInkiOiJPNWp0dXVBdmVKd1NLak9uRk96MnVUYXZob2kzZm9tM296MTUzOEd4RmVnIn19.eyJodHRwOi8vZXhhbXBsZS5jb20vaXNfcm9vdCI6dHJ1ZSwiaXNzIjoiam9lIn0.gyvKONZZiFmTUbQseoJ6KdAYJPyFixv0rMXL2T39saxdCFHU9ZuUVTBdSluhD8JK4Tb22mRKZBOQkNmp5bjpbg"}'

    cat <<EOF | zexe verify_jws_header_with_pk.zen jws_header_with_pk.json
Scenario 'w3c': jws

Given I have a 'string' named 'jws signature'

When I verify the jws signature in 'jws signature'

Then print the string 'signature verified'
EOF
    save_output verify_jws_header_with_pk.json
    assert_output '{"output":["signature_verified"]}'

}

@test "create jwk from keyring" {
    cat <<EOF | save_asset jwk_from_keyring.data
{
    "keyring": {
        "es256": "hqQUHoEbLJIqcoLEvEtu8kJ3WbhaskDb5Sl/ygPN220=",
        "ecdh": "wffXCldmMihxqkSrIj5a0stleXtfR7g7fqRuh5LX+cM="
    }
}
EOF
    cat <<EOF | zexe jwk_from_keyring.zen jwk_from_keyring.data
Scenario 'w3c': jwk

Given I have a 'keyring'

# es256
When I create the jwk of es256 public key
and I rename the 'jwk' to 'jwk_pk_from_sk_es256'

When I create the jwk of es256 public key with private key
and I rename the 'jwk' to 'jwk_keypair_from_sk_es256'

# es256k
When I create the jwk of es256k public key
and I rename the 'jwk' to 'jwk_pk_from_sk_es256k'

When I create the jwk of es256k public key with private key
and I rename the 'jwk' to 'jwk_keypair_from_sk_es256k'

and debug
Then print the data
EOF
    save_output jwk_from_keyring.json
    assert_output '{"jwk_keypair_from_sk_es256":{"crv":"P-256","d":"hqQUHoEbLJIqcoLEvEtu8kJ3WbhaskDb5Sl_ygPN220","kty":"EC","x":"LzOheBTJ7wIcII4MWkzoETuGroDn9ihIGEeVSbByUig","y":"O5jtuuAveJwSKjOnFOz2uTavhoi3fom3oz1538GxFeg"},"jwk_keypair_from_sk_es256k":{"crv":"secp256k1","d":"wffXCldmMihxqkSrIj5a0stleXtfR7g7fqRuh5LX-cM","kty":"EC","x":"wU3W31GXLu3mA6JwgbIxLjnEZNC7nOyI8rZiFbkA2A8","y":"RHK60VH_L1PmAew97zNmvBHB7mDKDsp07ffH9UNeMAQ"},"jwk_pk_from_sk_es256":{"crv":"P-256","kty":"EC","x":"LzOheBTJ7wIcII4MWkzoETuGroDn9ihIGEeVSbByUig","y":"O5jtuuAveJwSKjOnFOz2uTavhoi3fom3oz1538GxFeg"},"jwk_pk_from_sk_es256k":{"crv":"secp256k1","kty":"EC","x":"wU3W31GXLu3mA6JwgbIxLjnEZNC7nOyI8rZiFbkA2A8","y":"RHK60VH_L1PmAew97zNmvBHB7mDKDsp07ffH9UNeMAQ"}}'
}

@test "create jwk from public keys" {
    cat <<EOF | save_asset jwk_from_pk.data
{
    "ecdh_public_key": "BMFN1t9Rly7t5gOicIGyMS45xGTQu5zsiPK2YhW5ANgPRHK60VH/L1PmAew97zNmvBHB7mDKDsp07ffH9UNeMAQ=",
    "es256_public_key": "LzOheBTJ7wIcII4MWkzoETuGroDn9ihIGEeVSbByUig7mO264C94nBIqM6cU7Pa5Nq+GiLd+ibejPXnfwbEV6A=="
}
EOF
    cat <<EOF | zexe jwk.zen jwk_from_pk.data
Scenario 'w3c': jwk
Scenario 'ecdh': jwk
Scenario 'es256': jwk

Given I have a 'ecdh public key'
and I have a 'es256 public key'

# es256
When I create the jwk of es256 public key
and I rename the 'jwk' to 'jwk_pk_from_sk_es256'

When I create the jwk of es256 public key 'es256 public key'
and I rename the 'jwk' to 'jwk_pk_from_pk_es256'

# es256k
When I create the jwk of es256k public key
and I rename the 'jwk' to 'jwk_pk_from_sk_es256k'

When I create the jwk of es256k public key 'ecdh public key'
and I rename the 'jwk' to 'jwk_pk_from_pk_es256k'

Then print the data
EOF
    save_output jws_header_with_pk.json
    assert_output '{"ecdh_public_key":"BMFN1t9Rly7t5gOicIGyMS45xGTQu5zsiPK2YhW5ANgPRHK60VH/L1PmAew97zNmvBHB7mDKDsp07ffH9UNeMAQ=","es256_public_key":"LzOheBTJ7wIcII4MWkzoETuGroDn9ihIGEeVSbByUig7mO264C94nBIqM6cU7Pa5Nq+GiLd+ibejPXnfwbEV6A==","jwk_pk_from_pk_es256":{"crv":"P-256","kty":"EC","x":"LzOheBTJ7wIcII4MWkzoETuGroDn9ihIGEeVSbByUig","y":"O5jtuuAveJwSKjOnFOz2uTavhoi3fom3oz1538GxFeg"},"jwk_pk_from_pk_es256k":{"crv":"secp256k1","kty":"EC","x":"wU3W31GXLu3mA6JwgbIxLjnEZNC7nOyI8rZiFbkA2A8","y":"RHK60VH_L1PmAew97zNmvBHB7mDKDsp07ffH9UNeMAQ"},"jwk_pk_from_sk_es256":{"crv":"P-256","kty":"EC","x":"LzOheBTJ7wIcII4MWkzoETuGroDn9ihIGEeVSbByUig","y":"O5jtuuAveJwSKjOnFOz2uTavhoi3fom3oz1538GxFeg"},"jwk_pk_from_sk_es256k":{"crv":"secp256k1","kty":"EC","x":"wU3W31GXLu3mA6JwgbIxLjnEZNC7nOyI8rZiFbkA2A8","y":"RHK60VH_L1PmAew97zNmvBHB7mDKDsp07ffH9UNeMAQ"}}'
}

@test "bearer json web token schema" {
    cat <<EOF | save_asset bearer_jwt.data.json
{
    "token": "BEARER eyJhbGciOiJFUzI1NiIsImp3ayI6eyJrdHkiOiJFQyIsIngiOiJoLXlLRFRpVUttb0ZNcHdXR2tMcG42QksyU2pLeHdQYlVRMGVUaXpWeExrIiwieSI6Ii1VekQ0TlJtY2t0Qk5Db0dSUkNJWERuOUYwcUQzNDJVZlF5WTFSdG10TEEiLCJjcnYiOiJQLTI1NiJ9fQ.eyJzdWIiOiJjY2NkYTJkYjMxZTRlZDRlNmIwMmY0MTZmODE2ZjM2ODUxNDA4NTQ3IiwiaWF0IjoxNzEwNDkzNDI5LCJpc3MiOiJodHRwczovL2F1dGh6LXNlcnZlcjEuemVuc3dhcm0uZm9ya2JvbWIuZXU6MzEwMCIsImF1ZCI6ImRpZDpkeW5lOnNhbmRib3guc2lnbnJvb206OGZuOHM4Z1ZIMVRZWlY2TDJjYUdnOXZwUDJ6ZVdCZXczS1pQN0U1enRjRjEiLCJleHAiOjE3MTA0OTcwMjh9.6VS7_DO0VXRhopGvDguZI4vIblECqXcRpDG_VbTU7caz9Y4NlpEkuVaH7UlScfGKAsIB2msPMKMiWoWyo5aaag"
}
EOF
    cat <<EOF | zexe bearer_jwt.zen bearer_jwt.data.json
Scenario 'w3c': bearer json web token
Given I have a 'jwt' part of 'token' after string prefix 'BEARER'
When I pickup a 'string dictionary' from path 'token.payload'
Then print the 'payload'
EOF
    save_output bearer_jwt.out.json
    assert_output '{"payload":{"aud":"did:dyne:sandbox.signroom:8fn8s8gVH1TYZV6L2caGg9vpP2zeWBew3KZP7E5ztcF1","exp":1710497028,"iat":1710493429,"iss":"https://authz-server1.zenswarm.forkbomb.eu:3100","sub":"cccda2db31e4ed4e6b02f416f816f36851408547"}}'
}

@test "not bearer json web token schema" {
    cat <<EOF | save_asset not_bearer_jwt.data.json
{
    "token": "BEAREReyJhbGciOiJFUzI1NiIsImp3ayI6eyJrdHkiOiJFQyIsIngiOiJoLXlLRFRpVUttb0ZNcHdXR2tMcG42QksyU2pLeHdQYlVRMGVUaXpWeExrIiwieSI6Ii1VekQ0TlJtY2t0Qk5Db0dSUkNJWERuOUYwcUQzNDJVZlF5WTFSdG10TEEiLCJjcnYiOiJQLTI1NiJ9fQ.eyJzdWIiOiJjY2NkYTJkYjMxZTRlZDRlNmIwMmY0MTZmODE2ZjM2ODUxNDA4NTQ3IiwiaWF0IjoxNzEwNDkzNDI5LCJpc3MiOiJodHRwczovL2F1dGh6LXNlcnZlcjEuemVuc3dhcm0uZm9ya2JvbWIuZXU6MzEwMCIsImF1ZCI6ImRpZDpkeW5lOnNhbmRib3guc2lnbnJvb206OGZuOHM4Z1ZIMVRZWlY2TDJjYUdnOXZwUDJ6ZVdCZXczS1pQN0U1enRjRjEiLCJleHAiOjE3MTA0OTcwMjh9.6VS7_DO0VXRhopGvDguZI4vIblECqXcRpDG_VbTU7caz9Y4NlpEkuVaH7UlScfGKAsIB2msPMKMiWoWyo5aaag"
}
EOF
    cat <<EOF | save_asset not_bearer_jwt.zen
Scenario 'w3c': bearer json web token
Given I have a 'jwt' part of 'token' after string prefix 'BEARER'
When I pickup a 'string dictionary' from path 'token.payload'
Then print the 'payload'
EOF
    run $ZENROOM_EXECUTABLE -z -a not_bearer_jwt.data.json not_bearer_jwt.zen
    assert_success
}

@test "timestamp in jws body" {
    cat <<EOF | zexe jws_timestamp.zen
Scenario 'w3c': jws
Scenario 'es256': key

Given nothing
When I create es256 key

When I create the 'string dictionary' named 'DPoP-payload'
When I set 'iat' to '1750771160' as 'time'
When I move 'iat' in 'DPoP-payload'

When I create jws header for 'ES256' signature with public key
When I set 'typ' to 'dpop+jwt' as 'string'
When I move 'typ' in 'jws header'

When I create the jws signature of header 'jws header' and payload 'DPoP-payload'

Then print the 'jws signature'
EOF
    save_output jws_timestamp.out.json
    assert_output '{"jws_signature":"eyJhbGciOiJFUzI1NiIsImp3ayI6eyJhbGciOiJFUzI1NiIsImNydiI6IlAtMjU2Iiwia2V5X29wcyI6WyJ2ZXJpZnkiXSwia3R5IjoiRUMiLCJ4IjoiZ3l2S09OWlppRm1UVWJRc2VvSjZLZEFZSlB5Rml4djByTVhMMlQzOXNhdyIsInkiOiJNNGtkeU9QWXpLZi1nb1FMcVVHS21ZV0QxUXYwYmNRU1ByVkhGQzRkVWdvIn0sInR5cCI6ImRwb3Arand0In0.eyJpYXQiOjE3NTA3NzExNjB9.F8sdx5dB7P5vBU-VsHp2UNh2bF0nRq2b81iwThzCBRwKQOk3ULUU_R41y1V19tMCvAjFObPKs-bqdD4xF_zizQ"}'
}

@test "RSA: Create the keypair" {
    cat <<EOF | save_asset RSA-keypair.json
{"Alice":{"keyring":{"rsa":"iZLFrTu7CX8HtAkIO5Ad+aoKAxbQOQITmQcLC/pyAZi2lpmEF79rvgQSPOpudKLrGNIXK5hWOTLQdZDKgFBqsrD4bqqEbukOzCu1fvSkcetOJqsH8lkXhry8sXY5YkGTvTL5KsMwuGpY3IOsnoAw0PmuQNAj2b9Aj95ryeBySpyn3kiEnlmm7Z9RIgSMpGKxdn0GWfg5ksgCfeFQUAbAC5diNc4sUlnmPRKnDF6qV9t0ut1xPMjHNLtL9N0s5prAuhsDRvyJxnt+3WQwxOOL++dn/ElPgsWeRz/JskqN5gTqRB63hV9fODVo14aASfIfPaFjZjYXfV5it/AfmUJBQ/fTDS9jMsqOZoTLTkQPfT6fN94m4mB2GuSQzljcFBR3GsZDO7D/Ae9G45RhN7cHPaHaWo2K4BV5sr/TSX7X0Td3vLsYxsfJtXH/cU4JbllSVGMul5lfO3Tojhhrg13FaifpsMFt2ZDWZpIp8b/YFSpcm1fkKOd8fsA/A1bPs39kQdEmhyHUpzH4KUqwhbueMfmIh3H9aXCRaGqoLKWevbDf0wRnBNBVRb1ErTem/K6DXBS54V8w6h1nfcae+gIICMCP2afCQUXi2NHSQBfWudWNc1FJfX0O4QDX+KQDGD49SSB6WIIQynMlIYg+fyQQQkDXvh394O4Mm/6/Am3OVtMYP+bYQk8VvW5+LZll5mFiQLbDFKJfah5KOxOXaO3vmhuVMDo4dWVoeQ897ZTKumz2UxICfTe1nV9hWcRYGdS06rzfxO7THgGdu5aiaj0SV4fPCRa9gTbEaUBZh51V1HlWQEXrY7ySxSwkspEa3z27mEc+5XFsUGnw8iPN0eJThImShPXbc7IY8Jw8gtDHqR3e5OrZsQd0+Ax4Y97kPExdvrFxCoaFfZM38LHBXG5qTiSlS6NKM5npkZox70qa22xdYaWSPbGLavlRzPdLvVBPdtq9fa6mPm9H39aNttaMVRF2MHPo7oa6Qa/ZTbwPTL50/p2mxqIdVyXPhmQLf8JBSG78VJRm3QM//aI6jvQEBFCfEKRG2DDM7W9RkHFKwSyKu9Yc1T/Dff83N0Au+6T3I55hhytHEZ/PWffUbGmB8fdiR0EXoH9ZNCeYI1noUd0ZYx/UGXTXOPVbytFpxPeVbnMEQZTs2UOBGUl/KjZrAUWt9cNvHTGrDl+chzwP17Ui85GSP5YbBCTnVLhBbjPvoWKBTBToQ4mMflgHLKU4BkF1OL0vkADMcGRpSHHbOtqUCE7IC32Nf+imv23p3rwgar/guwKw9081ViZgq1cMW9mLEgAr2GiH5So6tx1ccZySChcYVXO46Gy630p8+Lpz0uX74GI64vj2gz+q4xNDF2vAgxg5xPk3idzIriLUkEbDchyPDsvEooQeyMYZeeQ+HRG+N57xS2DsY4vXJBrUmOQB0RTAxZwZ+PxRinPEXcnjFNr5JkXiYVa8WLAXSTDPWa50cChg5ErsuYdQWl6tIDUESZd+oi12PAcK1qv+dTNun+fIS6Z0pa/b+ZIgxU2vd4S7PdF+B8pGKT0cUgfNLWmrGi/xSyhkyWWHy4cfcXobSEH49D5Tej4VjrKUiSgCQU7mbdkOSLSVQDNprnSd0ThtRG52SH+w0MvFsnx0wUgzG+COJChQ+IM9PSigZZ8qe/SKO/yz+fRm5pWO3uy5KeQCKwG9EdVd956B+fl7loo="}}}
EOF
}

@test "RSA: Create the issuer keypair" {
    cat <<EOF | save_asset RSA-issuerKeypair.json
{"Authority":{"keyring":{"rsa":"iZLFrTu7CX8HtAkIO5Ad+aoKAxbQOQITmQcLC/pyAZi2lpmEF79rvgQSPOpudKLrGNIXK5hWOTLQdZDKgFBqsrD4bqqEbukOzCu1fvSkcetOJqsH8lkXhry8sXY5YkGTvTL5KsMwuGpY3IOsnoAw0PmuQNAj2b9Aj95ryeBySpyn3kiEnlmm7Z9RIgSMpGKxdn0GWfg5ksgCfeFQUAbAC5diNc4sUlnmPRKnDF6qV9t0ut1xPMjHNLtL9N0s5prAuhsDRvyJxnt+3WQwxOOL++dn/ElPgsWeRz/JskqN5gTqRB63hV9fODVo14aASfIfPaFjZjYXfV5it/AfmUJBQ/fTDS9jMsqOZoTLTkQPfT6fN94m4mB2GuSQzljcFBR3GsZDO7D/Ae9G45RhN7cHPaHaWo2K4BV5sr/TSX7X0Td3vLsYxsfJtXH/cU4JbllSVGMul5lfO3Tojhhrg13FaifpsMFt2ZDWZpIp8b/YFSpcm1fkKOd8fsA/A1bPs39kQdEmhyHUpzH4KUqwhbueMfmIh3H9aXCRaGqoLKWevbDf0wRnBNBVRb1ErTem/K6DXBS54V8w6h1nfcae+gIICMCP2afCQUXi2NHSQBfWudWNc1FJfX0O4QDX+KQDGD49SSB6WIIQynMlIYg+fyQQQkDXvh394O4Mm/6/Am3OVtMYP+bYQk8VvW5+LZll5mFiQLbDFKJfah5KOxOXaO3vmhuVMDo4dWVoeQ897ZTKumz2UxICfTe1nV9hWcRYGdS06rzfxO7THgGdu5aiaj0SV4fPCRa9gTbEaUBZh51V1HlWQEXrY7ySxSwkspEa3z27mEc+5XFsUGnw8iPN0eJThImShPXbc7IY8Jw8gtDHqR3e5OrZsQd0+Ax4Y97kPExdvrFxCoaFfZM38LHBXG5qTiSlS6NKM5npkZox70qa22xdYaWSPbGLavlRzPdLvVBPdtq9fa6mPm9H39aNttaMVRF2MHPo7oa6Qa/ZTbwPTL50/p2mxqIdVyXPhmQLf8JBSG78VJRm3QM//aI6jvQEBFCfEKRG2DDM7W9RkHFKwSyKu9Yc1T/Dff83N0Au+6T3I55hhytHEZ/PWffUbGmB8fdiR0EXoH9ZNCeYI1noUd0ZYx/UGXTXOPVbytFpxPeVbnMEQZTs2UOBGUl/KjZrAUWt9cNvHTGrDl+chzwP17Ui85GSP5YbBCTnVLhBbjPvoWKBTBToQ4mMflgHLKU4BkF1OL0vkADMcGRpSHHbOtqUCE7IC32Nf+imv23p3rwgar/guwKw9081ViZgq1cMW9mLEgAr2GiH5So6tx1ccZySChcYVXO46Gy630p8+Lpz0uX74GI64vj2gz+q4xNDF2vAgxg5xPk3idzIriLUkEbDchyPDsvEooQeyMYZeeQ+HRG+N57xS2DsY4vXJBrUmOQB0RTAxZwZ+PxRinPEXcnjFNr5JkXiYVa8WLAXSTDPWa50cChg5ErsuYdQWl6tIDUESZd+oi12PAcK1qv+dTNun+fIS6Z0pa/b+ZIgxU2vd4S7PdF+B8pGKT0cUgfNLWmrGi/xSyhkyWWHy4cfcXobSEH49D5Tej4VjrKUiSgCQU7mbdkOSLSVQDNprnSd0ThtRG52SH+w0MvFsnx0wUgzG+COJChQ+IM9PSigZZ8qe/SKO/yz+fRm5pWO3uy5KeQCKwG9EdVd956B+fl7loo="}}}
EOF
}

@test "RSA: Publish the public key" {
    cat <<EOF | zexe RSA-pubkey.zen RSA-issuerKeypair.json
Scenario 'rsa': Publish the public key
Given that I am known as 'Authority'
and I have my 'keyring'
When I create the rsa public key
Then print my 'rsa public key'
EOF
    save_output 'RSA-pubkey.json'
    assert_output '{"Authority":{"rsa_public_key":"hS4HyP201h/LX23wCPcUOREwBIvSaQ2kZ3GBfIXBw+SMdvZkvgcsQnfd+pruy9WrPt9R80wSkEaZLBRuoiSbRBQ5w5dyMpGzNXOh3c08Q0sGw/O8ffg54vkH8eKKyj8hGszIsFXC7pXcFJJTjOED8Kv62LCP1mv2RQv9k15g2p1NdNM7/biKsNNLM0oVNc6GsXfMl9zaTJpKXsh+5Gcl9WEr0xP3aTmqnms2x5E9gKYL2Yzpp5imjqJ0K9OvcFkTCnOcuKqI0a/oihw2WrgqC5u9iTbhfqM3y5Pnu1U64hIfPrmAl0gu+hGhyFA8Pn+d/dM7nXLMdzZ52ClgkPkg/aW0eT62jmWt47T7TM27omBpN/ngKCA+86+mEaju1ib6Z1m5vYqaiO5Ye9B1iHMqo/9iHW+YywC7gfmGFCT5JB/KFsdj1pX+1WrsBB+8S5aE/HcmbGT460f+4Dh7K3atPU1+hhrbE6xyohezkVXwdJnZgSW/O6iwU0oE2scbNq5dQ+B+K1jjtRrEq6vucxMqFldoyH00c4+cAnK/dnbKuLofFHusarmugQX6vCoCh55xtj7G1mKZ511s2zvEcLXJRkZPttsuF+R3bzYyEd63fow98FPD9/KRnZPsryICyywCsDa6xvd2H8Zs/K67zIsGBxED1wAHmcUxyKOQJ55yTDkAAQAB"}}'
}

@test "RSA: When I create jws detached signature of header '' and payload ''" {
    cat <<EOF | zexe RSA-jws_sign.zen simple_string.json RSA-issuerKeypair.json
Scenario 'w3c': sign JSON
Scenario 'rsa': (required)
Given that I am 'Authority'
Given I have my 'keyring'
Given I have a 'string dictionary' named 'simple'
When I create the jws header for 'rs256' signature
When I create jws detached signature of header 'jws header' and payload 'simple'
Then print the 'jws detached signature'
and print the 'simple'
EOF
    save_output 'RSA-jws_signed.json'
    assert_output '{"jws_detached_signature":"eyJhbGciOiJSUzI1NiJ9..TgCEKDNzKg3c0Nacm1bRwAdR-hOH6qHfI_Y47CuGayXNUmCMm08cYOINUPiKKiq4Rho5fqseDS98YUcKFBzIqnEFKqDFeEz5YAbDmMw82bX-jDfZZWmk0RH3ZU9s1MwSoBDU8ft9Pf_TIp053GS32JVrXSJIr6ihNAnrF6RlEUB5_X1BvVpn2dQXuJGkejx-2qcMkkA2aHnafmUQBIa9-4lbkUDdmhDVpKZqWtJJIX3I0Sbgp4kQquXYjOpBsfdsaGkN_8WPGD9v6rpjddbogv12t3abdhzhIyebPzrbTihu68SqhVC0frF6EqaQ1v_brGFZa3KFujPQVRCH9Gaf2lIzSznnnFl6Plya4-1BOMlYOyjTGPI_Z5tg9vhgP_fQHwGujazdT7FiQyn2Fe1FPBZTuNQNo6gERxP5oSvl7Pg6n0OhcO0fm3JtovHFK_ZXMExs-vf1gu0lzQRikNttXbkpxVOxfRQ7CuDP2tsNyUubIggkCD02xC9bX_TJ_uzGF-SOnXE6tguSquYC6iActCf7DtAHs2VEqIkuEEs5ggkww2eAJFGvqDD9f1I3Jor2yvHoQFCExXs-wBbr3idW9xjrN3AxiJmccUgfM5WYYN4Yx2ji3SZ7Z5YJAeaL3X9cHz0zdsnEx2phFwQL4cPyAy0gId0iTNoQ5-eS_gYurSY","simple":{"simple":"once upon a time... there was a wolf"}}'
}

@test "RSA: When I verify '' has a jws signature in ''" {
    cat <<EOF | zexe RSA-jws_verify.zen RSA-jws_signed.json RSA-pubkey.json
Scenario 'w3c': verify signature
Scenario 'rsa': (required)
Given I have a 'rsa public key' inside 'Authority'
and I have a 'string' named 'jws detached signature'
and I have a 'string dictionary' named 'simple'
When I verify 'simple' has a jws signature in 'jws detached signature'
Then print the string 'W3C JWS RS256 IS VALID'
EOF
    save_output 'RSA-jws_verify.out'
    assert_output '{"output":["W3C_JWS_RS256_IS_VALID"]}'
}

@test "JWS rs256" {
    cat <<EOF | save_asset jws_rs256.data
{
    "header": {
              "alg": "RS256",
              "b64": true,
              "crit": ["b64"]
    },
    "payload": {
               "iss": "joe",
               "http://example.com/is_root": true
    }
}
EOF
    cat <<EOF | zexe jws_rs256.zen jws_rs256.data RSA-issuerKeypair.json
Scenario 'w3c': jws
Scenario 'rsa': (required)
Given that I am 'Authority'
Given I have my 'keyring'
Given I have a 'string dictionary' named 'header'
Given I have a 'string dictionary' named 'payload'
When I create jws signature of header 'header' and payload 'payload'
Then print the 'jws signature'
EOF
    save_output jws_rs256.json
    assert_output '{"jws_signature":"eyJhbGciOiJSUzI1NiIsImI2NCI6dHJ1ZSwiY3JpdCI6WyJiNjQiXX0.eyJodHRwOi8vZXhhbXBsZS5jb20vaXNfcm9vdCI6dHJ1ZSwiaXNzIjoiam9lIn0.MIK6uUUrQ5o3qJdtUmlC0LBswLO1gubrk4Ct7rgqShjkdHhethRq_Xa0pNzyjgyo_50Tsrk0t0WKWEuKA5MFgEjFKPlpNNJTgMPtjLEvGliYw_4woz_NKpj3uSZRw2Q6GK9qYzBrEw50DliXIPyj_eO1mHIU-6CIgd1RZFIkredpzI1DGU_AmRjVH5maLbegcNJeRebwcstXaymxUL_bdUauLchEBRWAwIG1g_UTZ2QNU-MCxDna1fanx9DN8OWOAyJz4UVaQ6slIqGipxs2qfBukFADiqQK5NVWHnhPxC2SsdfZdMwpLe49vNOdovqNQmusZ_138ZhVgnaqhYk_XIs3iuEPCOU7frvWaqWJeXhrOgEaKK6k8rlaoVU3RKG3whCmcgEfgQvN_CQnDUMZ1VC9SZNTlytVygjJ48pu5WRPq0LChtqfnh0sEIEOMIdW_4JnW7mYCmrk8udPFEG3Sz44E7_iCRcukg5_hY3Dv90Xu5nf2VagT6J-UNkufq5rjZ8ojT-crBDpcL763JWmYO7wWdukGoXeijeBPkab9-5PcmauxspZLExIJeH3ItmijnPXOpUEqaPvMmDqTP0lU4OXBMjPTaCMaTrXRQGUzQthhXTDGC4thNMN-Qkj3_7pbzoMoEGrUOfW9_brgisUr2UVVQSsM6OIIZ3t_wFtMcY"}'
}

@test "verify JWS rs256" {
    cat <<EOF | save_asset verify_jws_rs256.data
{   
    "rsa_public_key": "hS4HyP201h/LX23wCPcUOREwBIvSaQ2kZ3GBfIXBw+SMdvZkvgcsQnfd+pruy9WrPt9R80wSkEaZLBRuoiSbRBQ5w5dyMpGzNXOh3c08Q0sGw/O8ffg54vkH8eKKyj8hGszIsFXC7pXcFJJTjOED8Kv62LCP1mv2RQv9k15g2p1NdNM7/biKsNNLM0oVNc6GsXfMl9zaTJpKXsh+5Gcl9WEr0xP3aTmqnms2x5E9gKYL2Yzpp5imjqJ0K9OvcFkTCnOcuKqI0a/oihw2WrgqC5u9iTbhfqM3y5Pnu1U64hIfPrmAl0gu+hGhyFA8Pn+d/dM7nXLMdzZ52ClgkPkg/aW0eT62jmWt47T7TM27omBpN/ngKCA+86+mEaju1ib6Z1m5vYqaiO5Ye9B1iHMqo/9iHW+YywC7gfmGFCT5JB/KFsdj1pX+1WrsBB+8S5aE/HcmbGT460f+4Dh7K3atPU1+hhrbE6xyohezkVXwdJnZgSW/O6iwU0oE2scbNq5dQ+B+K1jjtRrEq6vucxMqFldoyH00c4+cAnK/dnbKuLofFHusarmugQX6vCoCh55xtj7G1mKZ511s2zvEcLXJRkZPttsuF+R3bzYyEd63fow98FPD9/KRnZPsryICyywCsDa6xvd2H8Zs/K67zIsGBxED1wAHmcUxyKOQJ55yTDkAAQAB",
    "payload": {
               "iss": "joe",
               "http://example.com/is_root": true
    }
}
EOF
    cat <<EOF | zexe verify_jws_rs256.zen jws_rs256.json verify_jws_rs256.data RSA-pubkey.json
Scenario 'rsa': (required)
Scenario 'w3c': jws
Given I have a 'rsa public key'
and I have a 'string' named 'jws signature'
and I have a 'dictionary' named 'payload'
When I verify 'payload' has a jws signature in 'jws signature'
When I verify the jws signature in 'jws signature'
Then print the string 'rs256 signature verified'
EOF
    save_output verify_jws_rs256.json
    assert_output '{"output":["rs256_signature_verified"]}'
}

@test "verify JWS rs256 without external public key" {
    cat <<EOF | save_asset verify_jws_rs256_alone.data
{
    "payload": {
               "iss": "joe",
               "http://example.com/is_root": true
    }
}
EOF
    cat <<EOF | zexe jws_rs256_with_pk.zen verify_jws_rs256_alone.data RSA-issuerKeypair.json
Scenario 'w3c': jws
Scenario 'rsa': (required)
Given that I am 'Authority'
Given I have my 'keyring'
Given I have a 'string dictionary' named 'payload'
When I create jws header for 'rs256' signature with public key
When I create jws signature of header 'jws header' and payload 'payload'
Then print the 'jws signature'
EOF
    save_output jws_rs256_with_pk.json
    assert_output '{"jws_signature":"eyJhbGciOiJSUzI1NiIsImp3ayI6eyJhbGciOiJSUzI1NiIsImUiOiJBUUFCIiwia2V5X29wcyI6WyJ2ZXJpZnkiXSwia3R5IjoiUlNBIiwibiI6ImhTNEh5UDIwMWhfTFgyM3dDUGNVT1JFd0JJdlNhUTJrWjNHQmZJWEJ3LVNNZHZaa3ZnY3NRbmZkLXBydXk5V3JQdDlSODB3U2tFYVpMQlJ1b2lTYlJCUTV3NWR5TXBHek5YT2gzYzA4UTBzR3dfTzhmZmc1NHZrSDhlS0t5ajhoR3N6SXNGWEM3cFhjRkpKVGpPRUQ4S3Y2MkxDUDFtdjJSUXY5azE1ZzJwMU5kTk03X2JpS3NOTkxNMG9WTmM2R3NYZk1sOXphVEpwS1hzaC01R2NsOVdFcjB4UDNhVG1xbm1zMng1RTlnS1lMMll6cHA1aW1qcUowSzlPdmNGa1RDbk9jdUtxSTBhX29paHcyV3JncUM1dTlpVGJoZnFNM3k1UG51MVU2NGhJZlBybUFsMGd1LWhHaHlGQThQbi1kX2RNN25YTE1kelo1MkNsZ2tQa2dfYVcwZVQ2MmptV3Q0N1Q3VE0yN29tQnBOX25nS0NBLTg2LW1FYWp1MWliNloxbTV2WXFhaU81WWU5QjFpSE1xb185aUhXLVl5d0M3Z2ZtR0ZDVDVKQl9LRnNkajFwWC0xV3JzQkItOFM1YUVfSGNtYkdUNDYwZi00RGg3SzNhdFBVMS1oaHJiRTZ4eW9oZXprVlh3ZEpuWmdTV19PNml3VTBvRTJzY2JOcTVkUS1CLUsxamp0UnJFcTZ2dWN4TXFGbGRveUgwMGM0LWNBbktfZG5iS3VMb2ZGSHVzYXJtdWdRWDZ2Q29DaDU1eHRqN0cxbUtaNTExczJ6dkVjTFhKUmtaUHR0c3VGLVIzYnpZeUVkNjNmb3c5OEZQRDlfS1JuWlBzcnlJQ3l5d0NzRGE2eHZkMkg4WnNfSzY3eklzR0J4RUQxd0FIbWNVeHlLT1FKNTV5VERrIn19.eyJodHRwOi8vZXhhbXBsZS5jb20vaXNfcm9vdCI6dHJ1ZSwiaXNzIjoiam9lIn0.TKNUlw-VGxQJJK_KmeVF9h6VvVAwoR8XNk5fNBwLVKX2Cwaogoru4JdvlziXpsSWU_EQxkl3HvITuMl7qHviqAY3CY0glxGUB2BF81N6rRLMLuHjKofw34eT3psfXiS43fFslQc7SV0oJhOoooXw2-_mBf1DH5BRaO436L4cJhpTprAoyglKRuT071WvY7yOsWsy_Lm1u-uMAiVS2HoEBvPJqeEWKeQhvVCbqWGNAQPpcyaclMw5llwsniEeDpCUP7mI8SS2Dqgn9QkilYn3Yk-IdMKloRu4dJZfRqH2cC89GXGZsrHYMxXsB-EhFHl58EvXxnXo94qWxwYMOY_KE6PZ7XpXdypx7gbulWXDBNLi1KEdIQ8V2Yh7_mx1ag0Awk_uRZ4JTVt-P38rlhqcYFJHIlKZa0z5GLv7UPlaTge8hdjHhRWucS2xeNDDwNEzJqeJlFUdhkjR1VZtpMDirE1if9ygTsAhS-rbD3CpBNut5ICmKeI-NedU-wnkRgWaShxvVhb37HOGM_VyDVj_qT9Dey-tcLV_b0-w4a7m4E2AFc6hSu1unu6Y18MT5yDeCuT9FRzTMMNnFEDrp6-HSSAmS7_2i3aP4jgEe2K3adFhgNxQFtlfosH7p5J_ndIY08gusK2NCaBOPLU5hKgjUDGsdL4weYAgi2qKytFpjn8"}'

    cat <<EOF | zexe verify_jws_rs256_alone.zen jws_rs256_with_pk.json
Scenario 'w3c': jws
Given I have a 'string' named 'jws signature'
When I verify the jws signature in 'jws signature'
Then print the string 'rs256 signature verified'
EOF
    save_output verify_jws_rs256_alone.json
    assert_output '{"output":["rs256_signature_verified"]}'
}

@test "create jws header for rs256 signature with public key" {
    cat <<EOF | zexe jws_rs256_header_with_pk.zen jws_rs256.data RSA-issuerKeypair.json
Scenario 'w3c': jws
Scenario 'rsa': (required)
Given that I am 'Authority'
Given I have my 'keyring'
Given I have a 'string dictionary' named 'payload'
When I create jws header for 'rs256' signature with public key
When I create jws signature of header 'jws header' and payload 'payload'
Then print the 'jws signature'
and print the 'jws header'
EOF
    save_output jws_rs256_header_with_pk.json
    assert_output '{"jws_header":{"alg":"RS256","jwk":{"alg":"RS256","e":"AQAB","key_ops":["verify"],"kty":"RSA","n":"hS4HyP201h_LX23wCPcUOREwBIvSaQ2kZ3GBfIXBw-SMdvZkvgcsQnfd-pruy9WrPt9R80wSkEaZLBRuoiSbRBQ5w5dyMpGzNXOh3c08Q0sGw_O8ffg54vkH8eKKyj8hGszIsFXC7pXcFJJTjOED8Kv62LCP1mv2RQv9k15g2p1NdNM7_biKsNNLM0oVNc6GsXfMl9zaTJpKXsh-5Gcl9WEr0xP3aTmqnms2x5E9gKYL2Yzpp5imjqJ0K9OvcFkTCnOcuKqI0a_oihw2WrgqC5u9iTbhfqM3y5Pnu1U64hIfPrmAl0gu-hGhyFA8Pn-d_dM7nXLMdzZ52ClgkPkg_aW0eT62jmWt47T7TM27omBpN_ngKCA-86-mEaju1ib6Z1m5vYqaiO5Ye9B1iHMqo_9iHW-YywC7gfmGFCT5JB_KFsdj1pX-1WrsBB-8S5aE_HcmbGT460f-4Dh7K3atPU1-hhrbE6xyohezkVXwdJnZgSW_O6iwU0oE2scbNq5dQ-B-K1jjtRrEq6vucxMqFldoyH00c4-cAnK_dnbKuLofFHusarmugQX6vCoCh55xtj7G1mKZ511s2zvEcLXJRkZPttsuF-R3bzYyEd63fow98FPD9_KRnZPsryICyywCsDa6xvd2H8Zs_K67zIsGBxED1wAHmcUxyKOQJ55yTDk"}},"jws_signature":"eyJhbGciOiJSUzI1NiIsImp3ayI6eyJhbGciOiJSUzI1NiIsImUiOiJBUUFCIiwia2V5X29wcyI6WyJ2ZXJpZnkiXSwia3R5IjoiUlNBIiwibiI6ImhTNEh5UDIwMWhfTFgyM3dDUGNVT1JFd0JJdlNhUTJrWjNHQmZJWEJ3LVNNZHZaa3ZnY3NRbmZkLXBydXk5V3JQdDlSODB3U2tFYVpMQlJ1b2lTYlJCUTV3NWR5TXBHek5YT2gzYzA4UTBzR3dfTzhmZmc1NHZrSDhlS0t5ajhoR3N6SXNGWEM3cFhjRkpKVGpPRUQ4S3Y2MkxDUDFtdjJSUXY5azE1ZzJwMU5kTk03X2JpS3NOTkxNMG9WTmM2R3NYZk1sOXphVEpwS1hzaC01R2NsOVdFcjB4UDNhVG1xbm1zMng1RTlnS1lMMll6cHA1aW1qcUowSzlPdmNGa1RDbk9jdUtxSTBhX29paHcyV3JncUM1dTlpVGJoZnFNM3k1UG51MVU2NGhJZlBybUFsMGd1LWhHaHlGQThQbi1kX2RNN25YTE1kelo1MkNsZ2tQa2dfYVcwZVQ2MmptV3Q0N1Q3VE0yN29tQnBOX25nS0NBLTg2LW1FYWp1MWliNloxbTV2WXFhaU81WWU5QjFpSE1xb185aUhXLVl5d0M3Z2ZtR0ZDVDVKQl9LRnNkajFwWC0xV3JzQkItOFM1YUVfSGNtYkdUNDYwZi00RGg3SzNhdFBVMS1oaHJiRTZ4eW9oZXprVlh3ZEpuWmdTV19PNml3VTBvRTJzY2JOcTVkUS1CLUsxamp0UnJFcTZ2dWN4TXFGbGRveUgwMGM0LWNBbktfZG5iS3VMb2ZGSHVzYXJtdWdRWDZ2Q29DaDU1eHRqN0cxbUtaNTExczJ6dkVjTFhKUmtaUHR0c3VGLVIzYnpZeUVkNjNmb3c5OEZQRDlfS1JuWlBzcnlJQ3l5d0NzRGE2eHZkMkg4WnNfSzY3eklzR0J4RUQxd0FIbWNVeHlLT1FKNTV5VERrIn19.eyJodHRwOi8vZXhhbXBsZS5jb20vaXNfcm9vdCI6dHJ1ZSwiaXNzIjoiam9lIn0.TKNUlw-VGxQJJK_KmeVF9h6VvVAwoR8XNk5fNBwLVKX2Cwaogoru4JdvlziXpsSWU_EQxkl3HvITuMl7qHviqAY3CY0glxGUB2BF81N6rRLMLuHjKofw34eT3psfXiS43fFslQc7SV0oJhOoooXw2-_mBf1DH5BRaO436L4cJhpTprAoyglKRuT071WvY7yOsWsy_Lm1u-uMAiVS2HoEBvPJqeEWKeQhvVCbqWGNAQPpcyaclMw5llwsniEeDpCUP7mI8SS2Dqgn9QkilYn3Yk-IdMKloRu4dJZfRqH2cC89GXGZsrHYMxXsB-EhFHl58EvXxnXo94qWxwYMOY_KE6PZ7XpXdypx7gbulWXDBNLi1KEdIQ8V2Yh7_mx1ag0Awk_uRZ4JTVt-P38rlhqcYFJHIlKZa0z5GLv7UPlaTge8hdjHhRWucS2xeNDDwNEzJqeJlFUdhkjR1VZtpMDirE1if9ygTsAhS-rbD3CpBNut5ICmKeI-NedU-wnkRgWaShxvVhb37HOGM_VyDVj_qT9Dey-tcLV_b0-w4a7m4E2AFc6hSu1unu6Y18MT5yDeCuT9FRzTMMNnFEDrp6-HSSAmS7_2i3aP4jgEe2K3adFhgNxQFtlfosH7p5J_ndIY08gusK2NCaBOPLU5hKgjUDGsdL4weYAgi2qKytFpjn8"}'

    cat <<EOF | zexe verify_jws_rs256_header_with_pk.zen jws_rs256_header_with_pk.json
Scenario 'w3c': jws
Given I have a 'string' named 'jws signature'
When I verify the jws signature in 'jws signature'
Then print the string 'rs256 signature verified'
EOF
    save_output verify_jws_rs256_header_with_pk.json
    assert_output '{"output":["rs256_signature_verified"]}'
}

@test "RSA: create jwk from keyring" {
    cat <<EOF | zexe jwk_from_rsa_keyring.zen RSA-keypair.json
Scenario 'w3c': jwk
Scenario 'rsa': (required)
Given that I am known as 'Alice'
and I have my 'keyring'
When I create the jwk of rsa public key
and I rename the 'jwk' to 'jwk_pk_from_sk_rsa'
When I create the jwk of rsa public key with private key
and I rename the 'jwk' to 'jwk_keypair_from_sk_rsa'
Then print the data
EOF
    save_output jwk_from_rsa_keyring.json
    assert_output '{"jwk_keypair_from_sk_rsa":{"d":"iZLFrTu7CX8HtAkIO5Ad-aoKAxbQOQITmQcLC_pyAZi2lpmEF79rvgQSPOpudKLrGNIXK5hWOTLQdZDKgFBqsrD4bqqEbukOzCu1fvSkcetOJqsH8lkXhry8sXY5YkGTvTL5KsMwuGpY3IOsnoAw0PmuQNAj2b9Aj95ryeBySpyn3kiEnlmm7Z9RIgSMpGKxdn0GWfg5ksgCfeFQUAbAC5diNc4sUlnmPRKnDF6qV9t0ut1xPMjHNLtL9N0s5prAuhsDRvyJxnt-3WQwxOOL--dn_ElPgsWeRz_JskqN5gTqRB63hV9fODVo14aASfIfPaFjZjYXfV5it_AfmUJBQ_fTDS9jMsqOZoTLTkQPfT6fN94m4mB2GuSQzljcFBR3GsZDO7D_Ae9G45RhN7cHPaHaWo2K4BV5sr_TSX7X0Td3vLsYxsfJtXH_cU4JbllSVGMul5lfO3Tojhhrg13FaifpsMFt2ZDWZpIp8b_YFSpcm1fkKOd8fsA_A1bPs39kQdEmhyHUpzH4KUqwhbueMfmIh3H9aXCRaGqoLKWevbDf0wRnBNBVRb1ErTem_K6DXBS54V8w6h1nfcae-gIICMCP2afCQUXi2NHSQBfWudWNc1FJfX0O4QDX-KQDGD49SSB6WIIQynMlIYg-fyQQQkDXvh394O4Mm_6_Am3OVtMYP-bYQk8VvW5-LZll5mFiQLbDFKJfah5KOxOXaO3vmhuVMDo4dWVoeQ897ZTKumz2UxICfTe1nV9hWcRYGdS06rzfxO7THgGdu5aiaj0SV4fPCRa9gTbEaUBZh51V1HlWQEXrY7ySxSwkspEa3z27mEc-5XFsUGnw8iPN0eJThImShPXbc7IY8Jw8gtDHqR3e5OrZsQd0-Ax4Y97kPExdvrFxCoaFfZM38LHBXG5qTiSlS6NKM5npkZox70qa22xdYaWSPbGLavlRzPdLvVBPdtq9fa6mPm9H39aNttaMVRF2MHPo7oa6Qa_ZTbwPTL50_p2mxqIdVyXPhmQLf8JBSG78VJRm3QM__aI6jvQEBFCfEKRG2DDM7W9RkHFKwSyKu9Yc1T_Dff83N0Au-6T3I55hhytHEZ_PWffUbGmB8fdiR0EXoH9ZNCeYI1noUd0ZYx_UGXTXOPVbytFpxPeVbnMEQZTs2UOBGUl_KjZrAUWt9cNvHTGrDl-chzwP17Ui85GSP5YbBCTnVLhBbjPvoWKBTBToQ4mMflgHLKU4BkF1OL0vkADMcGRpSHHbOtqUCE7IC32Nf-imv23p3rwgar_guwKw9081ViZgq1cMW9mLEgAr2GiH5So6tx1ccZySChcYVXO46Gy630p8-Lpz0uX74GI64vj2gz-q4xNDF2vAgxg5xPk3idzIriLUkEbDchyPDsvEooQeyMYZeeQ-HRG-N57xS2DsY4vXJBrUmOQB0RTAxZwZ-PxRinPEXcnjFNr5JkXiYVa8WLAXSTDPWa50cChg5ErsuYdQWl6tIDUESZd-oi12PAcK1qv-dTNun-fIS6Z0pa_b-ZIgxU2vd4S7PdF-B8pGKT0cUgfNLWmrGi_xSyhkyWWHy4cfcXobSEH49D5Tej4VjrKUiSgCQU7mbdkOSLSVQDNprnSd0ThtRG52SH-w0MvFsnx0wUgzG-COJChQ-IM9PSigZZ8qe_SKO_yz-fRm5pWO3uy5KeQCKwG9EdVd956B-fl7loo","e":"AQAB","kty":"RSA","n":"hS4HyP201h_LX23wCPcUOREwBIvSaQ2kZ3GBfIXBw-SMdvZkvgcsQnfd-pruy9WrPt9R80wSkEaZLBRuoiSbRBQ5w5dyMpGzNXOh3c08Q0sGw_O8ffg54vkH8eKKyj8hGszIsFXC7pXcFJJTjOED8Kv62LCP1mv2RQv9k15g2p1NdNM7_biKsNNLM0oVNc6GsXfMl9zaTJpKXsh-5Gcl9WEr0xP3aTmqnms2x5E9gKYL2Yzpp5imjqJ0K9OvcFkTCnOcuKqI0a_oihw2WrgqC5u9iTbhfqM3y5Pnu1U64hIfPrmAl0gu-hGhyFA8Pn-d_dM7nXLMdzZ52ClgkPkg_aW0eT62jmWt47T7TM27omBpN_ngKCA-86-mEaju1ib6Z1m5vYqaiO5Ye9B1iHMqo_9iHW-YywC7gfmGFCT5JB_KFsdj1pX-1WrsBB-8S5aE_HcmbGT460f-4Dh7K3atPU1-hhrbE6xyohezkVXwdJnZgSW_O6iwU0oE2scbNq5dQ-B-K1jjtRrEq6vucxMqFldoyH00c4-cAnK_dnbKuLofFHusarmugQX6vCoCh55xtj7G1mKZ511s2zvEcLXJRkZPttsuF-R3bzYyEd63fow98FPD9_KRnZPsryICyywCsDa6xvd2H8Zs_K67zIsGBxED1wAHmcUxyKOQJ55yTDk"},"jwk_pk_from_sk_rsa":{"e":"AQAB","kty":"RSA","n":"hS4HyP201h_LX23wCPcUOREwBIvSaQ2kZ3GBfIXBw-SMdvZkvgcsQnfd-pruy9WrPt9R80wSkEaZLBRuoiSbRBQ5w5dyMpGzNXOh3c08Q0sGw_O8ffg54vkH8eKKyj8hGszIsFXC7pXcFJJTjOED8Kv62LCP1mv2RQv9k15g2p1NdNM7_biKsNNLM0oVNc6GsXfMl9zaTJpKXsh-5Gcl9WEr0xP3aTmqnms2x5E9gKYL2Yzpp5imjqJ0K9OvcFkTCnOcuKqI0a_oihw2WrgqC5u9iTbhfqM3y5Pnu1U64hIfPrmAl0gu-hGhyFA8Pn-d_dM7nXLMdzZ52ClgkPkg_aW0eT62jmWt47T7TM27omBpN_ngKCA-86-mEaju1ib6Z1m5vYqaiO5Ye9B1iHMqo_9iHW-YywC7gfmGFCT5JB_KFsdj1pX-1WrsBB-8S5aE_HcmbGT460f-4Dh7K3atPU1-hhrbE6xyohezkVXwdJnZgSW_O6iwU0oE2scbNq5dQ-B-K1jjtRrEq6vucxMqFldoyH00c4-cAnK_dnbKuLofFHusarmugQX6vCoCh55xtj7G1mKZ511s2zvEcLXJRkZPttsuF-R3bzYyEd63fow98FPD9_KRnZPsryICyywCsDa6xvd2H8Zs_K67zIsGBxED1wAHmcUxyKOQJ55yTDk"}}'
}

@test "RSA: create jwk from public key" {
    cat <<EOF | zexe jwk_from_rsa_pk.zen RSA-pubkey.json
Scenario 'w3c': jwk
Scenario 'rsa': (required)
Given I have a 'rsa public key' inside 'Authority'
When I create the jwk of rsa public key 'rsa public key'
and I rename the 'jwk' to 'jwk_pk_from_pk_rsa'
Then print the 'jwk_pk_from_pk_rsa'
EOF
    save_output jwk_from_rsa_pk.json
    assert_output '{"jwk_pk_from_pk_rsa":{"e":"AQAB","kty":"RSA","n":"hS4HyP201h_LX23wCPcUOREwBIvSaQ2kZ3GBfIXBw-SMdvZkvgcsQnfd-pruy9WrPt9R80wSkEaZLBRuoiSbRBQ5w5dyMpGzNXOh3c08Q0sGw_O8ffg54vkH8eKKyj8hGszIsFXC7pXcFJJTjOED8Kv62LCP1mv2RQv9k15g2p1NdNM7_biKsNNLM0oVNc6GsXfMl9zaTJpKXsh-5Gcl9WEr0xP3aTmqnms2x5E9gKYL2Yzpp5imjqJ0K9OvcFkTCnOcuKqI0a_oihw2WrgqC5u9iTbhfqM3y5Pnu1U64hIfPrmAl0gu-hGhyFA8Pn-d_dM7nXLMdzZ52ClgkPkg_aW0eT62jmWt47T7TM27omBpN_ngKCA-86-mEaju1ib6Z1m5vYqaiO5Ye9B1iHMqo_9iHW-YywC7gfmGFCT5JB_KFsdj1pX-1WrsBB-8S5aE_HcmbGT460f-4Dh7K3atPU1-hhrbE6xyohezkVXwdJnZgSW_O6iwU0oE2scbNq5dQ-B-K1jjtRrEq6vucxMqFldoyH00c4-cAnK_dnbKuLofFHusarmugQX6vCoCh55xtj7G1mKZ511s2zvEcLXJRkZPttsuF-R3bzYyEd63fow98FPD9_KRnZPsryICyywCsDa6xvd2H8Zs_K67zIsGBxED1wAHmcUxyKOQJ55yTDk"}}'
}
