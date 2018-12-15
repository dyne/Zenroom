#!/bin/sh

echo "Clean init"
rm -v -f \
   madhatter.keys \
   alice_declaration.json \
   declaration_public.json \
   declaration_keypair.json \
   madhatter_certificate.json \
   certificate_public.json \
   certificate_private.json

verbose=1

scenario="MadHatter generates its private keyring"
echo $scenario
cat <<EOF | zenroom | tee madhatter.keys
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'keygen': $scenario
		 Given that I am known as 'MadHatter'
		 When I create my new keypair
		 Then print my keyring
]])
ZEN:run()
EOF

scenario="Alice generates a declaration"
echo $scenario
cat <<EOF | zenroom -k madhatter.keys | tee alice_declaration.json
-- alice declares 
ZEN:begin($verbose)
ZEN:parse([[
  Scenario 'request': Make my declaration and request certificate
    Given that I introduce myself as 'Alice'
    and I have the 'public' key 'MadHatter' in keyring
    When I declare to 'MadHatter' that I am 'lost in Wonderland'
    and I issue my implicit certificate request 'declaration'
    Then print all data
]])
ZEN:run()
EOF

scenario="Alice splits the declaration in two halves: public and keypair (private)"
echo $scenario
cat <<EOF | zenroom -a alice_declaration.json | tee declaration_public.json
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'keygen': $scenario
		 Given that I am known as 'Alice'
		 and I have a 'declaration_public' 'from' 'Alice'
		 Then print data 'declaration_public'
]])
ZEN:run()
EOF
cat <<EOF | zenroom -a alice_declaration.json | tee declaration_keypair.json
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'keygen': $scenario
		 Given that I am known as 'Alice'
		 and I have a 'declaration_keypair'
		 Then print data 'declaration_keypair'
]])
ZEN:run()
EOF


echo "MadHatter gets the declaration and issues a certificate"
cat <<EOF | zenroom -k madhatter.keys -a declaration_public.json \
	| tee madhatter_certificate.json
-- madhatter certifies
ZEN:begin($verbose)
ZEN:parse([[
  Scenario 'issue': Receive a declaration request and issue a certificate
    Given that I am known as 'MadHatter'
    and I have a 'declaration_public' 'from' 'Alice'
    and I have my 'private' key in keyring
    When I issue an implicit certificate for 'declaration_public'
    Then print all data
]])
ZEN:run()
EOF

echo "The certificate is split in two:"
echo " _private is sent to REQ (certpriv and CERThash)"
echo " _public is broadcast (certpub and CERThash)"

cat <<EOF | zenroom -a madhatter_certificate.json | tee certificate_public.json
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'split': Print the public section of the certificate
		  Given I have a 'certificate_public' 'from' 'MadHatter'
		  When possible
		  Then print data 'certificate_public'
]])
ZEN:run()
EOF
cat <<EOF | zenroom -a madhatter_certificate.json | tee certificate_private.json
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'split': Print the private section of the certificate
		  Given I have a 'certificate_private'
		  When possible
		  Then print data 'certificate_private'
]])
ZEN:run()
EOF

echo "Alice receives certificate_private and verifies its validity"
cat <<EOF | zenroom -a certificate_private.json -k declaration_keypair.json
ZEN:begin($verbose)
ZEN:parse([[
  Scenario 'save': Receive a certificate of a declaration and save it
  	Given I have a 'certificate_private' 'from' 'MadHatter'
	and I have the 'private' key 'declaration_keypair' in keyring
	When I verify the implicit certificate 'certificate_private'
	Then I print data 'declaration'
]])
ZEN:run()
EOF

echo "Bob generates its private keyring"
cat <<EOF | zenroom | tee madhatter.keys
ZEN:begin($verbose)
ZEN:parse([[
Scenario 'keygen': $scenario
		 Given that I am known as 'Bob'
		 When I create my new keypair
		 Then print my keyring
]])
ZEN:run()
EOF

echo "Bob receives a certified declaration and uses it to encrypt a message"
cat <<EOF | zenroom -k bob.keys -a certificate_public.json | tee bob_handshake.json | json_pp
ZEN:begin($verbose)
ZEN:parse([[
  Scenario 'challenge': Receive a certificate of a declaration and use it to encrypt a message
    Given that I am known as 'Bob'
    and I have my 'private' key in keyring
  	and that 'Alice' declares to be 'lost in Wonderland'
	and I have a 'certificate' 'from' 'MadHatter'
	When I use the 'certificate' to encrypt 'a random proof, please echo back'
	Then I print all data
]])
ZEN:run()
EOF

echo "Alice receives an encrypted message, decrypts it and sends an encrypted answer back to sender"
cat <<EOF | zenroom -k bob.keys -a certificate_public.json | tee bob_handshake.json
ZEN:begin($verbose)
ZEN:parse([[
  Scenario 'respond': Alice receives an encrypted message, decrypts it and sends an encrypted answer back to sender
    Given that I am known as 'Alice'
    and I have my 'private' key in keyring
	When I receive a challenge of my declaration 'lost in Wonderland'
	and I decrypt the message
	and I use the 'certificate' to encrypt 'a random proof'
	Then I print all data
]])
ZEN:run()
EOF
