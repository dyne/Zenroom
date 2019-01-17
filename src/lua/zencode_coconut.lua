
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
		data['request'] = req
end)

