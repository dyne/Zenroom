load ../bats_setup
load ../bats_zencode

SUBDOC=w3c

# How it works:
# - The Oracle create private and public keys
# - The public keys are sent to the Controller that creates the did-document
# - Now the Oracle can sign documents using its keys
# - Everyone with the did-document can verify the signatures


@test "Generate oracle private keys" {
    cat <<EOF | zexe privatekey_gen.zen
Scenario 'ecdh': Create the key
Scenario 'ethereum': Create key
Scenario 'reflow': Create the key
Scenario 'schnorr': Create the key
Scenario 'qp': create the key
Scenario 'eddsa' : create the key

Given nothing

# Here we are creating the keys
When I create the ecdh key
When I create the eddsa key
When I create the ethereum key
When I create the reflow key
When I create the schnorr key
When I create the bitcoin key
When I create the dilithium key

Then print 'keyring'
EOF
    save_output "privatekey_gen.json"
}


@test "Generate oracle public keys/address" {
    cat <<EOF | zexe pubkey_gen.zen privatekey_gen.json
Scenario 'ecdh': Create the key
Scenario 'ethereum': Create key
Scenario 'reflow': Create the key
Scenario 'schnorr': Create the key
Scenario 'qp': create the key
Scenario 'eddsa' : create the key

Given I have the 'keyring'

When I create the ecdh public key
When I create the eddsa public key
When I create the ethereum address
When I create the reflow public key
When I create the schnorr public key
When I create the bitcoin public key
When I create the dilithium public key

Then print the 'ecdh public key'
Then print the 'eddsa public key'
Then print the 'ethereum address'
Then print the 'reflow public key'
Then print the 'schnorr public key'
Then print the 'bitcoin public key'
Then print the 'dilithium public key'
EOF
    save_output "pubkey_gen.json"
}


@test "Insert public keys inside identity" {
    cat <<EOF | save_asset identity.json
{
	"identity": {
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
		"uid": "zenswarm.zenroom.org:25931",
		"ip": "zenswarm.zenroom.org",
		"baseUrl": "https://zenswarm.zenroom.org",
		"port_https": "25931",
		"version": "2",
		"tracker": "https://apiroom.net/",
		"description": "restroom-mw",
		"State": "NONE",
		"Country": "ES",
		"L0": "planetmint"
	}
}
EOF
    cat <<EOF | zexe input_for_did_document.zen pubkey_gen.json identity.json
Given I have a 'string dictionary' named 'identity'
Given I have a 'string' named 'dilithium public key'
Given I have a 'string' named 'schnorr public key'
Given I have a 'string' named 'ecdh public key'
Given I have a 'string' named 'eddsa public key'
Given I have a 'string' named 'reflow public key'
Given I have a 'string' named 'ethereum address'

When I insert 'dilithium public key' in 'identity'
When I insert 'ecdh public key' in 'identity'
When I insert 'eddsa public key' in 'identity'
When I insert 'schnorr public key' in 'identity'
When I insert 'reflow public key' in 'identity'
When I insert 'ethereum address' in 'identity'
Then print the 'identity'
EOF
    save_output "complete_identity.json"


}


