--[[
  This file is part of Lua-FaCES (https://github.com/pakozm/lua-faces)
  This file is part of Lua-Tuple (https://github.com/pakozm/lua-tuple)
  This file is part of Lua-MapReduce (https://github.com/pakozm/lua-mapreduce)
  
  Copyright 2014, Francisco Zamora-Martinez
  
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
  
  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.
  
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
  IN THE SOFTWARE.
]]

-- Linear implementation of in-mutable and interned tuples for Lua. It is linear
-- because tuples are stored into a linear table. A different approach would be
-- store tuples into an inverted prefix tree (trie). Major difference between
-- both approaches is that linear implementation needs more memory but has
-- better indexing time, while prefix tree implementation needs less memory but
-- has worst indexing time.

local tuple = {
  _VERSION = "0.1",
  _NAME = "tuple",
}

if _VERSION ~= "Lua 5.3" then
  -- the following hack is needed to allow unpack over tuples
  local table = require "table"
  local function table_unpack(t,i,n)
    i = i or 1
    n = n or #t
    if i <= n then
      return t[i], table_unpack(t, i + 1, n)
    end
  end
  table.unpack = table_unpack
  unpack = table_unpack
end

-- libraries import
local assert = assert
local getmetatable = getmetatable
local ipairs = ipairs
local pairs = pairs
local select = select
local tostring = tostring
local type = type
local bit32_band = bit32.band
local bit32_lshift = bit32.lshift
local bit32_rshift = bit32.rshift
local bit32_bxor = bit32.bxor
local math_max = math.max
local string_byte = string.byte
local string_format = string.format
local string_sub = string.sub
local table_concat = table.concat
local table_pack = table.pack

-- constants
local BYTE_MASK = 0x000000FF
local WORD_MASK = 0xFFFFFFFF
local MAX_NUMBER = 2^32
local MAX_BUCKET_HOLES_RATIO = 100
local NUM_BUCKETS = 2^18
local WEAK_MT = { __mode="v" }

-- the list of tuples is a hash table with a maximum of NUM_BUCKETS
local list_of_tuples = {}
-- a table with metadata of tuples, indexed by tuples reference
local tuples_metadata = setmetatable({}, { __mode="k" })

-- iterate over all chars of a string
local function char_iterator(data,j)
  j=j+1
  if j < #data then return j,string.byte(data:sub(j,j)) end
end

-- converts a number into a binary string, for hash computation purposes
local function number_iterator(data,j)
   local d = data
   if data < 1 then d = data * 10 end
   if j < 4 then
	  local v = bit32_band(bit32_rshift(d,j*8),BYTE_MASK)
	  return j+1,v
   end
end

-- forward declaration
local compute_hash
-- iterates over all the bytes of a value
local function iterate(data)
  local tt = type(data)
  if tt == "string" then
    return char_iterator,data,0
  elseif tt == "number" then
    assert(data < MAX_NUMBER, "Only valid for 32 bit numbers")
    return number_iterator,data,0
  elseif tt == "table" then
    return iterate(compute_hash(data))
  elseif tt == "nil" then
    return function() end
  else
    local str = assert(tostring(data),
		       "Needs an array with numbers, tables or strings")
    return iterate(str)
  end
end

-- computes the hash of a given tuple candidate
compute_hash = function(t)
  local h = 0
  for i=1,#t do
    local v = t[i]
    -- hash computation for every byte number in iterator over v
    for j,c in iterate(v) do
      h = h + c
      h = h + bit32_lshift(h,10)
      h = bit32_bxor(h,  bit32_rshift(h,6))
      -- compute hash modules 2^32
      h = bit32_band(h, WORD_MASK)
    end
  end
  h = h + bit32_rshift(h,3)
  h = bit32_bxor(h, bit32_lshift(h,11))
  h = h + bit32_lshift(h,15)
  -- compute hash modules 2^32
  h = bit32_band(h, WORD_MASK)
  return h
end

-- tuple instances has this metatable
local tuple_instance_mt = {
  -- disallow to change metatable
  __metatable = false,
  -- avoid to insert new elements
  __newindex = function(self) error("Unable to modify a tuple") end,
  -- concatenates two tuples or a tuple with a number, string or another table
  __concat = function(a,b)
    if type(a) ~= "table" then a,b=b,a end
    local aux = {}
    for i=1,#a do aux[#aux+1] = a[i] end
    if type(b) == "table" then
      for i=1,#b do aux[#aux+1] = b[i] end
    else
      aux[#aux+1] = b
    end
    return tuple(aux)
  end,
}

-- functions for accessing tuple metadata
local unwrap = function(self) return tuples_metadata[self][1] end
local len = function(self) return tuples_metadata[self][2] end
local hash = function(self) return tuples_metadata[self][3] end
--
local proxy_metatable = {
  __metatable = "is_tuple",
  __index = function(self,k) return unwrap(self)[k] end,
  __newindex = function(self) error("Tuples are in-mutable data") end,
  __len = function(self) return len(self) end,
  -- convert it to a string like: tuple{ a, b, ... }
  __tostring = function(self)
    local t = unwrap(self)
    local result = {}
    for i=1,#self do
      local v = t[i]
      if type(v) == "string" then v = string_format("%q",v) end
      result[#result+1] = tostring(v)
    end
    return table_concat({"tuple{",table_concat(result, ", "),"}"}, " ")
  end,
  __lt = function(self,other)
    local t = unwrap(self)
    if type(other) ~= "table" then return false
    elseif #t < #other then return true
    elseif #t > #other then return false
    elseif t == other then return false
    else
      for i=1,#t do
	if t[i] > other[i] then return false end
      end
      return true
    end
  end,
  __le =  function(self,other)
    local t = unwrap(self)
    -- equality is comparing references (tuples are in-mutable and interned)
    if self == other then return true end
    return self < other
  end,
  __pairs = function(self) return pairs(unwrap(self)) end,
  __ipairs = function(self) return ipairs(unwrap(self)) end,
  __concat = function(self,other) return unwrap(self) .. other end,
  __gc = function(self)
    local h = hash(self)
    if h then
      local p = h % NUM_BUCKETS
      if list_of_tuples[p] and not next(list_of_tuples[p]) then
	list_of_tuples[p] = nil
      end
    end
  end,
  __mode = "v",
}

-- returns a wrapper table (proxy) which shades the data table, allowing
-- in-mutability in Lua, it receives the table data and the number of elements
local function proxy(tpl,n)
  setmetatable(tpl, tuple_instance_mt)
  local ref = setmetatable({}, proxy_metatable)
  -- the proxy table has an in-mutable metatable, and stores in tuples_metadata
  -- the real tuple data and the number of elements
  tuples_metadata[ref] = { tpl, n }
  return ref
end

-- builds a candidate tuple given a table, recursively converting tables in new
-- tuples
local function tuple_constructor(t)
  -- take n from the variadic args or from t length
  local n = t.n or #t
  local new_tuple = { }
  for i=1,n do
    local v = t[i]
    assert(type(i) == "number" and i>0, "Needs integer keys > 0")
    if type(v) == "table" then
      -- recursively converts tables in new tuples
      new_tuple[i] = tuple(v)
    else
      -- copies the value
      new_tuple[i] = v
    end
  end
  -- returns a proxy to the new_tuple table with #t length
  return proxy(new_tuple,n)
end

-- metatable of tuple "class" table
local tuple_mt = {
  -- tuple constructor doesn't allow table loops
  __call = function(self, ...)
    local n = select('#', ...)
    local t = table_pack(...) assert(#t == n) if #t == 1 then t = t[1] end
    if type(t) ~= "table" then
      -- non-table elements are unpacked when only one is given
      return t
    else
      -- check if the given table is a tuple, if it is the case, just return it
      local mt = getmetatable(t) if mt=="is_tuple" then return t end
      -- create a new tuple candidate
      local new_tuple = tuple_constructor(t)
      local h = compute_hash(new_tuple)
      local p = h % NUM_BUCKETS
      local bucket = (list_of_tuples[p] or setmetatable({}, WEAK_MT))
      list_of_tuples[p] = bucket
      -- Count the number of elements in the bucket and the maximum non-nil key.
      -- In case the relation between this two values was greater than
      -- MAX_BUCKET_HOLES_RATIO, the bucket will be rearranged to remove all nil
      -- holes.
      local max,n = 0,0
      for i,vi in pairs(bucket) do
	local equals = true
	-- check equality by comparing all the elements one-by-one
        if #vi == #new_tuple then
          for j=1,#vi do
            local vj = vi[j]
            if vj ~= new_tuple[j] then equals=false break end
          end
        else
          equals = false
        end
	-- BREAKS the execution flow in case the tuple exists in the bucket
	if equals == true then return vi end
	max = math_max(max,i)
	n = n+1
      end
      -- rearrange the bucket when the ratio achieves the threshold
      if max/n > MAX_BUCKET_HOLES_RATIO then
	local new_bucket = {}
	for i,vi in pairs(bucket) do new_bucket[#new_bucket+1] = vi end
	list_of_tuples[p], bucket = new_bucket, new_bucket
	max = #bucket
	collectgarbage("collect")
      end
      bucket[max+1] = new_tuple
      -- take note of the hash number into __metatable array, position 4
      tuples_metadata[new_tuple][3] = h
      return new_tuple
    end
  end,
}
setmetatable(tuple, tuple_mt)

----------------------------------------------------------------------------
------------------------------ UNIT TEST -----------------------------------
----------------------------------------------------------------------------

tuple.utest = function()
  local a = tuple(2,{4,5},"a")
  local b = tuple(4,5)
  local c = tuple(2,a[2],"a")
  assert(a == c)
  assert(b == a[2])
  assert(b == c[2])
  a,b,c = nil,nil,nil
  collectgarbage("collect")
  --
  local aux = {} for i=1,10000 do aux[tuple(i,i)] = i end
  assert(tuple.stats() == 10000)
  collectgarbage("collect")
  assert(tuple.stats() == 10000)
  aux = nil
  collectgarbage("collect")
  assert(tuple.stats() == 0)
  --
  assert(not getmetatable(tuple(1)))
end

-- returns the number of tuples "alive", the number of used buckets, and the
-- loading factor of the hash table
tuple.stats = function()
  local num_buckets = 0
  local size = 0
  for k1,v1 in pairs(list_of_tuples) do
    num_buckets = num_buckets + 1
    for k2,v2 in pairs(v1) do size=size+1 end
  end
  if num_buckets == 0 then num_buckets = 1 end
  local msz = 0
  for _,v in pairs(tuples_metadata) do msz = msz + 1 end
  return size,num_buckets,size/NUM_BUCKETS,msz
end

return tuple
