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

-- ABC/COCONUT implementation in Zencode

local ABC = require_once('crypto_abc')
local G1 = ECP.generator()
local G2 = ECP2.generator()

function issuer_key_f(o)
	local obj = deepmap(CONF.input.encoding.fun, o)
	return { x = ZEN.get(obj, 'x', INT.new),
			 y = ZEN.get(obj, 'y', INT.new) }
 end

ZEN.add_schema({
	keys = function(obj)
		local res = { }
		if obj.credential then
			res.credential = INT.new( CONF.input.encoding.fun(obj.credential))
		end
		if obj.issuer then
			local o = deepmap(CONF.input.encoding.fun, obj.issuer)
			res.issuer = {	x = INT.new(o.x),
							y = INT.new(o.y)	}
		end
		return(res)
	end,
	credential_verifier = function(obj)
		return(ECP.new(CONF.input.encoding.fun(obj)))
	end,
	issuer_verifier = function(obj)
		local o = deepmap(CONF.input.encoding.fun, obj)
		return { alpha = ECP2.new(o.alpha),
				 beta  = ECP2.new(o.beta)	}
	end
})

-- credential keypair operations
When("create the credential key", function()
	ACK.keys = fif(ACK.keys, ACK.keys, {})
	ZEN.assert(not ACK.keys.credential, "Cannot overwrite object: ".."keys.credential")
	ACK.keys.credential = INT.random()
end)

When("create the credential verifier", function()
	ZEN.have'keys'
	ZEN.assert(ACK.keys.credential, "Object not found: ".."keys.credential")
	ACK.credential_verifier = ECP.generator() *	ACK.keys.credential
end)

When("create the credential keypair with secret key ''", function(sec)
	local secret = ZEN.have(sec)
	ZEN.assert(not ACK.keypair.credential, "Cannot overwrite object: ".."keypair.credential")
	ACK.keypair.credential = INT.new(secret)
end)

When("create the issuer key", function()
	ACK.keys = fif(ACK.keys, ACK.keys, {})
	ZEN.assert(not ACK.keys.issuer, "Cannot overwrite object: ".."keys.issuer")
	ACK.keys.issuer = ABC.issuer_keygen()
end)

When("create the issuer verifier", function()
	ZEN.have'keys'
	ZEN.assert(ACK.keys.issuer, "Object not found: ".."keys.issuer")
	ACK.issuer_verifier = { alpha	= G2 * ACK.keys.issuer.x,
							beta	= G2 * ACK.keys.issuer.y	}
end)

-- TODO:
-- When("create the issuer key with secret key ''", function(sec)
-- 	local secret = ZEN.have(sec)
-- 	ZEN.assert(not ACK.keypair.issuer, "Cannot overwrite object: ".."keypair.issuer")
-- 	ACK.keypair.issuer = ABC.issuer_keygen(sec)
-- end)


-- request credential signatures
ZEN.add_schema({
     -- lambda
	  credential_request = function(obj)
		local req = { sign = {	a = ZEN.get(obj.sign, 'a', ECP.new),
								b = ZEN.get(obj.sign, 'b', ECP.new) },
					  pi_s = { rr = ZEN.get(obj.pi_s, 'rr', INT.new),
							   rm = ZEN.get(obj.pi_s, 'rm', INT.new),
							   rk = ZEN.get(obj.pi_s, 'rk', INT.new),
							   commit =  ZEN.get(obj.pi_s, 'commit',  INT.new)  },
					  commit = ZEN.get(obj, 'commit', ECP.new),
					  public = ZEN.get(obj, 'public', ECP.new) }
		ZEN.assert(ABC.verify_pi_s(req),
                   "Error in credential request: proof is invalid (verify_pi_s)")
		return req
	  end
})

When("create the credential request", function()
	ZEN.have'keys'
	ZEN.assert(ACK.keys.credential, "Credential key not found")
	ACK.credential_request = ABC.prepare_blind_sign(ACK.keys.credential)
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
		ZEN.have'credential request'
        ZEN.assert(ACK.keys.issuer, "Issuer key not found")
        ACK.credential_signature =
           ABC.blind_sign(ACK.keys.issuer, ACK.credential_request)
		ACK.verifier = {	alpha	= G2 * ACK.keys.issuer.x,
							beta	= G2 * ACK.keys.issuer.y	}
end)
When("create the credentials", function()
	ZEN.have'credential signature'
	ZEN.have'keys'
    ZEN.assert(ACK.keys.credential, "Credential key not found")
    -- prepare output with an aggregated sigma credential
    -- requester signs the sigma with private key
    ACK.credentials = ABC.aggregate_creds(
		   ACK.keys.credential, { ACK.credential_signature })
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
	--   verifiers = verifier_f
})

When("aggregate the verifiers", function()
	ZEN.have'issuer verifier'
		if not ACK.verifiers then ACK.verifiers = { } end
		for k,v in pairs(ACK.issuer_verifier) do
		-- if ACK.verifier.alpha then
		   ACK.verifiers[k] = v
		end
		-- TODO: aggregate all array
end)

When("create the credential proof", function()
	ZEN.have'verifiers'
	ZEN.have'keys'
	ZEN.have'credentials'
	ZEN.empty'credential proof'
	ZEN.assert(ACK.keys.credential, "Credential key not found")
	ACK.credential_proof =
		ABC.prove_cred(ACK.verifiers,
					   ACK.credentials,
					   ACK.keys.credential)
end)
When("verify the credential proof", function()
	ZEN.have'credential proof'
	ZEN.have'verifiers'
    ZEN.assert(
        ABC.verify_cred(	ACK.verifiers,
								ACK.credential_proof),
           "Credential proof does not validate")
end)

