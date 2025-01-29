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
--Last modified by Matteo Cristino
--on Monday, 13th January 2025
--]]

local hash = require'hash'

-- cache storing initialized tables for reuse
hash.cache = { }

function hash:init(name)
    local res
    if self.cache[name] then
        res = self.cache[name]
    else
        res = self.new(name)
        self.cache[name] = res
    end
    return res
end

-- easy to use calls
function sha256(data)   return hash:init("sha256"):process(data) end
function sha512(data)   return hash:init("sha512"):process(data) end
function sha3_256(data) return hash:init("sha256"):process(data) end
function sha3_512(data) return hash:init("sha512"):process(data) end
hash.sha256 = sha256
hash.sha512 = sha512
hash.sha3_256 = sha3_256
hash.sha3_512 = sha3_512

hash.shake256 = function(data, len) return hash:init("shake256"):process(data, len or 32) end
hash.keccak256 = function(data) return hash:init("keccak256"):process(data) end

function KDF(data, bits) return hash:init("sha"..tostring(bits or 256)):kdf2(data) end

function hash.dsha256(msg)
   local _SHA256 <const> = hash:init'sha256'
   return _SHA256:process(_SHA256:process(msg))
end

function hash.hash160(msg)
   local _SHA256 <const> = hash:init'sha256'
   local _RMD160 <const> = hash:init'ripemd160'
   return _RMD160:process(_SHA256:process(msg))

end

--used in BBS+ signature
hash.hkdf_extract = function(salt, ikm)
	return HASH.hmac(hash:init'sha256', salt, ikm)
end

--used in BBS+ signature
hash.hkdf_expand = function(prk, info, l)
	local h = hash:init'sha256'
	local hash_len = 32
	assert(#prk >= hash_len)
	assert(l <= 255 * hash_len)
	assert(l > 0)

	if type(info) == 'string' then
		info = O.from_string(info)
	end

	-- local n = math.ceil(l/hash_len)

	-- TODO: optimize using something like table.concat for octets
	local tprec = HASH.hmac(h, prk, info .. O.from_hex('01'))
	local i = 2
	local t = tprec
	while l > #t do
		tprec = HASH.hmac(h, prk, tprec .. info .. O.from_hex(string.format("%02x", i)))
		t = t .. tprec
		i = i+1
	end

	-- TODO: check that sub is not creating a copy
	return t:sub(1,l)
end

-- RFC8017 section 4
-- converts a nonnegative integer to an octet string of a specified length.
local function i2osp(x, x_len)
	return O.new(BIG.new(x)):pad(x_len)
end

--used in BBS+ signature
-- draft-irtf-cfrg-hash-to-curve-16 section 5.3.2
-- It outputs a uniformly random byte string. (uses SHAKE256)
hash.expand_message_xof = function (msg, DST, len_in_bytes)
--msg and DST must be octets
	if len_in_bytes > 65536 then
		error("len_in_bytes is too big", 2)
	end
	if #DST > 255 then
		error("len(DST) is too big", 2)
	end

	local DST_prime = DST .. i2osp(#DST, 1)
	local msg_prime = msg .. i2osp(len_in_bytes, 2) .. DST_prime
	local uniform_bytes = hash.shake256(msg_prime, len_in_bytes)

	return uniform_bytes, DST_prime, msg_prime

end

--used in BBS+ signature
-- draft-irtf-cfrg-hash-to-curve-16 section 5.3.1
-- It outputs a uniformly random byte string.
hash.expand_message_xmd = function(msg, DST, len_in_bytes)
	-- msg, DST are OCTETS; len_in_bytes is an integer.

	-- Parameters:
	-- a hash function (SHA-256 or SHA3-256 are appropriate)
	local b_in_bytes = 32 -- = output size of hash IN BITS / 8
	local s_in_bytes = 64 -- ok for SHA-256

	local ell = math.ceil(len_in_bytes / b_in_bytes)
	assert(ell <= 255)
	assert(len_in_bytes <= 65535)
	local DST_len = #DST
	assert( DST_len <= 255)

	local DST_prime = DST .. i2osp(DST_len, 1)
	local Z_pad = i2osp(0, s_in_bytes)
	local l_i_b_str = i2osp(len_in_bytes, 2)
	local msg_prime = Z_pad..msg..l_i_b_str..i2osp(0,1)..DST_prime

	local b_0 = sha256(msg_prime)
	local b_1 = sha256(b_0..i2osp(1,1)..DST_prime)
	local uniform_bytes = b_1
	-- b_j assumes the value of b_(i-1) inside the for loop, for i between 2 and ell.
	local b_j = b_1
	for i = 2,ell do
		local b_i = sha256(O.xor(b_0, b_j)..i2osp(i,1)..DST_prime)
		b_j = b_i
		uniform_bytes = uniform_bytes..b_i
	end
	return uniform_bytes:sub(1,len_in_bytes), DST_prime, msg_prime

end


return hash
