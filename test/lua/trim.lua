LEN = 64
local r = O.from_hex("72f400a8ce6284d9b3ee98bcc48828fbb3b1cb26076190d06aa0504ec26619de2a1845668335a755fa743a00e5089ebf53fc870b73370b43d514e287e20d200d")
assert(r:trim() == r)

local zero = O.from_hex("0000")
local a = zero..zero..r..zero
assert(a:trim() == r)

local c = zero..r
assert(c:trim() == r)

local one = O.from_hex("01")
local b = one..r
assert(b:trim() ~= r)
