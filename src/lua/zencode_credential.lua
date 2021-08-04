--[[
--This file is part of zenroom
--
--Copyright (C) 2018-2021 Dyne.org foundation
--designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License v3.0
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--Along with this program you should have received a copy of the
--GNU Affero General Public License v3.0
--If not, see http://www.gnu.org/licenses/agpl.txt
--
--Last modified by Denis Roio
--on Tuesday, 20th July 2021
--]]

-- ABC/COCONUT implementation in Zencode

local CRED = require_once('crypto_credential')
-- local G1 = ECP.generator()
local G2 = ECP2.generator()

-- exported function (non local) for use in zencode_petition
function import_credential_proof_f(obj)
	return {
		nu = ZEN.get(obj, 'nu', ECP.new),
		kappa = ZEN.get(obj, 'kappa', ECP2.new),
		pi_v = {
			c = ZEN.get(obj.pi_v, 'c', INT.new),
			rm = ZEN.get(obj.pi_v, 'rm', INT.new),
			rr = ZEN.get(obj.pi_v, 'rr', INT.new)
		},
		sigma_prime = {
			h_prime = ZEN.get(obj.sigma_prime, 'h_prime', ECP.new),
			s_prime = ZEN.get(obj.sigma_prime, 's_prime', ECP.new)
		}
	}
end
function key_import_issuer_verifier_f(obj)
	return {
		alpha = ZEN.get(obj, 'alpha', ECP2.new),
		beta = ZEN.get(obj, 'beta', ECP2.new)
	}
end

-- credential keypair operations
When(
	'create the credential key',
	function()
		initkeys'credential'
		ACK.keys.credential = INT.random()
	end
)

When(
	"create the credential key with secret key ''",
	function(sec)
		initkeys'credential'
		ACK.keys.credential = INT.new(secret) % ECP.modulo()
	end
)

When(
	'create the issuer key',
	function()
		initkeys'issuer'
		ACK.keys.issuer = CRED.issuer_keygen()
	end
)

When(
	'create the issuer public key',
	function()
		havekey'issuer'
		ACK.issuer_public_key = {
			alpha = G2 * ACK.keys.issuer.x,
			beta = G2 * ACK.keys.issuer.y
		}
	end
)

-- request credential signatures
ZEN.add_schema(
	{
        issuer_public_key = key_import_issuer_verifier_f,
		-- lambda
		credential_request = function(obj)
			local req = {
				sign = {
					a = ZEN.get(obj.sign, 'a', ECP.new),
					b = ZEN.get(obj.sign, 'b', ECP.new)
				},
				pi_s = {
					rr = ZEN.get(obj.pi_s, 'rr', INT.new),
					rm = ZEN.get(obj.pi_s, 'rm', INT.new),
					rk = ZEN.get(obj.pi_s, 'rk', INT.new),
					commit = ZEN.get(obj.pi_s, 'commit', INT.new)
				},
				commit = ZEN.get(obj, 'commit', ECP.new),
				public = ZEN.get(obj, 'public', ECP.new)
			}
			ZEN.assert(
				CRED.verify_pi_s(req),
				'Error in credential request: proof is invalid (verify_pi_s)'
			)
			return req
		end
	}
)

When(
	'create the credential request',
	function()
		havekey'credential'
		ACK.credential_request = CRED.prepare_blind_sign(ACK.keys.credential)
	end
)

-- issuer's signature of credentials
ZEN.add_schema(
	{
		-- sigmatilde
		credential_signature = function(obj)
			return {
				h = ZEN.get(obj, 'h', ECP.new),
				b_tilde = ZEN.get(obj, 'b_tilde', ECP.new),
				a_tilde = ZEN.get(obj, 'a_tilde', ECP.new)
			}
		end,
		-- aggsigma: aggregated signatures of ca issuers
		credentials = function(obj)
			return {
				h = ZEN.get(obj, 'h', ECP.new),
				s = ZEN.get(obj, 's', ECP.new)
			}
		end
	}
)
When(
	'create the credential signature',
	function()
		have 'credential request'
		havekey'issuer'
		ACK.credential_signature =
			CRED.blind_sign(ACK.keys.issuer, ACK.credential_request)
		ACK.verifier = {
			alpha = G2 * ACK.keys.issuer.x,
			beta = G2 * ACK.keys.issuer.y
		}
	end
)
When(
	'create the credentials',
	function()
		have 'credential signature'
		havekey'credential'
		-- prepare output with an aggregated sigma credential
		-- requester signs the sigma with private key
		ACK.credentials =
			CRED.aggregate_creds(ACK.keys.credential, {ACK.credential_signature})
	end
)

ZEN.add_schema(
	{
		-- theta: blind proof of certification
		credential_proof = function(obj)
			return {
				nu = ZEN.get(obj, 'nu', ECP.new),
				kappa = ZEN.get(obj, 'kappa', ECP2.new),
				pi_v = {
					c = ZEN.get(obj.pi_v, 'c', INT.new),
					rm = ZEN.get(obj.pi_v, 'rm', INT.new),
					rr = ZEN.get(obj.pi_v, 'rr', INT.new)
				},
				sigma_prime = {
					h_prime = ZEN.get(obj.sigma_prime, 'h_prime', ECP.new),
					s_prime = ZEN.get(obj.sigma_prime, 's_prime', ECP.new)
				}
			}
		end
	}
)

When(
	'aggregate the issuer public keys',
	function()
		have 'issuer public key'
		if not ACK.verifiers then
			ACK.verifiers = {}
		end
		for k, v in pairs(ACK.issuer_public_key) do
			ACK.verifiers[k] = v
		end
		-- TODO: aggregate all array
	end
)

When(
	'create the credential proof',
	function()
		have 'verifiers'
		have 'credentials'
		empty 'credential proof'
		havekey'credential'
		ACK.credential_proof =
			CRED.prove_cred(ACK.verifiers, ACK.credentials, ACK.keys.credential)
	end
)
IfWhen(
	'verify the credential proof',
	function()
		have 'credential proof'
		have 'verifiers'
		ZEN.assert(
			CRED.verify_cred(ACK.verifiers, ACK.credential_proof),
			'Credential proof does not validate'
		)
	end
)
