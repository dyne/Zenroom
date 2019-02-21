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
ZEN.add_schema(
   -- credential keypair (elgamal)
   { cred_keypair =
        { import = function(obj)
             return { public = get(ECP.new, obj, 'public'),
                      private = get(INT.new, obj, 'private') } end,
          export = function(obj, conv)
             return map(obj,conv) end },

     -- certificate authority (ca) / issuer keypair
	 issue_sign =
		{ import = function(obj)
			 return { x = get(INT.new, obj, 'x'),
					  y = get(INT.new, obj, 'y') }
		end,
		  export = function(obj,conv)
			 return map(obj, conv)
		end },
	 issue_verify =
		{ import = function(obj)
			 return { alpha = get(ECP2.new, obj, 'alpha'),
					  beta = get(ECP2.new, obj, 'beta') } 
		end,
		  export = function(obj,conv) return map(obj, conv)
		end },
     issue_keypair =
        { import = function(obj)
			 return { sign = import(obj.sign, 'issue_sign'),
					  verify = import(obj.verify, 'issue_verify') }
		end,
		  export = function(obj,conv)
			 return { sign = export(obj.sign, 'issue_sign', conv),
					  verify = export(obj.verify, 'issue_verify', conv) }
		  end },

     -- request
     lambda = {
        import = function(obj)
           return { c = { a = get(ECP.new, obj.c, 'a'),
                          b = get(ECP.new, obj.c, 'b') },
                    pi_s = { rr = get(INT.new, obj.pi_s, 'rr'),
                             rm = get(INT.new, obj.pi_s, 'rm'),
                             rk = get(INT.new, obj.pi_s, 'rk'),
                             c =  get(INT.new, obj.pi_s, 'c')  },
                    cm = get(ECP.new, obj, 'cm'),
					public = get(ECP.new, obj, 'public') } end,
        export = function(obj,conv)
		   local ret = { }
		   ret.cm = get(conv, obj, 'cm')
		   ret.public = get(conv, obj, 'public')
           ret.pi_s = map(obj.pi_s, conv)
           ret.c = map(obj.c, conv)
           return ret
     end },

     -- ca issuer signature
     sigmatilde = {
        import = function(obj)
           return { h = get(ECP.new, obj, 'h'),
                    b_tilde = get(ECP.new, obj, 'b_tilde'),
                    a_tilde = get(ECP.new, obj, 'a_tilde') } end,
        export = function(obj,conv)
           return map(obj,conv) end },

     -- aggregated signatures of ca issuers
     aggsigma = {
        import = function(obj)
           return { h = get(ECP.new, obj, 'h'),
                    s = get(ECP.new, obj, 's') } end,
        export = function(obj,conv)
           return map(obj,conv) end },

     -- blind proof of certification
     theta = {
        import = function(obj)
           return { nu = get(ECP.new, obj, 'nu'),
                    kappa = get(ECP2.new, obj, 'kappa'),
                    pi_v = map(obj.pi_v, INT.new), -- TODO map wrappers
                    sigma_prime = map(obj.sigma_prime, ECP.new) } end,
        export = function(obj, conv)
           -- TODO: validation of kappa and nu
           local out = map(obj, conv)
           out.sigma_prime = map(obj.sigma_prime, conv)
           out.pi_v = map(obj.pi_v, conv)
           return out
     end },

	  -- petition
	 petition_scores = {
		import = function(obj)
		   local res = { pos = { left = ECP.infinity(), right = ECP.infinity() },
						 neg = { left = ECP.infinity(), right = ECP.infinity() } }
		   if obj.pos.left  ~= "Infinity" then res.pos.left  = get(ECP.new, obj.pos, 'left')  end
		   if obj.pos.right ~= "Infinity" then res.pos.right = get(ECP.new, obj.pos, 'right') end
		   if obj.neg.left  ~= "Infinity" then res.neg.left  = get(ECP.new, obj.neg, 'left') end
		   if obj.neg.right ~= "Infinity" then res.neg.right = get(ECP.new, obj.neg, 'right') end
		   return res
		end,
		export = function(obj, conv)
		   local res = { pos = { left = "Infinity", right = "Infinity" },
						 neg = { left = "Infinity", right = "Infinity" } }
		   if not ECP.isinf(obj.pos.left)  then res.pos.left  = get(conv, obj.pos, 'left') end
		   if not ECP.isinf(obj.pos.right) then res.pos.right = get(conv, obj.pos, 'right') end
		   if not ECP.isinf(obj.neg.left)  then res.neg.left  = get(conv, obj.neg, 'left') end
		   if not ECP.isinf(obj.neg.right) then res.neg.right = get(conv, obj.neg, 'right') end
		   return res
		end },

	 petition = {
		import = function(obj)
		   local res = { uid = get(nil, obj, 'uid'),
						 owner = get(ECP.new, obj, 'owner'),
						 scores = import(obj.scores, 'petition_scores') }
		   if type(obj.vkeys) == 'table' then res.vkeys = import(obj.vkeys, 'issue_verify') end
		   if type(obj.list) == 'table' then
			  res.list = { }
			  for k,v in ipairs(obj.list) do res.list[k] = true end
		   end
		   return res
		end,
		export = function(obj,conv)
		   local res = { }
		   res.uid = get(nil, obj, 'uid')
		   res.owner = get(conv, obj, 'owner')
		   res.scores = export(obj.scores, 'petition_scores', conv)
		   if type(obj.vkeys) == 'table' then res.vkeys = export(obj.vkeys, 'issue_verify', conv) end
		   if type(obj.list) == 'table' then
			  res.list = { }
			  for k,v in ipairs(obj.list) do res.list[k] = true end
		   end
		   return res
		end },

	 petition_signature = {
		import = function(obj)
		   return { proof = import(obj.proof, 'theta'),
					uid_signature = get(ECP.new, obj, 'uid_signature'),
					uid_petition = get(nil, obj, 'uid_petition') }
		end,
		export = function(obj, conv)
		   return { proof = export(obj.proof, 'theta', hex),
					uid_signature = get(hex, obj, 'uid_signature'),
					uid_petition = get(nil, obj, 'uid_petition') }
	 end },

	 petition_tally = {
		import = function(obj)
		   return { uid = get(nil, obj, 'uid'),
					c = get(INT.new, obj, 'c'),
					dec = { neg = get(ECP.new, obj.dec, 'neg'),
							pos = get(ECP.new, obj.dec, 'pos') },
					rx = get(INT.new, obj, 'rx') }
		end,
		export = function(obj, conv)
		   return { uid = get(nil, obj, 'uid'),
					c = get(conv, obj, 'c'),
					dec = { neg = get(conv, obj.dec, 'neg'),
							pos = get(conv, obj.dec, 'pos') },
					rx = get(conv, obj, 'rx') }
		end }
})


