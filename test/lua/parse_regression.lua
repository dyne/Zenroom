local max_line = 1024

assert(parse_prefix("   Given   the data") == "given")
assert(parse_prefix(string.rep("a", max_line - 1)) == string.rep("a", max_line - 1))
assert(parse_prefix(string.rep("a", max_line)) == string.rep("a", max_line))
assert(parse_prefix(string.rep("a", max_line + 1)) == nil)

local ok, err = pcall(normalize_zencode_statement, string.rep("a", max_line + 1), "given")
assert(not ok)
assert(type(err) == "string" and #err > 0)
