#!/bin/sh


verbose=1

scenario="Generate credential request keypair"
echo $scenario
cat <<EOF | zenroom | tee alice.keys | json_pp
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'credential_request_keygen': $scenario
		 Given that I am known as 'Alice'
		 When I create my new credential request keypair
		 Then print keypair 'Alice'
]])
ZEN:run()
EOF

scenario="Generate credential issuer keypair"
echo $scenario
cat <<EOF | zenroom | tee madhatter.keys | json_pp
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'credential_issuer_keygen': $scenario
		 Given that I am known as 'MadHatter'
		 When I create my new credential issuer keypair
		 Then print keypair 'MadHatter'
]])
ZEN:run()
EOF

scenario="Generate credential issuer keypair"
echo $scenario
cat <<EOF | zenroom | tee cheshirecat.keys | json_pp
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'credential_issuer_keygen': $scenario
		 Given that I am known as 'CheshireCat'
		 When I create my new credential issuer keypair
		 Then print keypair 'CheshireCat'
]])
ZEN:run()
EOF

scenario="Publish the credential issuer verification key"
echo $scenario
cat <<EOF | zenroom -k madhatter.keys | tee madhatter_verification.keys | json_pp
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'publish_credential_issuer_key': $scenario
		 Given that I am known as 'MadHatter'
		 and I have my credential issuer keypair
		 When I remove the 'sign' key
		 Then print all keyring 
]])
ZEN:run()
EOF

scenario="Request a credential blind signature"
echo $scenario
cat <<EOF | zenroom -k alice.keys | tee alice_blindsign_request.json | json_pp
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'credential_request_blindsign': $scenario
		 Given that I am known as 'Alice'
		 and I have my credential request keypair
		 When I declare that I am 'lost in Wonderland'
		 and I request a credential blind signature
		 Then print all data
]])
ZEN:run()
EOF

scenario="Issue a credential blind signature"
echo $scenario
cat <<EOF | zenroom -k madhatter.keys -a alice_blindsign_request.json | tee madhatter_signed_credential.json | json_pp
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'credential_issue_blindsign': $scenario
		 Given that I am known as 'MadHatter'
		 and I have my credential issuer keypair
		 and I have a valid blind signature request
		 When I am sure that the credential is legitimate
		 and I blind sign the credential request
		 Then print 'signature'
]])
ZEN:run()
EOF
