print()
print '= ATTRIBUTE BASED CRYPTOGRAPHY TEST (ZKP + zeta/UID)'
print()

ABC = require_once('crypto_abc')

local client = {
	  private = INT.new(
		 OCTET.from_base64("21WtYpNevjgZx5V2066fRr7LFxs6+qr2ULfv1zJSc+8=") ),
	  public = ECP.new(
		 OCTET.from_base64( "A0kLFsmfBqat7npVjj0whyVAn4nqcBCl2IF3vx/TSQ0OVPmJ73CQd0flkITWh8neug=="))
}

local UID = "Unique Session Identifier"

issuer_keypair = ABC.issuer_keygen()
issuer2_keypair = ABC.issuer_keygen()
issuer3_keypair = ABC.issuer_keygen()
local issuer_aggkeys = ABC.aggregate_keys({issuer_keypair.verify,
									   issuer2_keypair.verify,
									   issuer3_keypair.verify})

Lambda = ABC.prepare_blind_sign(client.private)
local sigma_tilde1 = ABC.blind_sign(issuer_keypair.sign, Lambda)
local sigma_tilde2 = ABC.blind_sign(issuer2_keypair.sign, Lambda)
local sigma_tilde3 = ABC.blind_sign(issuer3_keypair.sign, Lambda)
client.aggsigma = ABC.aggregate_creds(client.private, {sigma_tilde1, sigma_tilde2, sigma_tilde3})

local Theta, Theta2
local zeta, zeta2
-- simple
Theta = ABC.prove_cred(issuer_aggkeys, client.aggsigma, client.private)
Theta2 = ABC.prove_cred(issuer_aggkeys, client.aggsigma, client.private)
assert( ABC.verify_cred(issuer_aggkeys, Theta) )
assert( ABC.verify_cred(issuer_aggkeys, Theta2) )
assert(not (ZEN.serialize(Theta) == ZEN.serialize(Theta2)), "different zk proofs do not differ")

-- zkp + uid + zeta
Theta, zeta = ABC.prove_cred_uid(issuer_aggkeys, client.aggsigma, client.private, UID)
Theta2, zeta2 = ABC.prove_cred_uid(issuer_aggkeys, client.aggsigma, client.private, UID)

assert( ABC.verify_cred_uid(issuer_aggkeys, Theta, zeta, UID), "first UID-proof verification fails" )
assert( ABC.verify_cred_uid(issuer_aggkeys, Theta2, zeta2, UID), "second UID-proof verification fails" )
assert(not (ZEN.serialize(Theta) == ZEN.serialize(Theta2)), "different zk UID-proofs do not differ")
assert(zeta == zeta2, "zeta differs with same UID")

print "OK"
print()
