-- Zencode statements to manage pub/priv keypairs

-- GLOBALS:
-- keyring: straight from JSON.decode(KEYS)
-- keypair: section in keyring
-- keypair_name: current section in keyring

keyring = nil
keypair = nil

-- crypto setup
random = RNG.new()
order = ECP.order()
G = ECP.generator()
KDF_rounds = 10000

ZEN.keygen = function()
   local key = INT.new(random,order)
   return { private = key,
			public = key * G }
end

function init_keyring(keyname)
   keypair = keyname
   if KEYS then
	  keyring = keyring or JSON.decode(KEYS)
   else
	  keyring = keyring or {}
   end
end

f_havekey = function (keytype, keyname)
   init_keyring(keyname or whoami)
   ZEN.assert(validate(keyring[keypair],schemas['keypair']), "Invalid keypair for "..keypair)
   local kp = keyring[keypair]
   local kt = keytype or { "public", "private" }
   if type(kt) == "string" then
	  if kt == "public" then
		 ZEN.assert(ECP.validate(kp[kt]), "Key "..kt.." not found in "..keypair.." keypair")
	  else
		 ZEN.assert(kp[kt], "Key "..kt.." not found in "..keypair.." keypair")
	  end
   elseif type(kt) == "table" then
	  for k,v in ipairs(kt) do
		 if v == "public" then
			ZEN.assert(ECP.validate(kp[v]), "Key "..v.." not found in "..keypair.." keypair")
		 else
			ZEN.assert(kp[v], "Key "..v.." not found in "..keypair.." keypair")
		 end
	  end
   end
end

Given("I have the '' key '' in keyring", f_havekey)
Given("I have my '' key in keyring", f_havekey)
Given("I have my keypair", f_havekey)

f_keygen = function (keyname)
   init_keyring(keyname or whoami)
   keyring[keypair] = map(ZEN.keygen(),hex)
end

When("I create a new keypair as ''", f_keygen)
When("I create my new keypair", f_keygen)

f_keyrm = function (keytype)
   init_keyring(keypair or whoami)
   ZEN.assert(validate(keyring[keypair],schemas['keypair']),
		  "Keypair is already halved, cannot remove element")
   if not (keytype == "public" or keytype == "private") then
	  error("keys inside a keypair are either public or private")
   end
   local kp = keyring[keypair]
   if kp[keytype] then
	  local out = {}
	  L.map(keyring[keypair],function(k,v)
			   if k ~= keytype then
				  out[k] = v end end)
	  keyring[keypair] = out
   end
end

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
		init_keyring()
		write_json(keyring)
end)
Then("print all keyring", function()
		init_keyring()
		write_json(keyring)
end)
Then("print keypair ''", function(kp)
		init_keyring(kp)
		write_json({ [keypair] = keyring[keypair]})
end)
