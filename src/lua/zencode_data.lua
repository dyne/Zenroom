-- Zencode statements to manage data

-- GLOBALS:
-- data        (root, decoded from DATA in Given)
-- selection   (currently selected portion of root)

ZEN.data = { }

function ZEN.data.load()
   local _data
   if DATA then -- global set by zenroom
      _data = JSON.decode(DATA)
   else
      _data = { }
   end
   return _data
end

function ZEN.data.add(_data, key, value)
   if _data[key] then
      error("ZEN.data.add(): DATA already contains '"..key.."' key")
   end
   if value['schema'] then
      ZEN.assert(validate(value, schemas[value['schema']]),
                 "ZEN.data.add(): invalid data format for "..key..
                    " (schema: "..value['schema']..")", value)
   end
   _data[key] = value
   return _data
end

function ZEN.data.conjoin(_data, section, key, value)
   if _data[section] then
      portion = _data[section]
   else
      portion = { }
   end
   if value['schema'] then
      ZEN.assert(validate(value, schemas[value.schema]),
				 "conjoin(): invalid data format for "..section.."."..key..
					" (schema: "..value.schema..")")
   end
   portion[key] = value
   _data[section] = portion
   return _data
end

function ZEN.data.disjoin(_data, section, key)
   portion = _data[section] -- L.property(section)(_data)
   local out = {}
   L.map(portion, function(k,v)
            if k ~= key then
               out[k] = v end end)
   _data[section] = out
   return _data
end

-- checks that a data section contains a key (no check on value)
function ZEN.data.check(_data, section, key)
   -- _data = _data or _G['data']
   portion = _data[section] -- L.property(section)(_data)
   if not portion then
      error("ZEN.data.check(): '"..section.."' data not found") end
   if key then
      if not portion[key] then
         error("ZEN.data.check(): '"..key..
			   "' not found in '"..section.."' data") end
      if type(portion) == "table" then
         if portion[key].schema then
            ZEN.assert(validate(portion[key], schemas[portion[key].schema]),
					   "ZEN.data.check(): invalid data format for "..section.."."..key..
						  " (schema: "..portion[key].schema..")");
         end
      end
      return(portion[key])
   else
      if type(portion) == "table" then
         if portion.schema then
            ZEN.assert(validate(portion, schemas[portion.schema]),
					   "ZEN.data.check(): invalid data format for "..section..
						  " (schema: "..portion.schema..")");
            return(portion)
         end
      end
   end
end

-- request
f_hello = function(nam) ACK.whoami = nam end
Given("I introduce myself as ''", f_hello)
Given("I am known as ''", f_hello)

f_havedata = function (section,key)
   -- _G['data'] = ZEN.check(JSON.decode(DATA),dataname)
   -- local _data = IN or ZEN.data.load()
   if key then
      ZEN.data.check(IN,section,key)
   else
      ZEN.data.check(IN,section)
   end
   -- _data = data or JSON.decode(DATA)
   -- section = _data[dataname] -- L.property(dataname)(_data)
   -- ZEN.assert(validate(section,schemas[dataname]),
   --         "Invalid data format for "..dataname)
   -- -- explicit global states
   selection = section
end

Given("I have a '' ''", f_havedata)
Given("I have a ''", f_havedata)


f_datakeyvalue = function(section,key,value)
   --   local _data = IN or ZEN.data.load()
   k = ZEN.data.check(IN,section,key)
   ZEN.assert(k == value, section.." data key "..key.."="..k.." instead of "..value)
   ACK[section] = IN[section]
end
Given("I have a '' '' ''", f_datakeyvalue)
Given("data '' field '' contains ''", f_datakeyvalue)

f_datarm = function (section)
   --   local _data = IN or ZEN.data.load()
   if not IN          then error("No data loaded") end
   if not selection   then error("No data selected") end
   if not section     then error("Specify the data portion to remove") end
   OUT = ZEN.data.disjoin(IN, selection, section)
end

When("I declare that I am ''", function(decl)
		-- declaration
		if not declared then declared = decl
		else declared = declared .." and ".. decl end
end)

When("I declare to '' that I am ''",function (auth,decl)
        -- declaration
        if not declared then declared = decl
        else declared = declared .." and ".. decl end
        -- authority
        authority = auth
end)

When("I draft the text ''", function(text)
        -- local _data = IN or ZEN.data.load()
        ACK = ZEN.data.add(IN,'text',text)
end)


Given("that '' declares to be ''",function(who, decl)
         -- declaration
         if not declared then declared = decl
         else declared = declared .." and ".. decl end
         whois = who
end)
Given("declares also to be ''", function(decl)
         ZEN.assert(who ~= "", "The subject making the declaration is unknown")
         -- declaration
         if not declared then declared = decl
         else declared = declared .." and ".. decl end
end)

When("I remove '' from data", f_datarm)

f_justprint =  function (what)
   ZEN.assert(OUT[what], "Cannot print, data not found: "..what)
   write_json({ [what] = OUT[what] })
end
Then("print data ''", f_justprint)

Then("print '' inside ''", function (what, section)
        -- local _data = OUT or ZEN.data.load()
        ZEN.assert(OUT[what], "Cannot print, data not found: "..what)
        local t = type(OUT[what])
        write_json({ [section] = OUT[what] })
end)

Then("print '' ''", function (what, section)
        -- local _data = OUT or ZEN.data.load()
        local sub = ZEN.data.check(OUT,section)
        local t = type(sub)
        if t == "table" then write_json(sub)
        elseif iszen(t) or t == "string" then
           print(sub)
        else
           error("Cannot print '"..what.."'.'"..section.."' data type: "..t)
        end
end)

Then("print string ''", function(s)
        print(s)
end)

Then("print all data", function()
        -- local _data = OUT or ZEN.data.load()
        local t = type(OUT)
        if t == "table" then
           write_json(OUT)
        elseif iszen(t) or t == "string" then
           print(OUT)
        end
end)
