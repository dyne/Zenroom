
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
		-- 	 pi_s = pi_s } -- table
		req.c = map(req.c, hex)
		req.pi_s = map(req.pi_s, hex)
		req.cm = hex(req.cm)
		req.schema = 'coconut_req_blindsign'
		req.version = COCONUT._VERSION
		req.public = keyring[keypair].public
		data['request'] = req
end)

When("I have a valid blind signature ''", function(reqname)
		 data = data or ZEN.data.load()
		 local req = data[reqname]
		 local lambda = {}
		 ZEN.assert(validate(req.pi_s,
							 S.record {
								rr = S.int,
								rm = S.int,
								rk = S.int,
								c = S.int }),
					"Blind signature request fails schema validation (pi_s)")
		 lambda.pi_s = { rr = INT.new(req.pi_s.rr),
						 rm = INT.new(req.pi_s.rm),
						 rk = INT.new(req.pi_s.rk),
						 c =  INT.new(req.pi_s.c)  }
		 lambda.cm = ECP.new(req.cm)
		 lambda.c = { a = ECP.new(req.c.a),
					  b = ECP.new(req.c.b) }
		 lambda.public = ECP.new(req.public)
		 ZEN.assert(COCONUT.verify_pi_s(lambda.public, lambda.c, lambda.cm, lambda.pi_s),
					"Blind signature zero knowledge proof is invalid")
		 data._blindsign = lambda
end)

When("I blind sign the credential ''", function(signdest)
		data = data or ZEN.data.load()
		init_keyring(whoami)
		ZEN.assert(data._blindsign, "No valid blind signature request found.")
		local sigmatilde =
		   COCONUT.blind_sign(keyring[keypair].sign,
							  data._blindsign.public, data._blindsign)
		data = map(sigmatilde,hex)
		-- to append also the public key of the issuer
		-- data.public = keyring[keypair].verify
		data.schema = 'coconut_sigmatilde'
		data.version = COCONUT._VERSION
end)
