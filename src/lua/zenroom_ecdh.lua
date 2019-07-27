-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2018-2019 Dyne.org foundation
-- designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

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
   local iv = O.random(16)
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
