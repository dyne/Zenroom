--[[
--This file is part of zenroom
--
--Copyright (C) 2022-2025 Dyne.org foundation
--designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License as
--published by the Free Software Foundation, either version 3 of the
--License, or (at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--You should have received a copy of the GNU Affero General Public License 
--along with this program.  If not, see <https://www.gnu.org/licenses/>.
--]]

-- TODO: distinguish zpack and mpack
When("create mpack of ''", function(src)
    empty'mpack'
    local source = have(src)
    local tmp = MPACK.encode(source)
    ACK.mpack = OCTET.from_rawlen( tmp, #tmp )
    new_codec('mpack', { zentype = 'e'})
end)

When("create '' decoded from mpack ''", function(dst, src)
    empty(dst)
    local pack = have(src)
    zencode_assert(CODEC[src].zentype == 'e', "Invalid mpack, not an element: "..src)
    zencode_assert(type(pack) == 'zenroom.octet', "Invalid mpack, not an octet: "..src)
    ACK[dst] = MPACK.decode( OCTET.to_string( pack ) )
    new_codec(dst)
end)
