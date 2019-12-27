DATA = [[
[
  { "first" : { "inside" : "first.inside" } },
  { "second" : { "inside" : "second.inside" } },
  { "third" : "three" }
]
]]

ZEN:begin(3)
ZEN:parse([[
rule check version 1.0.0
rule input untagged
Given I have a 'inside' inside 'first'
and I have a 'third'
When I write 'first.inside' in 'test'
and I write 'three' in 'tertiur'
and I verify 'inside' is equal to 'test'
and I verify 'third' is equal to 'tertiur'
Then print the 'inside' as 'string'
]])
ZEN:run()
