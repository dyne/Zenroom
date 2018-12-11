local ecdh = require'ecdh'

function prepare_session(keyring, pub) -- internal function
   local kr
   if (type(keyring) == "zenroom.ecdh") then
	  kr = keyring
   else
	  error("encrypt error: arg #1 type not known ("..type(keyring)..") expected an ECDH keyring object")
   end
   local pk
   if (type(pub) == "zenroom.ecdh") then
	  pk = pub:public()
   elseif (type(pub) == "zenroom.octet") then
	  pk = pub
   else
	  error("encrypt error: arg #2 type not known ("..type(pub)..") expected an ECDH keyring or OCTET object")
   end
   return(kr:session(pk))
end


-- encrypt with default AES-GCM technique, returns base58 encoded
-- values into a table containing: .text .iv .checksum .header
function ecdh.encrypt(alice, bob, msg, header)
   warn("ecdh.decrypt() use of this function is DEPRECATED");
   local key = prepare_session(alice,bob)
   local iv = RNG.new():octet(16)
   -- convert strings to octets
   local omsg, ohead
   if(type(msg) == "string") then
	  omsg = str(msg) else omsg = msg end
   if(type(header) == "string") then
	  ohead = str(header) else ohead = header end
   local cypher = {header = ohead, iv = iv}
   cypher.text, cypher.checksum = ecdh.aead_encrypt(key,omsg,iv,ohead)
   return(cypher)
end

function ecdh.decrypt(alice, bob, cypher)
   warn("ecdh.decrypt() use of this function is DEPRECATED");
   local key = prepare_session(alice,bob)
   local decode = {header = cypher.header}
   decode.text, decode.checksum =
	  ecdh.aead_decrypt(key,
				   cypher.text,
				   cypher.iv,
				   cypher.header)
   if(cypher.checksum ~= decode.checksum) then
	  error("decrypt error: header checksum mismatch")
   end
   return(decode)
end

return ecdh
