#!/usr/bin/env bash

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

cat <<EOF > unsigned.json
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
"pubkey_url": "https://dyne.org/marziano/keys/1"
}
EOF

cat <<EOF | zexe keygen.zen > keypair.json
Scenario 'ecdh': Create the keypair
Given that I am known as 'Alice'
When I create the keypair
Then print my data
EOF

cat <<EOF | zexe pubkey.zen -k keypair.json > pubkey.json
Scenario 'ecdh': Publish the public key
Given that I am known as 'Alice'
and I have my 'keypair'
Then print my 'public key' from 'keypair'
EOF

cat <<EOF | debug sign.zen -a unsigned.json -k keypair.json > signed.json
Scenario w3c
Scenario ecdh
Given that I am 'Alice'
and I have my 'keypair'
and I have a 'verifiable credential' named 'my-vc'
and I have a 'string' named 'pubkey url'
When I sign the verifiable credential named 'my-vc'
and I set the verification method in 'my-vc' to 'pubkey url'
Then print 'my-vc' as 'string'
EOF

cat <<EOF | debug verify.zen -a signed.json -k pubkey.json
Scenario w3c
Scenario ecdh
Given that I am 'Alice'
and I have my 'public key'
and I have a 'verifiable credential' named 'my-vc'
When I verify the verifiable credential named 'my-vc'
Then print 'W3C CRED IS VALID'
EOF


