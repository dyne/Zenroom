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

local get = ZEN.get


ZEN.add_schema({
	  -- credential keypair (elgamal)
      credential_keypair = function(obj)
         return { public  = get(obj, 'public', ECP.new),
                  private = get(obj, 'private', INT.new) } end
})
-- credential keypair operations
local function f_keygen()
   local kp = { }
   kp.private, kp.public = ELGAMAL.keygen()
   ACK[ACK.whoami] = kp
   ACK[ACK.whoami].schema = 'credential_keypair'
end
When("I create my new credential keypair", f_keygen)
When("I create my new credential request keypair", f_keygen)
When("I create my new keypair", f_keygen)

-- issuer authority kepair operations
ZEN.add_schema({
	  -- certificate authority (ca) / issuer keypair
      issue_sign = function(obj)
              return { x = get(obj, 'x', INT.new),
                       y = get(obj, 'y', INT.new) }
	  end,
      issue_verify = function(obj)
		 return { alpha = get(obj, 'alpha', ECP2.new),
				  beta  = get(obj, 'beta', ECP2.new) }
	  end,
	  issue_keypair = function(obj) -- recursive import
		 return { sign   = import(obj.sign,'issue_sign'),
				  verify = import(obj.verify,'issue_verify') }
	  end
})
local function f_ca_keygen()
   kp = COCONUT.ca_keygen()
   kp.schema = 'issue_keypair'
   ACK[ACK.whoami or 'anonymous'] = kp
end
When("I create my new issuer keypair", f_ca_keygen)
When("I create my new authority keypair", f_ca_keygen)
f_issue_keypair = function(keyname)
   ZEN.assert(keyname or ACK.whoami, "Cannot identify the issuer keypair to use")
   ACK.issue_keypair = import(IN.KEYS[keyname or ACK.whoami], 'issue_keypair')
