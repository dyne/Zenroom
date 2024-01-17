
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
		local IV,IV_codec = mayhave'IV' or octet.zero(32)
		local nonce = mayhave'nonce' or TIME.new(os.time())
		ACK.transcend_ciphertext =
		   T.encode_message(SS, nonce, message, IV)
		new_codec'transcend ciphertext'
end)

-- use keyring.transcend as SS
When("create transcend cleartext of ''",function(ctxt)
		local SS = havekey'transcend'
		local ciphertext = have(ctxt)
		local IV, IV_codec = mayhave'IV' or octet.zero(32)
		local nonce = mayhave'none' or TIME.new(os.time())
		ACK.transcend_cleartext =
		   T.decode_message(SS, nonce, ciphertext, IV)
		new_codec'transcend cleartext'
end)
