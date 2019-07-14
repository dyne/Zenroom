#!/bin/sh

# Comments use names from the Coconut paper: https://arxiv.org/pdf/1802.07344.pdf

verbose=1

alias zenroom='../../src/zenroom-shared'

scenario="Generate credential issuer keypair"
echo $scenario
cat <<EOF | zenroom | tee madhatter.keys
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
Given that I am known as 'MadHatter'
When I create my new issuer keypair
Then print my data
]])
ZEN:run()
EOF

# Note for devs: the output is verification cryptographic object (alpha, beta, g2) 
scenario="Publish the credential issuer verification key"
echo $scenario
cat <<EOF | zenroom -k madhatter.keys | tee madhatter_verification.keys
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
Given that I am known as 'MadHatter'
and my keys have 'issue_keypair'
When I publish my verification key
Then print my data
]])
ZEN:run()
EOF

scenario="Generate credential request keypair"
echo $scenario
cat <<EOF | zenroom | tee alice.keys
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I am known as 'Alice'
		 When I create my new keypair
		 Then print my data
]])
ZEN:run()
EOF

scenario="Generate credential request keypair"
echo $scenario
cat <<EOF | zenroom | tee strawman.keys
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I am known as 'Strawman'
		 When I create my new keypair
		 Then print my data
]])
ZEN:run()
EOF

scenario="Generate credential request keypair"
echo $scenario
cat <<EOF | zenroom | tee lionheart.keys
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I am known as 'Lionheart'
		 When I create my new keypair
		 Then print my data
]])
ZEN:run()
EOF

# from here onwards all credential holders (participants) ask the
# issuer to sign their credential keys and aggregate the signature
# (sigmatilde) into their keyring

scenario="Request a credential blind signature"
echo $scenario
cat <<EOF | zenroom -k alice.keys | tee alice_blindsign_request.json
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I am known as 'Alice'
		 and my keys have 'credential_keypair'
		 When I generate a credential signature request
		 Then print the 'credential_signature_request'
]])
ZEN:run()
EOF

scenario="Issuer signs a credential"
echo $scenario
cat <<EOF | zenroom -k madhatter.keys -a alice_blindsign_request.json | tee madhatter_signed_credential.json | json_pp
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I am known as 'MadHatter'
		 and my keys have 'issue_keypair'
		 and I have a 'credential_signature_request'
		 When I am ready
		 and I sign the credential
		 Then print my 'credential_signature'
		 and print my 'verify'
]])
ZEN:run()
EOF

# Dev note: this generates sigma (AggCred(σ1, . . . , σt) → (σ):) 
scenario="Receive the signature and archive the credential"
echo $scenario
cat <<EOF | zenroom -k alice.keys -a madhatter_signed_credential.json | tee /tmp/alice.keys
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I am known as 'Alice'
		 and my keys have 'credential_keypair'
		 and I have inside 'MadHatter' a 'credential_signature'
		 When I aggregate the credential in 'credentials'
		 Then print my 'credential_keypair'
		 and print my 'credentials'
]])
ZEN:run()
EOF
mv /tmp/alice.keys . # restore to avoid overwrite 

scenario="Request a credential blind signature"
echo $scenario
cat <<EOF | zenroom -k strawman.keys | tee strawman_blindsign_request.json
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I am known as 'Strawman'
		 and my keys have 'credential_keypair'
		 When I generate a credential signature request
		 Then print the 'credential_signature_request'
]])
ZEN:run()
EOF

scenario="Issuer signs a credential"
echo $scenario
cat <<EOF | zenroom -k madhatter.keys -a strawman_blindsign_request.json | tee madhatter_signed_credential.json |json_pp
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I am known as 'MadHatter'
		 and my keys have 'issue_keypair'
		 and I have a 'credential_signature_request'
		 When I am ready
		 and I sign the credential
		 Then print my 'credential_signature'
		 and print my 'verify'
]])
ZEN:run()
EOF

# Dev note: this generates sigma (AggCred(σ1, . . . , σt) → (σ):) 
scenario="Receive the signature and archive the credential"
echo $scenario
cat <<EOF | zenroom -k strawman.keys -a madhatter_signed_credential.json | tee /tmp/strawman.keys |json_pp
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I am known as 'Strawman'
		 and my keys have 'credential_keypair'
		 and I have inside 'MadHatter' a 'credential_signature'
		 When I aggregate the credential in 'credentials'
		 Then print my 'credential_keypair'
		 and print my 'credentials'
]])
ZEN:run()
EOF
mv /tmp/strawman.keys . # restore to avoid overwrite 

scenario="Request a credential blind signature"
echo $scenario
cat <<EOF | zenroom -k lionheart.keys | tee lionheart_blindsign_request.json
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I am known as 'Lionheart'
		 and my keys have 'credential_keypair'
		 When I generate a credential signature request
		 Then print the 'credential_signature_request'
]])
ZEN:run()
EOF

scenario="Issuer signs a credential"
echo $scenario
cat <<EOF | zenroom -k madhatter.keys -a lionheart_blindsign_request.json | tee madhatter_signed_credential.json |json_pp
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I am known as 'MadHatter'
		 and my keys have 'issue_keypair'
		 and I have a 'credential_signature_request'
		 When I am ready
		 and I sign the credential
		 Then print my 'credential_signature'
		 and print my 'verify'
]])
ZEN:run()
EOF

# Dev note: this generates sigma (AggCred(σ1, . . . , σt) → (σ):) 
scenario="Receive the signature and archive the credential"
echo $scenario
cat <<EOF | zenroom -k lionheart.keys -a madhatter_signed_credential.json | tee /tmp/lionheart.keys |json_pp
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I am known as 'Lionheart'
		 and my keys have 'credential_keypair'
		 and I have inside 'MadHatter' a 'credential_signature'
		 When I aggregate the credential in 'credentials'
		 Then print my 'credential_keypair'
		 and print my 'credentials'
]])
ZEN:run()
EOF
mv /tmp/lionheart.keys . # restore to avoid overwrite 



# Dev note: this generates theta (❖ ProveCred(vk, m, φ0) → (Θ, φ0):
scenario="Generate a blind proof of the credentials"
echo $scenario
cat <<EOF | zenroom -k alice.keys -a madhatter_verification.keys | tee alice_proof.json | json_pp
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I am known as 'Alice'
		 and my keys have 'credential_keypair'
		 and my keys have 'credentials'
		 and I use the verification key by 'MadHatter'
		 When I generate a credential proof
		 Then print the 'credential_proof'
]])
ZEN:run()
EOF


# Dev note: this checks if theta contains the statement, and returns a boolean VerifyCred(vk, Θ, φ0) 
scenario="Verify a blind proof of the credentials"
echo $scenario
cat <<EOF | zenroom -k alice_proof.json -a madhatter_verification.keys
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that my keys have 'credential_proof'
		 and I use the verification key by 'MadHatter'
		 When I verify the credential proof is correct
		 Then print 'result' 'OK'
]])
ZEN:run()
EOF

