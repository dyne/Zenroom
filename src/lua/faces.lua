-- Forward chaining expert system
-- fork of Lua-FaCES by Francisco Zamora-Martinez

local tuple = {
   _VERSION = "0.1",
  _NAME = "tuple",
}


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
  if j < 4 then
    local v = bit32_band(bit32_rshift(data,j*8),BYTE_MASK)
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
  return size,num_buckets,INT.new(size)/NUM_BUCKETS,msz
end


----------------------
-- STATIC FUNCTIONS --
----------------------

local faces = {}
local globals = {}
_G = setmetatable(_G, {
                    __index=function(self,k) return rawget(self,k) or globals[k] end,
                    
                    __newindex=function(self,k,v)
                      assert(not globals[k], ("Forbidden declaration of reserved global %s"):format(k))
                      rawset(self,k,v)
                    end,
})

-- inspired by Penlight string_lambda:
-- http://stevedonovan.github.io/Penlight/api/libraries/pl.utils.html#string_lambda
local lambda
do
  local memory = {}
  lambda = setmetatable({ clear = function() memory = {} end, },
    {
      __call = function(self,fstr)
        local fun = memory[fstr]
        if not fun then
          local args,code = fstr:match("^%s*|(.+)|(.+)$")
          assert(args and code, "Needs args and code sections, e.g., |args|code")
          local fun_src = ("return function(%s) return %s end"):format(args,code)
          fun = assert(load(fun_src))()
          memory[fstr] = fun
        end
        return fun      
      end,
                       })
end

