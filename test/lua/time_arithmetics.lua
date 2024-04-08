
local function assert_error(fn, e)
    local res, err = pcall(fn);
    assert(err:sub(-#e) == e, "Error: " .. err)
end

zero = TIME.new(0)
one  = TIME.new(1)
negative_one  = TIME.new(-1)
two  = TIME.new(2)
negative_two  = TIME.new(-2)
max  = TIME.new(2147483647)
min = TIME.new(-2147483647)
real_min = TIME.new("-2147483648")

-- sum test
assert(zero + zero == zero, "Error zero sum")
assert(one + one   == two, "Error one plus one")
assert(one + zero  == one, "Error one plus zero")
assert(one + negative_one   == zero, "Error one plus negative_one")
assert(max + min  == zero, "Error max plus min")
assert(min + max  == zero, "Error max plus min")
assert(max + real_min  == negative_one, "Error max plus real min")
assert(zero + real_min  == real_min, "Error zero plus real min")
assert(negative_one + min  == real_min, "Error negative_one plus min")

assert_error(function() local r = one + max end, "fatal time_add: Result of addition out of range")
assert_error(function() local r = negative_one + real_min end, "fatal time_add: Result of addition out of range")
assert_error(function() local r = max + max end, "fatal time_add: Result of addition out of range")
assert_error(function() local r = real_min + real_min end, "fatal time_add: Result of addition out of range")

-- sub test
assert(zero - zero == zero, "Error zero sub")
assert(one - one   == zero, "Error one minus one")
assert(one - zero  == one, "Error one minus zero")
assert(zero - one   == negative_one, "Error zero minus one")
assert(one - negative_one   == two, "Error one minus negative_one")
assert(negative_one - one   == negative_two, "Error negative_one minus one")
assert(max - max  == zero, "Error max minus min")
assert(min - min  == zero, "Error max minus min")
assert(real_min - real_min  == zero, "Error real min minus real min")
assert(zero - max == min, "Error zero minus real min")
assert(negative_one - max  == real_min, "Error negative_one minus min")

assert_error(function() local r = real_min - one  end, "fatal time_sub: Result of subtraction out of range")
assert_error(function() local r = max - negative_one end, "fatal time_sub: Result of subtraction out of range")
assert_error(function() local r = max - min end, "fatal time_sub: Result of subtraction out of range")
assert_error(function() local r = min - max end, "fatal time_sub: Result of subtraction out of range")

-- opposite test
assert(-zero == zero, "Error zero opposite")
assert(-one  == negative_one, "Error one opposite")
assert(-two  == negative_two, "Error two opposite")
assert(-max  == min, "Error max opposite")
assert(-min  == max, "Error min opposite")
