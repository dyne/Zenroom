-- global array of credential issuers

local function import(obj, sname)
   ZEN.assert(obj, "Import error: obj is nil")
   ZEN.assert(sname, "Import error: schema is nil")
   local s = schemas[sname]
   ZEN.assert(s ~= nil, "Import error: schema not found '"..sname.."'")
   return s(obj, nil)
end
local function export(obj, sname, conv)
   ZEN.assert(obj, "Export error: obj is nil")
   ZEN.assert(type(sname) == "string", "Export error: invalid schema string")
   ZEN.assert(type(conv) == "function", "Export error: invalid conversion function")
   return schemas[sname](obj, conv)
end

When("I create my new credential request keypair", function(keyname)
		init_keyring(keyname or whoami)
		keyring[keypair] = export(COCONUT.cred_keygen(), 'coconut_req_keypair',hex)
end)

When("I create my new credential issuer keypair", function(keyname)
		init_keyring(keyname or whoami)
		keyring[keypair] = export(COCONUT.ca_keygen(), 'coconut_ca_keypair',hex)
end)

Given("I have my credential issuer keypair", function()
         init_keyring(whoami)
		 ACK.ca_keypair = import(keyring[keypair],'coconut_ca_keypair')
end)

Given("I have my credential request keypair", function()
         init_keyring(keyname or whoami)
		 ACK.req_keypair = import(keyring[keypair],'coconut_req_keypair')
end)

Given("I use the verification key by ''", function(ca)
		 init_keyring(ca)
		 local kp = keyring[keypair]
		 ACK.aggkeys = { import(kp.verify,'coconut_ca_vk') }
end)

When("I request a credential blind signature", function()
		ZEN.assert(ACK.req_keypair.public,
				   "Public key for credential request not found")
        local req = COCONUT.prepare_blind_sign(
		   ACK.req_keypair.public, str(declared))
		OUT['request'] = export(req,'coconut_request',hex)
		OUT['request'].public = hex(ACK.req_keypair.public)
end)

When("I am requested to sign a credential", function(reqname)
		local lambda = import(IN[reqname or 'request'],'coconut_lambda')
		ZEN.assert(COCONUT.verify_pi_s(lambda.public, lambda.c, lambda.cm, lambda.pi_s),
				   "Crypto error in signature, proof is invalid (verify_pi_s)")
		ACK.blindsign = lambda
end)

When("I sign the credential ''", function(ca)
        init_keyring(whoami)
        ZEN.assert(ACK.blindsign, "No valid signature request found.")
        local sigmatilde =
           COCONUT.blind_sign(keyring[keypair].sign,
                              ACK.blindsign.public,
							  ACK.blindsign)
        OUT[ca] = export(sigmatilde,'coconut_sigmatilde', hex)
end)

When("I receive a credential signature ''", function(signfrom)
		init_keyring(whoami)
		-- one dimensional array is simple enough
		ZEN.assert(type(IN[signfrom]) == "table",
				   "No valid signature found for: " .. signfrom)
		ACK.sigmatilde = { import(IN[signfrom],'coconut_sigmatilde') }
		-- set the blocking state _sigmatilde (array)
end)

When("I aggregate all signatures into my credential", function()
		init_keyring(whoami)
		-- check the blocking state _sigmatilde
		ZEN.assert(ACK.sigmatilde, "No valid signatures have been collected.")
		-- prepare output with an aggregated sigma credential
		-- requester signs the sigma with private key
		local cred = COCONUT.aggregate_creds(INT.new(keyring[keypair].private),
											 ACK.sigmatilde)
		OUT = { credential = export(cred,'coconut_aggsigma', hex) }
		OUT.name = whoami -- TODO: customise according to pilot identifier
end)

When("the declaration is proven by credentials", function()
		-- TODO: multiple credential issuers
		ZEN.assert(declared, "Nothing has been declared yet")
		ZEN.assert(ACK.aggkeys, "There are no verification keys selected")
		-- aggregate ca public keys
		local aggkeys = COCONUT.aggregate_keys(ACK.aggkeys)
		-- import sigma
		local aggsigma = import(IN.credential, 'coconut_aggsigma')
		-- generate proof (theta)
		local Theta = COCONUT.prove_creds(aggkeys, aggsigma, declared)
		-- export proof
		OUT = { proof = export(Theta, 'coconut_theta', hex) }

end)

Given("I have a valid credential proof", function()
		 ACK.theta = import(IN.proof, 'coconut_theta')
end)

When("the credential proof is verified correctly", function()
		ZEN.assert(ACK.theta, "No valid credential proof found")
		ZEN.assert(ACK.aggkeys, "There are no verification keys selected")
		local aggkeys = COCONUT.aggregate_keys(ACK.aggkeys)
		ZEN.assert(
		   COCONUT.verify_creds(aggkeys, ACK.theta),
		   "Credential proof does not validate")
end)
