local mayo = require 'mayo'

local function mayo_public_key_f(obj)  
    local res = schema_get(obj, '.')
    zencode_assert(
        mayo.pubcheck(res),
        'MAYO public key length is not correct'
    )
    return res
end

local function mayo_signature_f(obj)
    local res = schema_get(obj, '.')
    zencode_assert(
        mayo.signature_check(res),
        'MAYO signature length is not correct'
    )
    return res
end

ZEN:add_schema(
    {
        mayo_public_key = {import=mayo_public_key_f},
        mayo_signature = {import=mayo_signature_f}
    }
)

--# MAYO #--

-- generate the private key
When("create mayo key",function()
	initkeyring'mayo'
	ACK.keyring.mayo = mayo.secgen()
end)

-- generate the public key
When("create mayo public key",function()
	empty'mayo public key'
	local sk = havekey'mayo'
	ACK.mayo_public_key = mayo.pubgen(sk)
	new_codec('mayo public key')
end)

local function _pubkey_from_secret(sec)
   local sk = have(sec)
   initkeyring'mayo'
   mayo.pubgen(sk)
   ACK.keyring.mayo = sk
end

When("create mayo key with secret key ''",
     _pubkey_from_secret
)

When("create mayo key with secret ''",
     _pubkey_from_secret
)

When("create mayo public key with secret key ''",function(sec)
	local sk = have(sec)
	empty'mayo public key'
	ACK.mayo_public_key = mayo.pubgen(sk)
	new_codec('mayo public key')
end)

-- generate the sign for a msg and verify
When("create mayo signature of ''",function(doc)
	local sk = havekey'mayo'
	local obj = have(doc)
	empty'mayo signature'
	ACK.mayo_signature = mayo.sign(sk, zencode_serialize(obj))
	new_codec('mayo signature')
end)

IfWhen("verify '' has a mayo signature in '' by ''",function(msg, sig, by)
	  local pk = load_pubkey_compat(by, 'mayo')
	  local m = have(msg)
	  local s = have(sig)
	  zencode_assert(
	     mayo.verify(pk, s, zencode_serialize(m)),
	     'The mayo signature by '..by..' is not authentic'
	  )
end)