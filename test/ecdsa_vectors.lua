
print "ECDSA vector tests for SECP256K1"
-- test vectors from org.bouncycastle.crypto.test.ECTest.testECDSASecP224k1sha256()

-- output encoding configuration
CONF.output.encoding.fun = hex

d = hex('ebb2c082fd7727890a28ac82f6bdf97bad8de9f5d7c9028692de1a255cad3e0f')
k = hex('49a0d7b786ec9cde0d0721d72804befd06571c974b191efb42ecf322ba9ddd9a')
M = hex('4b688df40bcedbe641ddb16ff0a1842d9c67ea1c3bf63f3e0471baa664531d1a')

kp = ECDH.new('secp256k1')
kp:private(d)
x, y = kp:public_xy()
assert(x == hex('779dd197a5df977ed2cf6cb31d82d43328b790dc6b3b7d4437a427bd5847dfcd'),
	   "ECDSA vectors for curve secp256k1 mismatch on x")
assert(y == hex('e94b724a555b6d017bb7607c3e3281daf5b1699d6ef4124975c9237b917d426f'),
	   "ECDSA vectors for curve secp256k1 mismatch on y")

S = kp:sign(M, k)

assert(S.r == hex('241097efbf8b63bf145c8961dbdf10c310efbb3b2676bbc0f8b08505c9e2f795'),
	   "ECDSA vectors for curve secp256k1 mismatch on S.r")
assert(S.s == hex('139c98ddeba50a63bbc95014a47ba1779db5ac846a85eee69bbd95b58bc96044'),
	   "ECDSA vectors for curve secp256k1 mismatch on S.s")

-- I.print({ d = d,
-- 		  k = k,
-- 		  M = M,
-- 		  x = x,
-- 		  y = y,
-- 		  P = kp:public(),
-- 		  r = S.r,
-- 		  s = S.s })
print "-- OK"
