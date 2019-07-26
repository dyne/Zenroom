-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2018-2019 Dyne.org foundation
-- designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

-- COCONUT implementation in Zencode

-- ELGAMAL = require('crypto_elgamal') <- inside crypto_coconut
COCONUT = require_once('crypto_coconut')


-- convenient alias
local get = ZEN.get


ZEN.add_schema({
	  -- credential keypair (elgamal)
      credential_keypair = function(obj)
         return { public  = get(obj, 'public', ECP.new),
                  private = get(obj, 'private', INT.new) } end
})
-- credential keypair operations
local function f_keygen()
   local t = { }
   t.sk, t.pk = ELGAMAL.keygen()
   ZEN:push('credential_keypair', { public = t.pk,
									private = t.sk })
end
When("I create my new credential keypair", f_keygen)
When("I create my new credential request keypair", f_keygen)
When("I create my new keypair", f_keygen)

-- issuer authority kepair operations
ZEN.add_schema({
	  -- certificate authority (ca) / issuer keypair
      ca_sign = function(obj)
              return { x = get(obj, 'x', INT.new),
                       y = get(obj, 'y', INT.new) }
	  end,
      ca_verify = function(obj)
		 return { alpha = get(obj, 'alpha', ECP2.new),
				  beta  = get(obj, 'beta', ECP2.new) }
	  end,
	  ca_keypair = function(obj) -- recursive import
		 return { ca_sign   = ZEN:valid('ca_sign', obj.ca_sign),
				  ca_verify = ZEN:valid('ca_verify', obj.ca_verify) }
	  end
})
local function f_ca_keygen()
   local t = { }
   t.sk, t.vk = COCONUT.ca_keygen()
   ZEN:push('ca_keypair', { ca_sign = t.sk,
							ca_verify = t.vk })
end
When("I create my new issuer keypair", f_ca_keygen)
When("I create my new authority keypair", f_ca_keygen)
f_ca_keypair = function(keyname)
   ZEN.assert(keyname or ACK.whoami, "Cannot identify the issuer keypair to use")
   ACK.ca_keypair = ZEN:valid('ca_keypair', IN.KEYS[keyname or ACK.whoami])
end
Given("I have '' issuer keypair", f_ca_keypair)
Given("I have my issuer keypair", f_ca_keypair)
When("I publish my verification key", function()
        ZEN.assert(ACK.whoami, "Cannot identify the issuer")
        ZEN.assert(ACK.ca_keypair.ca_verify,
				   "Issuer verification key not found")
		ACK[ACK.whoami].ca_verify = ACK.ca_keypair.ca_verify
end)

-- request credential signatures
ZEN.add_schema({
     -- lambda
	  credential_signature_request = function(obj)
		local req = { c = { a = get(obj.c, 'a', ECP.new),
							b = get(obj.c, 'b', ECP.new) },
					  pi_s = { rr = get(obj.pi_s, 'rr', INT.new),
							   rm = get(obj.pi_s, 'rm', INT.new),
							   rk = get(obj.pi_s, 'rk', INT.new),
							   c =  get(obj.pi_s, 'c',  INT.new)  },
					  cm = get(obj, 'cm', ECP.new),
					  public = get(obj, 'public', ECP.new) }
		ZEN.assert(COCONUT.verify_pi_s(req),
                   "Error in credential signature request: proof is invalid (verify_pi_s)")
		return req
	  end
})

When("I generate a credential signature request", function()
		ZEN.assert(ACK.credential_keypair.private,
				   "Private key not found in credential keypair")
		ZEN:push('credential_signature_request',
				 COCONUT.prepare_blind_sign(ACK.credential_keypair.public,
											ACK.credential_keypair.private))
end) -- synonyms


