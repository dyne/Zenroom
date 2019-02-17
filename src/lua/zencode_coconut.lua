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
     request = {
        import = function(obj)
           return { c = { a = get(ECP.new, obj.c, 'a'),
                          b = get(ECP.new, obj.c, 'b') },
                    pi_s = { rr = get(INT.new, obj.pi_s, 'rr'),
                             rm = get(INT.new, obj.pi_s, 'rm'),
                             rk = get(INT.new, obj.pi_s, 'rk'),
                             c =  get(INT.new, obj.pi_s, 'c')  },
                    cm = get(ECP.new, obj, 'cm') } end,
        export = function(obj,conv)
           local ret = map(obj, conv)
           ret.pi_s = map(obj.pi_s, conv)
           ret.c = map(obj.c, conv)
           return ret
     end },

     -- proof
     lambda = {
        import = function(obj)
           return { pi_s = { rr = get(INT.new, obj.pi_s, 'rr'),
                             rm = get(INT.new, obj.pi_s, 'rm'),
                             rk = get(INT.new, obj.pi_s, 'rk'),
                             c =  get(INT.new, obj.pi_s, 'c')  },
					-- cm is the h element in elgamal crypto
					-- in coconut is cm = (g1 * r + hs * m)
					-- where hs is a constant, r is random and m is secret
                    cm = get(ECP.new, obj, 'cm'),
					-- c .a .b are the results of elgamal encryption
                    c = { a = get(ECP.new, obj.c, 'a'),
                          b = get(ECP.new, obj.c, 'b') },
                    public = get(ECP.new, obj, 'public') } end,
        export = function(obj,conv)
		   local out = { }
		   out.cm = conv(obj.cm)
		   if obj.public then out.public = conv(obj.public) end
           out.pi_s = map(obj.pi_s, conv)
           out.c = map(obj.c, conv)
           return out
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
		   local res = { }
		   if obj.pos == "zero" then res.pos = ECP.infinity()
		   else res.pos = get(hex, obj, 'pos') end
		   if obj.neg == "zero" then res.neg = ECP.infinity()
		   else res.neg = get(hex, obj, 'neg') end
		   return res
		end,
		export = function(obj, conv)
		   local res = { }
		   if obj.pos == "zero" then res.pos = "zero"
		   else res.pos = conv(obj.pos) end
		   if obj.neg == "zero" then res.neg = "zero"
		   else res.neg = conv(obj.neg) end
		   return res
		end },

	 petition = {
		import = function(obj)
		   local res = { uid = get(O.from_hex, obj, 'uid'),
						 gid = get(nil, obj, 'gid'), -- string
						 owner = get(ECP.new, obj, 'pub_owner'),
						 scores = import(obj.scores, 'petition_scores') }
		   if type(obj.vkeys) == 'table' then res.vkeys = import(obj.vkeys, 'issue_verify') end
		   if type(obj.list) == 'table' then res.list = map(obj.list, INT.new) end
		   return res
		end,
		export = function(obj,conv)
		   local res = { }
		   res.uid = get(conv, obj, 'uid')
		   res.gid = get(nil, obj, 'gid')
		   res.owner = get(conv, obj, 'owner')
		   res.scores = export(obj.scores, 'petition_scores', conv)
		   if type(obj.vkeys) == 'table' then res.vkeys = export(obj.vkeys, 'issue_verify', conv) end
		   if type(obj.list) == 'table' then res.list = map(obj.list, hex) end
		   return res
		end },

	 petition_credential = {
		import = function(obj)
		   return { sigma = import(obj.sigma, 'aggsigma'),
					theta = import(obj.theta, 'theta') }
		end,
		export = function(obj, conv)
		   return { sigma = export(obj.sigma, 'aggsigma', conv),
					theta = export(obj.theta, 'theta', conv) }
		end }
})

Given("I receive a new petition request", function()
		 ZEN.assert(type(IN.petition_signed) == 'table',
					"No petition signature found")
		 ZEN.assert(type(IN.petition_credential) == 'table',
					"No petition credential found")
		 ACK.petition = import(IN.petition, 'petition')
		 ACK.petition_signature = map(IN.petition_signed, hex)
		 ACK.petition_credential = import(IN.petition_credential, 'petition_credential')
		 ecdh = ECDH.new()
end)

Given("I can sign a petition", function()
         ACK.petition = import(IN.petition, 'running_petition')
end)

When("I verify the new petition to be valid", function()
        -- ZEN.debug()
        ZEN.assert(ACK.petition.scores.first == str("Infinity"),
                   "Invalid new petition: first score is not infinite")
        ZEN.assert(ACK.petition.scores.second == str("Infinity"),
                   "Invalid new petition: first score is not infinite")
        -- TODO: check signature
end)

When("I certify the issuing of the petition", function()
		ZEN.assert(ACK.whoami, "Issuer is not known")
        ZEN.assert(ACK.petition, "No valid signature request found.")
        ZEN.assert(ACK.issue_kp.sign, "No valid issuer signature keys found.")
        local sigmatilde =
           COCONUT.blind_sign(ACK.issue_kp.sign,
                              ACK.petition.lambda)
		OUT.ca_public = export(ACK.issue_kp.verify, 'issue_verify', hex)
		OUT[ACK.whoami] = export(sigmatilde,'sigmatilde', hex)
		OUT.petition = export(ACK.petition, 'new_petition', hex)
end)

