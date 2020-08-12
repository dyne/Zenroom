-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2018-2020 Dyne.org foundation
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


--- WHEN

When("append '' to ''", function(src, dest, format)
		local val = ACK[src]
		ZEN.assert(val, "Cannot append a non existing variable: "..src)
		local dst = ACK[dest]
		ZEN.assert(dst, "Cannot append to non existing destination: "..dest)
		ACK[dest] = dst .. val
end)

-- simplified exception for I write: import encoding from_string ...
When("write string '' in ''", function(content, dest)
		ZEN.assert(not ACK[dest], "Cannot overwrite existing value: "..dest)
		ACK[dest] = O.from_string(content)
		ZEN.CODEC[dest] = { name = dest,
							encoding = 'string',
							luatype = 'string',
							zentype = 'element' }

end)
-- ... and from a number
When("write number '' in ''", function(content, dest)
		ZEN.assert(not ACK[dest], "Cannot overwrite existing value: "..dest)
		-- TODO: detect number base 10
		ACK[dest] = tonumber(content, 10)
		ZEN.CODEC[dest] = { name = dest,
							encoding = 'number',
							luatype = 'number',
							zentype = 'element' }
end)

When("set '' to '' as ''", function(dest, content, format)
		ZEN.assert(not ACK[dest], "Cannot overwrite existing value: "..dest)
		local guess = input_encoding(format)
		guess.raw = content
		ACK[dest] = operate_conversion(guess)
		ZEN.CODEC[dest] = { name = dest,
							encoding = 'format',
							luatype = 'string',
							zentype = 'element' }

end)

When("create the random ''", function(dest)
		ZEN.assert(not ACK[dest], "Cannot overwrite existing value: "..dest)
		ACK[dest] = OCTET.random(64) -- TODO: right now hardcoded 256 bit random secrets
end)

-- generic comparison using overloaded __eq on any value
When("verify '' is equal to ''", function(l,r)
		local tabeq = false
		if luatype(ACK[l]) == 'table' then
		   ZEN.assert(luatype(ACK[r]) == 'table',
					  "Cannot verify equality: "..l.." is a table, "..r.." is not")
		   tabeq = true
		end
		if luatype(ACK[r]) == 'table' then
		   ZEN.assert(luatype(ACK[l]) == 'table',
					  "Cannot verify equality: "..r.." is a table, "..l.." is not")
		   tabeq = true
		end
		if tabeq then -- use CBOR encoding and compare strings: there
					  -- may be faster ways, but this is certainly the
					  -- most maintainable
		   ZEN.assert( CBOR.encode(ACK[l]) == CBOR.encode(ACK[r]),
					   "Verification failed: arrays are not equal: "..l.." == "..r)
		else
		   ZEN.assert(ACK[l] == ACK[r],
					  "Verification failed: objects are not equal: "..l.." == "..r)
		end
end)

When("verify '' is not equal to ''", function(l,r)
	local tabeq = false
	if luatype(ACK[l]) == 'table' then
	   ZEN.assert(luatype(ACK[r]) == 'table',
				  "Cannot verify equality: "..l.." is a table, "..r.." is not")
	   tabeq = true
	end
	if luatype(ACK[r]) == 'table' then
	   ZEN.assert(luatype(ACK[l]) == 'table',
				  "Cannot verify equality: "..r.." is a table, "..l.." is not")
	   tabeq = true
	end
	if tabeq then -- use CBOR encoding and compare strings: there
				  -- may be faster ways, but this is certainly the
				  -- most maintainable
	   ZEN.assert( CBOR.encode(ACK[l]) ~= CBOR.encode(ACK[r]),
				   "Verification failed: arrays are equal: "..l.." == "..r)
	else
	   ZEN.assert(ACK[l] ~= ACK[r],
				  "Verification failed: objects are equal: "..l.." == "..r)
	end
end)

-- numericals
When("set '' to '' base ''", function(dest, content, base)
		ZEN.assert(not ACK[dest], "Cannot overwrite existing value: "..dest)
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

-- check a tuple of numbers before comparison, convert from octet if necessary
local function numcheck(left, right)
   local al, ar
   ZEN.assert(left, "numcheck left object not found")
   if type(left) == "zenroom.octet" then al = BIG.new(left):integer()
   else al = left end
   local l = tonumber(al)
   ZEN.assert(l, "Invalid numcheck left argument: "..type(left))

   ZEN.assert(right, "numcheck right object not found")
   if type(right) == "zenroom.octet" then ar = BIG.new(right):integer()
   else ar = right end
   local r = tonumber(ar)
   ZEN.assert(r, "Invalid numerical in right argument: "..type(right))
   return l, r
end
When("number '' is less than ''", function(left, right)
		local l, r = numcheck(ACK[left], ACK[right])
		ZEN.assert(l < r, "Failed comparison: "..l.." is not less than "..r)
end)
When("number '' is less or equal than ''", function(left, right)
		local l, r = numcheck(ACK[left], ACK[right])
		ZEN.assert(l <= r, "Failed comparison: "..l.." is not less or equal than "..r)
end)
When("number '' is more than ''", function(left, right)
		local l, r = numcheck(ACK[left], ACK[right])
		ZEN.assert(l > r, "Failed comparison: "..l.." is not more than "..r)
end)
When("number '' is more or equal than ''", function(left, right)
		local l, r = numcheck(ACK[left], ACK[right])
		ZEN.assert(l >= r, "Failed comparison: "..l.." is not more or equal than "..r)
end)

When("rename the '' to ''", function(old,new)
		ZEN.assert(ACK[old], "Object not found: "..old)
		ACK[new] = ACK[old]
		ACK[old] = nil
		ZEN.CODEC[new] = ZEN.CODEC[old]
		ZEN.CODEC[old] = nil
end)

When("split the rightmost '' bytes of ''", function(len, src)
		local s = tonumber(len)
		ZEN.assert(s, "Invalid number arg #1: "..type(len))
		ZEN.assert(ACK[src], "Element not found: "..src)
		ZEN.assert(not ACK.rightmost, "Cannot overwrite existing value: ".."rightmost")
		local l,r = OCTET.chop(ACK[src],s)
		ACK.rightmost = r
		ACK[src] = l
		ZEN.CODEC.rightmost = ZEN.CODEC[src]
end)

When("split the leftmost '' bytes of ''", function(len, src)
		local s = tonumber(len)
		ZEN.assert(s, "Invalid number arg #1: "..type(len))
		ZEN.assert(ACK[src], "Element not found: "..src)
		ZEN.assert(not ACK.leftmost, "Cannot overwrite existing value: ".."leftmost")
		local l,r = OCTET.chop(ACK[src],s)
		ACK.leftmost = l
		ACK[src] = r
		ZEN.CODEC.leftmost = ZEN.CODEC[src]
end)

-- TODO:
-- When("set '' as '' with ''", function(dest, format, content) end)
-- When("append '' as '' to ''", function(content, format, dest) end)
-- When("write '' as '' in ''", function(content, dest) end)
-- implicit conversion as string
