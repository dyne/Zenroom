-- global array of credential issuers
coco_ci = {}

f_coco_req_keygen = function(keyname)
   init_keyring(keyname or whoami)
   keyring[keypair] = map(COCONUT.cred_keygen(), hex)
   keyring[keypair].schema = 'coconut_req_keypair'
end

f_coco_ca_keygen = function(keyname)
   init_keyring(keyname or whoami)
   local kp = COCONUT.ca_keygen()
   kp.sign = map(kp.sign, hex)
   kp.verify = map(kp.verify, hex)
   kp.schema = 'coconut_ca_keypair'
   kp.version = COCONUT._VERSION
   keyring[keypair] = kp
end

When("I create my new credential request keypair", f_coco_req_keygen)
When("I create my new credential issuer keypair", f_coco_ca_keygen)

Given("I have my credential issuer keypair", function()
         init_keyring(whoami)
         local kp = keyring[keypair]
         ZEN.assert(validate(kp, schemas[kp.schema]), "Keypair "..whoami.." does not validate as "..kp.schema)
         ZEN.assert(validate(kp.verify, schemas['coconut_ca_vk']), "Keypair "..whoami.." lacks a valid verify key")
         ZEN.assert(validate(kp.sign, schemas['coconut_ca_sk']), "Keypair "..whoami.." lacks a valid sign key")
end)
Given("I have my credential request keypair", function()
         init_keyring(keyname or whoami)
         local kp = keyring[keypair]
         ZEN.assert(validate(kp, schemas[kp.schema]), "Keypair "..whoami.." does not validate as "..kp.schema)
end)
Given("I select the credential issuer ''", function(ca)
         data = data or ZEN.data.load()
         ZEN.assert(validate(data[ca].verify, schemas['coconut_ca_vk']),
                    "Invalid credential issuer verification key: ".. ca)
         table.insert(coco_ci, ca)
end)
Given("I use the verification key by ''", function(ca)
		 data = data or ZEN.data.load()
		 init_keyring(ca)
		 local kp = keyring[keypair]
         ZEN.assert(validate(kp.verify, schemas['coconut_ca_vk']), "Keypair "..ca.." lacks a valid verify key")
		 local vk = { }
		 vk.alpha = ECP2.new(kp.verify.alpha)
		 vk.beta = ECP2.new(kp.verify.beta)
		 vk.g2 = ECP2.new(kp.verify.g2)
		 if not data._aggkeys then data._aggkeys = {} end
		 table.insert(data._aggkeys, vk)
end)

When("I request a credential blind signature", function()
        data = data or ZEN.data.load()
        init_keyring(whoami)
        local req = COCONUT.prepare_blind_sign(
           -- explicit ECP conversion (see src/lua/crypto_elgamal)
           ECP.new(keyring[keypair].public),
           str(declared))
        -- prepare_blind_sign returns:
        -- { cm   = cm,    -- ecp
        --   c    = c,     -- table
        --   pi_s = pi_s } -- table
		-- hex encode nested EDN for JSON rendering
        req.c = map(req.c, hex)
        req.pi_s = map(req.pi_s, hex)
        req.cm = hex(req.cm)
        req.schema = 'coconut_req_blindsign'
        req.version = COCONUT._VERSION
        req.public = keyring[keypair].public
        data['request'] = req
end)

When("I am requested to sign a credential", function(reqname)
		data = data or ZEN.data.load()
		local req = data[reqname or 'request']
		local lambda = {}
		ZEN.assert(validate(req.pi_s, schemas['coconut_pi_s']),
				   "Signature request fails schema validation (pi_s)")
		lambda.pi_s = { rr = INT.new(req.pi_s.rr),
						rm = INT.new(req.pi_s.rm),
						rk = INT.new(req.pi_s.rk),
						c =  INT.new(req.pi_s.c)  }
		lambda.cm = ECP.new(req.cm)
		lambda.c = { a = ECP.new(req.c.a),
					 b = ECP.new(req.c.b) }
		lambda.public = ECP.new(req.public)
		ZEN.assert(COCONUT.verify_pi_s(lambda.public, lambda.c, lambda.cm, lambda.pi_s),
				   "Crypto error in signature, proof is invalid (verify_pi_s)")
        -- set the blocking state _blindsign
		data._blindsign = lambda
end)

