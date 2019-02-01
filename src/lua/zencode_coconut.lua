



When("I create my new credential request keypair", function()
		OUT[ACK.whoami] = export(COCONUT.cred_keygen(), 'coconut_req_keypair',hex)
end)

When("I create my new credential issuer keypair", function()
		OUT[ACK.whoami] = export(COCONUT.ca_keygen(), 'coconut_ca_keypair',hex)
end)

f_ca_keypair = function(keyname)
   ZEN.assert(keyname or ACK.whoami, "Cannot identify the issuer keypair to use")
   ACK.ca_keypair = import(IN.KEYS[keyname or ACK.whoami],'coconut_ca_keypair')
end
Given("I have my credential issuer keypair", f_ca_keypair)
Given("I have '' credential issuer keypair", f_ca_keypair)

When("I publish my issuer verification key", function()
		ZEN.assert(ACK.whoami, "Cannot identify the issuer")
		ZEN.assert(ACK.ca_keypair.verify, "Issuer verification key not found")
		OUT[ACK.whoami] = { }
		OUT[ACK.whoami].verify = map(ACK.ca_keypair.verify, hex)
end)

f_req_keypair = function(keyname)
   ZEN.assert(keyname or ACK.whoami, "Cannot identify the request keypair to use")
   ACK.req_keypair = import(IN.KEYS[keyname or ACK.whoami],'coconut_req_keypair')
end
Given("I have my credential request keypair", f_req_keypair)
Given("I have '' credential request keypair", f_req_keypair)


Given("I use the verification key by ''", function(ca)
		 ZEN.assert(IN.KEYS[ca].verify, "Verification key not found: "..ca)
		 ACK.aggkeys = { import(IN.KEYS[ca].verify,'coconut_ca_vk') }
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
        ZEN.assert(ACK.blindsign, "No valid signature request found.")
        ZEN.assert(ACK.ca_keypair.sign, "No valid issuer signature keys found.")
        local sigmatilde =
           COCONUT.blind_sign(ACK.ca_keypair.sign,
                              ACK.blindsign.public,
							  ACK.blindsign)
        OUT[ca] = export(sigmatilde,'coconut_sigmatilde', hex)
end)

When("I receive a credential signature ''", function(signfrom)
		-- one dimensional array is simple enough
		ZEN.assert(type(IN[signfrom]) == "table",
				   "No valid signature found for: " .. signfrom)
		ACK.sigmatilde = { import(IN[signfrom],'coconut_sigmatilde') }
		-- set the blocking state _sigmatilde (array)
end)

When("I aggregate all signatures into my credential", function()
		-- check the blocking state _sigmatilde
		ZEN.assert(ACK.sigmatilde, "No valid signatures have been collected.")
		ZEN.assert(ACK.req_keypair.private, "No valid request private key found")
		-- prepare output with an aggregated sigma credential
		-- requester signs the sigma with private key
		local cred = COCONUT.aggregate_creds(ACK.req_keypair.private,
											 ACK.sigmatilde)
		OUT = { credential = export(cred,'coconut_aggsigma', hex) }
		OUT.name = ACK.whoami -- TODO: customise according to pilot identifier
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
