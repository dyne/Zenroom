-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2020 Dyne.org foundation
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
When("move '' in ''", function(from, to)
        ZEN.assert(ACK[to], "Destination not found: "..to)
        ZEN.assert(ACK[from], "Object not found: "..from)
        ZEN.assert(ZEN.CODEC[from].zentype == 'element',
                   "Object to move is not a single element: "..from)
        ZEN.assert(luatype(ACK[to]) == 'table',
                   "Invalid destination, not a table container: "..to)
        if ZEN.CODEC[to].zentype == 'array' then
           table.insert(ACK[to], ACK[from])
        else
           ACK[to][from] = ACK[from]
        end
        ACK[from] = nil
end)

When("copy '' in ''", function(from, to)
        ZEN.assert(ACK[to], "Destination not found: "..to)
        ZEN.assert(ACK[from], "Object not found: "..from)
        ZEN.assert(ZEN.CODEC[from].zentype == 'element',
                   "Object to copy is not a single element: "..from)
        ZEN.assert(luatype(ACK[to]) == 'table',
                   "Invalid destination, not a table container: "..to)
        if isarray(ACK[to]) then
           table.insert(ACK[to], ACK[from])
        else
           ACK[to][from] = ACK[from]
        end
        ACK[from] = nil
end)

-- this is a map reduce function processing a single argument as
-- values found, it uses function pointers and conditions from the
-- params structure.
-- param.target = key name of the value to find
-- param.op = single argument function to run on found value
-- param.cmp = dual argument comparison for dictionary eligibility
-- param.conditions = k/v list of elements to compare in dictionary

local function dicts_reduce(dicts, params)
   local found
   for ak,av in pairs(dicts) do
	  found = false
	  -- apply params filters, boolean just check key presence
	  if params.conditions and params.cmp then
		 for pk,pv in pairs(params.conditions) do
			if av[pk] then
			   if params.cmp(av[pk], pv) then
				  found = true
			   end
			end
		 end
	  else found = true end -- no filters, apply everywhere
	  -- apply sum of selected key/value
	  if found then
		 for k,v in pairs(av) do
			if k == params.target then
			   params.op(v)
			end
		 end
	  end
   end
end

When("find the max value '' for dictionaries in ''", function(name, arr)
        ZEN.assert(ACK[arr], "No dictionaries found in: "..arr)
        local max = 0
		local params = { target = name }
		params.op = function(v) if max < v then max = v end end
		dicts_reduce(ACK[arr],params)
        ZEN.assert(max, "No max value "..name.." found across dictionaries in"..arr)
        ACK.max_value = max
        ZEN.CODEC.max_value = ZEN.CODEC[arr]
end)

When("create the sum value '' for dictionaries in '' where '' > ''", function(name,arr, left, right)
        ZEN.assert(ACK[arr], "No dictionaries found in: "..arr)
		ZEN.assert(ACK[right], "Right side term of comparison not found: "..right)

		local sum = 0 -- result of reduction
		local params = { target = name,
						 conditions = { } }
		params.conditions[left] = ACK[right] -- used in cmp
		params.cmp = function(l,r) return l > r end
		params.op = function(v) sum = sum + v end
        dicts_reduce(ACK[arr], params)

        ZEN.assert(sum, "No sum of value "..name
					  .." found across dictionaries in"..arr)
        ACK.sum_value = sum
        ZEN.CODEC.sum_value = ZEN.CODEC[arr]
end)

When("find the '' for dictionaries in '' where '' = ''",function(name, arr, left, right)
        ZEN.assert(ACK[arr], "No dictionaries found in: "..arr)
		ZEN.assert(ACK[right], "Right side term of comparison not found: "..right)

		local val
		local params = { target = name,
						 conditions = { } }
		params.conditions[left] = ACK[right]
		params.cmp = function(l,r) return l == r end
		params.op = function(v) val = v end
		dicts_reduce(ACK[arr], params)

		ZEN.assert(val, "No value found "..name.." across dictionaries in "..arr)
		ACK[name] = val
		ZEN.CODEC[name] = ZEN.CODEC[arr]
end)
