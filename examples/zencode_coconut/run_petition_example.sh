#!/bin/sh

# Coconut paper: https://arxiv.org/pdf/1802.07344.pdf

verbose=1

alias zenroom='../../src/zenroom-shared'

# this example presumes that run_credential_example.sh was already ran
# succesfully in order to create credential keypairs and sign them,
# basically assuming the following scenarios are covered:

# scenario="Generate Alice's credential keypair"
# scenario="Generate Strawman's credential keypair"
# scenario="Generate Lionheart's credential keypair"
# scenario="Verify credential keypair to sign petitions"


scenario="Create a new petition"
echo $scenario
cat <<EOF | zenroom -k alice.keys -a madhatter_verification.keys | tee alice_petition_request.json |json_pp
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I am known as 'Alice'
		 and my keys have 'credential_keypair'
		 and my keys have 'credentials'
		 and I use the verification key by 'MadHatter'
		 When I generate a credential proof
		 and I generate a new petition 'To betray the Queen'
		 Then print the 'credential_proof'
		 and print the 'petition'
]])
ZEN:run()
EOF

scenario="Approve the creation of a petition"
echo $scenario
cat <<EOF | zenroom -k madhatter_verification.keys -a alice_petition_request.json | tee petition.json | json_pp
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I use the verification key by 'MadHatter'
		 and I have a 'credential_proof'
		 and I have a 'petition'
		 When I verify the credential proof is correct
		 and I verify the new petition to be empty
		 Then print the 'petition'
		 and print the 'verifiers'
]])
ZEN:run()
EOF

scenario="Sign a petition (produce a proof of signature)"
echo $scenario
cat <<EOF | zenroom -k alice.keys -a madhatter_verification.keys | tee petition_signature.json | json_pp
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I am known as 'Alice'
		 and I have my 'credential_keypair'
		 and I have my 'credentials'
		 and I use the verification key by 'MadHatter'
		 When I sign the petition 'To betray the Queen'
		 Then print the 'petition_signature'
]])
ZEN:run()
EOF

scenario="Count a signature on petition (increase scores)"
echo $scenario
cat <<EOF | zenroom -a petition_signature.json -k petition.json | tee /tmp/petition.json
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I have a 'petition_signature'
		 and I have a 'petition'
		 and I use the verification key by 'MadHatter'
		 When I verify the signature proof is correct
		 and the signature is not a duplicate
		 and the signature is just one more
		 and I add the signature to the petition
		 Then print the 'petition'
]])
ZEN:run()
EOF
mv /tmp/petition.json .
return 0

scenario="Sign a petition #2 (produce a proof of signature)"
echo $scenario
cat <<EOF | zenroom -k strawman.keys -a madhatter_verification.keys | tee petition_signature.json | json_pp
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I am known as 'Strawman'
		 and I have my 'credential_keypair'
		 and I have my 'credentials'
		 and I use the verification key by 'MadHatter'
		 When I sign the petition 'To betray the Queen'
		 Then print the 'petition_signature'
]])
ZEN:run()
EOF


scenario="Count a signature on petition #2 (increase scores)"
echo $scenario
cat <<EOF | zenroom -a petition_signature.json -k petition.json | tee /tmp/petition.json
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I receive a signature
		 and I receive a petition
		 When a valid petition signature is counted
		 Then print all data
]])
ZEN:run()
EOF
mv /tmp/petition.json .


scenario="Sign a petition #3 (produce a proof of signature)"
echo $scenario
cat <<EOF | zenroom -k lionheart.keys -a madhatter_verification.keys | tee petition_signature.json | json_pp
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I am known as 'Lionheart'
		 and I have my 'credential_keypair'
		 and I have my 'credentials'
		 and I use the verification key by 'MadHatter'
		 When I sign the petition 'To betray the Queen'
		 Then print the 'petition_signature'
]])
ZEN:run()
EOF


scenario="Count a signature on petition #3 (increase scores)"
echo $scenario
cat <<EOF | zenroom -a petition_signature.json -k petition.json | tee /tmp/petition.json
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I receive a signature
		 and I receive a petition
		 When a valid petition signature is counted
		 Then print all data
]])
ZEN:run()
EOF
mv /tmp/petition.json .


scenario="Tally the petition"
echo $scenario
cat <<EOF | zenroom -a petition.json -k alice.keys | tee tally.json | json_pp
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I am known as 'Alice'
		 and I have my keypair
		 and I receive a petition
		 When I tally the petition
		 Then print all data
]])
ZEN:run()
EOF

scenario="Count the petition result"
echo $scenario
cat <<EOF | zenroom -a petition.json -k tally.json
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I receive a petition
		 and I receive a tally
		 When I count the petition results
		 and print debug info
		 Then print all data
]])
ZEN:run()
EOF

