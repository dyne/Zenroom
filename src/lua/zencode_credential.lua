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

COCONUT = require_once('crypto_coconut')

ZEN.add_schema({
	  -- credential keypair (elgamal)
      credential_keypair = function(obj)
		 local pub = ZEN.get(obj, 'public', ECP.new)
		 local sec = ZEN.get(obj, 'private', INT.new)
		 ZEN.assert(pub == ECP.generator() * sec,
					"Public key does not belong to secret key in credential keypair")
         return { public  = ZEN.get(obj, 'public', ECP.new),
                  private = ZEN.get(obj, 'private', INT.new) } end
})

-- credential keypair operations
When("create the credential keypair", function()
		-- sk = rand, pk = G * sk
		ACK.credential_keypair = { private = INT.random() }
		ACK.credential_keypair.public = ECP.generator() *
		   ACK.credential_keypair.private
end)

When("create the credential keypair with secret key ''", function(sec)
		-- pk = G * sec
		ZEN.assert(ACK[sec], "Secret key not found: "..sec)
		ACK.credential_keypair = { private = INT.new(ACK[sec]) }
		ACK.credential_keypair.public = ECP.generator() *
		   ACK.credential_keypair.private
end)

function issuer_sign_f(o)
   local obj = deepmap(CONF.input.encoding.fun, o)
   return { x = ZEN.get(obj, 'x', INT.new),
			y = ZEN.get(obj, 'y', INT.new) }
end
function verifier_f(o)
   local obj = deepmap(CONF.input.encoding.fun, o)
	return { alpha = ZEN.get(obj, 'alpha', ECP2.new),
			 beta  = ZEN.get(obj, 'beta', ECP2.new) }
end
-- issuer authority kepair operations
ZEN.add_schema({
	  -- certificate authority (ca) / issuer keypair
      issuer_sign = issuer_sign_f,
      verifier = verifier_f,
	  issuer_keypair = function(obj) -- recursive import
		 return { issuer_sign   = issuer_sign_f(obj.issuer_sign),
				  verifier = verifier_f(obj.verifier) }
	  end
})

When("create the issuer keypair", function()
		ACK.issuer_keypair = { }
		ACK.issuer_keypair.issuer_sign,
		ACK.issuer_keypair.verifier = COCONUT.ca_keygen()
end)

-- request credential signatures
ZEN.add_schema({
     -- lambda
	  credential_request = function(obj)
		local req = { c = { a = ZEN.get(obj.c, 'a', ECP.new),
							b = ZEN.get(obj.c, 'b', ECP.new) },
					  pi_s = { rr = ZEN.get(obj.pi_s, 'rr', INT.new),
							   rm = ZEN.get(obj.pi_s, 'rm', INT.new),
							   rk = ZEN.get(obj.pi_s, 'rk', INT.new),
							   c =  ZEN.get(obj.pi_s, 'c',  INT.new)  },
					  commit = ZEN.get(obj, 'commit', ECP.new),
					  public = ZEN.get(obj, 'public', ECP.new) }
		ZEN.assert(COCONUT.verify_pi_s(req),
                   "Error in credential request: proof is invalid (verify_pi_s)")
		return req
	  end
})

When("create the credential request", function()
		ZEN.assert(ACK.credential_keypair.private,
				   "Private key not found in credential keypair")
		ACK.credential_request =
		   COCONUT.prepare_blind_sign(ACK.credential_keypair.public,
									  ACK.credential_keypair.private)
end)


-- issuer's signature of credentials
ZEN.add_schema({
	  -- sigmatilde
	  credential_signature = function(obj)
		 return { h = ZEN.get(obj, 'h', ECP.new),
				  b_tilde = ZEN.get(obj, 'b_tilde', ECP.new),
				  a_tilde = ZEN.get(obj, 'a_tilde', ECP.new) } end,
	  -- aggsigma: aggregated signatures of ca issuers
	  credentials = function(obj)
		 return { h = ZEN.get(obj, 'h', ECP.new),
				  s = ZEN.get(obj, 's', ECP.new) } end,
})
When("create the credential signature", function()
		ZEN.assert(WHO, "Issuer is not known")
        ZEN.assert(ACK.credential_request, "No valid signature request found.")
        ZEN.assert(ACK.issuer_keypair.issuer_sign, "No valid issuer signature keys found.")
        ACK.credential_signature =
           COCONUT.blind_sign(ACK.issuer_keypair.issuer_sign,
                              ACK.credential_request)
		ACK.verifier = ACK.issuer_keypair.verifier
end)
When("create the credentials", function()
        ZEN.assert(ACK.credential_signature, "Credential signature not found")
        ZEN.assert(ACK.credential_keypair.private, "Credential private key not found")
        -- prepare output with an aggregated sigma credential
        -- requester signs the sigma with private key
        ACK.credentials = COCONUT.aggregate_creds(
		   ACK.credential_keypair.private, { ACK.credential_signature })
end)

function credential_proof_f(o)
   local obj = deepmap(CONF.input.encoding.fun, o)
   return { nu = ZEN.get(obj, 'nu', ECP.new),
			kappa = ZEN.get(obj, 'kappa', ECP2.new),
			pi_v = { c = ZEN.get(obj.pi_v, 'c', INT.new),
					 rm = ZEN.get(obj.pi_v, 'rm', INT.new),
					 rr = ZEN.get(obj.pi_v, 'rr', INT.new) },
			sigma_prime = { h_prime = ZEN.get(obj.sigma_prime, 'h_prime', ECP.new),
							s_prime = ZEN.get(obj.sigma_prime, 's_prime', ECP.new) } }
end

ZEN.add_schema({
	  -- theta: blind proof of certification
	  credential_proof = credential_proof_f,
	  -- aggregated verifiers schema is same as a single verifier
	  verifiers = verifier_f
})

When("aggregate the verifiers", function()
		if not ACK.verifiers then ACK.verifiers = { } end
		for k,v in pairs(ACK.verifier) do
		-- if ACK.verifier.alpha then
		   ACK.verifiers[k] = v
		end
		-- TODO: aggregate all array
end)

When("create the credential proof", function()
        ZEN.assert(ACK.verifiers, "No issuer verification keys are selected")
		ZEN.assert(ACK.credential_keypair.private,
				   "Credential private key not found")
		ZEN.assert(ACK.credentials, "Credentials not found")
		ACK.credential_proof =
		   COCONUT.prove_creds(ACK.verifiers,
							   ACK.credentials,
							   ACK.credential_keypair.private)
end)
When("verify the credential proof", function()
        ZEN.assert(ACK.credential_proof, "No valid credential proof found")
        ZEN.assert(ACK.verifiers, "Verifier of aggregated issuer keys not found")
        ZEN.assert(
           COCONUT.verify_creds(ACK.verifiers,
								ACK.credential_proof),
           "Credential proof does not validate")
end)

