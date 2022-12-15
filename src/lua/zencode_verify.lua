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
--on Sunday, 11th July 2021
--]]
-- generic comparison using overloaded __eq on values
local function _eq(left, right)
  if (luatype(left) == 'number' and luatype(right) == 'number')
      or (type(left) == 'zenroom.float' and type(right) == 'zenroom.float')
      or (type(left) == 'zenroom.big' and type(right) == 'zenroom.big') then
    return (left == right)
  elseif luatype(left) == 'table' and luatype(right) == 'table' then
     if(#left ~= #right) then return false end -- optimization
     return (ZEN.serialize(left) == ZEN.serialize(right))
  elseif iszen(type(left)) and iszen(type(right)) then
     return (left:octet() == right:octet())
  else
     error("Comparison between incompatible types: "
	   ..type(left).." and "..type(right), 2)
  end
end
local function _neq(left, right)
  if luatype(left) == 'number' and luatype(right) == 'number' then
    return (left ~= right)
  elseif (type(left) == 'zenroom.float' and type(right) == 'zenroom.float')
      or (type(left) == 'zenroom.big' and type(right) == 'zenroom.big') then
    return not (left == right)
  elseif luatype(left) == 'table' and luatype(right) == 'table' then
     if(#left ~= #right) then return true end -- optimization
     return (ZEN.serialize(left) ~= ZEN.serialize(right))
  elseif iszen(type(left)) and iszen(type(right)) then
     return (left:octet() ~= right:octet())
  else
     error("Comparison between incompatible types: "
	   ..type(left).." and "..type(right), 2)
  end
end

IfWhen(
  "verify '' is equal to ''",
  function(l, r)
    local left = have(l)
    local right = have(r)
    ZEN.assert(
      _eq(left, right),
      'Verification fail: elements are not equal: ' .. l .. ' == ' .. r
    )
  end
)

IfWhen(
  "verify '' is not equal to ''",
  function(l, r)
    local left = have(l)
    local right = have(r)
    ZEN.assert(
      _neq(left, right),
      'Verification fail: elements are equal: ' .. l .. ' == ' .. r
    )
  end
)

-- comparison inside dictionary
IfWhen(
  "verify '' is equal to '' in ''",
  function(l, tr, tt)
    local left = have(l)
    local tab = have(tt)
    local right = tab[tr]
    ZEN.assert(
      _eq(left, right),
      'Verification fail: elements are not equal: ' ..
        l .. ' == ' .. tt .. '.' .. tr
    )
  end
)

IfWhen(
  "verify '' is not equal to '' in ''",
  function(l, tr, tt)
    local left = have(l)
    local tab = have(tt)
    local right = tab[tr]
    ZEN.assert(
      _neq(left, right),
      'Verification fail: elements are equal: ' ..
        l .. ' == ' .. tt .. '.' .. tr
    )
  end
)

-- check a tuple of numbers before comparison, convert to BIG or number
local function numcheck(left, right)
  local al, ar
  --
  if left == nil then
    error('1st argument of numerical comparison is nil', 2)
  end
  local tl = type(left)
  if not iszen(tl) then
    if tl ~= 'number' then
      error('1st argument invalid numeric type: ' .. tl, 2)
    end
  end
  if tl == 'zenroom.octet' then
    al = BIG.new(left)
  elseif tl == 'zenroom.big' or tl == 'number' or tl == 'zenroom.float' then
    al = left
  else
    al = left:octet()
  end
  --
  if right == nil then
    error('2nd argument of numerical comparison is nil', 2)
  end
  local tr = type(right)
  if not iszen(tr) then
    if tr ~= 'number' then
      error('2nd argument invalid numeric type: ' .. tr, 2)
    end
  end
  if tr == 'zenroom.octet' then
    ar = BIG.new(right)
  elseif tr == 'zenroom.big' or tr == 'number' or tr == 'zenroom.float' then
    ar = right
  else
    ar = right:octet()
  end
  return al, ar
end

IfWhen(
  "number '' is less than ''",
  function(left, right)
    local l, r = numcheck(ACK[left], ACK[right])
    ZEN.assert(
      l < r,
      'Comparison fail: ' .. left .. ' is not less than ' .. right
    )
  end
)
IfWhen(
  "number '' is less or equal than ''",
  function(left, right)
    local l, r = numcheck(ACK[left], ACK[right])
    ZEN.assert(
      l <= r,
      'Comparison fail: ' ..
        left .. ' is not less or equal than ' .. right
    )
  end
)
IfWhen(
  "number '' is more than ''",
  function(left, right)
    local l, r = numcheck(ACK[left], ACK[right])
    ZEN.assert(
      r < l,
      'Comparison fail: ' .. left .. ' is not more than ' .. right
    )
  end
)
IfWhen(
  "number '' is more or equal than ''",
  function(left, right)
    local l, r = numcheck(ACK[left], ACK[right])
    ZEN.assert(
      r <= l,
      'Comparison fail: ' ..
        left .. ' is not more or equal than ' .. right
    )
  end
)

-- TODO: substitute with RFC2047 compliant code (take from jaromail)
local function validemail(str)
  if str == nil then
    return nil
  end
  if (type(str) ~= 'string') then
    error('Expected string')
    return nil
  end
  local lastAt = str:find('[^%@]+$')
  local localPart = str:sub(1, (lastAt - 2)) -- Returns the substring before '@' symbol
  local domainPart = str:sub(lastAt, #str) -- Returns the substring after '@' symbol
  -- we werent able to split the email properly
  if localPart == nil then
    return nil, 'Local name is invalid'
  end

  if domainPart == nil then
    return nil, 'Domain is invalid'
  end
  -- local part is maxed at 64 characters
  if #localPart > 64 then
    return nil, 'Local name must be less than 64 characters'
  end
  -- domains are maxed at 253 characters
  if #domainPart > 253 then
    return nil, 'Domain must be less than 253 characters'
  end
  -- somthing is wrong
  if lastAt >= 65 then
    return nil, 'Invalid @ symbol usage'
  end
  if string.sub(domainPart, 1, 1) == '.' then
    return false, 'first character in domainPart is a dot'
  end
  -- quotes are only allowed at the beginning of a the local name
  local quotes = localPart:find('["]')
  if type(quotes) == 'number' and quotes > 1 then
    return nil, 'Invalid usage of quotes'
  end
  -- no @ symbols allowed outside quotes
  if localPart:find('%@+') and quotes == nil then
    return nil, 'Invalid @ symbol usage in local part'
  end
  -- no dot found in domain name
  if not domainPart:find('%.') then
    return nil, 'No TLD found in domain'
  end
  -- only 1 period in succession allowed
  if domainPart:find('%.%.') then
    return nil, 'Too many periods in domain'
  end
  if localPart:find('%.%.') then
    return nil, 'Too many periods in local part'
  end
  -- just a general match
  if not str:match('[%w]*[%p]*%@+[%w]*[%.]?[%w]*') then
    return nil, 'Email pattern test failed'
  end
  if (lastAt == nil) then
    lastAt = #str + 1
  end

  -- all our tests passed, so we are ok
  return true
end

IfWhen(
  "verify '' is a email",
  function(name)
    local A = ACK[name]
    ZEN.assert(A, 'Object not found: ' .. name)
    local res, err = validemail(O.to_string(A))
    ZEN.assert(res, err)
  end
)

IfWhen(
  "verify '' contains a list of emails",
  function(name)
    local A = ACK[name]
    ZEN.assert(A, 'Object not found: ' .. name)
    ZEN.assert(
      luatype(A) == 'table',
      'Object is not a container: ' .. name
    )
    local res, err
    for k, v in pairs(A) do
      res, err = validemail(O.to_string(v))
      ZEN.assert(res, (err or 'OK') .. ' on email: ' .. O.to_string(v))
    end
  end
)

IfWhen("the elements in '' are equal", function(obj_name)
       local obj = have(obj_name)
       local all_equal = true
       local first = nil
       local first_idx = nil
       for k,v in pairs(obj) do
             if first == nil then
                     first = v
                     first_idx = k
            else
                     ZEN.assert(_eq(first, v),
                         "Verification failed: the elements in position "
                         .. k .. " and " .. first_idx
                         .. "are not equal")
            end
       end
end)

IfWhen("the elements in '' are not equal", function(obj_name)
       local obj = have(obj_name)
       local first = nil
       local first_idx = nil
       for k,v in pairs(obj) do
             if first == nil then
                     first = v
                     first_idx = k
            else
                    if _neq(first, v) then
                            -- at least two elements are different
                            return true
                    end
            end
       end
       ZEN.assert(false, "Verification failed: all elements are equal")
end)

-- if start = nil then will check if
-- the string ends with the substring
local function start_with_from(str, sub, start)
   local str_oct = have(str)
   local sub_oct = ACK[sub]
   local str_codec = ZEN.CODEC[str]
   local sub_codec = {}
   if sub_oct then
      sub_codec = ZEN.CODEC[sub]
   else
      sub_oct = O.from_string(sub)
      sub_codec.encoding = 'string'
      sub_codec.zentype = 'element'
   end
   ZEN.assert(str_codec.zentype == 'element' and
	      sub_codec.zentype == 'element',
	      "Verification failed: one or both inputs are not elements")
   ZEN.assert(str_codec.encoding == 'string' and
	      sub_codec.encoding == 'string',
	      "Verification failed: one or both inputs are not strings")
   ZEN.assert(#sub_oct <= #str_oct,
	      "Verification failed: substring is longer than the string")
   local s = str_oct:string()
   local b = sub_oct:string()
   start = start or (#s-#b+1)
   ZEN.assert(s:find(b, start, true) == start,
	      "Verification failed: substring not found at position "..start)
end

IfWhen("verify '' starts with ''", function(str, sub)
	  start_with_from(str, sub, 1)
end)

IfWhen("verify '' has prefix ''", function(str, sub)
	  start_with_from(str, sub, 1)
end)

IfWhen("verify '' ends with ''", function(str, sub)
	  start_with_from(str, sub, nil)
end)

IfWhen("verify '' has suffix ''", function(str, sub)
	  start_with_from(str, sub, nil)
end)