-- issuer's signature of credentials
ZEN.add_schema({
	  -- sigmatilde
	  credential_signature = function(obj)
		 return { h = get(obj, 'h', ECP.new),
				  b_tilde = get(obj, 'b_tilde', ECP.new),
				  a_tilde = get(obj, 'a_tilde', ECP.new) } end,
	  -- aggsigma: aggregated signatures of ca issuers
	  credentials = function(obj)
		 return { h = get(obj, 'h', ECP.new),
				  s = get(obj, 's', ECP.new) } end,
})
When("I sign the credential", function()
		ZEN.assert(ACK.whoami, "Issuer is not known")
        ZEN.assert(ACK.credential_signature_request, "No valid signature request found.")
        ZEN.assert(ACK.ca_keypair.ca_sign, "No valid issuer signature keys found.")
        ACK.credential_signature = 
           COCONUT.blind_sign(ACK.ca_keypair.ca_sign,
                              ACK.credential_signature_request)
		ACK.ca_verify = ACK.ca_keypair.ca_verify
end)
When("I aggregate the credential in ''", function(dest)
		-- TODO: expose the accumulator to zencode
        -- check the blocking state _sigmatilde
		-- ZEN.assert(ACK.verify, "Verification keys from issuer not found")
        ZEN.assert(ACK.credential_signature, "Credential issuer signatures not found")
        ZEN.assert(ACK.credential_keypair.private, "Credential private key not found")
        -- prepare output with an aggregated sigma credential
        -- requester signs the sigma with private key
		-- TODO: for added security check sigmatilde with an ECDH
		-- signature before aggregating into credential
        ACK[dest] = COCONUT.aggregate_creds(
		   ACK.credential_keypair.private, { ACK.credential_signature })
end)


ZEN.add_schema({
	  -- theta: blind proof of certification
	  credential_proof = function(obj)
		 return { nu = get(obj, 'nu', ECP.new),
				  kappa = get(obj, 'kappa', ECP2.new),
				  pi_v = map(obj.pi_v, INT.new), -- TODO map wrappers
				  sigma_prime = map(obj.sigma_prime, ECP.new) } end
})

-- aggregated verifiers schema is same as a single ca_verify
ZEN.add_schema({verifiers = ZEN.schemas['ca_verify']})

When("I aggregate verifiers from ''", function(ca_verify)
		if ACK[ca_verify].alpha then
		   ACK.verifiers = ACK[ca_verify]
		else
		   -- TODO: aggregate all array
		end
end)

When("I generate a credential proof", function()
        ZEN.assert(ACK.verifiers, "No issuer verification keys are selected")
		ZEN.assert(ACK.credential_keypair.private,
				   "Credential private key not found")
		ZEN.assert(ACK.credentials, "Credentials not found")
		ACK.credential_proof =
		   COCONUT.prove_creds(ACK.verifiers,
							   ACK.credentials,
							   ACK.credential_keypair.private)
end)
When("I verify the credential proof is correct", function()
        ZEN.assert(ACK.credential_proof, "No valid credential proof found")
        ZEN.assert(ACK.verifiers, "Verifier of aggregated issuer keys not found")
        ZEN.assert(
           COCONUT.verify_creds(ACK.verifiers,
								ACK.credential_proof),
           "Credential proof does not validate")
end)




-- petition
ZEN.add_schema({
	  petition_scores = function(obj)
		 return({
			   pos = { left  = get(obj.pos, 'left', ECP.new),
					   right = get(obj.pos, 'right', ECP.new) },
			   neg = { left  = get(obj.neg, 'left', ECP.new),
					   right = get(obj.neg, 'right', ECP.new) } })
	  end,
	  petition = function(obj)
		 local res = { uid = obj['uid'], -- get(obj, 'uid', str),
					   owner = get(obj, 'owner', ECP.new),
					   scores = ZEN:valid('petition_scores',obj.scores) }
		 if type(obj.vkeys) == 'table' then res.vkeys = ZEN:valid('ca_verify',obj.vkeys) end
		 if type(obj.list) == 'table' then
			res.list = { }
			for k,v in ipairs(obj.list) do res.list[k] = true end
		 end
		 return res
			   end,
	 petition_signature = function(obj)
		return { proof = ZEN:valid('credential_proof',obj.proof),
				 uid_signature = get(obj, 'uid_signature', ECP.new),
				 uid_petition = obj['uid_petition'] } 
		end,

	 petition_tally = function(obj)
		   local dec = { }
		   dec.neg = get(obj.dec, 'neg', ECP.new)
		   dec.pos = get(obj.dec, 'pos', ECP.new)
		   return { uid = uid, -- get(obj, 'uid'),
					c = get(obj, 'c', INT.new),
					dec = dec,
					rx = get(obj, 'rx', INT.new) }
		end

})