When("I sign the credential ''", function(signdest)
        data = data or ZEN.data.load()
        init_keyring(whoami)
		-- check the blocking _blindsign
        ZEN.assert(data._blindsign, "No valid signature request found.")
        local sigmatilde =
           COCONUT.blind_sign(keyring[keypair].sign,
                              data._blindsign.public, data._blindsign)
		data = { }
        data[signdest] = map(sigmatilde,hex)
        -- to append also the public key of the issuer
        -- data.public = keyring[keypair].verify
        data[signdest].schema = 'coconut_sigmatilde'
        data[signdest].version = COCONUT._VERSION
end)

When("I receive a credential signature ''", function(signfrom)
		data = data or ZEN.data.load()
		init_keyring(whoami)
		-- one dimensional array is simple enough
		ZEN.assert(validate(data[signfrom], schemas['coconut_sigmatilde']),
				   "No valid signature found: " .. signfrom)		
		local sigmatilde = {}
		sigmatilde.h = ECP.new(data[signfrom].h)
		sigmatilde.a_tilde = ECP.new(data[signfrom].a_tilde)
		sigmatilde.b_tilde = ECP.new(data[signfrom].b_tilde)
		-- set the blocking state _sigmatilde (array)
		if not data._sigmatilde then data._sigmatilde = {} end
		table.insert(data._sigmatilde, sigmatilde)
end)

When("I aggregate all signatures into my credential", function()
		data = data or ZEN.data.load()
		init_keyring(whoami)
		-- check the blocking state _sigmatilde
		ZEN.assert(data._sigmatilde, "No valid signatures have been collected.")
		local cred = COCONUT.aggregate_creds(INT.new(keyring[keypair].private), data._sigmatilde)
		data = { }
		data.name = whoami -- TODO: customise according to pilot identifier
		data.credential = map(cred, hex)
		data.credential.schema = 'coconut_aggsigma'
		data.credential.version = COCONUT._VERSION
end)

When("the declaration is proven by credentials", function()
		-- TODO: multiple credential issuers
		data = data or ZEN.data.load()
		ZEN.assert(declared, "Nothing has been declared yet")
		ZEN.assert(data._aggkeys, "There are no verification keys selected")
		-- I.print(data._aggkeys)
		local aggkeys = COCONUT.aggregate_keys(data._aggkeys)
		ZEN.assert(validate(data.credential, schemas['coconut_aggsigma']),
				   "Invalid credentials provided by "..whois)
		-- I.print(data)
		local aggsigma = { }
		aggsigma.h = ECP.new(data.credential.h)
		aggsigma.s = ECP.new(data.credential.s)
		local Theta = COCONUT.prove_creds(aggkeys, aggsigma, declared)
		data = { proof = { } }
		data.proof = map(Theta, hex)
		data.proof.pi_v = map(Theta.pi_v, hex)
		data.proof.sigma_prime = map(Theta.sigma_prime, hex)
		data.proof.schema = 'coconut_theta'
		data.proof.version = COCONUT._VERSION

end)

Given("I have a valid credential proof", function()
		 data = data or ZEN.data.load()		 
		 ZEN.assert(data.proof.schema == "coconut_theta",
					"Invalid credential proof")
		 local theta = { }
		 theta.nu = ECP.new(data.proof.nu)
		 theta.kappa = ECP2.new(data.proof.kappa)
		 theta.pi_v = map(data.proof.pi_v, INT.new)
		 theta.sigma_prime = map(data.proof.sigma_prime, ECP.new)
		 data._theta = theta
end)

When("the credential proof is verified correctly", function()
		data = data or ZEN.data.load()
		ZEN.assert(data._theta, "No valid credential proof found")
		ZEN.assert(data._aggkeys, "There are no verification keys selected")
		-- I.print(data._aggkeys)
		local aggkeys = COCONUT.aggregate_keys(data._aggkeys)
		ZEN.assert(
		   COCONUT.verify_creds(aggkeys, data._theta),
		   "Credential proof does not validate")
end)
