load ../bats_setup
load ../bats_zencode

SUBDOC=w3c

# How it works:
# - The Oracle creates private and public keys
# - The Oracle creates its did document and send it to the controller that notarize it
# - The Oracle can sign documents using its keys
# - Everyone with the did-document can verify the signatures


@test "Generate oracle private keys" {
    cat <<EOF | zexe privatekey_gen.zen
Scenario 'ecdh': Create the key
Scenario 'ethereum': Create key
Scenario 'reflow': Create the key
Scenario 'eddsa' : create the key

Given nothing

# Here we are creating the keys
When I create the ecdh key
When I create the eddsa key
When I create the ethereum key
When I create the reflow key
When I create the bitcoin key

Then print 'keyring'
EOF
    save_output "privatekey_gen.json"
}

@test "Generate oracle public keys/address" {
    cat <<EOF | zexe pubkey_gen.zen privatekey_gen.json
Scenario 'ecdh': Create the key
Scenario 'ethereum': Create key
Scenario 'reflow': Create the key
Scenario 'eddsa' : create the key

Given I have the 'keyring'

When I create the ecdh public key
When I create the eddsa public key
When I create the ethereum address
When I create the reflow public key
When I create the bitcoin public key

Then print the 'ecdh public key' as 'base58'
Then print the 'eddsa public key' as 'base58'
Then print the 'ethereum address'
Then print the 'reflow public key' as 'base58'
Then print the 'bitcoin public key' as 'base58'
EOF
    save_output "pubkey_gen.json"
}

