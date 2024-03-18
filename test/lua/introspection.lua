
scenarios = I.spy( zencode_scenarios() )

print''
print( 'Introspection found '.. #scenarios..' scenarios')
print''

local before
local after
for _,v in ipairs(scenarios) do
   -- before = os.time()

   -- exceptions: data, zencode
   if v ~= 'zencode' and v ~= 'data' then
	  print ('+ load: '..v)
	  load_scenario('zencode_'..v)
   end
	  -- after = os.time()
	  -- print ('  seconds: '..after-before)
end

print''
print( 'All scenarios are loaded now')
print''

-- total_statements = ( 0
-- 					 + table_size(ZEN.when_steps)
-- 					 + table_size(ZEN.given_steps)
-- 					 + table_size(ZEN.then_steps)
-- 					 + table_size(ZEN.foreach_steps) )
-- print( 'Total Zencode statements: '..total_statements)

statements = { }
for k,v in pairs(ZEN.when_steps) do table.insert(statements, k) end
for k,v in pairs(ZEN.given_steps) do table.insert(statements, k) end
for k,v in pairs(ZEN.then_steps) do table.insert(statements, k) end
for k,v in pairs(ZEN.foreach_steps) do table.insert(statements, k) end

tokens = { }
for _,v in ipairs(statements) do
   local toks = strtok(trim(v):lower(), ' ')
   for _,t in ipairs(toks) do
	  if t ~= "''" then
		 if tokens[t] then
			tokens[t] = tokens[t] + 1
		 else
			tokens[t] = 1
		 end
	  end
   end
end

print( 'Hall of fame:')
local function sortbyval(tbl, sortFunction)
  local keys = {}
  for key in pairs(tbl) do
    table.insert(keys, key)
  end

  table.sort(keys, function(a, b)
    return sortFunction(tbl[a], tbl[b])
  end)

  return keys
end

local sorted_tokens = sortbyval(tokens, function(a, b) return a < b end)

for _,v in ipairs(sorted_tokens) do
   print(tokens[v]..'\t'..v)
end

print''
print( 'Total Zencode statements: '..#statements)
print( 'Total unique word tokens: '..table_size(tokens))
print''
