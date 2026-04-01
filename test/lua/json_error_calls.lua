local function expect_error(label, expected, fn)
   local ok, err = pcall(fn)
   assert(not ok, label .. ': expected failure')
   local actual = tostring(err)
   assert(actual:find(expected, 1, true), label .. ': expected "' .. expected .. '" in "' .. actual .. '"')
end

expect_error('decode without argument', 'JSON.decode called without argument', function()
   JSON.decode()
end)

expect_error('decode empty string', 'JSON.decode argument is empty string', function()
   JSON.decode('')
end)

expect_error('auto unsupported type', 'JSON.auto unrecognised input type: boolean', function()
   JSON.auto(true)
end)

print('json error call regressions OK')
