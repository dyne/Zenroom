-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2018-2022 Dyne.org foundation designed, written and
-- maintained by Denis Roio <jaromil@dyne.org>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
-- Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public
-- License along with this program.  If not, see
-- <https://www.gnu.org/licenses/>.

-- init script embedded at compile time.  executed in
-- zen_load_extensions(L) usually after zen_init()

-- -- remap fatal and error
function fatal(msg)
	ZEN.debug()
	msg = msg or 'fatal error'
	error(msg, 2)
end

-- global
REQUIRED = {}
-- avoid duplicating requires (internal includes)
function require_once(ninc)
	local class = REQUIRED[ninc]
	local _res
	if not class then
		_res, class = pcall( function() return require(ninc) end )
		assert(_res, class)
		REQUIRED[ninc] = class
	end
	return class
end

SCENARIOS = {}
function load_scenario(scen)
   local s = SCENARIOS[scen]
   if not s then
      local _res, _err
      _res, _err = pcall( function() require(scen) end)
      assert(_res, _err)
      SCENARIOS[scen] = true
   end
end

-- error = zen_error -- from zen_io

-- ZEN = { assert = assert } -- zencode shim when not loaded
require('zenroom_common')
INSPECT = require('inspect')
OCTET = require('zenroom_octet')
BIG = require('zenroom_big')
FLOAT = require'float'
JSON = require('zenroom_json')
ECDH = require('zenroom_ecdh')
-- ECDH public keys cannot function as ECP because of IANA 7303
AES = require'aes'
ECP = require('zenroom_ecp')
ECP2 = require('zenroom_ecp2')
HASH = require('zenroom_hash')
O = OCTET -- alias
INT = BIG -- alias
F=FLOAT
I = INSPECT -- alias
H = HASH -- alias
PAIR = ECP2 -- alias
PAIR.ate = ECP2.miller --alias
MPACK = require('zenroom_msgpack')
BENCH = require('zenroom_bench')
MACHINE = require('statemachine')
TIME = require('timetable')
-- BITCOIN primitives are imported by default
BTC = require('crypto_bitcoin')
V = require('semver')
ZENROOM_VERSION = V(VERSION)
MAXITER = tonumber(STR_MAXITER)

ZEN = require('zencode')
-- the global ZEN context

-- base zencode functions and schemas
load_scenario('zencode_data') -- pick/in, conversions etc.
load_scenario('zencode_given')
load_scenario('zencode_when')
load_scenario('zencode_hash') -- when extension
load_scenario('zencode_array') -- when extension
load_scenario('zencode_random') -- when extension
load_scenario('zencode_dictionary') -- when extension
load_scenario('zencode_verify') -- when extension
load_scenario('zencode_then')
load_scenario('zencode_keyring')
load_scenario('zencode_pack') -- mpack and zpack 
load_scenario('zencode_foreach')
-- this is to evaluate expressions or derivate a column
-- it would execute lua code inside the zencode and is
-- therefore dangerous, switched off by default
-- require('zencode_eval')
load_scenario('zencode_debug')

-- bitcoin is loaded by default
load_scenario('zencode_bitcoin')

-- scenario are loaded on-demand
-- scenarios can only implement "When ..." steps
_G['Given'] = nil
_G['Then'] = nil

-----------
-- defaults
_G['CONF'] = {
	input = {
		encoding = input_encoding('base64'),
		format = { fun = JSON.auto, name = 'json' },
		tagged = false
	},
	output = {
		encoding = { fun = guess_outcast('base64'),
			     name = 'base64' },
		format = { fun = JSON.auto, name = 'json' },
		versioning = false
	},
	debug = { encoding = { fun = guess_outcast('hex'),
			       name = 'hex' } },
	parser = {strict_match = true},
	heap = { check_collision = true },
	hash = 'sha256',
}
-- turn on heapguard when DEBUG or linux-debug build
if DEBUG > 1 or MAKETARGET == "linux-debug" then
	_G['CONF'].heapguard = true
else
	_G['CONF'].heapguard = false
end

-- do not modify
_G['LICENSE'] =
	[[
Licensed under the terms of the GNU Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.  Unless required by applicable
law or agreed to in writing, software distributed under the License
is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.
]]
_G['COPYRIGHT'] =
	[[
Forked by Jaromil on 18 January 2020 from Coconut Petition
]]
SALT = ECP.hashtopoint(OCTET.from_string(COPYRIGHT .. LICENSE))
-- Calculate a system-wide crypto challenge for ZKP operations
-- returns a BIG INT
-- this is a sort of salted hash for advanced ZKP operations and
-- should not be changed. It may be made configurable in future.
function ZKP_challenge(list)
	local challenge =
		ECP.generator():octet() .. ECP2.generator():octet() .. SALT:octet()
	local ser = serialize(list)
	return INT.new(
		sha256(challenge .. ser.octets .. OCTET.from_string(ser.strings))
	) % ECP.order()
end

collectgarbage 'collect'