When("I generate a petition ''", function(uid)
		ZEN:push('petition', 
				 { uid = uid,
				   owner = ACK.credential_keypair.public,
				   scores = { pos = { left = "Infinity",       -- ECP.infinity()
									  right = "Infinity" },    -- ECP.infinity()
							  neg = { left = "Infinity",       -- ECP.infinity()
									  right = "Infinity" } }
		}) -- ECP.infinity()
		-- generate an ECDH signature of the (encoded) petition using the
		-- credential keys
		-- ecdh = ECDH.new()
		-- ecdh:private(ACK.cred_kp.private)
		-- ACK.petition_ecdh_sign = { ecdh:sign(MSG.pack(OUT.petition)) }
		-- OUT.petition_ecdh_sign = map(ACK.petition_ecdh_sign, hex)
end)

When("I verify the new petition to be empty", function()
        ZEN.assert(ECP.isinf(ACK.petition.scores.pos.left),
                   "Invalid new petition: positive left score is not zero")
        ZEN.assert(ECP.isinf(ACK.petition.scores.pos.right),
                   "Invalid new petition: positive right score is not zero")
        ZEN.assert(ECP.isinf(ACK.petition.scores.neg.left),
                   "Invalid new petition: negative left score is not zero")
        ZEN.assert(ECP.isinf(ACK.petition.scores.neg.right),
                   "Invalid new petition: negative right score is not zero")
end)

When("I sign the petition ''", function(uid)
        ZEN.assert(ACK.verifiers, "Verifier of aggregated issuer keys not found")
		ZEN.assert(ACK.credential_keypair.private,
				   "Credential private key not found")
		ZEN.assert(ACK.credentials, "Signed credential not found")
		local Theta
		local zeta
		Theta, zeta = COCONUT.prove_cred_petition(
		   ACK.verifiers,
		   ACK.credentials, 
		   ACK.credential_keypair.private, uid)
		ZEN:push('petition_signature',
				 { proof = Theta,
				   uid_signature = zeta,
				   uid_petition = uid })
end)

When("I verify the signature proof is correct", function()
		ZEN.assert(
		   COCONUT.verify_cred_petition(ACK.verifiers,
										ACK.petition_signature.proof,
										ACK.petition_signature.uid_signature,
										ACK.petition_signature.uid_petition),
		   "Petition signature is invalid")
end)

When("the petition signature is not a duplicate", function()
		enc = ENCODING or url64
		local k = enc(ACK.petition_signature.uid_signature)
		if type(ACK.petition.list) == 'table' then
		   ZEN.assert(
			  ACK.petition.list[k] == nil,
			  "Duplicate petition signature detected")
		   ACK.petition.list[k] = true
		else
		   ACK.petition.list = { }
		   ACK.petition.list[k] = true
		end
end)

When("the petition signature is just one more", function()
		-- verify that the signature is +1 (no other value supported)
		ACK.petition_signature.one =
		   COCONUT.prove_sign_petition(ACK.petition.owner, BIG.new(1))
		ZEN.assert(COCONUT.verify_sign_petition(ACK.petition.owner,
												ACK.petition_signature.one),
				   "Coconut petition signature adds more than one signature")
end)

When("I add the signature to the petition", function()
		-- add the signature to the petition count
		local scores = ACK.petition.scores
		local psign  = ACK.petition_signature.one
		scores.pos.left =  scores.pos.left  + psign.scores.pos.left
		scores.pos.right = scores.pos.right + psign.scores.pos.right
		scores.neg.left =  scores.neg.left  + psign.scores.neg.left
		scores.neg.right = scores.neg.right + psign.scores.neg.right
		-- TODO: ZEN:push({'petition' ,'scores'}
		ACK.petition.scores = scores
end)

When("I tally the petition", function()
        ZEN.assert(ACK.credential_keypair.private,
				   "Private key not found in credential keypair")
		ZEN.assert(ACK.petition, "Petition not found")
		ACK.petition_tally = COCONUT.prove_tally_petition(
		   ACK.credential_keypair.private, ACK.petition.scores)
		ACK.petition_tally.uid = ACK.petition.uid
end)

When("I count the petition results", function()
		ZEN.assert(ACK.petition, "Petition not found")
		ZEN.assert(ACK.petition_tally, "Tally not found")
		ZEN.assert(ACK.petition_tally.uid == ACK.petition.uid,
				   "Tally does not correspond to petition")
		ACK.results = COCONUT.count_signatures_petition(
		   ACK.petition.scores, ACK.petition_tally)
end)
