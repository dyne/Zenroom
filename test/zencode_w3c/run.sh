#!/usr/bin/env bash

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

cat <<EOF | save w3c W3C-VC_unsigned.json
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

cat <<EOF | zexe W3C-VC_keygen.zen | save w3c W3C-VC_keypair.json
Scenario 'ecdh': Create the keypair
Given that I am known as 'Alice'
When I create the ecdh key
Then print my data
EOF

cat <<EOF | zexe W3C-VC_issuerKeygen.zen  | save w3c W3C-VC_issuerKeypair.json
Scenario 'ecdh': Create the keypair
Given that I am known as 'Authority'
When I create the ecdh key
Then print my data
EOF


cat <<EOF | zexe W3C-VC_pubkey.zen -k W3C-VC_issuerKeypair.json | save w3c W3C-VC_pubkey.json
Scenario 'ecdh': Publish the public key
Given that I am known as 'Authority'
and I have my 'keyring'
When I create the ecdh public key
Then print my 'ecdh public key'
EOF

cat <<EOF | zexe W3C-VC_sign.zen -a W3C-VC_unsigned.json -k W3C-VC_issuerKeypair.json | save w3c W3C-VC_signed.json
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

cat <<EOF | zexe W3C-VC_verify.zen -a W3C-VC_signed.json -k W3C-VC_pubkey.json | save w3c W3C-VC_output.json
Scenario 'w3c': verify signature
Scenario 'ecdh': (required)
Given I have a 'ecdh public key' inside 'Authority'
Given I have a 'verifiable credential' named 'my-vc'
When I verify the verifiable credential named 'my-vc'
Then print the string 'W3C CREDENTIAL IS VALID'
EOF

cat <<EOF | zexe W3C-VC_extract.zen -a W3C-VC_signed.json | save w3c W3C-VC_extracted_verification_method.json
Scenario 'w3c' : extract verification method
Given I have a 'verifiable credential' named 'my-vc'
When I get the verification method in 'my-vc'
Then print 'verification method' as 'string'
EOF

