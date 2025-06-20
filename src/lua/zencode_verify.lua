--[[
--This file is part of zenroom
--
--Copyright (C) 2018-2025 Dyne.org foundation
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
      or (type(left) == 'zenroom.big' and type(right) == 'zenroom.big')
      or (type(left) == 'zenroom.time' and type(right) == 'zenroom.time') then
    return (left == right)
  elseif luatype(left) == 'table' and luatype(right) == 'table' then
     if(#left ~= #right) then return false end -- optimization
     return (zencode_serialize(left) == zencode_serialize(right))
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
      or (type(left) == 'zenroom.big' and type(right) == 'zenroom.big')
      or (type(left) == 'zenroom.time' and type(right) == 'zenroom.time') then
    return not (left == right)
  elseif luatype(left) == 'table' and luatype(right) == 'table' then
     if(#left ~= #right) then return true end -- optimization
     return (zencode_serialize(left) ~= zencode_serialize(right))
  elseif iszen(type(left)) and iszen(type(right)) then
     return (left:octet() ~= right:octet())
  else
     error("Comparison between incompatible types: "
	   ..type(left).." and "..type(right), 2)
  end
end

IfWhen("verify '' is equal to ''",function(l, r)
    local left = have(l)
    local right = have(r)
    zencode_assert(
      _eq(left, right),
      'Verification fail: elements are not equal: ' .. l .. ' == ' .. r
    )
end)

IfWhen("verify '' is not equal to ''",function(l, r)
    local left = have(l)
    local right = have(r)
    zencode_assert(
      _neq(left, right),
      'Verification fail: elements are equal: ' .. l .. ' == ' .. r
    )
end)

-- comparison inside dictionary
IfWhen("verify '' is equal to '' in ''",function(l, tr, tt)
    local left = have(l)
    local tab = have(tt)
    local right = tab[tr]
    zencode_assert(
      _eq(left, right),
      'Verification fail: elements are not equal: ' ..
        l .. ' == ' .. tt .. '.' .. tr
    )
end)

IfWhen("verify '' is not equal to '' in ''",function(l, tr, tt)
    local left = have(l)
    local tab = have(tt)
    local right = tab[tr]
    zencode_assert(
      _neq(left, right),
      'Verification fail: elements are equal: ' ..
        l .. ' == ' .. tt .. '.' .. tr
    )
end)

-- check a tuple of numbers before comparison, convert to BIG or number, and then compare
local function numcheck(l, r, op)
    local operators = {
        ["<"] = function(x, y) return x<y end,
        ["<="] = function(x, y) return x<=y end,
        [">"] = function(x, y) return x>y end,
        [">="] = function(x, y) return x>=y end
    }
    local left = have(l)
    local right = have(r)
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
    elseif tl == 'zenroom.big' or tl == 'number' or tl == 'zenroom.float' or tl == 'zenroom.time' then
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
    elseif tr == 'zenroom.big' or tr == 'number' or tr == 'zenroom.float' or tr == 'zenroom.time' then
        ar = right
    else
        ar = right:octet()
    end
    zencode_assert(operators[op](al, ar), 'Comparison fail: ' .. l .. op .. r)
end

IfWhen("verify number '' is less than ''", function(left, right)
    numcheck(left, right, "<")
end)

IfWhen("verify number '' is less or equal than ''", function(left, right)
    numcheck(left, right, "<=")
end)

IfWhen("verify number '' is more than ''", function(left, right)
    numcheck(left, right, ">")
end)

IfWhen("verify number '' is more or equal than ''", function(left, right)
    numcheck(left, right, ">=")
end)

local function _check_compare_length(obj_name, num_name)
    local obj, obj_codec = have(obj_name)
    local obj_ztype = obj_codec.zentype
    local num, num_codec = have(num_name)
    local num_enc = num_codec.encoding
    if not zencode_assert(obj_ztype == "a" or obj_ztype == "d" or
        (obj_ztype == "e" and obj_codec.encoding == "string"),
        "Can not compute the length for type "..obj_ztype) then return end
    if not zencode_assert(num_enc == "integer" or num_enc == "float",
        "Can not compare the length of "..obj_name.." with number of type "..num_enc) then return end
    local obj_len_enc = { ["integer"] = BIG.new, ["float"] = F.new }
    local obj_len
    if obj_ztype == "a" or obj_ztype == "e" then
        obj_len = obj_len_enc[num_enc](#obj)
    else
        obj_len = obj_len_enc[num_enc](0)
        local one = obj_len_enc[num_enc](1)
        for _ in pairs(obj) do
            obj_len = obj_len + one
        end
    end
    return obj_len, num
end

IfWhen("verify size of '' is less than ''", function(obj_name, num_name)
    local l, r = _check_compare_length(obj_name, num_name)
    zencode_assert(l < r,
        "Comparison fail: size of "..obj_name.." is not less than "..num_name)
end)

IfWhen("verify size of '' is less or equal than ''", function(obj_name, num_name)
    local l, r = _check_compare_length(obj_name, num_name)
    zencode_assert(l <= r,
        "Comparison fail: size of "..obj_name.." is not less or equal than "..num_name)
end)

IfWhen("verify size of '' is more than ''", function(obj_name, num_name)
    local l, r = _check_compare_length(obj_name, num_name)
    zencode_assert(r < l,
        "Comparison fail: size of "..obj_name.." is not more than "..num_name)
end)

IfWhen("verify size of '' is more or equal than ''", function(obj_name, num_name)
    local l, r = _check_compare_length(obj_name, num_name)
    zencode_assert(r <= l,
        "Comparison fail: size of "..obj_name.." is not more or equal than "..num_name)
end)

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

IfWhen("verify '' is a email",function(name)
    local A = ACK[name]
    if not zencode_assert(A, 'Object not found: ' .. name) then return end
    local res, err = validemail(O.to_string(A))
    zencode_assert(res, err)
end)

IfWhen("verify '' contains a list of emails",function(name)
    local A = ACK[name]
    if not zencode_assert(A, 'Object not found: ' .. name) then return end
    if not zencode_assert(
      luatype(A) == 'table',
      'Object is not a container: ' .. name
    ) then return end
    local res, err
    for k, v in pairs(A) do
      res, err = validemail(O.to_string(v))
      if not zencode_assert(res, (err or 'OK') .. ' on email: ' .. O.to_string(v)) then return end
    end
end)

IfWhen("verify elements in '' are equal", function(obj_name)
    local obj = have(obj_name)
    local first = nil
    local first_idx = nil
    for k,v in pairs(obj) do
        if first == nil then
            first = v
            first_idx = k
        else
            if not zencode_assert(_eq(first, v),
                "Verification failed: the elements in position "
                .. k .. " and " .. first_idx
                .. "are not equal") then return end
        end
    end
end)

IfWhen("verify elements in '' are not equal", function(obj_name)
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
    zencode_assert(false, "Verification failed: all elements are equal")
end)

-- if start = nil then will check if
-- the string ends with the substring
local function start_with_from(str, sub, start)
   local str_oct = have(str)
   local sub_oct = ACK[sub]
   local str_codec = CODEC[str]
   local sub_codec = {}
   if sub_oct then
      sub_codec = CODEC[sub]
   else
      sub_oct = O.from_string(sub)
      sub_codec.encoding = 'string'
      sub_codec.zentype = 'e'
   end
   if not zencode_assert(str_codec.zentype == 'e' and
	      sub_codec.zentype == 'e',
	      "Verification failed: one or both inputs are not elements") then return end
   if not zencode_assert(str_codec.encoding == 'string' and
	      sub_codec.encoding == 'string',
	      "Verification failed: one or both inputs are not strings") then return end
   if not zencode_assert(#sub_oct <= #str_oct,
	      "Verification failed: substring is longer than the string") then return end
   local s = str_oct:string()
   local b = sub_oct:string()
   start = start or (#s-#b+1)
   zencode_assert(s:find(b, start, true) == start,
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