end
Given("I have '' issuer keypair", f_issue_keypair)
Given("I have my issuer keypair", f_issue_keypair)
When("I publish my verification key", function()
        ZEN.assert(ACK.whoami, "Cannot identify the issuer")
        ZEN.assert(ACK.issue_keypair.verify,
				   "Issuer verification key not found")
		ACK[ACK.whoami] = { verify = ACK.issue_keypair.verify,
							schema = 'issue_verify' }
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
f_blindsign_req = function()
   ZEN.assert(ACK.credential_keypair.private,
			  "Private key not found in credential keypair")
   ACK['credential_signature_request'] = COCONUT.prepare_blind_sign(
	  ACK.credential_keypair.public, ACK.credential_keypair.private)
   ACK['credential_signature_request'].schema = 'credential_signature_request'
end -- synonyms
When("I generate a credential signature request", f_blindsign_req)
When("I request a blind signature of my keypair", f_blindsign_req)

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
				  s = get(obj, 's', ECP.new) } end
})
When("I sign the credential", function()
		ZEN.assert(ACK.whoami, "Issuer is not known")
        ZEN.assert(ACK.credential_signature_request, "No valid signature request found.")
        ZEN.assert(ACK.issue_keypair.sign, "No valid issuer signature keys found.")
        ACK.credential_signature = 
           COCONUT.blind_sign(ACK.issue_keypair.sign,
                              ACK.credential_signature_request)
		ACK.verify = ACK.issue_keypair.verify
end)
When("I aggregate the credential in ''", function(dest)
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
Given("I use the verification key by ''", function(ca)
         if not ACK.verifiers then ACK.verifiers = { } end -- array
		 if IN[ca] and type(IN[ca].verify) == 'table' then
			table.insert(ACK.verifiers, import(IN[ca].verify,'issue_verify'))
		 elseif IN.KEYS[ca] and type(IN.KEYS[ca].verify) == 'table' then
			table.insert(ACK.verifiers, import(IN.KEYS[ca].verify,'issue_verify'))
		 else
			ZEN.assert(false,"Verification key not found for issuer: "..ca)
		 end
end)
When("I aggregate all the verification keys", function()
        ZEN.assert(#ACK.aggkeys, "No verification keys have been selected")
		OUT.verifier = export(ACK.verifier, 'issue_verify', hex)
end)
When("I generate a credential proof", function()
        ZEN.assert(#ACK.verifiers > 0, "No verification keys are in use")
		ZEN.assert(ACK.credential_keypair.private,
				   "Credential private key not found")
		ZEN.assert(ACK.credentials, "Credentials not found")
		ACK.credential_proof =
		   COCONUT.prove_creds(
			  COCONUT.aggregate_keys(ACK.verifiers),
			  ACK.credentials, ACK.credential_keypair.private)
end)
When("I verify the credential proof is correct", function()
        ZEN.assert(ACK.credential_proof, "No valid credential proof found")
        ZEN.assert(ACK.verifiers, "Verifier of aggregated issuer keys not found")
        ZEN.assert(
           COCONUT.verify_creds(
			  COCONUT.aggregate_keys(ACK.verifiers),
			  ACK.credential_proof),
           "Credential proof does not validate")
end)




-- petition
ZEN.add_schema({
	  petition_scores = function(obj)
		 local res = { pos = { left = ECP.infinity(), right = ECP.infinity() },
					   neg = { left = ECP.infinity(), right = ECP.infinity() } }
		 if obj.pos.left  ~= "Infinity" then res.pos.left  = get(obj.pos, 'left', ECP.new) end
		 if obj.pos.right ~= "Infinity" then res.pos.right = get(obj.pos, 'right', ECP.new) end
		 if obj.neg.left  ~= "Infinity" then res.neg.left  = get(obj.neg, 'left', ECP.new) end
		 if obj.neg.right ~= "Infinity" then res.neg.right = get(obj.neg, 'right', ECP.new) end
		 return res
	  end,
   -- export = function(obj)
   --    local res = { pos = { left = "Infinity", right = "Infinity" },
   --               neg = { left = "Infinity", right = "Infinity" } }
   --    if not ECP.isinf(obj.pos.left)  then res.pos.left  = get(conv, obj.pos, 'left') end
   --    if not ECP.isinf(obj.pos.right) then res.pos.right = get(conv, obj.pos, 'right') end
   --    if not ECP.isinf(obj.neg.left)  then res.neg.left  = get(conv, obj.neg, 'left') end
   --    if not ECP.isinf(obj.neg.right) then res.neg.right = get(conv, obj.neg, 'right') end
   --    return res
   -- end },

	  petition = function(obj)
		 local res = { uid = obj['uid'], -- get(obj, 'uid', str),
					   owner = get(obj, 'owner', ECP.new),
					   scores = import(obj.scores, 'petition_scores') }
		 if type(obj.vkeys) == 'table' then res.vkeys = import(obj.vkeys, 'issue_verify') end
		 if type(obj.list) == 'table' then
			res.list = { }
			for k,v in ipairs(obj.list) do res.list[k] = true end
		 end
		 return res
			   end,

	 petition_signature = function(obj)
		   return { proof = import(obj.proof, 'theta'),
					uid_signature = get(obj, 'uid_signature', ECP.new),
					uid_petition = get(obj, 'uid_petition') }
		end,

	 petition_tally = function(obj)
		   local dec = { }
		   if obj.dec.neg ~= "Infinity" then dec.neg = get(obj.dec, 'neg', ECP.new)
		   else dec.neg = ECP.infinity() end
		   if obj.dec.pos ~= "Infinity" then dec.pos = get(obj.dec, 'pos', ECP.new)
		   else dec.pos = ECP.infinity() end
		   return { uid = get(obj, 'uid'),
					c = get(obj, 'c', INT.new),
					dec = dec,
					rx = get(obj, 'rx', INT.new) }
		end

})


When("I generate a new petition ''", function(uid)
		ACK.petition = 
		   { uid = uid,
			 owner = ACK.credential_keypair.public,
			 scores = { pos = { left = "Infinity",       -- ECP.infinity()
								right = "Infinity" },    -- ECP.infinity()
						neg = { left = "Infinity",       -- ECP.infinity()
								right = "Infinity" } } } -- ECP.infinity()
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
		   COCONUT.aggregate_keys(ACK.verifiers),
		   ACK.credentials, 
		   ACK.credential_keypair.private, uid)
		ACK.petition_signature = { proof = Theta,
								   uid_signature = zeta,
								   uid_petition = uid }
end)

Given("I receive a petition", function()
		 if type(IN.petition) == 'table' then
			ACK.petition = import(IN.petition, 'petition')
			ACK.verifier = import(IN.verifier, 'issue_verify')
		 elseif type(IN.KEYS.petition) == 'table' then
			ACK.petition = import(IN.KEYS.petition, 'petition')
			ACK.verifier = import(IN.KEYS.verifier, 'issue_verify')
		 else
			ZEN.assert(false, "Petition not found")
		 end
end)

When("a valid petition signature is counted", function()
		ZEN.assert(ACK.petition_signature, "Petition signature not found")
		ZEN.assert(ACK.petition, "Petition not found")
        ZEN.assert(ACK.verifier, "Verifier of aggregated issuer keys not found")
		ZEN.assert(ACK.petition_signature.uid_petition ==
				   ACK.petition.uid, "Petition and signature do not match")
		ZEN.assert(
		   COCONUT.verify_cred_petition(ACK.verifier,
										ACK.petition_signature.proof,
										ACK.petition_signature.uid_signature,
										ACK.petition_signature.uid_petition),
		   "Petition signature is invalid")
		-- check for duplicate signatures
		local k = hex(ACK.petition_signature.uid_signature)
		if type(ACK.petition.list) == 'table' then
		   ZEN.assert(
			  ACK.petition.list[k] == nil,
			  "Duplicate petition signature detected")
		   ACK.petition.list[k] = true
		else
		   ACK.petition.list = { }
		   ACK.petition.list[k] = true
		end
		-- verify that the signature is +1 (no other value supported)
		local psign = COCONUT.prove_sign_petition(ACK.petition.owner, BIG.new(1))
		ZEN.assert(COCONUT.verify_sign_petition(ACK.petition.owner, psign),
				   "Coconut petition signature internal error")
		-- add the signature to the petition count
		local ps = ACK.petition.scores
		local ss = psign.scores
		ps.pos.left  = ps.pos.left  + ss.pos.left
		ps.pos.right = ps.pos.right + ss.pos.right
		ps.neg.left  = ps.neg.left  + ss.neg.left
		ps.neg.right = ps.neg.right + ss.neg.right
		OUT.petition = export(ACK.petition, 'petition', hex)
		OUT.petition.scores = export(ps, 'petition_scores', hex)
		OUT.verifier = export(ACK.verifier, 'issue_verify', hex)
end)

Given("I receive a tally", function()
		 -- TODO: find tally in DATA and KEYS
		 ZEN.assert(type(IN.KEYS.tally) == 'table', "Tally not found")
		 ACK.tally = import(IN.KEYS.tally, 'petition_tally')
end)

When("I tally the petition", function()
        ZEN.assert(ACK.cred_kp.private,
				   "Private key not found in credential keypair")
		ZEN.assert(ACK.petition, "Petition not found")
		ACK.tally = COCONUT.prove_tally_petition(
		   ACK.cred_kp.private, ACK.petition.scores)
		OUT.petition = export(ACK.petition, 'petition', hex)
		OUT.petition.list = nil -- save space
		ACK.tally.uid = ACK.petition.uid
		OUT.tally = export(ACK.tally, 'petition_tally', hex)
end)

When("I count the petition results", function()
		ZEN.assert(ACK.petition, "Petition not found")
		ZEN.assert(ACK.tally, "Tally not found")
		ZEN.assert(ACK.tally.uid == ACK.petition.uid,
				   "Tally does not correspond to petition")
		OUT = { }
		local res = COCONUT.count_signatures_petition(ACK.petition.scores, ACK.tally)
		-- handle no signatures correctly: res.pos is nil hence result: 0
		if res.pos then OUT.result = res.pos else OUT.result = 0 end
		OUT.uid = ACK.petition.uid
end)
