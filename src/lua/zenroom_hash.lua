--[[
--This file is part of zenroom
--
--Copyright (C) 2018-2021 Dyne.org foundation
--designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License v3.0
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--Along with this program you should have received a copy of the
--GNU Affero General Public License v3.0
--If not, see http://www.gnu.org/licenses/agpl.txt
--
--Last modified by Denis Roio
--on Tuesday, 20th July 2021
--]]

local hash = require'hash'

-- when using facility functions, global hashers are created only once
SHA256 = nil
SHA512 = nil
local function init(bits)
   local h
   if bits == 256 or bits == 32 then
	  if SHA256==nil then SHA256 = hash.new('sha256') end
	  h = SHA256
   elseif bits == 512 or bits == 64 then
	  if SHA512==nil then SHA512 = hash.new('sha512') end
	  h = SHA512
   else
	  error("HASH bits not supported: "..bits)
   end
   return h
end

function sha256(data) return init(256):process(data) end
function sha512(data) return init(512):process(data) end
function KDF(data, bits)
   local b = bits or 256
   return init(b):kdf2(data)
end

function hash.dsha256(msg)
   local SHA256 = HASH.new('sha256')
   return SHA256:process(SHA256:process(msg))
end

function hash.hash160(msg)
   local SHA256 = HASH.new('sha256')
   local RMD160 = HASH.new('ripemd160')
   return RMD160:process(SHA256:process(msg))

end


return hash
