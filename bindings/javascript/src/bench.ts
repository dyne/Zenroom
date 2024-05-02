const ITERATIONS = 300
import bench from 'nanobench';


import {zencode_exec, // zenroom_exec,
// zenroom_hash_init, zenroom_hash_update, zenroom_hash_final, zenroom_hash
} from "./index";

const GENERATE_KEYRING =`
# Here we are loading all the scenarios needed for the keys creations
Scenario 'ecdh': Create the key
Scenario 'ethereum': Create key
Scenario 'reflow': Create the key
Scenario 'schnorr': Create the key
Scenario 'eddsa': Create the key

Given nothing

# Here we are creating the keys
When I create the ecdh key
When I create the ethereum key
When I create the reflow key
When I create the schnorr key
When I create the bitcoin key
When I create the eddsa key

Then print the 'keyring'
`
const GENERATE_PUBKEYS =`
# Loading scenarios
Scenario 'ecdh': Create the public key
Scenario 'ethereum': Create the address
Scenario 'reflow': Create the public key
Scenario 'schnorr': Create the public key
Scenario 'eddsa': Create the public key

# Loading the private keys
Given I have the 'keyring'

# Generating the public keys
When I create the ecdh public key
When I create the reflow public key
When I create the schnorr public key
When I create the bitcoin public key
When I create the eddsa public key

# With Ethereum the 'ethereum address' is what we want to create, rather than a public key
When I create the ethereum address

# Here we pring all the output
Then print the 'ecdh public key'
Then print the 'eddsa public key'
Then print the 'reflow public key'
Then print the 'schnorr public key'
Then print the 'bitcoin public key'
Then print the 'ethereum address'
`
const SIGN = `
Scenario 'ecdh': create the signature of an object
Given I have the 'keyring'
Given that I have a 'string' named 'myMessage'

When I create the signature of 'myMessage'
When I rename the 'signature' to 'myMessage.signature'


Then print the 'myMessage'
Then print the 'myMessage.signature'
`

const SIGN_DATA = `
{
  "myMessage": "Dear Bob, your name is too short, goodbye - Alice."
}
`

const VERIFY = `
rule check version 2.0.0

Scenario 'ecdh': Bob verifies the signature from Alice
Given I have a 'ecdh public key' from 'Alice'
Given I have a 'string' named 'myMessage'
Given I have a 'signature' named 'myMessage.signature'
When I verify the 'myMessage' has a signature in 'myMessage.signature' by 'Alice'
Then print the string 'ok'
Then print the 'myMessage'
`

const signverify = async () => {
  const keyring = (await zencode_exec(GENERATE_KEYRING)).result;
  const pubkeys = (await zencode_exec(GENERATE_PUBKEYS, {keys: keyring})).result;
  const sign = (await zencode_exec(SIGN, {data: SIGN_DATA, keys: keyring})).result;
  const verify = (await zencode_exec(VERIFY,
    {data: sign, keys: `{"Alice": ${pubkeys}}`})).result;
  verify;
}

bench('sign and verify '+ITERATIONS+' times', (b) => {
  b.start();
  for(let i=0; i<ITERATIONS; i++) {
    signverify();
  }
  b.end();
})