When("I aggregate all certifications for my petition", function()
        -- check the blocking state _sigmatilde
        ZEN.assert(ACK.sigmatilde, "No valid signatures have been collected.")
        ZEN.assert(ACK.cred_kp.private, "No valid request private key found")

		ACK.petition = import(IN.petition, 'new_petition')

        -- prepare output with an aggregated sigma credential
        -- requester signs the sigma with private key
        local aggsigma = COCONUT.aggregate_creds(ACK.cred_kp.private,
                                             ACK.sigmatilde)
        OUT = { petition = export({ sigma = aggsigma,
									uid = ACK.petition.uid,
									scores = "TODO",
									-- TODOS here
									ca_public = import(IN.ca_public,'issue_verify') },
				   'running_petition', hex) }
        OUT.name = ACK.whoami -- TODO: customise according to pilot identifier
end)

When("I sign the petition", function()
		ZEN.assert(ACK.whoami, "Signer is not known")
		ZEN.assert(ACK.cred_kp.private, "No valid request private key found")
		ZEN.assert(ACK.petition.sigma, "No valid petition found")
		local Theta
		local zeta
		Theta, zeta = COCONUT.prove_cred_petition(ACK.petition.ca_public,
												  ACK.petition.sigma,
												  ACK.cred_kp.private,
												  ACK.petition.uid)
		ZEN.assert(COCONUT.verify_cred_petition(ACK.petition.ca_public,
												Theta, zeta, ACK.petition.uid),
				   "Failed to verify the petition signature")
		print("PETITION SIGN SUCCESS") -- WIP
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
         ZEN.assert(type(IN[ca].verify) == "table",
					"Invalid verification key by issuer: "..ca)
         if not ACK.aggkeys then ACK.aggkeys = { } end
		 table.insert(ACK.aggkeys, import(IN[ca].verify,'issue_verify'))
end)

When("I aggregate all the verification keys", function()
        ZEN.assert(ACK.aggkeys, "No verification keys have been selected")
		ACK.verifier = COCONUT.aggregate_keys(ACK.aggkeys)
		OUT.verifier = export(ACK.verifier, 'issue_verify', hex)
end)

When("I request a blind signature of my keypair", function()
        ZEN.assert(type(ACK.cred_kp.public) == "zenroom.ecp",
                   "Invalid public key for credential request")
        ZEN.assert(ACK.cred_kp.private,
                   "Private key not found in credential keypair")
		ACK.lambda = COCONUT.prepare_blind_sign(
		   ACK.cred_kp.public, ACK.cred_kp.private)
		OUT['request'] = export(ACK.lambda,'request',hex)
end)

When("I request a blind signature of my declaration", function()
        ZEN.assert(type(ACK.cred_kp.public) == "zenroom.ecp",
                   "Invalid public key for credential request")
		ZEN.assert(ACK.declared,
				   "No declaration was made so far")
		ACK.lambda = COCONUT.prepare_blind_sign(
		   ACK.cred_kp.public, str(ACK.declared))
		OUT['request'] = export(ACK.lambda,'request',hex)
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
        ZEN.assert(ACK.aggkeys, "No verification keys have been selected")
		ZEN.assert(ACK.cred_kp.private, "Credential private key not found")
		ZEN.assert(ACK.sigma, "Signed credential not found")
		local verifier = COCONUT.aggregate_keys(ACK.aggkeys)
		local Theta = COCONUT.prove_creds(verifier, ACK.sigma, 
										  ACK.cred_kp.private)
		OUT.proof = export(Theta, 'theta', hex)
end)

When("the declaration is proven by credentials", function()
        -- TODO: multiple credential issuers
        ZEN.assert(ACK.declared, "Nothing has been declared yet")
        ZEN.assert(ACK.aggkeys, "There are no verification keys selected")
        -- aggregate ca public keys
        local aggkeys = COCONUT.aggregate_keys(ACK.aggkeys)
        -- import sigma
        ACK.aggsigma = import(IN.credential, 'aggsigma')
        -- generate proof (theta)
        local Theta = COCONUT.prove_creds(aggkeys, ACK.aggsigma, ACK.declared)
        -- export proof
        OUT = { proof = export(Theta, 'theta', hex) }

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
        ZEN.assert(ACK.aggkeys, "There are no verification keys selected")
        local aggkeys = COCONUT.aggregate_keys(ACK.aggkeys)
        ZEN.assert(
           COCONUT.verify_creds(aggkeys, ACK.theta),
           "Credential proof does not validate")
end)

When("I create a new petition '' in ''", function(ptext, pgroup)
		ACK.petition = { uid = RNG.new():octet(32),
						 gid = pgroup,
						 owner = ACK.cred_kp.public,
						 scores = { pos = 'zero', neg = 'zero' } }
		OUT.petition = export(ACK.petition, 'petition', hex)
		ecdh = ECDH.new()
		ecdh:private(ACK.cred_kp.private)
		ACK.petition_ecdh_sign = { ecdh:sign(JSON.encode(OUT.petition)) }
		OUT.petition_signed = map(ACK.petition_ecdh_sign, hex)
end)
