-- some local definitions

crypto = require "crypto"
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

local stx, xts = stohex, hextos

local function px(s, msg) 
	print("--", msg or "")
	print(stohex(s, 16, " ")) 
end

print("------------------------------------------------------------")
print(_VERSION, VERSION )
print("------------------------------------------------------------")

------------------------------------------------------------------------
print("testing lzf compression...")
do
	assert(crypto.compress_lzf("") == "")
	assert(crypto.decompress_lzf("") == "")
	local x
	x = "Hello world"; assert(crypto.decompress_lzf(crypto.compress_lzf(x)) == x)
	x = ("a"):rep(301); assert(crypto.decompress_lzf(crypto.compress_lzf(x)) == x)
	assert(#crypto.compress_lzf(("a"):rep(301)) < 30)
end

------------------------------------------------------------------------
print("testing brieflz compression...")
do
	assert(crypto.compress_blz("") == "\0\0\0\0")
	assert(crypto.decompress_blz("\0\0\0\0") == "")
	local x
	x = "Hello world"; assert(crypto.decompress_blz(crypto.compress_blz(x)) == x)
	x = ("a"):rep(301); assert(crypto.decompress_blz(crypto.compress_blz(x)) == x)
	assert(#crypto.compress_blz(("a"):rep(301)) < 30)
end

------------------------------------------------------------------------
print("testing luazen legacy...")

-- xor
do
	local xor = crypto.xor
	pa5 = xts'aa55'; p5a = xts'55aa'; p00 = xts'0000'; pff = xts'ffff'
	assert(xor(pa5, p00) == pa5)
	assert(xor(pa5, pff) == p5a)
	assert(xor(pa5, pa5) == p00)
	assert(xor(pa5, p5a) == pff)
	-- check that 1. result is always same length as plaintext
	-- and 2. key wraps around as needed
	assert(xor((xts"aa"):rep(1), (xts"ff"):rep(31)) == (xts"55"):rep(1))
	assert(xor((xts"aa"):rep(31), (xts"ff"):rep(17)) == (xts"55"):rep(31))
	assert(xor((xts"aa"):rep(32), (xts"ff"):rep(31)) == (xts"55"):rep(32))
end

------------------------------------------------------------------------
-- rc4
if rc4 then do
	local k = ('1'):rep(16)
	local plain = 'abcdef'
	local encr = crypto.rc4(plain, k)
	assert(encr == xts"2598fae14d66")
	encr = crypto.rc4raw(plain, k) -- "raw", no drop
	assert(encr == xts"0178a109f221")
	plain = plain:rep(100)
	assert(plain == crypto.rc4(crypto.rc4(plain, k), k))
	end 
end


------------------------------------------------------------------------
-- md5
md5 = crypto.md5
if md5 then do
	assert(stx(md5('')) == 'd41d8cd98f00b204e9800998ecf8427e')
	assert(stx(md5('abc')) == '900150983cd24fb0d6963f7d28e17f72')
	end--do
end--if
------------------------------------------------------------------------
print("testing base64, base58...")

encode_b64 = crypto.encode_b64
decode_b64 = crypto.decode_b64
-- b64 encode/decode
do 
	local be = encode_b64
	local bd = decode_b64
	--
	assert(be"" == "")
	assert(be"a" == "YQ==")
	assert(be"aa" == "YWE=")
	assert(be"aaa" == "YWFh")
	assert(be"aaaa" == "YWFhYQ==")
	assert(be(("a"):rep(61)) ==
		"YWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFh"
		.. "YWFhYWFh\nYWFhYWFhYQ==") -- produce 72-byte lines
	assert(be(("a"):rep(61), 64) ==
		"YWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFh"
		.. "\nYWFhYWFhYWFhYWFhYQ==") -- produce 64-byte lines
	assert(be(("a"):rep(61), 0) ==
		"YWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFh"
		.. "YWFhYWFhYWFhYWFhYQ==") -- produce one line (no \n inserted)
	assert("" == bd"")
	assert("a" == bd"YQ==")
	assert("aa" == bd"YWE=")
	assert("aaa" == bd"YWFh")
	assert("aaaa" == bd"YWFhYQ==")
	assert(bd"YWFhYWFhYQ" == "aaaaaaa") -- not well-formed (no padding)
	assert(bd"YWF\nhY  W\t\r\nFhYQ" == "aaaaaaa") -- no padding, whitespaces
	assert(bd(be(xts"0001020300" )) == xts"0001020300")
end --b64

------------------------------------------------------------------------
-- b58encode  (check on-line at eg. http://lenschulwitz.com/base58)
encode_b58 = crypto.encode_b58
decode_b58 = crypto.decode_b58
do
	assert(encode_b58(xts'01') == '2')
	assert(encode_b58(xts'0001') == '12')
	assert(encode_b58('') == '')
	assert(encode_b58('\0\0') == '11')
	assert(encode_b58('o hai') == 'DYB3oMS')
	assert(encode_b58('Hello world') == 'JxF12TrwXzT5jvT')
	local x1 = xts"00010966776006953D5567439E5E39F86A0D273BEED61967F6"
	local e1 = "16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM"
	assert(encode_b58(x1) == e1)
	local x2 = xts[[
		0102030405060708090a0b0c0d0e0f
		101112131415161718191a1b1c1d1e1f ]]
	local e2 = "thX6LZfHDZZKUs92febYZhYRcXddmzfzF2NvTkPNE"
	assert(encode_b58(x2) == e2) 
	-- b58decode
	assert(decode_b58('') == '')
	assert(decode_b58('11') == '\0\0')	
	assert(decode_b58('DYB3oMS') == 'o hai')
	assert(decode_b58('JxF12TrwXzT5jvT') == 'Hello world')
	assert(decode_b58(e1) == x1)
	assert(decode_b58(e2) == x2)
end
------------------------------------------------------------------------
print("testing norx aead...")
encrypt_norx = crypto.encrypt_norx
decrypt_norx = crypto.decrypt_norx

k = ('k'):rep(32)  -- key
n = ('n'):rep(32)  -- nonce
a = ('a'):rep(16)  -- aad  (61 61 ...)
z = ('z'):rep(8)   -- zad  (7a 7a ...)
m = ('\0'):rep(83) -- plain text

c = encrypt_norx(k, n, m, 0, a, z)
assert(#c == #a + #m + 32 + #z)
mm, aa, zz = decrypt_norx(k, n, c, 0, 16, 8)
assert(mm == m and aa == a and zz == z)

-- test defaults
c = encrypt_norx(k, n, m, 0, a) -- no zad
assert(#c == #a + #m + 32)
mm, aa, zz = decrypt_norx(k, n, c, 0, 16)
assert(mm == m and aa == a and #zz == 0)
--
c = encrypt_norx(k, n, m) -- no ninc, no aad, no zad
assert(#c == #m + 32)
mm, aa, zz = decrypt_norx(k, n, c)
assert(mm == m and #aa == 0 and #zz == 0)

-- same encryption stream
m1 = ('\0'):rep(85) -- plain text
c1 = encrypt_norx(k, n, m1)
assert(c1:sub(1,83) == c:sub(1,83))

-- mac error
r, msg = decrypt_norx(k, n, c .. "!")
assert(not r and msg == "decrypt error")
--
c = encrypt_norx(k, n, m, 0, a, z)
r, msg = decrypt_norx(k, n, c) -- no aad and zad
assert(not r and msg == "decrypt error")
-- replace unencrypted aad 'aaa...' with 'bbb...'
c1 = ('b'):rep(16) .. c:sub(17); assert(#c == #c1)
r, msg = decrypt_norx(k, n, c1, 0, 16, 8)
assert(not r and msg == "decrypt error")

-- test nonce increment
c = encrypt_norx(k, n, m) 
c1 = encrypt_norx(k, n, m, 1) 
c2 = encrypt_norx(k, n, m, 2) 
assert(#c1 == #m + 32)
assert((c ~= c1) and (c ~= c2) and (c1 ~= c2))
r, msg = decrypt_norx(k, n, c1)
assert(not r and msg == "decrypt error")
r, msg = decrypt_norx(k, n, c1, 1)
assert(r == m)

-- check aliases: removed. these are different functions in Lua5.1 !!
--~ assert(encrypt_norx == encrypt)
--~ assert(decrypt_norx == decrypt)

------------------------------------------------------------------------
-- blake2b tests
hash_blake2b = crypto.hash_blake2b
hash_init_blake2b = crypto.hash_init_blake2b
hash_update_blake2b = crypto.hash_update_blake2b
hash_final_blake2b = crypto.hash_final_blake2b

print("testing blake2b...")

t = "The quick brown fox jumps over the lazy dog"
e = hextos(
	"A8ADD4BDDDFD93E4877D2746E62817B116364A1FA7BC148D95090BC7333B3673" ..
	"F82401CF7AA2E4CB1ECD90296E3F14CB5413F8ED77BE73045B13914CDCD6A918")
	
-- test convenience function
dig = hash_blake2b(t)
assert(e == dig)

-- test chunked interface
ctx = hash_init_blake2b()
hash_update_blake2b(ctx, "The q")
hash_update_blake2b(ctx, "uick brown fox jumps over the lazy dog")
dig = hash_final_blake2b(ctx)
assert(e == dig)

-- test shorter digests
ctx = hash_init_blake2b(5)
hash_update_blake2b(ctx, "The q")
hash_update_blake2b(ctx, "uick brown fox jumps over the lazy dog")
dig51 = hash_final_blake2b(ctx)
ctx = hash_init_blake2b(5)
hash_update_blake2b(ctx, "The quick b")
hash_update_blake2b(ctx, "rown fox jumps over the lazy dog")
dig52 = hash_final_blake2b(ctx)
assert(#dig51 == 5 and dig51 == dig52)

-- same, with a key
ctx = hash_init_blake2b(5, "somekey")
hash_update_blake2b(ctx, "The q")
hash_update_blake2b(ctx, "uick brown fox jumps over the lazy dog")
dig53 = hash_final_blake2b(ctx)
ctx = hash_init_blake2b(5, "somekey")
hash_update_blake2b(ctx, "The quick b")
hash_update_blake2b(ctx, "rown fox jumps over the lazy dog")
dig54 = hash_final_blake2b(ctx)
assert(#dig53 == 5 and dig53 == dig54)

ctx = hash_init_blake2b(5, ("\0"):rep(0)) -- is it same as no key??
hash_update_blake2b(ctx, "The q")
hash_update_blake2b(ctx, "uick brown fox jumps over the lazy dog")
dig55 = hash_final_blake2b(ctx)
assert(dig51==dig55)


------------------------------------------------------------------------
-- x25519 tests

print("testing x25519 key exchange...")

apk, ask = crypto.keygen_session_x25519() -- alice keypair
bpk, bsk = crypto.keygen_session_x25519() -- bob keypair
assert(apk == crypto.pubkey_session_x25519(ask))

k1 = crypto.exchange_session_x25519(ask, bpk)
k2 = crypto.exchange_session_x25519(bsk, apk)
assert(k1 == k2)


------------------------------------------------------------------------
-- ed25519 signature tests

print("testing ed25519 signature...")

t = "The quick brown fox jumps over the lazy dog"

pk, sk = crypto.keygen_sign_ed25519() -- signature keypair
assert(pk == crypto.pubkey_sign_ed25519(sk))

sig = crypto.sign_ed25519(sk, pk, t)
assert(#sig == 64)
--~ px(sig, 'sig')

-- check signature
assert(crypto.check_ed25519(sig, pk, t))

-- modified text doesn't check
assert(not crypto.check_ed25519(sig, pk, t .. "!"))


------------------------------------------------------------------------
-- password derivation argon2i tests

print("testing argon2i...")

pw = "hello"
salt = "salt salt salt"
k = ""
-- c0 = os.clock()
k = crypto.kdf_argon2i(pw, salt, 1000, 3)
assert(#k == 32)
assert(encode_b64(k) == "UvEmGTUztnx7XDjZ0uIjg8E8d0Le6NHoZPqGBizo/ms=")
print("argon2i (1MB, 3 iter)")
-- print("Execution time (sec): ", os.clock()-c0)


------------------------------------------------------------------------
------------------------------------------------------------------------
print("test_luazen", "ok")
