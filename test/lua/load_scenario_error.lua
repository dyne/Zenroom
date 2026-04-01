local function expect_error(label, expected, fn)
   local ok, err = pcall(fn)
   assert(not ok, label .. ': expected failure')
   local actual = tostring(err)
   assert(not actual:find('Could not allocate message to show', 1, true),
      label .. ': lost error context: ' .. actual)
   assert(actual:find(expected, 1, true),
      label .. ': expected "' .. expected .. '" in "' .. actual .. '"')
end

expect_error('missing module', 'required extension not found: definitely_missing_module', function()
   require_once('definitely_missing_module')
end)

print('protected require error regressions OK')
