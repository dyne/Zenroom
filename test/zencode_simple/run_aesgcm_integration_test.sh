#!/bin/sh


verbose=1

alias zenroom='../../src/zenroom-shared'

scenario="Alice generate a keypair"
echo $scenario
cat <<EOF | zenroom | tee alice.keys
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'simple': $scenario
Given that I am known as 'Alice'
When I create my new keypair
Then print my data
]])
ZEN:run()
EOF

scenario="Alice publishes her public key"
echo $scenario
cat <<EOF | zenroom -k alice.keys | tee alice.pub
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'simple': $scenario
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
Scenario 'simple': $scenario
Given that I am known as 'Bob'
When I create my new keypair
Then print my data
]])
ZEN:run()
EOF

scenario="Bob publishes his public key"
echo $scenario
cat <<EOF | zenroom -k bob.keys | tee bob.pub
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'simple': $scenario
Given that I am known as 'Bob'
and I have my 'public' key
Then print my data
]])
ZEN:run()
EOF

scenario="Alice encrypts a message for Bob"
echo $scenario
cat <<EOF | zenroom -z -d$verbose -k alice.keys -a bob.pub | tee alice_to_bob.json
Scenario 'simple': $scenario
Given that I am known as 'Alice'
and I have my 'keypair'
and I have inside 'Bob' a valid 'public' key
When I draft the string 'This is my secret message to Bob'
and I encrypt the draft as 'secret message'
Then print the 'secret message'
EOF

scenario="Bob decrypts the message from Alice"
echo $scenario
cat <<EOF | zenroom -z -d$verbose -k bob.keys -a alice_to_bob.json
Scenario 'simple': $scenario
Given that I am known as 'Bob'
and I have my valid 'keypair'
and I have a valid 'secret message'
When I decrypt the 'secret message' as 'clear text'
Then print as 'string' the 'clear text'
and print as 'string' the 'header' inside 'secret message'
EOF

return 0

# TODO: multiple recipients zencode

# join in array: [ { alice = { public = "..." } }, { bob = { public = "..." } } ]
jq -s '.' *.pub > recipients.pub

scenario="Alice encrypts a message for Bob"
echo $scenario
cat <<EOF | zenroom -z -d$verbose -k alice.keys -a recipients.pub | tee alice_to_bob.json
Scenario 'simple': $scenario
Given that I am known as 'Alice'
and I create a table 'recipients'
and I have inside 'Bob' a valid 'public' key
and I add it to 'recipients'
When I draft the string 'This is my secret message to you'
and I encrypt the draft for all 'recipients' as 'secret message'
Then print the 'secret message'
EOF
