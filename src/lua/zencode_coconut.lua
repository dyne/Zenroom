-- COCONUT implementation in Zencode

local random = RNG.new()

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
     issue_keypair =
        { import = function(obj)
             return { sign = { x = get(INT.new, obj.sign, 'x'),
                               y = get(INT.new, obj.sign, 'y') },
                      verify = { alpha = get(ECP2.new,obj.verify, 'alpha'),
                                 beta = get(ECP2.new, obj.verify, 'beta'),
                                 g2 = get(ECP2.new, obj.verify, 'g2') } } end,
          export = function(obj,conv)
             return { sign   = map(obj.sign, conv),
                      verify = map(obj.verify, conv) } end },
     -- ca public issuer keys / verification key
     ca_vk =
        { import = function(obj)
             return { alpha = get(ECP2.new, obj, 'alpha'),
                      beta = get(ECP2.new, obj, 'beta'),
                      g2 = get(ECP2.new, obj, 'g2') } end,
          export = function(obj,conv)
             return map(obj,conv) end },

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
      new_petition = {
         import = function(obj)
			return { uid = get(O.from_hex, obj, 'uid'),
					 pub_owner = get(ECP.new, obj, 'pub_owner'),
					 lambda = import(obj.lambda, 'lambda'), -- see above
					 scores = { first = get(hex, obj.scores, 'first'),
					 			second = get(hex, obj.scores, 'second'),
					 			dec = obj.scores.dec,
					 			list = obj.scores.list }
		 } end,
		 export = function(obj,conv)
			local out = map(obj, conv)
			out.lambda = export(obj.lambda, 'lambda', conv)
			out.scores = map(obj.scores, conv)
			out.scores.dec = map(obj.scores.dec, conv)
			out.scores.list = map(obj.scores.list, conv)
			return out
	  end },

	  running_petition = {
		 import = function(obj)
			return { uid = get(O.from_hex, obj, 'uid'),
					 scores = hex("TODO"),
						-- { first = get(hex, obj.scores, 'first'),
						--   second = get(hex, obj.scores, 'second'),
						--   dec = obj.scores.dec,
						--   list = obj.scores.list },
					 sigma = import(obj.sigma, 'aggsigma'),
					 ca_public = import(obj.ca_public, 'ca_vk') } end,
		 export = function(obj,conv)
			local out = map(obj,conv)
			out.sigma = export(obj.sigma,'aggsigma',conv)
			out.scores = conv("TODO")
			out.ca_public = export(obj.ca_public, 'ca_vk', conv)
			return out
		 end
	  }

})


When("I create a new petition", function()
        local j = export(
		   { uid = "sadasd", -- INT.new(random),
			 pub_owner = ACK.cred_kp.public,
			 lambda = COCONUT.prepare_blind_sign(
				-- TODO: private key or secret string?
				ACK.cred_kp.public, ACK.cred_kp.private),
			 scores = { first = "Infinity",
						second = "Infinity",
						dec = { },
						list = { } } }, 'new_petition', hex)
        -- TODO: sign the JSON string or MSGPACK
        OUT.petition = j
        OUT.petition_signature = true
        OUT.petition_owner = ACK.whoami
end)

Given("I am requested to sign a new petition", function()
         ACK.petition = import(IN.petition, 'new_petition')
end)
Given("I can sign a petition", function()
         ACK.petition = import(IN.petition, 'running_petition')
end)

When("I verify the petition to be valid", function()
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
		OUT.ca_public = export(ACK.issue_kp.verify, 'ca_vk', hex)
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
									ca_public = import(IN.ca_public,'ca_vk') },
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
         ZEN.assert(type(IN.KEYS[ca].verify) == "table",
					"Invalid verification key by issuer: "..ca)
         ACK.aggkeys = { import(IN.KEYS[ca].verify,'ca_vk') }
end)

When("I request a credential blind signature", function()
        ZEN.assert(type(ACK.cred_kp.public) == "zenroom.ecp",
                   "Invalid public key for credential request")
        local lambda = COCONUT.prepare_blind_sign(
           ACK.cred_kp.public, str(declared))
        OUT['request'] = export(lambda,'request',hex)
end)

When("I am requested to sign a credential", function()
        local lambda = import(IN['request'],'lambda')
        ZEN.assert(COCONUT.verify_pi_s(lambda),
                   "Crypto error in signature, proof is invalid (verify_pi_s)")
        ACK.blindsign = lambda
end)

When("I sign the credential ''", function(ca)
        ZEN.assert(ACK.blindsign, "No valid signature request found.")
        ZEN.assert(ACK.issue_kp.sign, "No valid issuer signature keys found.")
        local sigmatilde =
           COCONUT.blind_sign(ACK.issue_kp.sign,
                              ACK.blindsign)
        OUT[ca] = export(sigmatilde,'sigmatilde', hex)
end)

When("I receive a credential signature ''", function(signfrom)
        -- one dimensional array is simple enough
        ZEN.assert(type(IN[signfrom]) == "table",
                   "No valid signature found for: " .. signfrom)
        ACK.sigmatilde = { import(IN[signfrom],'sigmatilde') }
        -- set the blocking state _sigmatilde (array)
end)

When("I aggregate all signatures into my credential", function()
        -- check the blocking state _sigmatilde
        ZEN.assert(ACK.sigmatilde, "No valid signatures have been collected.")
        ZEN.assert(ACK.cred_kp.private, "No valid request private key found")
        -- prepare output with an aggregated sigma credential
        -- requester signs the sigma with private key
        local cred = COCONUT.aggregate_creds(ACK.cred_kp.private,
                                             ACK.sigmatilde)
        OUT = { credential = export(cred,'aggsigma', hex) }
        OUT.name = ACK.whoami -- TODO: customise according to pilot identifier
end)

When("the declaration is proven by credentials", function()
        -- TODO: multiple credential issuers
        ZEN.assert(declared, "Nothing has been declared yet")
        ZEN.assert(ACK.aggkeys, "There are no verification keys selected")
        -- aggregate ca public keys
        local aggkeys = COCONUT.aggregate_keys(ACK.aggkeys)
        -- import sigma
        local aggsigma = import(IN.credential, 'aggsigma')
        -- generate proof (theta)
        local Theta = COCONUT.prove_creds(aggkeys, aggsigma, declared)
        -- export proof
        OUT = { proof = export(Theta, 'theta', hex) }

end)

Given("I have a valid credential proof", function()
         ACK.theta = import(IN.proof, 'theta')
end)

When("the credential proof is verified correctly", function()
        ZEN.assert(ACK.theta, "No valid credential proof found")
        ZEN.assert(ACK.aggkeys, "There are no verification keys selected")
        local aggkeys = COCONUT.aggregate_keys(ACK.aggkeys)
        ZEN.assert(
           COCONUT.verify_creds(aggkeys, ACK.theta),
           "Credential proof does not validate")
end)

When("I create a new petition ''", function(ptext)
		ACK.petition = { uid = O.new(RNG.new(),32),
						 owner = ACK.cred_kp.public,
						 scores = { first = 0,
									second = 0 },
						 list = { } }
		OUT.petition = export(ACK.petition, 'petition', hex)
		ACK.petition_ecdh_sign = 'signed' -- TODO sign OUT.petition string
		OUT.petition_signed = hex(ACK.petition_ecdh_sign)
end)
