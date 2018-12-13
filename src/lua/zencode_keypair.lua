-- Zencode statements to manage pub/priv keypairs

-- GLOBALS:
-- keyring: straight from JSON.decode(KEYS)
-- keypair: section in keyring
-- keypair_name: current section in keyring
f_havekey = function (keytype, keyname)
   keypair_name = keyname or whoami
   keyring = JSON.decode(KEYS)
   keypair = keyring[keypair_name]
   assert(validate(keypair,schemas['keypair']),
		  "Invalid keypair for "..keypair_name)
   kt = keytype or { 'public', 'private' }
   if type(kt) == "string" then
	  assert(keypair[kt], "Key "..kt.." not found in "..keypair_name.." keypair")
   elseif type(kt) == "table" then
	  for k,v in ipairs(kt) do
		 assert(keypair[v], "Key "..v.." not found in "..keypair_name.." keypair")
	  end
   end
   -- explicit global states
   -- _G['keypair_name'] = keypair_name
   -- _G['keypair']      = { [keypair_name] = keypair }
end

Given("I have the '' key '' in keyring", f_havekey)
Given("I have my '' key in keyring", f_havekey)
Given("I have my keypair", f_havekey)

f_keygen = function (keyname)
   keypair_name = keyname or whoami
   local rng = RNG.new()
   local priv = INT.new(rng,ECP.order())
   keyring = {
	  [keypair_name] = {
		 private = hex(priv),
		 public = hex(priv * ECP.generator())}
   }
end

When("I create a new keypair as ''", f_keygen)
When("I create my new keypair", f_keygen)

f_keyrm = function (keytype)
   keyring = keyring or JSON.decode(KEYS)
   keypair_name = keypair_name or whoami
   keypair = keyring[keypair_name]
   assert(validate(keypair,schemas['keypair']),
		  "Keypair is already halved, cannot remove element")
   if keypair[keytype] then
	  local out = {}
	  L.map(keypair,function(k,v)
			   if k ~= keytype then
				  out[k] = v end end)
	  keyring = { [keypair_name] = out }
   end
end

When("I remove the '' key", f_keyrm)

Then("print my keyring", function()
		keyring = keyring or JSON.decode(KEYS)
		write_json(keyring)
end)