When("I create a new petition ''", function(uid)
		ACK.petition = { uid = uid,
						 owner = ACK.cred_kp.public,
						 scores = { pos = { left = ECP.infinity(), right = ECP.infinity() },
									neg = { left = ECP.infinity(), right = ECP.infinity() } } }
		OUT.petition = export(ACK.petition, 'petition', hex)
		-- generate an ECDH signature of the JSON encoding using the
		-- credential keys
		ecdh = ECDH.new()
		ecdh:private(ACK.cred_kp.private)
		ACK.petition_ecdh_sign = { ecdh:sign(JSON.encode(OUT.petition)) }
		OUT.petition_ecdh_sign = map(ACK.petition_ecdh_sign, hex)
end)

Given("I receive a new petition request", function()
		 ZEN.assert(type(IN.petition) == 'table',
					"Petition not found")
		 ZEN.assert(type(IN.petition_ecdh_sign) == 'table',
					"Signature not found in petition")
		 ZEN.assert(type(IN.proof) == 'table',
					"Credential proof not found in petition ")
		 ACK.petition = import(IN.petition, 'petition')
		 ACK.petition_ecdh_sign = map(IN.petition_ecdh_sign, hex)
		 ACK.petition_credential = import(IN.proof, 'theta')
end)

When("I verify the new petition to be valid", function()
        -- ZEN.debug()
        ZEN.assert(ECP.isinf(ACK.petition.scores.pos.left),
                   "Invalid new petition: positive left score is not zero")
        ZEN.assert(ECP.isinf(ACK.petition.scores.pos.right),
                   "Invalid new petition: positive right score is not zero")
        ZEN.assert(ECP.isinf(ACK.petition.scores.neg.left),
                   "Invalid new petition: negative left score is not zero")
        ZEN.assert(ECP.isinf(ACK.petition.scores.neg.right),
                   "Invalid new petition: negative right score is not zero")
		ZEN.assert(
		   COCONUT.verify_creds(ACK.verifier,
								ACK.petition_credential),
		   "Credential proof not valid in new petition")
        -- TODO: check ECDH signature
		OUT.petition = export(ACK.petition, 'petition', hex)
end)

