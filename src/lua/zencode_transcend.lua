
T = require'crypto_transcend'
-- TRANSCEND.encode_message
-- TRANSCEND.decode_message
-- TRANSCEND.encode_response
-- TRANSCEND.decode_response


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
         local nonce = mayhave'nonce' or TIME.new(os.time())
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
