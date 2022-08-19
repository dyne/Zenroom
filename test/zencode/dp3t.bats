load ../bats_setup
load ../bats_zencode
SUBDOC=dp3t

@test "dp3t keygen" {
    cat <<EOF | zexe dp3t_keygen.zen
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given nothing
When I create the random object of '256' bits
and I rename the 'random object' to 'secret day key'
Then print the 'secret day key'
EOF
    save_output 'SK1.json'
    assert_output '{"secret_day_key":"5dd8c0623f9163de7ebb260c23c7d1dfe7e63f92f241a379e2fc934d52b16720"}'
}

@test "dp3t key derivation" {
    cat <<EOF | zexe dp3t_keyderiv.zen SK1.json
scenario 'dp3t': Decentralized Privacy-Preserving Proximity Tracing
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given I have an 'hex' named 'secret day key'
# TODO: if the key is found in HEAP then parse secret day key as octet in default encoding
When I renew the secret day key to a new day
Then print the 'secret day key'
EOF
    save_output 'SK2.json'
    assert_output '{"secret_day_key":"78d41911d3f217ec19045930c452734e0fa5e29388f0bc6789ac46f5be907c09"}'
}

@test "dp3t ephemeral id generate" {
    cat <<EOF | zexe dp3t_ephidgen.zen SK2.json
scenario 'dp3t': Decentralized Privacy-Preserving Proximity Tracing
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given I have an 'hex' named 'secret day key'
When I write string 'Broadcast key' in 'broadcast key'
and I write number '180' in 'epoch'
and I create the ephemeral ids for today
and I randomize the 'ephemeral ids' array
Then print the 'ephemeral ids'
EOF
    save_output 'EphID_2.json'
    assert_output '{"ephemeral_ids":["0d9ca53ae60035f2c6b8539cfee10b70","b171d5d32f3b5768d36858a8952e78b3","612242e04c41bca63a1fee4bd76167c3","c972ead48aa4e455cbc886c7265c04fc","7b168159ddb95950ba47246fc048af69","90a67bd49f6d9a078392ecfca6bdd474","af9f9bc5c8ca29c4ee4424a5d1d2cd9d","c74b1899a2cc2c9d569a1bb2c5bf7c2b","4e0b8aa0fb1c9648698955efa255c5aa"]}'
}

@test "now generate a test with 20.000 infected SK" {
    cat <<EOF | zexe dp3t_testgen.zen
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given nothing
When I create the array of '200' random objects of '256' bits
and I rename the 'array' to 'list of infected'
and debug
Then print the 'list of infected'
EOF

    save_output 'SK_infected_20k.json'
    # Output very long...
}

@test 'extract a few random infected ephemeral ids to simulate proximity' {
    cat <<EOF | zexe dp3t_testextract.zen SK_infected_20k.json
scenario 'dp3t'
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given I have an 'hex array' named 'list of infected'
When I pick the random object in 'list of infected'
and I rename the 'random object' to 'secret day key'
and I write number '180' in 'epoch'
and I write string 'Broadcast key' in 'broadcast key'
and I create the ephemeral ids for today
# and the 'secret day key' is found in 'list of infected'
Then print the 'ephemeral ids'
EOF
    save_output 'EphID_infected.json'

}

@test 'given a list of infected and a list of ephemeral ids ' {
    cat <<EOF | zexe dp3t_checkinfected.zen SK_infected_20k.json EphID_infected.json
scenario 'dp3t'
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given I have a 'hex array' named 'list of infected'
and I have a 'hex array' named 'ephemeral ids'
When I write number '180' in 'epoch'
and I write string 'Broadcast key' in 'broadcast key'
and I create the proximity tracing of infected ids
and debug
Then print the 'proximity tracing'
EOF
    save_output 'SK_proximity.json'
    assert_output '{"proximity_tracing":["9f5d8859f81256a7605847a4610ed49eb9b2303995cd4ba5df59edf2c8276b8f","9f5d8859f81256a7605847a4610ed49eb9b2303995cd4ba5df59edf2c8276b8f","9f5d8859f81256a7605847a4610ed49eb9b2303995cd4ba5df59edf2c8276b8f","9f5d8859f81256a7605847a4610ed49eb9b2303995cd4ba5df59edf2c8276b8f","9f5d8859f81256a7605847a4610ed49eb9b2303995cd4ba5df59edf2c8276b8f","9f5d8859f81256a7605847a4610ed49eb9b2303995cd4ba5df59edf2c8276b8f","9f5d8859f81256a7605847a4610ed49eb9b2303995cd4ba5df59edf2c8276b8f","9f5d8859f81256a7605847a4610ed49eb9b2303995cd4ba5df59edf2c8276b8f","9f5d8859f81256a7605847a4610ed49eb9b2303995cd4ba5df59edf2c8276b8f"]}'

}


@test 'given a list of infected and a list of ephemeral ids (again)' {
    skip "Use memmanger=sys in config"
    cat <<EOF | zexe -c memmanager=sys -z -a $D/SK_infected_20k.json -k $D/EphID_2.json
scenario 'dp3t'
rule check version 1.0.0
rule input encoding hex
rule output encoding hex
Given I have a valid array in 'list of infected'
and I have a valid array in 'ephemeral ids'
When I write number '8' in 'moments'
and I write string 'Broadcast key' in 'broadcast key'
and I create the proximity tracing of infected ids
Then print the 'proximity tracing'
EOF
}