When("I sign the petition ''", function(uid)
        ZEN.assert(ACK.verifier, "Verifier of aggregated issuer keys not found")
		ZEN.assert(ACK.cred_kp.private, "Credential private key not found")
		ZEN.assert(ACK.sigma, "Signed credential not found")
		local Theta
		local zeta
		Theta, zeta = COCONUT.prove_cred_petition(ACK.verifier, ACK.sigma, 
												  ACK.cred_kp.private, uid)
		OUT.petition_signature = { }
		OUT.petition_signature.proof = export(Theta, 'theta', hex)
		OUT.petition_signature.uid_signature = hex(zeta)
		OUT.petition_signature.uid_petition = uid
		OUT.verifier = nil
end)

Given("I receive a signature", function()
		 ZEN.assert(type(IN.petition_signature) == 'table',
					"Petition signature not found")
		 ACK.petition_signature = import(IN.petition_signature,
										 'petition_signature')
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
		OUT = { result = COCONUT.count_signatures_petition(ACK.petition.scores,
														   ACK.tally).pos }
		OUT.uid = ACK.petition.uid
end)

-- credential keypair operations
local function f_keygen()
   local kp = { }
   kp.private, kp.public = ELGAMAL.keygen()
   OUT[ACK.whoami] = export(kp, 'cred_keypair',hex) end
When("I create my new credential keypair", f_keygen)
When("I create my new credential request keypair", f_keygen)
When("I create my new keypair", f_keygen)

f_cred_keypair = function(keyname)
   ZEN.assert(keyname or ACK.whoami, "Cannot identify the request keypair to use")
   ACK.cred_kp = import(IN.KEYS[keyname or ACK.whoami],'cred_keypair') end
Given("I have my credential keypair", f_cred_keypair)
Given("I have '' credential keypair", f_cred_keypair)
Given("I have my keypair", f_cred_keypair)

-- issuer authority kepair operations
local function f_ca_keygen()
   OUT[ACK.whoami] = export(COCONUT.ca_keygen(), 'issue_keypair',hex) end
When("I create my new issuer keypair", f_ca_keygen)
When("I create my new authority keypair", f_ca_keygen)
f_issue_keypair = function(keyname)
   ZEN.assert(keyname or ACK.whoami, "Cannot identify the issuer keypair to use")
   ACK.issue_kp = import(IN.KEYS[keyname or ACK.whoami],'issue_keypair') end
Given("I have my issuer keypair", f_issue_keypair)
Given("I have '' issuer keypair", f_issue_keypair)
Given("I have my issuer keypair", f_issue_keypair)

When("I publish my issuer verification key", function()
        ZEN.assert(ACK.whoami, "Cannot identify the issuer")
        ZEN.assert(ACK.issue_kp.verify, "Issuer verification key not found")
        OUT[ACK.whoami] = { }
        OUT[ACK.whoami].verify = map(ACK.issue_kp.verify, hex) -- array
end)


Given("I use the verification key by ''", function(ca)
         if not ACK.aggkeys then ACK.aggkeys = { } end
		 if IN[ca] and type(IN[ca].verify) == 'table' then
			table.insert(ACK.aggkeys, import(IN[ca].verify,'issue_verify'))
		 elseif IN.KEYS[ca] and type(IN.KEYS[ca].verify) == 'table' then
			table.insert(ACK.aggkeys, import(IN.KEYS[ca].verify,'issue_verify'))
		 else
			ZEN.assert(false,"Verification key not found for issuer: "..ca)
		 end
end)

When("I aggregate all the verification keys", function()
        ZEN.assert(ACK.aggkeys, "No verification keys have been selected")
		ACK.verifier = COCONUT.aggregate_keys(ACK.aggkeys)
		OUT.verifier = export(ACK.verifier, 'issue_verify', hex)
end)

f_blindsign_req = function()
   ZEN.assert(type(ACK.cred_kp.public) == "zenroom.ecp",
			  "Invalid public key for credential request")
   ZEN.assert(ACK.cred_kp.private,
			  "Private key not found in credential keypair")
   ACK.lambda = COCONUT.prepare_blind_sign(
	  ACK.cred_kp.public, ACK.cred_kp.private)
   OUT['request'] = export(ACK.lambda,'lambda',hex)
