-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2018-2019 Dyne.org foundation
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

-- init script embedded at compile time.  executed in
-- zen_load_extensions(L) usually after zen_init()

-- override type to recognize zenroom's types
luatype = type
function type(var)
   local simple = luatype(var)
   if simple == "userdata" then
	  if getmetatable(var).__name then
		 return(getmetatable(var).__name)
	  else
		 return("unknown")
	  end
   else return(simple) end
end
function iszen(n)
   for c in n:gmatch("zenroom") do
	  return true
   end
   return false
end

require('msgpack')
MSG = msgpack
msgpack = nil -- rename default global

OCTET  = require('zenroom_octet')
O = OCTET -- alias

INSIDE = require('inspect')
I = INSIDE -- alias

JSON = require('zenroom_json')
RNG    = require('zenroom_rng')
ECDH   = require('zenroom_ecdh')
LAMBDA = require('functional')
L = LAMBDA -- alias
FP12   = require('fp12')
BIG    = require('zenroom_big')
INT = BIG -- alias
HASH   = require('zenroom_hash')
ECP    = require('zenroom_ecp')
ECP2   = require('zenroom_ecp2')
H = HASH -- alias
ELGAMAL = require('crypto_elgamal')
COCONUT = require('crypto_coconut')

-- Zencode language interpreter
-- global class
ZEN = require('zencode')
-- import/export schema helpers
require('zencode_schemas')
-- basic keypair functions
-- require('zencode_keypair')
-- base data functions
require('zencode_data')
-- base encryption functions
-- require('zencode_aesgcm')
-- implicit certificates
-- require('zencode_ecqv')
-- coconut credentials
-- require('zencode_coconut')

function content(var)
   if type(var) == "zenroom.octet" then
	  INSIDE.print(var:array())
   else
	  INSIDE.print(var)
   end
end

-- switch to deterministic (sorted) table iterators
_G["pairs"]  = LAMBDA.pairs
_G["ipairs"] = LAMBDA.pairs

-- default encoding base64url (RFC4648)
-- this is the fastest and most portable encoder in zenroom
_G["ENCODING"] = url64

-- map values in place, sort tables by keys for deterministic order
function map(data, fun)
   if(type(data) ~= "table") then
	  error "map() first argument is not a table"
	  return nil end
   if(type(fun) ~= "function") then
	  error "map() second argument is not a function"
	  return nil end
   out = {}
   L.map(data,function(k,v) out[k] = fun(v) end)
   return(out)
end


function help(module)
   if module == nil then
	  print("usage: help(module)")
	  print("example > help(octet)")
	  print("example > help(ecdh)")
	  print("example > help(ecp)")
	  return
   end
   for k,v in pairs(module) do
	  if type(v)~='table' and string.sub(k,1,1)~='_' then
		 print("class method: "..k)
	  end
   end
   if module.new == nil then return end
   local inst = module.new()
   for s,f in pairs(getmetatable(inst)) do
	  if(string.sub(s,1,2)~='__') then print("object method: "..s) end
   end
end

-- TODO: deprecated, to be removed
function read_json(data)
   if not data then
	  error("read_json() missing data")
   end
   out,res = JSON.decode(data)
   if not out then
	  if res then
		 error("read_json() invalid json: ".. res)
	  end
   end
end
function write_json(data)
   t = type(data)
   if(t == "zenroom.ecp") then
	  print(JSON.encode(data:table()))
	  return
   else
	  print(JSON.encode(data))
   end
end
json_write = write_json
json_read = read_json
