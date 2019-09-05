#!/bin/sh

alias zenroom="$1"
echo "============================================"
echo "TEST SYMMETRIC ENCRYPTION WITH JSON AND CBOR"
echo "============================================"


echo "=== JSON"

echo "Generate a secret"
cat << EOF | zenroom -z | tee secret.json
Scenario 'simple'
Given nothing
When I create a random 'secret'
Then print the 'secret'
EOF

echo "Encrypt a message with the secret"
cat <<EOF | zenroom -k secret.json -z | tee cipher_message.json
# rule set encoding url64
# rule set curve ed25519
Scenario 'simple'
Given I have a 'secret'
When I write 'a very short but very very confidential message' in 'message'
and I write 'this is the header' in 'header'
and I encrypt the 'message' to 'secret message' with 'secret'
Then print the 'secret message'
EOF

echo "Decrypt the message with the secret"
cat <<EOF | zenroom -k secret.json -a cipher_message.json -z | json_pp
# rule set encoding url64
# rule set curve ed25519
Scenario 'simple'
given i have a 'secret'
and i have a valid 'secret message'
When I decrypt the 'secret message' to 'message' with 'secret'
then print as 'string' the 'text' inside 'message'
and print as 'string' the 'header' inside 'message'
EOF

echo "=== CBOR"

echo "Generate a secret"
cat << EOF | zenroom -z | tee secret.cbor
rule output format cbor
Scenario 'simple'
Given nothing
When I create a random 'secret'
Then print the 'secret'
EOF

echo "Encrypt a message with the secret"
cat <<EOF | zenroom -k secret.cbor -z | tee cipher_message.cbor
# rule set encoding url64
# rule set curve ed25519
rule input format cbor
rule output format cbor
Scenario 'simple'
Given I have a 'secret'
When I write 'a very short but very very confidential message' in 'message'
and I write 'this is the header' in 'header'
and I encrypt the 'message' to 'secret message' with 'secret'
Then print the 'secret message'
EOF

echo "Decrypt the message with the secret"
cat <<EOF | zenroom -k secret.cbor -a cipher_message.cbor -z
# rule set encoding url64
# rule set curve ed25519
rule input format cbor
rule output format cbor
Scenario 'simple'
given i have a 'secret'
and i have a valid 'secret message'
When I decrypt the 'secret message' to 'message' with 'secret'
then print as 'string' the 'text' inside 'message'
and print as 'string' the 'header' inside 'message'
EOF
