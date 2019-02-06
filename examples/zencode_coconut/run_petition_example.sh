#!/bin/sh

# Coconut paper: https://arxiv.org/pdf/1802.07344.pdf

verbose=1

scenario="Generate Alice's credential request keypair"
echo $scenario
cat <<EOF | zenroom | tee alice_petition.keys
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I am known as 'Alice'
		 When I create my new credential keypair
		 Then print all data
]])
ZEN:run()
EOF


scenario="Generate Bobs's credential request keypair"
echo $scenario
cat <<EOF | zenroom | tee bob_petition.keys
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I am known as 'Bob'
		 When I create my new credential keypair
		 Then print all data
]])
ZEN:run()
EOF

scenario="Create a new petition (lambda)"
echo $scenario
cat <<EOF | zenroom -k alice_petition.keys | tee alice_petition_request.json | json_pp
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I am known as 'Alice'
		 and I have my credential request keypair
		 When I create a new petition 'to betray the Queen'
		 Then print all data
]])
ZEN:run()
EOF

scenario="Issue a new petition blind signature (sigmatilde)"
echo $scenario
cat <<EOF | zenroom -k madhatter.keys -a alice_petition_request.json | tee madhatter_verified_petition.json | json_pp
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I am known as 'MadHatter'
		 and I have my credential issuer keypair
		 and I am requested to sign a new petition
		 When I verify the petition to be valid
		 and I certify the issuing of the petition
		 Then print all data
]])
ZEN:run()
EOF

# Dev note: this generates sigma (AggCred(σ1, . . . , σt) → (σ):) 
scenario="Receive the issuer signature and publish the petition (aggregate sigma)"
echo $scenario
cat <<EOF | zenroom -k alice_petition.keys -a madhatter_verified_petition.json | tee alice_aggregated_petition.json |json_pp
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I am known as 'Alice'
		 and I have my credential request keypair
		 When I receive a credential signature 'MadHatter'
		 and I aggregate all certifications for my petition
		 Then print all data
]])
ZEN:run()
EOF

scenario="Sign a petition (produce a proof of signature)"
echo $scenario
cat <<EOF | zenroom -k bob_petition.keys -a alice_aggregated_petition.json
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'coconut': $scenario
		 Given that I am known as 'Bob'
		 and I have my credential request keypair
		 and I can sign a petition
		 When I sign the petition
		 Then print all data
]])
ZEN:run()
EOF
