-- quick and dirty test of the major luanacha functions

-- local na = require "luanacha"
require'string'
require'table'
require'os'
-- some local definitions

local strf = string.format
local byte, char = string.byte, string.char
local spack, sunpack = string.pack, string.unpack

local app, concat = table.insert, table.concat

local function stohex(s, ln, sep)
	-- stohex(s [, ln [, sep]])
	-- return the hex encoding of string s
	-- ln: (optional) a newline is inserted after 'ln' bytes 
	--	ie. after 2*ln hex digits. Defaults to no newlines.
	-- sep: (optional) separator between bytes in the encoded string
	--	defaults to nothing (if ln is nil, sep is ignored)
	-- example: 
	--	stohex('abcdef', 4, ":") => '61:62:63:64\n65:66'
	--	stohex('abcdef') => '616263646566'
	--
	if #s == 0 then return "" end
	if not ln then -- no newline, no separator: do it the fast way!
		return (s:gsub('.', 
			function(c) return strf('%02x', byte(c)) end
			))
	end
	sep = sep or "" -- optional separator between each byte
	local t = {}
	for i = 1, #s - 1 do
		t[#t + 1] = strf("%02x%s", s:byte(i),
				(i % ln == 0) and '\n' or sep) 
	end
	-- last byte, without any sep appended
	t[#t + 1] = strf("%02x", s:byte(#s))
	return concat(t)	
end --stohex()

local function hextos(hs, unsafe)
	-- decode an hex encoded string. return the decoded string
	-- if optional parameter unsafe is defined, assume the hex
	-- string is well formed (no checks, no whitespace removal).
	-- Default is to remove white spaces (incl newlines)
	-- and check that the hex string is well formed
	local tonumber = tonumber
	if not unsafe then
		hs = string.gsub(hs, "%s+", "") -- remove whitespaces
		if string.find(hs, '[^0-9A-Za-z]') or #hs % 2 ~= 0 then
			error("invalid hex string")
		end
	end
	return (hs:gsub(	'(%x%x)', 
		function(c) return char(tonumber(c, 16)) end
		))
end -- hextos

local function px(s, msg) 
	print("--", msg or "")
	print(stohex(s, 16, " ")) 
end

print("------------------------------------------------------------")
print(_VERSION, VERSION )
print("------------------------------------------------------------")

------------------------------------------------------------------------
-- lock/unlock tests

print("testing authenticated encryption...")

-- lock stream encryption - test with Xchacha20 test vectors
--
-- lock() uses the first 32 bytes of the xchacha encryption stream
-- to generate the poly1305 MAC key. So lock stream must be compared 
-- with xchacha20 stream at offset 32.

-- xchacha test vector from
-- https://raw.githubusercontent.com/DaGenix/rust-crypto/master/src/chacha20.rs
k = hextos"1b27556473e985d462cd51197a9a46c76009549eac6474f206c4ee0844f68389"
n = hextos"69696ee955b62b73cd62bda875fc73d68219e0036b7a0b37"
e = hextos(
	"4febf2fe4b359c508dc5e8b5980c88e38946d8f18f313465c862a08782648248" ..
	"018dacdcb904178853a46dca3a0eaaee747cba97434eaffad58fea8222047e0d" ..
	"e6c3a6775106e0331ad714d2f27a55641340a1f1dd9f94532e68cb241cbdd150" ..
	"970d14e05c5b173193fb14f51c41f393835bf7f416a7e0bba81ffb8b13af0e21" ..
	"691d7ecec93b75e6e4183a")
m = string.rep('\0', #e)
c = lock(k, n, m)
assert(#c == #e+16)
-- the 32 first bytes of e are used for the MAC key
-- the first 16 bytes of c are the MAC
-- so we compare e:sub(33) with c:sub(17, #c-32)
--
--~ px(e, 'e')
--~ px(c, 'c')
--~ px(c:sub(17, #c-32), 'c'); 
--~ px(e:sub(33), 'e')
assert(e:sub(33) == c:sub(17, #c-32))


-- xchacha test vector from libsodium
-- https://github.com/jedisct1/libsodium/blob/master/test/default/xchacha20.c
k = hextos"eadc0e27f77113b5241f8ca9d6f9a5e7f09eee68d8a5cf30700563bf01060b4e"
n = hextos"a171a4ef3fde7c4794c5b86170dc5a099b478f1b852f7b64"
e = hextos(
	"23839f61795c3cdbcee2c749a92543baeeea3cbb721402aa42e6cae140447575" ..
	"f2916c5d71108e3b13357eaf86f060cb")
m = string.rep('\0', #e)
c = lock(k, n, m)
assert(e:sub(33) == c:sub(17, #c-32))

-- unlock
m2, msg = unlock(k, n, c)
assert(m2)
assert(m2 == m)

-- prefix and offset - prepend the nonce:
c = lock(k, n, m, n)
assert(#c == #m + 16 + #n)
n2 = c:sub(1,24)
m2 = unlock(k, n2, c, #n2)
assert(m2 == m)

print("OK")
------------------------------------------------------------------------
-- blake2b tests

print("testing blake2b...")

t = "The quick brown fox jumps over the lazy dog"
e = hextos(
	"A8ADD4BDDDFD93E4877D2746E62817B116364A1FA7BC148D95090BC7333B3673" ..
	"F82401CF7AA2E4CB1ECD90296E3F14CB5413F8ED77BE73045B13914CDCD6A918")
	
-- test convenience function
dig = blake2b(t)
assert(e == dig)

-- test chunked interface
ctx = blake2b_init()
blake2b_update(ctx, "The q")
blake2b_update(ctx, "uick brown fox jumps over the lazy dog")
dig = blake2b_final(ctx)
assert(e == dig)

-- test shorter digests
ctx = blake2b_init(5)
blake2b_update(ctx, "The q")
blake2b_update(ctx, "uick brown fox jumps over the lazy dog")
dig51 = blake2b_final(ctx)
ctx = blake2b_init(5)
blake2b_update(ctx, "The quick b")
blake2b_update(ctx, "rown fox jumps over the lazy dog")
dig52 = blake2b_final(ctx)
assert(#dig51 == 5 and dig51 == dig52)

-- same, with a key
ctx = blake2b_init(5, "somekey")
blake2b_update(ctx, "The q")
blake2b_update(ctx, "uick brown fox jumps over the lazy dog")
dig53 = blake2b_final(ctx)
ctx = blake2b_init(5, "somekey")
blake2b_update(ctx, "The quick b")
blake2b_update(ctx, "rown fox jumps over the lazy dog")
dig54 = blake2b_final(ctx)
assert(#dig53 == 5 and dig53 == dig54)

ctx = blake2b_init(5, ("\0"):rep(0)) -- is it same as no key??
blake2b_update(ctx, "The q")
blake2b_update(ctx, "uick brown fox jumps over the lazy dog")
dig55 = blake2b_final(ctx)
assert(dig51==dig55)

print("OK")
------------------------------------------------------------------------
-- x25519 tests

print("testing x25519 key exchange...")

apk, ask = x25519_keypair() -- alice keypair
bpk, bsk = x25519_keypair() -- bob keypair
assert(apk == x25519_public_key(ask))

k1 = key_exchange(ask, bpk)
k2 = key_exchange(bsk, apk)
assert(k1 == k2)

print("OK")
------------------------------------------------------------------------
-- ed25519 signature tests

print("testing ed25519 signature...")

t = "The quick brown fox jumps over the lazy dog"

pk, sk = sign_keypair() -- signature keypair
assert(pk == sign_public_key(sk))

sig = sign(sk, pk, t)
assert(#sig == 64)
--~ px(sig, 'sig')

-- check signature
assert(check(sig, pk, t))

-- modified text doesn't check
assert(not check(sig, pk, t .. "!"))

print("OK")
------------------------------------------------------------------------
-- password derivation argon2i tests

print("testing argon2i...")

pw = "hello"
salt = "salt salt salt"
k = ""
c0 = os.clock()
k = argon2i(pw, salt, 100000, 10)
assert(#k == 32)
print("OK: argon2i (100MB, 10 iter) Execution time (sec): ", os.clock()-c0)
print("------------------------------------------------------------")
