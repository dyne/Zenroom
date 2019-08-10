#!/bin/sh


verbose=3

alias zenroom='../../src/zenroom-shared'

scenario="Alice generate a keypair"
echo $scenario
cat <<EOF | zenroom | tee alice.keys
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'aesgcm': $scenario
Given that I am known as 'Alice'
When I create my new keypair
Then print my data
]])
ZEN:run()
EOF

scenario="Alice publishes her public key"
echo $scenario
cat <<EOF | zenroom -k alice.keys | tee alice_pub.keys
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'aesgcm': $scenario
Given that I am known as 'Alice'
and I have my 'public' key
Then print my data
]])
ZEN:run()
EOF


scenario="Bob generate a keypair"
echo $scenario
cat <<EOF | zenroom | tee bob.keys
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'aesgcm': $scenario
Given that I am known as 'Bob'
When I create my new keypair
Then print my data
]])
ZEN:run()
EOF

scenario="Bob publishes his public key"
echo $scenario
cat <<EOF | zenroom -k bob.keys | tee bob_pub.keys
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'aesgcm': $scenario
Given that I am known as 'Bob'
and I have my 'public' key
Then print my data
]])
ZEN:run()
EOF