end -- synonyms
When("I request a blind signature of my keypair", f_blindsign_req)
When("I request a signature of my keypair", f_blindsign_req)
When("I request to verify my keypair", f_blindsign_req)
When("I request to certify my keypair", f_blindsign_req)
When("I request a verification of my keypair", f_blindsign_req)
When("I request a certification of my keypair", f_blindsign_req)


When("I request a blind signature of my declaration", function()
        ZEN.assert(type(ACK.cred_kp.public) == "zenroom.ecp",
                   "Invalid public key for credential request")
		ZEN.assert(ACK.declared,
				   "No declaration was made so far")
		ACK.lambda = COCONUT.prepare_blind_sign(
		   ACK.cred_kp.public, str(ACK.declared))
		OUT['request'] = export(ACK.lambda,'lambda',hex)
end)

When("I am requested to sign a credential", function()
        local lambda = import(IN['request'],'lambda')
        ZEN.assert(COCONUT.verify_pi_s(lambda),
                   "Crypto error in signature, proof is invalid (verify_pi_s)")
        ACK.blindsign = lambda
end)

When("I sign the credential", function()
		ZEN.assert(ACK.whoami, "Issuer is not known")
        ZEN.assert(ACK.blindsign, "No valid signature request found.")
        ZEN.assert(ACK.issue_kp.sign, "No valid issuer signature keys found.")
        local sigmatilde =
           COCONUT.blind_sign(ACK.issue_kp.sign,
                              ACK.blindsign)
        OUT[ACK.whoami] = export(sigmatilde,'sigmatilde', hex)
		OUT.verify = export(ACK.issue_kp.verify, 'issue_verify', hex)
end)

When("I receive a credential signature ''", function(signfrom)
        -- one dimensional array is simple enough
		ACK.issuer = signfrom
        ZEN.assert(type(IN[signfrom]) == "table",
                   "No valid signature found for: " .. signfrom)
        ACK.sigmatilde = { import(IN[signfrom],'sigmatilde') }
		ACK.verify = import(IN.verify, 'issue_verify')
        -- set the blocking state _sigmatilde (array)
end)

When("I aggregate the credential into my keyring", function()
        -- check the blocking state _sigmatilde
		ZEN.assert(ACK.verify, "Verification keys from issuer not found")
        ZEN.assert(ACK.sigmatilde, "Credential issuer signatures not found")
        ZEN.assert(ACK.cred_kp.private, "Credential private key not found")
        -- prepare output with an aggregated sigma credential
        -- requester signs the sigma with private key
		-- TODO: for added security check sigmatilde with an ECDH
		-- signature before aggregating into credential
        local cred = COCONUT.aggregate_creds(ACK.cred_kp.private, ACK.sigmatilde)
		OUT.credential = export(cred,'aggsigma', hex)
		-- merge credentials with keyring
        OUT[ACK.whoami] = export(ACK.cred_kp, 'cred_keypair', hex)
end)

Given("I have a signed credential", function()
 		 ACK.sigma = import(IN.KEYS.credential, 'aggsigma')
end)

When("I generate a credential proof", function()
        ZEN.assert(ACK.verifier, "Verifier of aggregated issuer keys not found")
		ZEN.assert(ACK.cred_kp.private, "Credential private key not found")
		ZEN.assert(ACK.sigma, "Signed credential not found")
		local Theta = COCONUT.prove_creds(ACK.verifier, ACK.sigma, 
										  ACK.cred_kp.private)
		OUT.proof = export(Theta, 'theta', hex)
end)

Given("I have a valid credential proof", function()
		 if IN.KEYS.proof then
			ACK.theta = import(IN.KEYS.proof, 'theta')
		 elseif IN.proof then
			ACK.theta = import(IN.proof, 'theta')
		 else
			ZEN.assert(false, "Credential proof not found")
		 end
end)

When("the credential proof is verified correctly", function()
        ZEN.assert(ACK.theta, "No valid credential proof found")
        ZEN.assert(ACK.verifier, "Verifier of aggregated issuer keys not found")
        ZEN.assert(
           COCONUT.verify_creds(ACK.verifier, ACK.theta),
           "Credential proof does not validate")
end)
