
T = require'crypto_transcend'
-- TRANSCEND.encode_message
-- TRANSCEND.decode_message
-- TRANSCEND.encode_response
-- TRANSCEND.decode_response

-- length of k and p must be at least 32 bytes
local function transcend_ciphertext_f(obj)
    local res = {}
    res.p = schema_get(obj, 'p')
    zencode_assert(#res.p >= 32, "Transcend ciphertext component p must be at least 32 bytes long")
    res.k = schema_get(obj, 'k')
    zencode_assert(#res.k >= 32, "Transcend ciphertext component k must be at least 32 bytes long")
    res.n = schema_get(obj, 'n')
    zencode_assert(#res.n < #res.k, "Transcend ciphertext component n must be smaller than k")
    zencode_assert(#res.p == #res.k, "Transcend ciphertext component p length must be equal to k")
    return res
end

local function transcend_32_bound(obj, name)
    local res = schema_get(obj, '.')
    zencode_assert(#res > 32, "Transcend " .. name .. " must be at least 32 bytes long")
    return res
end

ZEN:add_schema(
    {
        transcend_ciphertext = transcend_ciphertext_f,
        transcend_response = function(obj) return transcend_32_bound(obj, "response") end,
        transcend_session_key = function(obj) return transcend_32_bound(obj, "session key") end
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
When("create transcend key",function()
         initkeyring'transcend'
         ACK.keyring.transcend = _keygen()
end)

local function _transcend_key_from_secret(sec)
    local k = have(sec)
    initkeyring'transcend'
    ACK.keyring.transcend = k
end

When("create transcend key with secret key ''",
	 _transcend_key_from_secret
)
When("create transcend key with secret ''",
     _transcend_key_from_secret
)


-- create transcend cleartext of ''
-- ACK.transcend_cleartext
-- create transcend response of '' to ''
-- create transcend clear response of ''

-- create AES GCM ciphertext of ''
-- ACK.AES GCM_ciphertext
-- create AES GCM cleartext of ''
-- ACK.AES GCM_cleartext

-- use keyring.transcend as SS

-- create transcend ciphertext of ''
-- ACK.transcend_ciphertext
When("create transcend ciphertext of ''",function(msg)
         local SS = havekey'transcend'
         local message = have(msg)
         -- RSK session key is not imported because should be generated
         -- every new session.
         local nonce = mayhave'nonce' or TIME.new(os.time()):octet()
         ACK.transcend_ciphertext =
             T.encode_message(SS, nonce, message)
         new_codec'transcend ciphertext'
end)

-- use keyring.transcend as SS
When("create transcend cleartext of ''",function(ctxt)
         local SS = havekey'transcend'
         local ciphertext = have(ctxt)
         local RSK
         ACK.transcend_cleartext, RSK =
             T.decode_message(SS, ciphertext)
         new_codec'transcend cleartext'
         new_cache('transcend session key', RSK)
         new_cache('transcend session nonce', ciphertext.n)
end)

When("create transcend response with ''",function(msg)
         local SS = havekey'transcend'
         local response = have(msg)
         local RSK =
             mayhave'transcend session key' or CACHE.transcend_session_key or
             error("Transcend session key (RSK) not found")
         local nonce =
             mayhave'nonce' or CACHE.transcend_session_nonce or
             error("Transcend session nonce not found")
         ACK.transcend_response =
             T.encode_response(SS, nonce, RSK, response)
         new_codec'transcend response'
end)

When("create transcend response of '' with ''",function(ctxt, msg)
         local SS = havekey'transcend'
         local ciphertext = have(ctxt)
         local response = have(msg)
         local _, RSK = T.decode_message(SS, ciphertext)
         local nonce = ciphertext.n or
             mayhave'nonce' or CACHE.transcend_session_nonce or
             TIME.new(os.time())
         ACK.transcend_response =
             T.encode_response(SS, nonce, RSK, response)
         new_codec'transcend response'
end)

When("create transcend cleartext of response ''",function(ctxt)
         local SS = havekey'transcend'
         local ciphertext = have(ctxt)
         local RSK =
             mayhave'transcend session key' or CACHE.transcend_session_key or
             error("Transcend session key (RSK) not found")
         local nonce =
             mayhave'transcend session nonce' or
             CACHE.transcend_session_nonce or
             TIME.new(os.time())
         ACK.transcend_cleartext =
             T.decode_response(SS, nonce, RSK, ciphertext)
         new_codec'transcend cleartext'
end)

When("create transcend cleartext of response '' to ''",function(cres, cmsg)
         local SS = havekey'transcend'
         local response = have(cres)
         local message = have(cmsg)
         local nonce = message.n or
             mayhave'transcend session nonce' or
             CACHE.transcend_session_nonce or
             TIME.new(os.time())
         local _, RSK = T.decode_message(SS, message)
         ACK.transcend_cleartext =
             T.decode_response(SS, nonce, RSK, response)
         new_codec'transcend cleartext'
end)
