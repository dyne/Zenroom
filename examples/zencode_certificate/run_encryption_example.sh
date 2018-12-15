#!/bin/sh

verbose=1

scenario="Generate a new keypair"
echo $scenario
cat <<EOF | zenroom | tee alice.keys
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'keygen': $scenario
		 Given that I am known as 'Alice'
		 When I create my new keypair
		 Then print keypair 'Alice'
]])
ZEN:run()
EOF

scenario="Split a keypair"
echo $scenario
cat <<EOF | zenroom -k alice.keys | tee alice_public.keys
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'keygen': $scenario
		 Given that I am known as 'Alice'
		 and I have my keypair
		 When I remove the 'private' key
		 Then print all keyring
]])
ZEN:run()
EOF

scenario="Generate a new keypair"
echo $scenario
cat <<EOF | zenroom | tee bob.keys
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'keygen': $scenario
		 Given that I am known as 'Bob'
		 When I create my new keypair
		 Then print all keyring
]])
ZEN:run()
EOF

scenario="Split a keypair"
echo $scenario
cat <<EOF | zenroom -k bob.keys | tee bob_public.keys
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'keygen': $scenario
		 Given that I am known as 'Bob'
		 and I have my keypair
		 When I remove the 'private' key
		 Then print all keyring
]])
ZEN:run()
EOF

scenario="Alice saves Bob's public key into her keyring"
echo $scenario
cat <<EOF | zenroom -k alice.keys -a bob_public.keys | tee alice_ring.keys | json_pp
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'store in keyring': $scenario
		 Given that I am known as 'Alice'
		 and I have my keypair
		 and I have a 'Bob' 'public' key
		 When I import 'Bob' keypair into my keyring
		 Then print my keyring
]])
ZEN:run()
EOF

scenario="Bob saves Alice's public key into his keyring"
echo $scenario
cat <<EOF | zenroom -k bob.keys -a alice_public.keys | tee bob_ring.keys | json_pp
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'store in keyring': $scenario
		 Given that I am known as 'Bob'
		 and I have my keypair
		 and I have a 'Alice' 'public' key
		 When I import 'Alice' keypair into my keyring
		 Then print my keyring
]])
ZEN:run()
EOF

scenario="Alice encrypts a message for Bob"
echo $scenario
cat <<EOF | zenroom -k alice_ring.keys | tee alice_to_bob.json
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'crypto message': $scenario
		 Given that I am known as 'Alice'
		 and I have my keypair
		 and I have the 'public' key 'Bob' in keyring
		 When I draft the text 'Hey Bob: Alice here, can you read me?'
		 and I use 'Bob' key to encrypt the text into 'ciphertext'
		 Then print data 'ciphertext'
]])
ZEN:run()
EOF

scenario="Bob answers a message from Alice"
echo $scenario
cat <<EOF | zenroom -k bob_ring.keys -a alice_to_bob.json | tee bob_to_alice.json
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'crypto answer': $scenario
		 Given that I am known as 'Bob'
		 and I have my keypair
		 When I decrypt the 'ciphertext' to 'decoded'
		 Then print data 'decoded'
]])
ZEN:run()
EOF

