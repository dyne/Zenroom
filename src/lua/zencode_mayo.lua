local mayo = require 'mayo'

local function mayo_public_key_f(obj)  
    local res = schema_get(obj, '.')
    zencode_assert(
        mayo.sigpubcheck(res),
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

-- generate the keypair
When("create mayo key pair",function()
	initkeyring'mayo'
    empty'mayo public key'
    local keys = mayo.sigkeygen()
    ACK.keyring.mayo = keys.private
    ACK.mayo_public_key = keys.public
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
