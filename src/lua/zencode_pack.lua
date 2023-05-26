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

-- TODO: distinguish zpack and mpack
When("create the mpack of ''", function(src)
    empty'mpack'
    local source = have(src)
    local tmp = MPACK.encode(source)
    ACK.mpack = OCTET.from_rawlen( tmp, #tmp )
    new_codec('mpack', { zentype = 'e'})
end)

When("create the '' decoded from mpack ''", function(dst, src)
    empty(dst)
    local pack = have(src)
    ZEN.assert(ZEN.CODEC[src].zentype == 'e', "Invalid mpack, not an element: "..src)
    ZEN.assert(type(pack) == 'zenroom.octet', "Invalid mpack, not an octet: "..src)
    ACK[dst] = MPACK.decode( OCTET.to_string( pack ) )
    new_codec(dst)
end)