@test "the Controller creates the did-document of the Oracle" {
    cat <<EOF | save_asset controller.json
{
	"@context": [
		"https://www.w3.org/ns/did/v1",
		"https://dyne.github.io/W3C-DID/specs/EcdsaSecp256k1_b64.json",
		"https://dyne.github.io/W3C-DID/specs/ReflowBLS12381_b64.json",
		"https://dyne.github.io/W3C-DID/specs/SchnorrBLS12381_b64.json",
		"https://w3id.org/security/suites/secp256k1-2020/v1",
		{
			"Country": "https://schema.org/Country",
			"State": "https://schema.org/State",
			"description": "https://schema.org/description",
			"url": "https://schema.org/url"
		}
	],
	"type": "EcdsaSecp256k1VerificationKey2019",
	"W3C-DID-dyne-issuer": {
		"ecdh_public_key": "BLL50JCBTKJZc+Pc5sC9cW7Feyx728h3TAEkWYIcOUZzukbPVPYIfOjDptkYIv/GGSI/XFh778eAFHtnkJppLls=",
		"keyring": {
			"ecdh": "Fi9XW2IWlBrUWsTmgKXeE9+LzlrQyNLPb/7tWwwuOSQ="
		}
	},
	"proof": {
		"type": "EcdsaSecp256k1Signature2019",
		"proofPurpose": "assertionMethod",
		"created": "0"
	},
	"misc-input": {
		"controller": "did:dyne:controller:BLL50JCBTKJZc+Pc5sC9cW7Feyx728h3TAEkWYIcOUZzukbPVPYIfOjDptkYIv/GGSI/XFh778eAFHtnkJppLls="
	},
	"ethereum_address": "8388f6a2a4940c3fe14d640ddf151aa771f03b81"
}
EOF
    cat <<EOF | zexe did_doc_gen.zen controller.json complete_identity.json
Scenario 'w3c': sign JSON

# controller
Given I am 'W3C-DID-dyne-issuer'
Given I have my 'keyring'
Given I have a 'string dictionary' named 'misc-input'
# service
Given I have a 'string dictionary' named 'service' in 'identity'
# identity
Given I have a 'string' named 'Country' in 'identity'
Given I have a 'string' named 'State' in 'identity'
#Given I have a 'string' named 'baseUrl' in 'identity'
#Given I have a 'string' named 'port_http' in 'identity'
Given I have a 'string' named 'description' inside 'identity'
Given I have a 'string' named 'ecdh_public_key' in 'identity'
Given I have a 'string' named 'eddsa_public_key' in 'identity'
Given I have a 'string' named 'reflow_public_key' in 'identity'
Given I have a 'string' named 'schnorr_public_key' in 'identity'
Given I have a 'string' named 'dilithium_public_key' in 'identity'
Given I have a 'string' named 'ethereum_address' in 'identity'
# context and proof
Given I have a 'string array' named '@context'
Given I have a 'string dictionary' named 'proof'

### DID-Document
When I create the 'string dictionary' named 'did document'

## @context
When I insert '@context' in 'did document'

## id
When I set 'did:dyne:id:' to 'did:dyne:id:' as 'string'
When I append 'ecdh_public_key' to 'did:dyne:id:'
When I copy the 'did:dyne:id:' to 'id'
When I insert 'id' in 'did document'

## alsoKnownAs
When I set 'alsoKnownAs' to 'did:dyne:fabchain:' as 'string'
When I append 'ecdh public key' to 'alsoKnownAs'
When I insert 'alsoKnownAs' in 'did document'

## Country
When I insert 'Country' in 'did document'

## State
When I insert 'State' in 'did document'

## description
When I insert 'description' in 'did document'

## veririfcationMethod
When I create the 'string array' named 'verificationMethod'

# 1
When I create the 'string dictionary' named 'verification-key1'
# pk
When I copy 'ecdh public key' to 'publicKeyBase64'
When I insert 'publicKeyBase64' in 'verification-key1'
# type
When I set 'type' to 'EcdsaSecp256k1VerificationKey_b64' as 'string'
When I insert 'type' in 'verification-key1'
# id
When I copy 'did:dyne:id:' to 'id'
When I set '#key1' to '#key1' as 'string'
When I append '#key1' to 'id'
When I insert 'id' in 'verification-key1'
# controller
When I create the copy of 'controller' from dictionary 'misc-input'
When I rename the 'copy' to 'controller'
When I insert 'controller' in 'verification-key1'

When I insert 'verification-key1' in 'verificationMethod'

# 2
When I create the 'string dictionary' named 'verification-key2'
# pk
When I copy 'reflow public key' to 'publicKeyBase64'
When I insert 'publicKeyBase64' in 'verification-key2'
# type
When I set 'type' to 'ReflowBLS12381VerificationKey_b64' as 'string'
When I insert 'type' in 'verification-key2'
# id
When I copy 'did:dyne:id:' to 'id'
When I set '#key2' to '#key2' as 'string'
When I append '#key2' to 'id'
When I insert 'id' in 'verification-key2'
# controller
When I create the copy of 'controller' from dictionary 'misc-input'
When I rename the 'copy' to 'controller'
When I insert 'controller' in 'verification-key2'

When I insert 'verification-key2' in 'verificationMethod'

# 3
When I create the 'string dictionary' named 'verification-key3'
# pk
When I copy 'schnorr public key' to 'publicKeyBase64'
When I insert 'publicKeyBase64' in 'verification-key3'
# type
When I set 'type' to 'SchnorrBLS12381VerificationKey_b64' as 'string'
When I insert 'type' in 'verification-key3'
# id
When I copy 'did:dyne:id:' to 'id'
When I set '#key3' to '#key3' as 'string'
When I append '#key3' to 'id'
When I insert 'id' in 'verification-key3'
# controller
When I create the copy of 'controller' from dictionary 'misc-input'
When I rename the 'copy' to 'controller'
When I insert 'controller' in 'verification-key3'

When I insert 'verification-key3' in 'verificationMethod'

# 4
When I create the 'string dictionary' named 'verification-key4'
# pk
When I copy 'dilithium public key' to 'publicKeyBase64'
When I insert 'publicKeyBase64' in 'verification-key4'
# type
When I set 'type' to 'Dilithium2VerificationKey_b64' as 'string'
When I insert 'type' in 'verification-key4'
# id
When I copy 'did:dyne:id:' to 'id'
When I set '#key4' to '#key4' as 'string'
When I append '#key4' to 'id'
When I insert 'id' in 'verification-key4'
# controller
When I create the copy of 'controller' from dictionary 'misc-input'
When I rename the 'copy' to 'controller'
When I insert 'controller' in 'verification-key4'

When I insert 'verification-key4' in 'verificationMethod'

# 5
When I create the 'string dictionary' named 'verification-key5'
# pk
When I copy 'eddsa public key' to 'publicKeyBase58'
When I insert 'publicKeyBase58' in 'verification-key5'
# type
When I set 'type' to 'Ed25519VerificationKey2018' as 'string'
When I insert 'type' in 'verification-key5'
# id
When I copy 'did:dyne:id:' to 'id'
When I set '#key5' to '#key5' as 'string'
When I append '#key5' to 'id'
When I insert 'id' in 'verification-key5'
# controller
When I create the copy of 'controller' from dictionary 'misc-input'
When I rename the 'copy' to 'controller'
When I insert 'controller' in 'verification-key5'

When I insert 'verification-key5' in 'verificationMethod'

# 6
When I create the 'string dictionary' named 'verification-key6'
# address
# this follows the CAIP-10(https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-10.md) spec
# thus it is: namespace + ":" + chain_id + ":" + address
When I set 'blockchainAccountId' to 'eip155:1717658228:0x' as 'string'
When I append 'ethereum address' to 'blockchainAccountId'
When I insert 'blockchainAccountId' in 'verification-key6'
# type
When I set 'type' to 'EcdsaSecp256k1RecoveryMethod2020' as 'string'
When I insert 'type' in 'verification-key6'
# id
When I copy 'did:dyne:id:' to 'id'
When I set '#blockchainAccountId' to '#blockchainAccountId' as 'string'
When I append '#blockchainAccountId' to 'id'
When I insert 'id' in 'verification-key6'
# controller
When I create the copy of 'controller' from dictionary 'misc-input'
When I rename the 'copy' to 'controller'
When I insert 'controller' in 'verification-key6'

When I insert 'verification-key6' in 'verificationMethod'

When I insert 'verificationMethod' in 'did document'

## service
When I insert 'service' in 'did document'

## Proof
# jws
When I create the jws signature of 'did document'
When I insert 'jws' in 'proof'
# created
# When I insert 'created' in 'proof'
# verificationMethod
When I create the copy of 'controller' from dictionary 'misc-input'
When I rename the 'copy' to 'verificationMethod'
When I append '#key1' to 'verificationMethod'
When I insert 'verificationMethod' in 'proof'

When I insert 'proof' in 'did document'

### DID-Document ended

### mpack of the DID-Document
# When I create the mpack of 'DID'
# When I rename the 'mpack' to 'DID-mpack'

### create the address:nonce that will be incremented in the next script
# When I copy 'ethereum address' to 'address:nonce'
# When I set ':nonce' to ':nonce' as 'string'
# When I append ':nonce' to 'address:nonce'

### print all out
then print the 'did document'
EOF
    save_output "did_document.json"
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
Scenario 'schnorr': sign
Scenario 'qp': sign
Scenario 'eddsa': sign

Given I have a 'keyring'
Given I have a 'string dictionary' named 'json'

When I create the ecdh signature of 'json'
When I create the schnorr signature of 'json'
When I create the dilithium signature of 'json'
When I create the eddsa signature of 'json'

Then print the 'ecdh signature'
Then print the 'schnorr signature'
Then print the 'dilithium signature'
Then print the 'eddsa signature'
Then print the 'json'
EOF
    save_output "signed.json"


}

