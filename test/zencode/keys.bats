load ../bats_setup
load ../bats_zencode
SUBDOC=keys

@test "Generate key seed" {
    cat <<EOF >generate-key-seed.keys
{
	"seed": "pNivlLFjZesFAqSG3qDobmrhKeWkGtPuUBeJ3FmkAWQ="
}
EOF

    cat <<EOF | zexe generate-key-seed.zen generate-key-seed.keys
Rule check version 2.0.0
Scenario 'ecdh': Create the key
Scenario 'ethereum': Create key
Scenario 'reflow': Create the key
Scenario 'schnorr': Create the key

# Loading the seed
Given I have a 'base64' named 'seed'

# this needs to be implemented
When I create the ecdh key with secret key 'seed'
When I create the ethereum key with secret key 'seed'
When I create the reflow key with secret key 'seed'
# When I create the schnorr key with secret key 'seed'
When I create the bitcoin key with secret key 'seed'


Then print the 'keyring'
and print the 'seed'
EOF
    save_output "generate-key-seed.out"
    assert_output '{"keyring":{"bitcoin":"L2k9hYDzpETch3fE83ADmTWBWUyV7S8rgWuTHyLYSV5Kk5Laduzh","ecdh":"pNivlLFjZesFAqSG3qDobmrhKeWkGtPuUBeJ3FmkAWQ=","ethereum":"a4d8af94b16365eb0502a486dea0e86e6ae129e5a41ad3ee501789dc59a40164","reflow":"pNivlLFjZesFAqSG3qDobmrhKeWkGtPuUBeJ3FmkAWQ="},"seed":"pNivlLFjZesFAqSG3qDobmrhKeWkGtPuUBeJ3FmkAWQ="}'
}

@test "String seed" {
    cat <<EOF > string-seed.json
{
	"seed": "Hello World"
}
EOF
    cat <<EOF | zexe generate-key-seed-string.zen string-seed.json
Rule check version 2.0.0
Scenario 'ecdh': Create the key
Scenario 'ethereum': Create key
Scenario 'reflow': Create the key
Scenario 'schnorr': Create the key

# Loading the seed
Given I have a 'string' named 'seed'

# this needs to be implemented
When I create the ecdh key with secret key 'seed'
When I create the ethereum key with secret key 'seed'
When I create the reflow key with secret key 'seed'
# When I create the schnorr key with secret key 'seed'
# When I create the bitcoin key with secret key 'seed'

Then print the 'keyring'
Then print the 'seed'
EOF
    save_output "generate-key-seed-string.out"
    assert_output '{"keyring":{"ecdh":"SGVsbG8gV29ybGQ=","ethereum":"48656c6c6f20576f726c64","reflow":"SGVsbG8gV29ybGQ="},"seed":"Hello World"}'
}
