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
--Last modified by Denis Roio
--on Tuesday, 20th July 2021
--]]

local hash = require'hash'

-- when using facility functions, global hashers are created only once
SHA256 = nil
SHA512 = nil
SHAKE256 = nil
KECCAK256 = nil
local function init(bits)
   local h
   if bits == 256 or bits == 32 then
	  if SHA256==nil then SHA256 = hash.new('sha256') end
	  h = SHA256
   elseif bits == 512 or bits == 64 then
	  if SHA512==nil then SHA512 = hash.new('sha512') end
	  h = SHA512
	else
	  error("HASH bits not supported: "..bits)
   end
   return h
end

function sha256(data) return init(256):process(data) end
function sha512(data) return init(512):process(data) end
function shake256(data, len)
	if SHAKE256==nil then SHAKE256 = hash.new('shake256') end
	if not len then len = 32 end
	return SHAKE256:process(data, len)
end

function keccak256(data)
    if KECCAK256==nil then KECCAK256 = hash.new('keccak256') end
    return KECCAK256:process(data)
end

function KDF(data, bits)
   local b = bits or 256
   return init(b):kdf2(data)
end

function hash.dsha256(msg)
   local SHA256 = HASH.new('sha256')
   return SHA256:process(SHA256:process(msg))
end

function hash.hash160(msg)
   local SHA256 = HASH.new('sha256')
   local RMD160 = HASH.new('ripemd160')
   return RMD160:process(SHA256:process(msg))

end

--used in BBS+ signature
function hkdf_extract(salt, ikm)
	return HASH.hmac(hash.new('sha256'), salt, ikm)
end

--used in BBS+ signature
function hkdf_expand(prk, info, l)
	local h = hash.new('sha256')
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
function expand_message_xof(msg, DST, len_in_bytes)
--msg and DST must be octets
	if len_in_bytes > 65536 then
		error("len_in_bytes is too big", 2)
	end
	if #DST > 255 then
		error("len(DST) is too big", 2)
	end

	local DST_prime = DST .. i2osp(#DST, 1)
	local msg_prime = msg .. i2osp(len_in_bytes, 2) .. DST_prime
	local uniform_bytes = shake256(msg_prime, len_in_bytes)

	return uniform_bytes, DST_prime, msg_prime

end

--used in BBS+ signature
-- draft-irtf-cfrg-hash-to-curve-16 section 5.3.1
-- It outputs a uniformly random byte string.
function expand_message_xmd(msg, DST, len_in_bytes)
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
