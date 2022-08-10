print()
print '= ATTRIBUTE BASED CRYPTOGRAPHY TEST (ZKP + zeta/UID)'
print()

local CRED = require_once('crypto_credential')
local G2 = ECP2.generator()

local client = {
	private = INT.new(
		OCTET.from_base64('21WtYpNevjgZx5V2066fRr7LFxs6+qr2ULfv1zJSc+8=')
	),
	public = ECP.new(
		OCTET.from_base64(
			'A0kLFsmfBqat7npVjj0whyVAn4nqcBCl2IF3vx/TSQ0OVPmJ73CQd0flkITWh8neug=='
		)
	)
}

local UID = 'Unique Session Identifier'

local issuer_key =CRED.issuer_keygen()
local issuer2_key =CRED.issuer_keygen()
local issuer3_key =CRED.issuer_keygen()
local issuer_verifier = {
	alpha = G2 * issuer_key.x,
	beta = G2 * issuer_key.y
}
local issuer2_verifier = {
	alpha = G2 * issuer2_key.x,
	beta = G2 * issuer2_key.y
}
local issuer3_verifier = {
	alpha = G2 * issuer3_key.x,
	beta = G2 * issuer3_key.y
}

local issuer_aggkeys =
	CRED.aggregate_keys(
	{issuer_verifier, issuer2_verifier, issuer3_verifier}
)

local Lambda =CRED.prepare_blind_sign(client.private)
local sigma_tilde1 =CRED.blind_sign(issuer_key, Lambda)
local sigma_tilde2 =CRED.blind_sign(issuer2_key, Lambda)
local sigma_tilde3 =CRED.blind_sign(issuer3_key, Lambda)
client.aggsigma =
	CRED.aggregate_creds(
	client.private,
	{sigma_tilde1, sigma_tilde2, sigma_tilde3}
)

local Theta, Theta2
local zeta, zeta2
-- simple
Theta =CRED.prove_cred(issuer_aggkeys, client.aggsigma, client.private)
Theta2 =CRED.prove_cred(issuer_aggkeys, client.aggsigma, client.private)
assert(CRED.verify_cred(issuer_aggkeys, Theta))
assert(CRED.verify_cred(issuer_aggkeys, Theta2))
assert(
	not (ZEN.serialize(Theta) == ZEN.serialize(Theta2)),
	'different zk proofs do not differ'
)

-- zkp + uid + zeta
Theta, zeta =
	CRED.prove_cred_uid(
	issuer_aggkeys,
	client.aggsigma,
	client.private,
	UID
)
Theta2, zeta2 =
	CRED.prove_cred_uid(
	issuer_aggkeys,
	client.aggsigma,
	client.private,
	UID
)

assert(
	CRED.verify_cred_uid(issuer_aggkeys, Theta, zeta, UID),
	'first UID-proof verification fails'
)
assert(
	CRED.verify_cred_uid(issuer_aggkeys, Theta2, zeta2, UID),
	'second UID-proof verification fails'
)
assert(
	not (ZEN.serialize(Theta) == ZEN.serialize(Theta2)),
	'different zk UID-proofs do not differ'
)
assert(zeta == zeta2, 'zeta differs with same UID')

print 'OK'
print()
