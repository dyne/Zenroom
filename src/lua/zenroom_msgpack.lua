--[[
--This file is part of zenroom
--
--Copyright (C) 2022 Dyne.org foundation
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
--]]

-- required by zenroom_zpack

local mpack = require_once'msgpack'
local pack, unpack = string.pack, string.unpack

local to_octenv = OCTET.to_url64
local from_octenv = OCTET.from_url64

-- userdata codes available

-- 0xc{7,8,9} 
mpack.encoder_functions['zenroom.octet'] = function(v)
   return pack('>Bs4', 0xc7, to_octenv(v)) end
mpack.encoder_functions['zenroom.big'] = function(v)
   return pack('>Bs4', 0xc8, to_octenv(v:octet())) end
-- reserved for zenroom 3.0
-- mpack.encoder_functions['zenroom.float'] = function(v)
--    return pack('>Bs4', 0xc9, to_octenv(v:octet())) end

-- 0xd{4,5,6,7,8}
mpack.encoder_functions['zenroom.ecp']   = function(v)
   return pack('>Bs4', 0xd4, to_octenv(v:octet())) end
mpack.encoder_functions['zenroom.ecp2']   = function(v)
   return pack('>Bs4', 0xd5, to_octenv(v:octet())) end

local function decode_octet(data, offset)
   local value, pos = string.unpack('>s4', data, offset)
   return from_octenv(value), pos
end
local function decode_big(data, offset)
   local value, pos = string.unpack('>s4', data, offset)
   return BIG.new(from_octenv(value)), pos
end
local function decode_ecp(data, offset)
   local value, pos = string.unpack('>s4', data, offset)
   return ECP.new(from_octenv(value)), pos   
end
local function decode_ecp2(data, offset)
   local value, pos = string.unpack('>s4', data, offset)
   return ECP2.new(from_octenv(value)), pos   
end
mpack.decoder_functions[0xc7] = decode_octet
mpack.decoder_functions[0xc8] = decode_big
mpack.decoder_functions[0xd4] = decode_ecp
mpack.decoder_functions[0xd5] = decode_ecp2

return mpack
