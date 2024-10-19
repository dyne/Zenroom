LEN = 64
hash = HASH.new('sha3_512')

print '== test octet XOR'
a = OCTET.random(LEN)
b = OCTET.random(LEN/2) -- test xor with different length
c = TIME.new(os.time())

-- I.print({a=a,b=b,c=c:octet():pad(64)})

assert(a ~ b == b ~ a)
assert(c ~ b == b ~ c)
assert(c ~ a == a ~ c)

b = OCTET.random(LEN)
assert(a ~ b == b ~ a)
assert(c ~ b == b ~ c)
assert(c ~ a == a ~ c)

c = TIME.new(os.time())
-- I.print({a=a,b=b,c=c:octet():pad(64)})

assert(a ~ b ~ c == a ~ c ~ b)
assert(b ~ a ~ c == b ~ c ~ a)
assert(c ~ a ~ b == c ~ b ~ a)

assert(hash:process(a ~ b) == hash:process(b ~ a))

assert(hash:process(c ~ b) == hash:process(b ~ c))

print '== test octet AND'
a = OCTET.random(LEN)
b = OCTET.random(LEN/2)
c = TIME.new(os.time())

assert(a & b == b & a)
assert(c & b == b & c)
assert(c & a == a & c)

b = OCTET.random(LEN)
assert(a & b == b & a)
assert(c & b == b & c)
assert(c & a == a & c)

c = TIME.new(os.time())

assert(a & b & c == a & c & b)
assert(b & a & c == b & c & a)
assert(c & a & b == c & b & a)

assert(hash:process(a & b) == hash:process(b & a))

assert(hash:process(c & b) == hash:process(b & c))

print '== test octet OR'
a = OCTET.random(LEN)
b = OCTET.random(LEN/2)
c = TIME.new(os.time())

assert(a | b == b | a)
assert(c | b == b | c)
assert(c | a == a | c)

b = OCTET.random(LEN)
assert(a | b == b | a)
assert(c | b == b | c)
assert(c | a == a | c)

c = TIME.new(os.time())

assert(a | b | c == a | c | b)
assert(b | a | c == b | c | a)
assert(c | a | b == c | b | a)

assert(hash:process(a | b) == hash:process(b | a))

assert(hash:process(c | b) == hash:process(b | c))


print '== test octet NOT'
a = OCTET.random(LEN)
b = OCTET.random(LEN/2)

assert(~(~a) == a)
assert(~(~b) == b)

b = OCTET.random(LEN)

assert(~(a & b) == ~a | ~b)
assert(~(a | b) == ~a & ~b)

print '= OK'
