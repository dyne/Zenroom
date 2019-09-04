#!/bin/sh


verbose=1

alias zenroom="$1"

scenario="Alice signs a message for Bob"
echo $scenario
cat <<EOF | zenroom -z -d$verbose -k alice.keys | tee alice_signs_to_bob.json
Scenario 'simple': $scenario
Given that I am known as 'Alice'
and I have my valid 'keypair'
When I write 'This is my signed message to Bob.' in 'draft'
and I sign the 'draft' as 'signed message'
Then print my 'signed message'
EOF

scenario="Bob verifies the signature from Alice"
echo $scenario
cat <<EOF | zenroom -z -d$verbose -k alice.pub -a alice_signs_to_bob.json
Scenario 'simple': $scenario
Given that I am known as 'Bob'
and I have inside 'Alice' a valid 'public key'
and I have a valid 'signed message'
When I verify the 'signed message' is authentic
Then print 'signature' 'correct'
and print as 'string' the 'text' inside 'signed message'
EOF
