local function assert_error(fn, suffix)
    local ok, err = pcall(fn)
    assert(not ok, "Expected failure")
    assert(err:sub(-#suffix) == suffix, "Error: " .. err)
end

assert(tostring(TIME.new(-2147483648)) == "-2147483648")
assert(tostring(TIME.new(2147483648)) == "2147483648")
assert(tostring(TIME.new("9223372036854775807")) == "9223372036854775807")

assert_error(function() TIME.new(1.2) end, "Could not read unix timestamp 1.2")
assert_error(function() TIME.new("1e3") end, "Could not read unix timestamp 1e3")
