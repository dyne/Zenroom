-- Zencode statements to manage pub/priv keypairs

-- GLOBALS:
-- keyring: straight from JSON.decode(KEYS)
-- keypair: section in keyring
-- keypair_name: current section in keyring

-- crypto setup
-- TODO: review scoping, make local or into finite-state machine
order = ECP.order()
G = ECP.generator()
KDF_rounds = 10000

local ecdh_keygen = function()
   local key = INT.new(RNG.new(),order)
   return { private = key,
			public = key * G }
end

f_havekey = function (keytype, keyname)
   local name = keyname or ACK.whoami
   local keypair = IN.KEYS[name]
   ZEN.assert(keypair, "Keypair not found: "..name)
   if keytype then
	  local key = keypair[keytype]
	  ZEN.assert(key, "Key not found for keypair "..name..": "..keytype)	  
	  ACK[name] = { }
	  ACK[name][keytype] = ZEN.get(ECP.new, keypair, keytype)
   else
	  ACK[name] = ZEN:valid("ecdh_keypair", keypair)
   end
end

Given("I have the '' key '' in keyring", f_havekey)
Given("I have my '' key in keyring", f_havekey)
Given("I have my keypair", f_havekey)

f_keygen = function (keyname)
   ACK[keyname or ACK.whoami] = map(ecdh_keygen(),hex)
end

When("I create a new keypair as ''", f_keygen)
When("I create my new keypair", f_keygen)

-- f_keyrm = function (keytype)
--    ZEN.assert([keytype],
-- 			  "Keypair "..keypair.." does not contain element: ".. keytype)
--    if kp[keytype] then
-- 	  local out = {}
-- 	  L.map(kp,function(k,v)
-- 			   if k ~= keytype then
-- 				  out[k] = v end end)
-- 	  keyring[keypair] = out
--    end
-- end

When("I remove the '' key", f_keyrm)

When("I import '' keypair into my keyring", function(kp)
		init_keyring()
		data = data or JSON.decode(DATA)
		if not data[kp] then
		   error("Keypair '"..kp.."' not found in DATA")
		end
		ZEN.data.add(keyring,kp,data[kp])
end)

Then("print my keyring", function()
		write_json(OUT[whoami])
end)
Then("print keypair ''", function(kp)
		write_json({ [keypair] = keyring[keypair]})
end)
