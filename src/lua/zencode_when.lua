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
--on Friday, 9th April 2021
--]]

--- WHEN

When("append '' to ''", function(src, dest)
	local val = have(src)
	local dst = have(dest)
	ACK[dest] = dst .. val
end)

When("create the ''", function(dest)
	empty (dest)
	ACK[dest] = { }
	ZEN.CODEC[dest] = guess_conversion(ACK[dest], dest)
	ZEN.CODEC[dest].name = dest
end)

-- simplified exception for I write: import encoding from_string ...
When("write string '' in ''", function(content, dest)
	empty(dest)
	ACK[dest] = O.from_string(content)
	ZEN.CODEC[dest] = { name = dest,
						encoding = 'string',
						luatype = 'string',
						zentype = 'element' }
end)

-- ... and from a number
When("write number '' in ''", function(content, dest)
	empty(dest)
	-- TODO: detect number base 10
	ACK[dest] = tonumber(content, 10)
	ZEN.CODEC[dest] = { name = dest,
						encoding = 'number',
						luatype = 'number',
						zentype = 'element' }
end)

When("set '' to '' as ''", function(dest, content, format)
	empty(dest)
	local guess = input_encoding(format)
	guess.raw = content
	ACK[dest] = operate_conversion(guess)
	ZEN.CODEC[dest] = { name = dest,
						encoding = format,
						luatype = 'string',
						zentype = 'element' }

end)

When("create the cbor of ''", function(src)
	have(src)
	empty'cbor'
	ACK.cbor = OCTET.from_string( CBOR.encode(ACK[src]) )
end)

When("create the json of ''", function(src)
	have(src)
	empty'json'
	ACK.json = OCTET.from_string( JSON.encode(ACK[src]) )
end)

-- numericals
When("set '' to '' base ''", function(dest, content, base)
	empty(dest)
	local bas = tonumber(base)
	ZEN.assert(bas, "Invalid numerical conversion for base: "..base)
	local num = tonumber(content,bas)
	ZEN.assert(num, "Invalid numerical conversion for value: "..content)
	ACK[dest] = num
	ZEN.CODEC[dest] = { name = dest,
						encoding = 'number',
						luatype = 'number',
						zentype = 'element' }
end)

When("rename the '' to ''", function(old,new)
	have(old)
	empty(new)
	ACK[new] = ACK[old]
	ACK[old] = nil
	ZEN.CODEC[new] = ZEN.CODEC[old]
	ZEN.CODEC[old] = nil
end)
When("rename '' to ''", function(old,new)
	have(old)
	empty(new)
	ACK[new] = ACK[old]
	ACK[old] = nil
	ZEN.CODEC[new] = ZEN.CODEC[old]
	ZEN.CODEC[old] = nil
end)

When("copy the '' to ''", function(old,new)
	have(old)
	empty(new)
	ACK[new] = deepcopy(ACK[old])
	ZEN.CODEC[new] = deepcopy(ZEN.CODEC[old])
end)
When("copy '' to ''", function(old,new)
	have(old)
	empty(new)
	ACK[new] = deepcopy(ACK[old])
	ZEN.CODEC[new] = deepcopy(ZEN.CODEC[old])
end)

When("split the rightmost '' bytes of ''", function(len, src)
	have(src)
	empty'rightmost'
	local s = tonumber(len)
	ZEN.assert(s, "Invalid number arg #1: "..type(len))
	local l,r = OCTET.chop(ACK[src],s)
	ACK.rightmost = r
	ACK[src] = l
	ZEN.CODEC.rightmost = ZEN.CODEC[src]
end)

When("split the leftmost '' bytes of ''", function(len, src)
	have(src)
	empty'leftmost'
	local s = tonumber(len)
	ZEN.assert(s, "Invalid number arg #1: "..type(len))
	local l,r = OCTET.chop(ACK[src],s)
	ACK.leftmost = l
	ACK[src] = r
	ZEN.CODEC.leftmost = ZEN.CODEC[src]
end)

When("create the result of '' + ''", function(left,right)
	have(left)
	have(right)
	empty'result'
    local l = 0
	if ZEN.CODEC[left].zentype == 'array' then
	   for k,v in ipairs(ACK[left]) do l = l + tonumber(v) end
	else
	   l = tonumber(ACK[left])
	end
       ZEN.assert(l, "Invalid number in element: "..left)
	local r = 0
	if ZEN.CODEC[right].zentype == 'array' then
	   for k,v in ipairs(ACK[right]) do r = r + tonumber(v) end
	else
	   r = tonumber(ACK[right])
	end
       ZEN.assert(r, "Invalid number in element: "..right)
       ACK.result = l + r
       ZEN.CODEC.result = { name = result,
                            encoding = 'number',
                             luatype = 'number',
							 zentype = 'element' }
end)

When("create the result of '' - ''", function(left,right)
	have(left)
	have(right)
	empty'result'
	    local l = tonumber(ACK[left])
        ZEN.assert(l, "Invalid number in element: "..left)
        local r = tonumber(ACK[right])
        ZEN.assert(r, "Invalid number in element: "..right)
	    ACK.result = l - r
        ZEN.CODEC.result = { name = result,
							 encoding = 'number',
							 luatype = 'number',
							 zentype = 'element' }
end)

When("create the result of '' * ''", function(left,right)
	have(left)
	have(right)
	empty'result'
    local l = tonumber(ACK[left])
        ZEN.assert(l, "Invalid number in element: "..left)
        local r = tonumber(ACK[right])
        ZEN.assert(r, "Invalid number in element: "..right)
        ACK.result = l * r
        ZEN.CODEC.result = { name = result,
							 encoding = 'number',
							 luatype = 'number',
							 zentype = 'element' }
end)

When("create the result of '' / ''", function(left,right)
	have(left)
	have(right)
	empty'result'
        local l = tonumber(ACK[left])
        ZEN.assert(l, "Invalid number in element: "..left)
        local r = tonumber(ACK[right])
        ZEN.assert(r, "Invalid number in element: "..right)
        ACK.result = l / r
        ZEN.CODEC.result = { name = result,
							 encoding = 'number',
							 luatype = 'number',
							 zentype = 'element' }
end)

When("create the result of '' % ''", function(left,right)
	have(left)
	have(right)
	empty'result'
        local l = tonumber(ACK[left])
        ZEN.assert(l, "Invalid number in element: "..left)
        local r = tonumber(ACK[right])
        ZEN.assert(r, "Invalid number in element: "..right)
        ACK.result = l % r
        ZEN.CODEC.result = { name = result,
							 encoding = 'number',
							 luatype = 'number',
							 zentype = 'element' }
end)

-- TODO:
-- When("set '' as '' with ''", function(dest, format, content) end)
-- When("append '' as '' to ''", function(content, format, dest) end)
-- When("write '' as '' in ''", function(content, dest) end)
-- implicit conversion as string

