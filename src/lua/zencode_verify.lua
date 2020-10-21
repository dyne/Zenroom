-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2018-2020 Dyne.org foundation
-- designed, written and maintained by Denis Roio <jaromil@dyne.org>
-- includes public domain code by James Doyle (validemail)
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
		   ZEN.assert( ZEN.serialize(ACK[l]) == ZEN.serialize(ACK[r]),
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

-- TODO: substitute with RFC2047 compliant code (take from jaromail)
local function validemail(str)
  if str == nil then return nil end
  if (type(str) ~= 'string') then
    error("Expected string")
    return nil
  end
  local lastAt = str:find("[^%@]+$")
  local localPart = str:sub(1, (lastAt - 2)) -- Returns the substring before '@' symbol
  local domainPart = str:sub(lastAt, #str) -- Returns the substring after '@' symbol
  -- we werent able to split the email properly
  if localPart == nil then
    return nil, "Local name is invalid"
  end

  if domainPart == nil then
    return nil, "Domain is invalid"
  end
  -- local part is maxed at 64 characters
  if #localPart > 64 then
    return nil, "Local name must be less than 64 characters"
  end
  -- domains are maxed at 253 characters
  if #domainPart > 253 then
    return nil, "Domain must be less than 253 characters"
  end
  -- somthing is wrong
  if lastAt >= 65 then
    return nil, "Invalid @ symbol usage"
  end
  if string.sub(domainPart, 1, 1) == "." then
	 return false, "first character in domainPart is a dot"
  end
  -- quotes are only allowed at the beginning of a the local name
  local quotes = localPart:find("[\"]")
  if type(quotes) == 'number' and quotes > 1 then
    return nil, "Invalid usage of quotes"
  end
  -- no @ symbols allowed outside quotes
  if localPart:find("%@+") and quotes == nil then
    return nil, "Invalid @ symbol usage in local part"
  end
  -- no dot found in domain name
  if not domainPart:find("%.") then
    return nil, "No TLD found in domain"
  end
  -- only 1 period in succession allowed
  if domainPart:find("%.%.") then
    return nil, "Too many periods in domain"
  end
  if localPart:find("%.%.") then
    return nil, "Too many periods in local part"
  end
  -- just a general match
  if not str:match('[%w]*[%p]*%@+[%w]*[%.]?[%w]*') then
    return nil, "Email pattern test failed"
  end
  if (lastAt == nil) then lastAt = #str + 1 end

  -- all our tests passed, so we are ok
  return true
end

When("verify '' is a email", function(name)
		local A = ACK[name]
		ZEN.assert(A, "Object not found: "..name)
		local res, err = validemail(O.to_string(A))
		ZEN.assert(res, err)
end)

