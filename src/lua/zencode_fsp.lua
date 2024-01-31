
FSP = require'crypto_fsp'
-- FSP.encode_message
-- FSP.decode_message
-- FSP.encode_response
-- FSP.decode_response

-- length of k and p must be at least 32 bytes
local function fsp_ciphertext_f(obj)
    local res = {}
    res.p = schema_get(obj, 'p')
    zencode_assert(#res.p >= 32, "Fsp ciphertext component p must be at least 32 bytes long")
    res.k = schema_get(obj, 'k')
    zencode_assert(#res.k >= 32, "Fsp ciphertext component k must be at least 32 bytes long")
    res.n = schema_get(obj, 'n')
    zencode_assert(#res.n < #res.k, "Fsp ciphertext component n must be smaller than k")
    zencode_assert(#res.p == #res.k, "Fsp ciphertext component p length must be equal to k")
    return res
end

local function fsp_32_bound(obj, name)
    local res = schema_get(obj, '.')
    zencode_assert(#res > 32, "Fsp " .. name .. " must be at least 32 bytes long")
    return res
end

ZEN:add_schema(
    {
        fsp_ciphertext = fsp_ciphertext_f,
        fsp_response = function(obj) return fsp_32_bound(obj, "response") end,
        fsp_session_key = function(obj) return fsp_32_bound(obj, "session key") end
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
         local nonce = mayhave'nonce' or TIME.new(os.time()):octet()
         ACK.fsp_ciphertext =
             FSP:encode_message(SS, nonce, message)
         new_codec'fsp ciphertext'
end)

-- use keyring.fsp as SS
When("create fsp cleartext of ''",function(ctxt)
         local SS = havekey'fsp'
         local ciphertext = have(ctxt)
         local RSK
         ACK.fsp_cleartext, RSK =
             FSP:decode_message(SS, ciphertext)
         new_codec'fsp cleartext'
         new_cache('fsp session key', RSK)
         new_cache('fsp session nonce', ciphertext.n)
end)

When("create fsp response with ''",function(msg)
         local SS = havekey'fsp'
         local response = have(msg)
         local RSK =
             mayhave'fsp session key' or CACHE.fsp_session_key or
             error("Fsp session key (RSK) not found")
         local nonce =
             mayhave'nonce' or CACHE.fsp_session_nonce or
             error("Fsp session nonce not found")
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
             mayhave'nonce' or CACHE.fsp_session_nonce or
             TIME.new(os.time())
         ACK.fsp_response =
             FSP:encode_response(SS, nonce, RSK, response)
         new_codec'fsp response'
end)

When("create fsp cleartext of response ''",function(ctxt)
         local SS = havekey'fsp'
         local ciphertext = have(ctxt)
         local RSK =
             mayhave'fsp session key' or CACHE.fsp_session_key or
             error("Fsp session key (RSK) not found")
         local nonce =
             mayhave'fsp session nonce' or
             CACHE.fsp_session_nonce or
             TIME.new(os.time())
         ACK.fsp_cleartext =
             FSP:decode_response(SS, nonce, RSK, ciphertext)
         new_codec'fsp cleartext'
end)

When("create fsp cleartext of response '' to ''",function(cres, cmsg)
         local SS = havekey'fsp'
         local response = have(cres)
         local message = have(cmsg)
         local nonce = message.n or
             mayhave'fsp session nonce' or
             CACHE.fsp_session_nonce or
             TIME.new(os.time())
         local _, RSK = FSP:decode_message(SS, message)
         ACK.fsp_cleartext =
             FSP:decode_response(SS, nonce, RSK, response)
         new_codec'fsp cleartext'
end)