@test "The Oracle creates its did document" {
    cat <<EOF | save_asset data.json
{
	"service": [
		{
			"id": "did:dyne:zenswarm-api#zenswarm-oracle-announce",
			"serviceEndpoint": "http://172.104.233.185:28634/api/zenswarm-oracle-announce",
			"type": "LinkedDomains"
		},
		{
			"id": "did:dyne:zenswarm-api#ethereum-to-ethereum-notarization.chain",
			"serviceEndpoint": "http://172.104.233.185:28634/api/ethereum-to-ethereum-notarization.chain",
			"type": "LinkedDomains"
		},
		{
			"id": "did:dyne:zenswarm-api#zenswarm-oracle-get-identity",
			"serviceEndpoint": "http://172.104.233.185:28634/api/zenswarm-oracle-get-identity",
			"type": "LinkedDomains"
		},
		{
			"id": "did:dyne:zenswarm-api#zenswarm-oracle-http-post",
			"serviceEndpoint": "http://172.104.233.185:28634/api/zenswarm-oracle-http-post",
			"type": "LinkedDomains"
		},
		{
			"id": "did:dyne:zenswarm-api#zenswarm-oracle-key-issuance.chain",
			"serviceEndpoint": "http://172.104.233.185:28634/api/zenswarm-oracle-key-issuance.chain",
			"type": "LinkedDomains"
		},
		{
			"id": "did:dyne:zenswarm-api#zenswarm-oracle-ping.zen",
			"serviceEndpoint": "http://172.104.233.185:28634/api/zenswarm-oracle-ping.zen",
			"type": "LinkedDomains"
		},
		{
			"id": "did:dyne:zenswarm-api#sawroom-to-ethereum-notarization.chain",
			"serviceEndpoint": "http://172.104.233.185:28634/api/sawroom-to-ethereum-notarization.chain",
			"type": "LinkedDomains"
		},
		{
			"id": "did:dyne:zenswarm-api#zenswarm-oracle-get-timestamp.zen",
			"serviceEndpoint": "http://172.104.233.185:28634/api/zenswarm-oracle-get-timestamp.zen",
			"type": "LinkedDomains"
		},
		{
			"id": "did:dyne:zenswarm-api#zenswarm-oracle-update",
			"serviceEndpoint": "http://172.104.233.185:28634/api/zenswarm-oracle-update",
			"type": "LinkedDomains"
		}
	],
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
	"description":"restroom-mw"
}
EOF
    cat <<EOF | zexe did_doc_gen.zen data.json pubkey_gen.json
Scenario 'w3c': sign JSON
# public keys, description, State and Country
Given I have a 'string' named 'ecdh_public_key'
Given I have a 'string' named 'reflow_public_key'
Given I have a 'string' named 'ethereum_address'
Given I have a 'string' named 'eddsa_public_key'
Given I have a 'string' named 'bitcoin_public_key'
Given I have a 'string' named 'description'
Given I have a 'string' named 'State'
Given I have a 'string' named 'Country'

# context and service
Given I have a 'string array' named '@context'
Given I have a 'string array' named 'service'

### DID-Document
When I create the 'string dictionary' named 'did document'

## @context
When I insert '@context' in 'did document'
## service
When I insert 'service' in 'did document'
## State
When I insert 'State' in 'did document'
## Country
When I insert 'Country' in 'did document'
## description
When I insert 'description' in 'did document'

## id
When I set 'did:dyne:' to 'did:dyne:oracle:' as 'string'
When I append 'eddsa public key' to 'did:dyne:'
When I copy the 'did:dyne:' to 'id'
When I insert 'id' in 'did document'

## alsoKnownAs
When I set 'alsoKnownAs' to 'did:dyne:ganache:' as 'string'
When I append 'eddsa public key' to 'alsoKnownAs'
When I insert 'alsoKnownAs' in 'did document'

## veririfcationMethod
When I create the 'string array' named 'verificationMethod'

# 1-ecdsa public key
When I create the 'string dictionary' named 'verification-key'
# pk
When I copy 'ecdh public key' to 'publicKeyBase58' 
When I insert 'publicKeyBase58' in 'verification-key'
# type
When I set 'type' to 'EcdsaSecp256k1VerificationKey2019' as 'string'
When I insert 'type' in 'verification-key'
# id
When I copy 'did:dyne:' to 'id'
When I set '#ecdh_public_key' to '#ecdh_public_key' as 'string'
When I append '#ecdh_public_key' to 'id'
When I insert 'id' in 'verification-key'
# controller
When I copy 'did:dyne:' to 'controller'
When I insert 'controller' in 'verification-key'
When I insert 'verification-key' in 'verificationMethod'

# 2-reflow public key
When I create the 'string dictionary' named 'verification-key'
# pk
When I copy 'reflow public key' to 'publicKeyBase58' 
When I insert 'publicKeyBase58' in 'verification-key'
# type
When I set 'type' to 'ReflowBLS12381VerificationKey' as 'string'
When I insert 'type' in 'verification-key'
# id
When I copy 'did:dyne:' to 'id'
When I set '#reflow_public_key' to '#reflow_public_key' as 'string'
When I append '#reflow_public_key' to 'id'
When I insert 'id' in 'verification-key'
# controller
When I copy 'did:dyne:' to 'controller'
When I insert 'controller' in 'verification-key'
When I insert 'verification-key' in 'verificationMethod'

# 3-bitcoin public key
When I create the 'string dictionary' named 'verification-key'
# pk
When I copy 'bitcoin public key' to 'publicKeyBase58' 
When I insert 'publicKeyBase58' in 'verification-key'
# type
When I set 'type' to 'EcdsaSecp256k1VerificationKey2019' as 'string'
When I insert 'type' in 'verification-key'
# id
When I copy 'did:dyne:' to 'id'
When I set '#bitcoin_public_key' to '#bitcoin_public_key' as 'string'
When I append '#bitcoin_public_key' to 'id'
When I insert 'id' in 'verification-key'
# controller
When I copy 'did:dyne:' to 'controller'
When I insert 'controller' in 'verification-key'
When I insert 'verification-key' in 'verificationMethod'

# 4-eddsa public key
When I create the 'string dictionary' named 'verification-key'
# pk
When I copy 'eddsa_public_key' to 'publicKeyBase58'
When I insert 'publicKeyBase58' in 'verification-key'
# type
When I set 'type' to 'Ed25519VerificationKey2018' as 'string'
When I insert 'type' in 'verification-key'
# id
When I copy 'did:dyne:' to 'id'
When I set '#eddsa_public_key' to '#eddsa_public_key' as 'string'
When I append '#eddsa_public_key' to 'id'
When I insert 'id' in 'verification-key'
# controller
When I copy 'did:dyne:' to 'controller'
When I insert 'controller' in 'verification-key'
When I insert 'verification-key' in 'verificationMethod'

# 5-ethereum address
When I create the 'string dictionary' named 'verification-key'
# address
# this follows the CAIP-10(https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-10.md) spec
# thus it is: namespace + ":" + chain_id + ":" + address
When I set 'blockchainAccountId' to 'eip155:1717658228:0x' as 'string'
When I append 'ethereum address' to 'blockchainAccountId'
When I insert 'blockchainAccountId' in 'verification-key'
# type
When I set 'type' to 'EcdsaSecp256k1RecoveryMethod2020' as 'string'
When I insert 'type' in 'verification-key'
# id
When I copy 'did:dyne:' to 'id'
When I set '#ethereum_address' to '#ethereum_address' as 'string'
When I append '#ethereum_address' to 'id'
When I insert 'id' in 'verification-key'
# controller
When I copy 'did:dyne:' to 'controller'
When I insert 'controller' in 'verification-key'
When I insert 'verification-key' in 'verificationMethod'

When I insert 'verificationMethod' in 'did document'
### DID-Document ended

### save DID document
Then print the 'did document'
EOF
    save_output "did_document.json"
}

