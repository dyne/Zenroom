
FSP = require'crypto_fsp'
-- FSP.encode_message
-- FSP.decode_message
-- FSP.encode_response
-- FSP.decode_response

-- length of k and p must be at least 32 bytes
local function fsp_ciphertext_f(obj)
    local res = {}
    res.p = schema_get(obj, 'p')
	local pl = #res.p
    zencode_assert(pl == FSP.RSK_length,
				   "Fsp ciphertext component p must be "..FSP.RSK_length.." bytes long")
    res.k = schema_get(obj, 'k')
	local kl = #res.k
    zencode_assert(kl == FSP.RSK_length,
				   "Fsp ciphertext component k must be "..FSP.RSK_length.." bytes long")
    res.n = schema_get(obj, 'n')
    zencode_assert(#res.n < FSP.RSK_length,
				   "Fsp ciphertext component n must be smaller than 256 bytes")
    zencode_assert(pl == kl,
				   "Fsp ciphertext component p length must be equal to k")
    return res
end

local function fsp_256_bound(obj, name)
    local res = schema_get(obj, '.')
    zencode_assert(#res == 256, "FSP " .. name .. " must be at least 256 bytes long")
    return res
end

ZEN:add_schema(
    {
        fsp_ciphertext = fsp_ciphertext_f,
        fsp_response = function(obj) return fsp_256_bound(obj, "response") end,
        fsp_session = function(obj) return fsp_256_bound(obj, "session") end
    }
)

local function _keygen()
    -- method for obtaining a valid EC secret key at random
    local sk, d
    repeat
        sk = OCTET.random(32)
        d = BIG.new(sk)
        if  ECP.order() <= d then d = BIG.new(0) end --guaranties that the generated keypair is valid
    until (d ~= BIG.new(0))
    return sk
end

-- generate the private key
When("create fsp key",function()
         initkeyring'fsp'
         ACK.keyring.fsp = _keygen()
end)

local function _fsp_key_from_secret(sec)
    local k = have(sec)
    initkeyring'fsp'
    ACK.keyring.fsp = k
end

When("create fsp key with secret key ''",
	 _fsp_key_from_secret
)
When("create fsp key with secret ''",
     _fsp_key_from_secret
)


-- create fsp cleartext of ''
-- ACK.fsp_cleartext
-- create fsp response of '' to ''
-- create fsp clear response of ''

-- create AES GCM ciphertext of ''
-- ACK.AES GCM_ciphertext
-- create AES GCM cleartext of ''
-- ACK.AES GCM_cleartext

-- use keyring.fsp as SS

-- create fsp ciphertext of ''
-- ACK.fsp_ciphertext
When("create fsp ciphertext of ''",function(msg)
         local SS = havekey'fsp'
         local message = have(msg)
         -- RSK session key is not imported because should be generated
         -- every new session.
		 local RSK = mayhave'fsp session'
			or OCTET.random(FSP.RSK_length)
         local nonce = mayhave'fsp nonce'
			or FSP:makenonce()
         ACK.fsp_ciphertext =
			FSP:encode_message(SS, nonce, message)
         new_codec'fsp ciphertext'
end)

-- use keyring.fsp as SS
When("create fsp cleartext of ''",function(ctxt)
         local SS = havekey'fsp'
         local ciphertext = have(ctxt)
		 local nonce = mayhave'fsp nonce' or ciphertext.n
         local RSK
         ACK.fsp_cleartext, RSK =
             FSP:decode_message(SS, ciphertext, nonce)
         new_codec'fsp cleartext'
         new_cache('fsp session', RSK)
         new_cache('fsp nonce', nonce)
end)

When("create fsp response with ''",function(msg)
         local SS = havekey'fsp'
         local response = have(msg)
         local RSK =
             mayhave'fsp session' or CACHE.fsp_session or
             error("FSP session not found")
         local nonce =
             mayhave'fsp nonce' or CACHE.fsp_nonce or
             error("FSP nonce not found")
         ACK.fsp_response =
             FSP:encode_response(SS, nonce, RSK, response)
         new_codec'fsp response'
end)

When("create fsp response of '' with ''",function(ctxt, msg)
         local SS = havekey'fsp'
         local ciphertext = have(ctxt)
         local response = have(msg)
         local _, RSK = FSP:decode_message(SS, ciphertext)
         local nonce = ciphertext.n or
             mayhave'fsp nonce' or CACHE.fsp_nonce or FSP:makenonce()
         ACK.fsp_response =
             FSP:encode_response(SS, nonce, RSK, response)
         new_codec'fsp response'
end)

When("create fsp cleartext of response ''",function(ctxt)
         local SS = havekey'fsp'
         local ciphertext = have(ctxt)
         local RSK =
             mayhave'fsp session' or CACHE.fsp_session or
             error("FSP session not found")
         local nonce =
             mayhave'fsp nonce' or CACHE.fsp_nonce or FSP:makenonce()
         ACK.fsp_cleartext =
             FSP:decode_response(SS, nonce, RSK, ciphertext)
         new_codec'fsp cleartext'
end)

When("create fsp cleartext of response '' to ''",function(cres, cmsg)
         local SS = havekey'fsp'
         local response = have(cres)
         local message = have(cmsg)
         local nonce = message.n or
             mayhave'fsp nonce' or CACHE.fsp_nonce or FSP:makenonce()
         local _, RSK = FSP:decode_message(SS, message)
         ACK.fsp_cleartext =
             FSP:decode_response(SS, nonce, RSK, response)
         new_codec'fsp cleartext'
end)