-- transform a user function string into a lambda function
local function lambda_transform(func_str)
  return function(vars)
    local values,keys = {},{}
    for k,v in pairs(vars) do
      values[#values+1] = v
      keys[#keys+1] = k
    end
    local code = ('|%s|%s'):format(table.concat(keys,","),func_str)
    local f = lambda(code)
    return f(table.unpack(values))
  end
end

local function get_user_func(user_func)
  -- user_func receives one argument: vars
  if type(user_func) == "string" then
    user_func = lambda_transform(user_func)
  end
  return user_func
end

globals.u = function(func_str)
  local f = get_user_func(func_str)
  return setmetatable({ __user_function__ = true },
    { __call=function(_, ...) return f(...) end })
end

-- converts to in-mutable the given table argument
local function inmutable(tbl)
  return setmetatable({}, {
      __index = function(_,k) return tbl[k] end,
      __newindex = function() error("Unable to modify an in-mutable table") end,
      __len = function() return #tbl end,
      __ipairs = function() return ipairs(tbl) end,
      __pairs = function() return pairs(tbl) end,
  })
end

-- pattern matching between a fact and the rule pattern
local function fact_match(fact, pattern)
  if #fact ~= #pattern then return false end
  local fact_str = tostring(fact):gsub('"', '')
  local pat_str = tostring(pattern):gsub("%.", "[^,]"):gsub('"', ''):
    gsub("%$%?[^%s,]+", "tuple%%b{}"):gsub("%?[^%s,]+", "[^,]*")
  -- print(fact_str, pat_str, fact_str:find(pat_str))
  assert(not pat_str:find("%?"),
         string.format("Incorrect variable name in pattern: %s",
                       tostring(pattern)))
  -- print(fact_str, pat_str, fact_str:find(pat_str))
  return fact_str:find(pat_str)
end

-- check that the fact string doesn't contain forbidden symbols
local function check_fact_strings(fact)
  for i=1,#fact do
    local tt = type(fact[i])
    if tt == "table" then
      check_fact_strings(fact[i])
    elseif tt == "string" then
      assert(not fact[i]:find("[%$%.%-%,%+%?%(%)%{%}%[%]]"),
             string.format("Forbidden use of the following symbols in fact '%s': $ . - , + ? ( ) { } [ ]",
                           tostring(tuple(fact))))
    end
  end
end

-- forward declarations
local replace_variables
local replace_user_functions
do
  local function replace(vi, vars)
    local new_v = {}
    for j,vj in ipairs(vi) do
      local tt = type(vj)
      if tt == "string" then
        local varname = vj:match("%?([^%s]+)")
        if varname then
          new_v[j] = assert(vars[varname],
                            string.format("Unable to find variable: %s", varname))
        else
          new_v[j] = vj
        end
      elseif tt == "table" then
        new_v[j] = replace(vj, vars)
      else
        new_v[j] = vj
      end
    end
    return new_v
  end

  replace_variables = function(args, vars)
    local new_args = {}
    for i,vi in ipairs(args) do
      new_args[i] = replace(vi, vars)
    end
    return new_args
  end

  replace_user_functions = function(args, vars)
    local result = {}
    for i,v in pairs(args) do
      local tt = type(v)
      if tt == "function" or tt == "table" and v.__user_function__ then
        result[i] = v(vars)
      elseif tt == "table" then
        result[i] = replace_user_functions(v, vars)
      else
        result[i] = v
      end
    end
    return result
  end
end

-- forward declaration
local assign_variables
do
  local function assign_fact_vars(vars, pat, fact, var_matches)
    for j,v in ipairs(pat) do
      local tt = type(v)
      if tt == "string" then
        local varname = v:match("%?([^%s]+)")
        if varname then
          local value = fact[j]
          if not var_matches[varname] or var_matches[varname](value) then
            if not vars[varname] then
              vars[varname] = value
            else
              if vars[varname] ~= value then return false end
            end
          else
            return false
          end
        end
      elseif tt == "table" then
        if not assign_fact_vars(vars, v, fact[j], var_matches) then
          return false
        end
      end
    end
    return true
  end

  assign_variables = function(self, vars, patterns, sequence, var_matches,
                              user_clauses, fact_vars)
    for i,pat in ipairs(patterns) do
      local fid  = sequence[i]
      local fact = self.fact_list[fid]
      if not assign_fact_vars(vars, pat, fact, var_matches) then return false end
    end
    for vname,i in pairs(fact_vars) do vars[vname] = sequence[i] end
    local inmutable_vars = inmutable(vars)
    for _,func in ipairs(user_clauses) do
      if not func(inmutable_vars) then return false end
    end
    return true
  end
end

-- returns an iterator function which enumerates all possible combinations
-- (Cartesian product) between all the given array arguments
local function enumerate(...)
  local function f(seq, tbl, ...)
    if tbl == nil and select('#', ...) == 0 then
      if #seq > 0 then coroutine.yield(tuple(seq)) end
    else
      if tbl ~= nil then
        if #seq > 0 then
          for i,v in ipairs(tbl) do
            f(seq .. tuple(v), ...)
          end
        else
          for i,v in ipairs(tbl) do
            f(tuple{v}, ...)
          end
        end
      end
    end
  end
  local args = table.pack(...)
  return coroutine.wrap(function() f({}, table.unpack(args)) end)
end

-- traverses all possible rules with all possible matches and introduces into
-- the agenda whose clause sequences which weren't entailed before and are valid
-- for the analyzed rule
local function regenerate_agenda(self)
  self.needs_regenerate_agenda = false
  local entailed = self.entailed
  local matches = self.matches
  local agenda = {}
  for rule_name,rule in pairs(self.kb_table) do
    local rule_entailements = entailed[rule_name] or {}
    local combinations = {}
    local variables = {}
    if #matches[rule_name] == #rule.patterns then
      for sequence in enumerate(table.unpack(matches[rule_name])) do
        if not rule_entailements[sequence] then
          local seq_vars = {}
          if assign_variables(self, seq_vars, rule.patterns, sequence,
                              rule.var_matches, rule.user_clauses,
                              rule.fact_vars) then
            table.insert(combinations, sequence)
            table.insert(variables, seq_vars)
          end
        end
      end
      if #combinations > 0 then
        table.insert(agenda, {
                       rule_name = rule_name,
                       salience = rule.salience,
                       combinations = combinations,
                       variables = variables,
        })
      end
    end
  end
  table.sort(agenda, function(a,b) return a.salience > b.salience end)
  self.rules_agenda = agenda
end

-- look-ups for the rule with best salience, and returns the rule name and its
-- pattern matching arguments
local function take_best_rule(self)
  if self.needs_regenerate_agenda then regenerate_agenda(self) end
  local rules_agenda = self.rules_agenda
  if #rules_agenda > 0 then
    local rule_data = rules_agenda[1]
    local args = assert(table.remove(rule_data.combinations, 1),
                        "Found empty LHS args :'(")
    local vars = assert(table.remove(rule_data.variables, 1),
                        "Found empty LHS vars :'(")
    if #rule_data.combinations == 0 then table.remove(rules_agenda, 1) end
    local rule_name = rule_data.rule_name
    return rule_name,args,vars
  end
end

-- executes the given rule name with the given pattern matching arguments
local function fire_rule(self, rule_name, args, vars)
  local rule = self.kb_table[rule_name]
  self.entailed[rule_name] = self.entailed[rule_name] or {}
  self.entailed[rule_name][args] = true
  for i,v in ipairs(args) do self.fact_entailment[v] = args end
  -- execute rule actions
  for _,action in ipairs(rule.actions) do
    action(inmutable(vars))
  end
end

-- binary search in a sorted array of numbers, where tbl is the array, v is the
-- look-up value, p is the start position (by default it is 1) and q the end
-- position (by default it is #tbl)
local function bsearch(tbl, v, p, q)
  p, q = p or 1, q or #tbl
  if p <= q then
    local n = q - p + 1
    if n < 30 then
      for i=p,q do if tbl[i] == v then return true end end
    else
      local m = math.floor((p+q)/2)
      if tbl[m] == v then
        return true
      elseif v < tbl[m] then
        return bsearch(tbl, v, p, m-1)
      else
        return bsearch(tbl, v, m+1, q)
      end
    end
  end
end

-- updates possible matches with the information given by one new fact
local function update_forward_chaining_with_assert_fact(self, fact)
  local fid     = self.fact_map[fact]
  local matches = self.matches
  for rule_name,rule in pairs(self.kb_table) do
    local rule_matches = matches[rule_name] or {}
    matches[rule_name] = rule_matches
    for i,pat in ipairs(rule.patterns) do
      if fact_match(fact, pat) then
        rule_matches[i] = rule_matches[i] or {}
        table.insert(rule_matches[i], fid)
        table.sort(rule_matches[i])
      end
    end
  end
  self.needs_regenerate_agenda = true
end

-- updates possible matches after retracting one fact
local function update_forward_chaining_with_retract_fact(self, fact)
  local fid     = self.fact_map[fact]
  local matches = self.matches
  for rule_name,rule in pairs(self.kb_table) do
    local rule_matches = matches[rule_name]
    for i,pat in ipairs(rule.patterns) do
      if rule_matches[i] then
        if bsearch(rule_matches[i], fid) then
          new_rule_matches = {}
          for j,v in ipairs(rule_matches[i]) do
            if v ~= fid then table.insert(new_rule_matches, v) end
          end
          table.sort(new_rule_matches)
          rule_matches[i] = new_rule_matches
        end
      end
    end
  end
  for _,sequence in ipairs(self.fact_entailment[fid] or {}) do
    self.entailed[sequence] = nil
  end
  self.fact_entailment[fid] = nil
  self.needs_regenerate_agenda = true
end

-- updates possible matches after introducing a new rule
local function update_forward_chaining_with_rule(self, rule_name, rule)
  local fid          = self.fact_map[fact]
  local matches      = self.matches
  local rule_matches = {}
  for i,pat in ipairs(rule.patterns) do
    for fid,fact in pairs(self.fact_list) do
      if fact_match(fact, pat) then
        rule_matches[i] = rule_matches[i] or {}
        table.insert(rule_matches[i], fid)
        table.sort(rule_matches[i])
      end
    end
  end
  matches[rule_name] = rule_matches
  self.needs_regenerate_agenda = true
end

-------------
-- METHODS --
-------------

local faces_methods = {}

-- initializes the facts database
function faces_methods:clear()
  self.needs_regenerate_agenda = false
  -- counter index
  self.fact_idx = 0
  -- global memory for data
  self.fact_map = {}
  self.fact_list = {}
  -- agenda with lists of rules and its matching preconditions, sorted by
  -- salience
  self.rules_agenda = {}
  -- list of entailed preconditions, indexed by rule name
  self.entailed = {}
  -- list of entailed sequences related with every fact id
  self.fact_entailment = {}
  -- match rules dictionary, stores:
  --   rule_name = { pos1 = { fid1, fid2, ... }, pos2 = { ... } }
  -- where pos are rule LHS which matches with indicated fact ids
  self.matches = {}
  --
  self:fassert{ "initial fact" }
end

-- introduces a new fact into the database
function faces_methods:fassert(fact, ...)
  if fact ~= nil then
    assert(type(fact) == "table", "A table argument is expected")
    check_fact_strings(fact)
    local fact = tuple(fact)
    if not self.fact_map[fact] then
      self.fact_idx = self.fact_idx + 1
      self.fact_list[self.fact_idx] = fact
      self.fact_map[fact] = self.fact_idx
      -- executes a partial step of forward chaining with all rules affected by
      -- the given fact
      update_forward_chaining_with_assert_fact(self, fact)
      return self.fact_map[fact],self:fassert(...)
    else
      return self.fact_map[fact],self:fassert(...)
    end
  end
end

-- removes a fact from the database
function faces_methods:retract(...)
  for i=1,select('#',...) do
    local v = select(i,...)
    if v == "*" then
      self.needs_regenerate_agenda = true
      -- retract all facts
      for idx,f in pairs(self.fact_list) do
        self.fact_list[idx] = nil
        self.fact_map[f] = nil
      end
      self.matches = {}
      self.rules_agenda = {}
      self.entailed = {}
      self.fact_entailment = {}
    else
      -- retract a given fact
      assert(type(v) == "number", "Expected fact number or '*' string")
      local f = self.fact_list[v]
      if f then
        -- executes a partial step of forward chaining with all rules affected by
        -- the given fact
        update_forward_chaining_with_retract_fact(self, f)
        self.fact_list[v] = nil
        self.fact_map[f] = nil
      else
        error("Unable to find fact " .. v)
      end
    end
  end
end

-- shows in screen all the available facts
function faces_methods:facts()
  local facts = {}
  for i,v in pairs(self.fact_list) do
    table.insert(facts, {i,v})
  end
  table.sort(facts, function(a,b) return a[1]<b[1] end)
  print("# Facts list")
  for _,v in ipairs(facts) do
    print("f-" .. v[1], v[2])
  end
  print(string.format("# For a total of %d facts", #facts))
end

-- shows in screen all the available rules
function faces_methods:rules()
  local rules = {}
  for i,v in pairs(self.kb_table) do
    table.insert(rules, {i,v})
  end
  table.sort(rules, function(a,b) return a[1]<b[1] end)
  print("# Rules list")
  for _,v in ipairs(rules) do
    print(v[1], "salience:", v[2].salience)
  end
end

-- shows the agenda in screen
function faces_methods:agenda()
  if self.needs_regenerate_agenda then regenerate_agenda(self) end
  print("# Agenda")
  local n=0
  for _,v in ipairs(self.rules_agenda) do
    local rule_name    = v.rule_name
    local salience     = v.salience
    local combinations = v.combinations
    for _,seq in ipairs(combinations) do
      n=n+1
      print(tostring(salience), rule_name, tostring(seq))
    end
  end
  print(string.format("# For a total of %d activations", n))
end

-- executes at most n iterations, being by default n=infinity
function faces_methods:run(n)
  n = n or math.huge
  local i=0
  repeat
     -- I.print( { n = n, i = i } )
     local data = table.pack( take_best_rule(self) )
    if data[1] then fire_rule(self, table.unpack(data) ) i = i+1 end
  until i==n or not data[1]
end

-- returns the fact related to the given fact id
function faces_methods:consult(fid)
  local fact = assert(self.fact_list[fid],
                      "Unable to find fact with index " .. tostring(fid))
  return fact
end

-- declares a new rule in the knowledge base
function faces_methods:defrule(rule_name)
  local rule = { patterns={}, user_clauses = {},
                 actions={}, salience=0, var_matches = {}, fact_vars = {} }
  self.kb_table[rule_name] = rule
  local rule_builder
  rule_builder = {
    pattern = function(rule_builder, pattern)
      table.insert(rule.patterns, tuple(pattern))
      return rule_builder
    end,
    var = function(rule_builder, varname)
      varname = assert(varname:match("%?([^%s]+)"),
                       string.format("Incorrect variable name: %s", varname))
      rule.fact_vars[varname] = #rule.patterns + 1
      return {
        pattern = function(_,...)
          return rule_builder.pattern(rule_builder,...)
        end,
      }
    end,
    u = function(rule_builder, ...)
      -- user_func receives one argument: vars
      table.insert(rule.user_clauses, get_user_func(...))
      return rule_builder
    end,
    salience = function(rule_builder, value)
      rule.salience = value
      return rule_builder
    end,
    match = function(rule_builder, varname, value)
      varname = assert(varname:match("%?([^%s]+)"),
                       string.format("Incorrect variable name: %s", varname))
      rule.var_matches[varname] = function(v)
        return v:find(value)
      end
      return rule_builder
    end,
    numeric = function(rule_builder, varname)
      varname = assert(varname:match("%?([^%s]+)"),
                       string.format("Incorrect variable name: %s", varname))
      rule.var_matches[varname] = function(v)
        return type(v) == "number"
      end
      return rule_builder
    end,
    ENTAILS = function(_, arg)
      assert(arg == "=>", "ENTAILS needs '=>' string as argument")
      update_forward_chaining_with_rule(self, rule_name, rule)
      return setmetatable({},{
          __index = function(rule_builder, key)
            if key == "u" then
              return function(rule_builder, ...)
                -- user_func receives one argument: vars
                table.insert(rule.actions, get_user_func(...))
                return rule_builder
              end
            else
              local f = assert(self[key], "Undefined function " .. key)
              if key == "fassert" then
                return function(rule_builder, ...)
                  local args = table.pack(...)
                  table.insert(rule.actions,
                               function(vars)
                                 local args = replace_user_functions(args, vars)
                                 for i=1,args.n do args[i] = tuple(args[i]) end
                                 local new_args = replace_variables(args, vars)
                                 return self[key](self, table.unpack(new_args))
                  end)
                  return rule_builder
                end
              elseif key == "retract" then
                return function(rule_builder, ...)
                  local args = table.pack(...)
                  table.insert(rule.actions,
                               function(vars)
                                 local args = replace_user_functions(args, vars)
                                 local new_args = replace_variables({ args }, vars)
                                 return self[key](self, table.unpack(new_args[1]))
                  end)
                  return rule_builder
                end
              else
                error("Key %s not available (it could be using user defined function")
              end
            end
          end
      })
    end
  }
  return rule_builder
end

-----------------
-- CONSTRUCTOR --
-----------------

--
local faces_metatable = {
  __index = faces_methods,
}

-- calling faces table returns a new rule-based expert system
setmetatable(faces, {
               __call = function()
                 local t = {
                   -- knowledge-base table, contains all the rules
                   kb_table = {},
                 }
                 local t = setmetatable(t, faces_metatable)
                 t:clear()
                 return t
               end
})

-- returns module table
return faces