@test "the Oracle sign the did document" {
    cat <<EOF | zexe did_doc_sign.zen privatekey_gen.json did_document.json
    Scenario 'eddsa': sign the did doc

    Given I have a 'string dictionary' named 'did document'
    Given I have a 'keyring'

    When I create the json of 'did document'
    When I create the eddsa signature of 'json'

    Then print the 'did document'
    Then print the 'eddsa signature'
EOF
    save_output "did_document_signed.json"
}

@test "the Controller verify the signature" {
    cat <<EOF | zexe did_doc_sign.zen did_document_signed.json
    Scenario 'w3c': did doc
    Scenario 'eddsa': verify signature

    Given I have a 'string dictionary' named 'did document'
    Given I have a 'eddsa signature'

    When I create the verificationMethod of 'did document'
    When I pickup a 'eddsa_public_key' from path 'verificationMethod.eddsa_public_key'

    When I create the json of 'did document'
    When I verify the 'json' has a eddsa signature in 'eddsa signature' by 'eddsa public key'

    Then print the string 'did document signature verified'
EOF
    save_output "did_document_signed.json"
}

@test "now the Oracle sign different documents with its keys" {
    cat <<EOF | save_asset to_sign.json
{
	"json": {
		"simple message": "hello world",
		"simple dictionary": { "hello" : "world" },
		"simple array": [ "hello", "world" ]
	}
}
EOF
    cat <<EOF | zexe oracle_signature.zen privatekey_gen.json to_sign.json
Scenario 'ecdh': sign
Scenario 'eddsa': sign

Given I have a 'keyring'
Given I have a 'string dictionary' named 'json'

When I create the ecdh signature of 'json'
When I create the eddsa signature of 'json'

Then print the 'ecdh signature'
Then print the 'eddsa signature'
Then print the 'json'
EOF
    save_output "signed.json"
}

@test "Everyone that has the did document can now verify the signatures" {
cat <<EOF | zexe verify_signatures.zen did_document.json signed.json
Scenario 'w3c': did document
Scenario 'ecdh': verify sign
Scenario 'eddsa':verify sign

# load did document and signatures
Given I have a 'did document'
and I have a 'ecdh signature'
and I have a 'eddsa signature'
and I have a 'string dictionary' named 'json'

# Here I retrieve all the public keys/address from
# the verififcationMethod
When I create the verificationMethod of 'did document'

# Here I use the publc keys to verify the sgnatures

When I pickup from path 'verificationMethod.ecdh_public_key'
When I verify the 'json' has a ecdh signature in 'ecdh signature' by 'ecdh public key'

When I pickup from path 'verificationMethod.eddsa_public_key'
When I verify the 'json' has a eddsa signature in 'eddsa signature' by 'eddsa public key'

# verification is succesfull
Then print the string 'signature verified!!!'
EOF
}
