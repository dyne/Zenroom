--[[
--This file is part of zenroom
--
--Copyright (C) 2020-2021 Dyne.org foundation
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

local CRED = require_once'crypto_credential'
local PET = require_once'crypto_petition'

local function petition_scores_f(o)
	local obj = deepmap(CONF.input.encoding.fun, o)
	return ({
		pos = {
			left = ZEN.get(obj.pos, 'left', ECP.new),
			right = ZEN.get(obj.pos, 'right', ECP.new)
		},
		neg = {
			left = ZEN.get(obj.neg, 'left', ECP.new),
			right = ZEN.get(obj.neg, 'right', ECP.new)
		}
	})
end


-- petition
ZEN.add_schema(
	{
		petition_scores = petition_scores_f,
		petition = function(obj)
			local res = {
				uid = ZEN.get(obj, 'uid'),
				scores = petition_scores_f(obj.scores)
			}
			if obj.owner then
				res.owner = ZEN.get(obj, 'owner', ECP.new)
			end
			if obj.issuer_public_key then
				res.issuer_public_key = key_import_issuer_verifier_f(obj.issuer_public_key)
			end
			if obj.list then
				res.list =
					deepmap(
					function(o)
						return ZEN.get(o, '.', ECP.new)
					end,
					obj.list
				)
			end
			if obj.signature then
				res.signature = {
					r = ZEN.get(obj.signature, 'r'),
					s = ZEN.get(obj.signature, 's')
				}
			end
			return res
		end,
		petition_signature = function(obj)
			return {
						-- from zencode_credential
				proof = import_credential_proof_f(obj.proof),
				uid_signature = ZEN.get(obj, 'uid_signature', ECP.new),
				uid_petition = ZEN.get(obj, 'uid_petition')
			}
		end,
		petition_tally = function(obj)
			local dec = {}
			dec.neg = ZEN.get(obj.dec, 'neg', ECP.new)
			dec.pos = ZEN.get(obj.dec, 'pos', ECP.new)
			return {
				uid = ZEN.get(obj, 'uid'),
				c = ZEN.get(obj, 'c', INT.new),
				dec = dec,
				rx = ZEN.get(obj, 'rx', INT.new)
			}
		end
	}
)

When(
	"create the petition ''",
	function(uid)
		havekey'credential'
		-- ZEN.assert(ACK.keys.credential,"Credential key not found")
		ACK.petition = {
			uid = OCTET.from_string(uid), -- TODO: take UID from HEAP not STACK
			owner = ECP.generator() * ACK.keys.credential,
			scores = {
				pos = {
					left = ECP.infinity(),
					right = ECP.infinity()
				},
				neg = {
					left = ECP.infinity(),
					right = ECP.infinity()
				}
			}
		}
		ZEN.CODEC.petition = {
			name = 'petition',
			encoding = check_codec('petition'),
			zentype = 'schema'
		}
		-- generate an ECDH signature of the (encoded) petition using the
		-- credential keys
		-- ecdh = ECDH.new()
		-- ecdh:private(ACK.cred_kp.private)
		-- ACK.petition_ecdh_sign = { ecdh:sign(MSG.pack(OUT.petition)) }
		-- OUT.petition_ecdh_sign = map(ACK.petition_ecdh_sign, hex)
	end
)

When(
	'verify the new petition to be empty',
	function()
		ZEN.assert(
			ECP.isinf(ACK.petition.scores.pos.left),
			'Invalid new petition: positive left score is not zero'
		)
		ZEN.assert(
			ECP.isinf(ACK.petition.scores.pos.right),
			'Invalid new petition: positive right score is not zero'
		)
		ZEN.assert(
			ECP.isinf(ACK.petition.scores.neg.left),
			'Invalid new petition: negative left score is not zero'
		)
		ZEN.assert(
			ECP.isinf(ACK.petition.scores.neg.right),
			'Invalid new petition: negative right score is not zero'
		)
	end
)

When(
	"create the petition signature ''",
	function(uid)
		have'credentials'
		have'issuer public key'
		havekey'credential'
		local Theta
		local zeta
		local ack_uid = OCTET.from_string(uid)
		Theta, zeta =
			CRED.prove_cred_uid(
			ACK.issuer_public_key,
			ACK.credentials,
			ACK.keys.credential,
			ack_uid
		)
		ACK.petition_signature = {
			proof = Theta,
			uid_signature = zeta, -- ECP
			uid_petition = ack_uid
		}
	end
)

IfWhen(
	'verify the signature proof is correct',
	function()
		ZEN.assert(
			CRED.verify_cred_uid(
				ACK.issuer_public_key,
				ACK.petition_signature.proof,
				ACK.petition_signature.uid_signature,
				ACK.petition_signature.uid_petition
			),
			'Petition signature is invalid'
		)
	end
)

IfWhen(
	'the petition signature is not a duplicate',
	function()
		if luatype(ACK.petition.list) == 'table' then
			ZEN.assert(
				(not array_contains(
					ACK.petition.list,
					ACK.petition_signature.uid_signature
				)),
				'Duplicate petition signature detected'
			)
		else
			ACK.petition.list = {}
		end
		table.insert(ACK.petition.list, ACK.petition_signature.uid_signature)
	end
)

IfWhen(
	'the petition signature is just one more',
	function()
		-- verify that the signature is +1 (no other value supported)
		ACK.petition_signature.one =
			PET.prove_sign_petition(ACK.petition.owner, BIG.new(1))
		ZEN.assert(
			PET.verify_sign_petition(
				ACK.petition.owner,
				ACK.petition_signature.one
			),
			'ABC petition signature adds more than one signature'
		)
	end
)

When(
	'add the signature to the petition',
	function()
		-- add the signature to the petition count
		local scores = ACK.petition.scores
		local psign = ACK.petition_signature.one
		scores.pos.left = scores.pos.left + psign.scores.pos.left
		scores.pos.right = scores.pos.right + psign.scores.pos.right
		scores.neg.left = scores.neg.left + psign.scores.neg.left
		scores.neg.right = scores.neg.right + psign.scores.neg.right
		-- TODO: ZEN:push({'petition' ,'scores'}
		ACK.petition.scores = scores
	end
)

When(
	'create a petition tally',
	function()
		havekey'credential'
		ZEN.assert(ACK.petition, 'Petition not found')
		ACK.petition_tally =
			PET.prove_tally_petition(
			ACK.keys.credential,
			ACK.petition.scores
		)
		ACK.petition_tally.uid = ACK.petition.uid
	end
)

When(
	'count the petition results',
	function()
		ZEN.assert(ACK.petition, 'Petition not found')
		ZEN.assert(ACK.petition_tally, 'Tally not found')
		ZEN.assert(
			ACK.petition_tally.uid == ACK.petition.uid,
			'Tally does not correspond to petition'
		)
		ACK.petition_results =
			PET.count_signatures_petition(
			ACK.petition.scores,
			ACK.petition_tally
		).pos
	end
)
