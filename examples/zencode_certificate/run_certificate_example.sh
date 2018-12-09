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

echo "MadHatter generates its private keyring"
cat <<EOF | zenroom | tee madhatter.keys | json_pp
local rng = RNG.new()
local priv = INT.new(rng,ECP.order())
write_json({ MadHatter = {
			 private = hex(priv),
			 public = hex(priv * ECP.generator())
			 }
		   })
EOF

echo "Alice generates a declaration"
cat <<EOF | zenroom -k madhatter.keys | tee alice_declaration.json | json_pp
-- alice declares 
ZEN:begin($verbose)
ZEN:parse([[
  Scenario 'request': Make my declaration and request certificate
    Given that I introduce myself as 'Alice'
    and I have the 'public' key 'MadHatter' in keyring
    When I declare to 'MadHatter' that I am 'lost in Wonderland'
    and I issue my declaration
    Then print my 'declaration'
]])
ZEN:run()
EOF

echo "The declaration is split in two:"
echo " _public to send to CA"
echo " _keypair to save locally"
echo "write_json({ declaration = L.property('public')(JSON.decode(DATA))})" \
	| zenroom -a alice_declaration.json | tee declaration_public.json | json_pp
echo "write_json({ declaration = L.property('keypair')(JSON.decode(DATA))})" \
	| zenroom -a alice_declaration.json | tee declaration_keypair.json | json_pp


echo "MadHatter gets the declaration and issues a certificate"
cat <<EOF | zenroom -k madhatter.keys -a declaration_public.json \
	| tee madhatter_certificate.json
-- madhatter certifies
ZEN:begin($verbose)
ZEN:parse([[
  Scenario 'issue': Receive a declaration request and issue a certificate
    Given that I am known as 'MadHatter'
    and I receive a 'declaration' from 'Alice'
    and I have my 'private' key in keyring
    When the 'declaration' by 'Alice' is true
    and I issue my certificate
    Then print my 'certificate'
]])
ZEN:run()
EOF

echo "The certificate is split in two:"
echo " _private is sent to REQ (certpriv and CERThash)"
echo " _public is broadcast (certpub and CERThash)"
echo "write_json({ certificate = L.property('public')(JSON.decode(DATA))})" \
	| zenroom -a madhatter_certificate.json | tee certificate_public.json | json_pp
echo "write_json({ certificate = L.property('private')(JSON.decode(DATA))})" \
	| zenroom -a madhatter_certificate.json | tee certificate_private.json | json_pp
rm -f madhatter_certificate.json

echo "Alice receives certificate_private and verifies its validity"
cat <<EOF | zenroom -a certificate_private.json -k declaration_keypair.json | json_pp
ZEN:begin($verbose)
ZEN:parse([[
  Scenario 'save': Receive a certificate of a declaration and save it
  	Given I receive a 'certificate' from 'MadHatter'
	and I have the 'private' key 'declaration' in keyring
	When I verify the 'certificate'
	Then I print my 'declaration'
]])
ZEN:run()
EOF


echo "Bob generates its private keyring"
cat <<EOF | zenroom | tee bob.keys | json_pp
local rng = RNG.new()
local priv = INT.new(rng,ECP.order())
write_json({ Bob = {
			 private = hex(priv),
			 public = hex(priv * ECP.generator())
			 }
		   })
EOF

echo "Bob receives a certified declaration and uses it to encrypt a message"
cat <<EOF | zenroom -k bob.keys -a certificate_public.json | tee bob_handshake.json
ZEN:begin($verbose)
ZEN:parse([[
  Scenario 'verify': Receive a certificate of a declaration and use it to encrypt a message
    Given that I am known as 'Bob'
    and I have my 'private' key in keyring
  	and that 'Alice' declares to be 'lost in Wonderland'
	When I receive the 'certificate' from 'MadHatter'
	and I use the 'certificate' to encrypt 'a random proof'
	Then I print my 'message'
]])
ZEN:run()
EOF