@test "Everyone that has the did documetn can now verify the signatures" {
cat <<EOF | zexe verify_signatures.zen did_document.json signed.json
Scenario 'w3c': did document
Scenario 'ecdh': verify sign
Scenario 'schnorr': verify sign
Scenario 'qp': verify sign
Scenario 'eddsa':verify sign

# load did document and signatures
Given I have a 'did document'
and I have a 'ecdh signature'
and I have a 'schnorr signature'
and I have a 'dilithium signature'
and I have a 'eddsa signature'
and I have a 'string dictionary' named 'json'

# Here I retrieve all the public keys/address from
# the verififcationMethod
When I create the verificationMethod of 'did document'

# Here I use the publc keys to verify the sgnatures

When I pickup from path 'verificationMethod.ecdh_public_key'
When I verify the 'json' has a ecdh signature in 'ecdh signature' by 'ecdh public key'

When I pickup from path 'verificationMethod.schnorr_public_key'
When I verify the 'json' has a schnorr signature in 'schnorr signature' by 'schnorr public key'

When I pickup from path 'verificationMethod.dilithium_public_key'
When I verify the 'json' has a dilithium signature in 'dilithium signature' by 'dilthium public key'

When I pickup from path 'verificationMethod.eddsa_public_key'
When I verify the 'json' has a eddsa signature in 'eddsa signature' by 'eddsa public key'

# verification is succesfull
Then print the string 'signature verified!!!'
EOF
}
