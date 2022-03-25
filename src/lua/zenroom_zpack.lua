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

local mpack = MPACK -- require_once'zenroom_msgpack'

local zpack = { }

zpack.encode = function(src)
   local tmp = mpack.encode(src)
   return compress( O.from_rawlen(tmp, #tmp) )
end

zpack.decode = function(src)
   return mpack.decode( O.to_string( decompress(src) ) )
end

return zpack
