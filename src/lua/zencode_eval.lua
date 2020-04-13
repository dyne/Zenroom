-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2019-2020 Dyne.org foundation
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


ZEN.eval_cache = { }
-- http://www.lua.org/manual/5.3/manual.html#pdf-load
function ZEN.eval_condition(cond, env)
   local lcond = string.gsub(cond,'_', ' ')
   local funcond = "-- .."..lcond..[[
local x=_ENV.x
local y=_ENV.y
if ]]..lcond..[[ then
return true
else return false
end]]
   -- cache the assert
   if not ZEN.eval_cache[cond] then
	  ZEN.assert(load(funcond, 'condition', 't'), "Invalid condition: "..lcond)
	  ZEN.eval_cache[cond] = funcond
   else
	  funcond = ZEN.eval_cache[cond]
   end
   if env then -- fill environment
	  env.sha256 = sha256
	  env.ECDH = ECDH
	  env.ECP = ECP
	  env.ECP2 = ECP2
	  env.PAIR = PAIR
	  env.INT = INT
	  env.OCTET = OCTET
	  return(load(funcond,'condition','t',env)())
   else return nil end
end

function ZEN.eval_function(fun, env)
   local lfun = string.gsub(fun,'_', ' ')
   local funexe = [[-- "]]..lfun..[[
local x=_ENV.x
return ]]..lfun
   -- cache the assert
   if not ZEN.eval_cache[fun] then
	  ZEN.assert(load(funexe, 'condition', 't'), "Invalid condition: "..lfun)
	  ZEN.eval_cache[fun] = funexe
   else
	  funexe = ZEN.eval_cache[fun]
   end
   if env then -- fill environment
	  env.sha256 = sha256
	  env.sha512 = sha512
	  env.ECDH = ECDH
	  env.ECP = ECP
	  env.ECP2 = ECP2
	  env.PAIR = PAIR
	  env.INT = INT
	  env.OCTET = OCTET
	  return(load(funexe,'function','t',env)())
   else return nil end
end

When("for each x in '' y in '' is true ''", function(X, Y, cond)
		ZEN.assert(isarray(ACK[X]), "Array X not found: "..X)
		ZEN.assert(isarray(ACK[Y]), "Array Y not found: "..Y)
		ZEN.eval_condition(cond) -- check
		local c = 0
		for k,x in sort_ipairs(ACK[X]) do
		   c = c + 1
		   local y = ACK[Y][k]
		   -- local fun = load(asscond, 'condition', 't', {y=y,x=x,ECP=ECP})
		   ZEN.assert(ZEN.eval_condition(cond, {y=y,x=x}),
					  "Checked condition failed on arr["..c.."]: " ..cond)
		end
end)
When("for each x in '' create the array using ''", function(arr,fun)
		ZEN.assert(isarray(ACK[arr]), "Array not found: "..arr)
		ZEN.eval_function(fun) -- check
		local c = 0
		ACK.array = { }
		for k,v in sort_ipairs(ACK[arr]) do
		   c = c + 1
		   table.insert(ACK.array, ZEN.eval_function(fun,{x=v}))
		end
end)
