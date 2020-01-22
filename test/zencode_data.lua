DATA = [[
[
  { "first" : { "inside" : "first.inside" } },
  { "second" : { "inside" : "second.inside" } },
  { "third" : "three" }
]
]]

ZEN:begin()
ZEN:parse([[
rule check version 1.0.0
rule input untagged
Given I have a 'inside' inside 'first'
and I have a 'third'
When I write 'first.inside' in 'test'
and I write 'three' in 'tertiur'
# and I verify 'inside' is equal to 'test'
and I verify 'third' is equal to 'tertiur'
Then print the 'test' as 'string'
]])
ZEN:run()

DATA = nil

ZEN:begin()
ZEN:parse([[
rule check version 1.0.0
Given nothing
When I create the array of '64' random curve points
and I create the aggregation of 'array'
Then print the 'aggregation'
]])
ZEN:run()
