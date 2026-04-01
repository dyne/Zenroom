local base = TIME.new(1)

assert(TIME.add(base, "2") == TIME.new(3))
assert(TIME.add(base, 2) == TIME.new(3))
assert(TIME.sub(TIME.new(5), "2") == TIME.new(3))
assert(TIME.sub(TIME.new(5), 2) == TIME.new(3))

assert(BIG.new(255):bytes() == 1)
assert(BIG.new(256):bytes() == 2)
assert(BIG.new(257):bytes() == 2)
