local function expect_error(label, expected, fn)
   local ok, err = pcall(fn)
   assert(not ok, label .. ': expected failure')
   local actual = tostring(err)
   assert(actual:find(expected, 1, true),
      label .. ': expected "' .. expected .. '" in "' .. actual .. '"')
end

assert(ZEN.given_steps['nothing'], "expected built-in GIVEN statement 'nothing'")
assert(ZEN.then_steps['print data'], "expected built-in THEN statement 'print data'")

expect_error('when duplicate', 'Conflicting WHEN statement loaded by scenario: duplicate when', function()
   When('Duplicate When', function() end)
   When('duplicate when', function() end)
end)

expect_error('ifwhen duplicate across when', 'Conflicting IF-WHEN statement loaded by scenario: shared ifwhen', function()
   When('Shared IfWhen', function() end)
   IfWhen('shared ifwhen', function() end)
end)

expect_error('foreach duplicate', 'Conflicting FOREACH statement loaded by scenario: duplicate foreach', function()
   Foreach('Duplicate Foreach', function() end)
   Foreach('duplicate foreach', function() end)
end)

print('statement registration regressions OK')
