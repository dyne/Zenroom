print "ZENCODE GENERIC DATA MANIPULATION TESTS"

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
rule input encoding string
Given I have a 'inside' inside 'first'
and I have a 'third'
When I write string 'first.inside' in 'test'
and I write string 'three' in 'tertiur'
and I verify 'third' is equal to 'tertiur'
Then print the 'test' as 'string'
]])
ZEN:run()

print "OK: INSIDE, STRING EQUALITY"

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

print "OK: RANDOM ECP ARRAY CREATION, AGGREGATION"


ZEN:begin()
ZEN:parse([[
rule check version 1.0.0
Given nothing
When I create the array of '32' random objects of '256' bits
and I pick the random object in 'array'
and I remove the 'random object' from 'array'
and the 'random object' is not found in 'array'
Then print the 'random object'
]])
ZEN:run()


ZEN:begin()
ZEN:parse([[
rule check version 1.0.0
Given nothing
When I set 'whole' to 'Zenroom works great' as 'string'
and I split the leftmost '3' bytes of 'whole'
Then print the 'leftmost' as 'string'
and print the 'whole' as 'string'
]])
ZEN:run()

print "OK: RANDOM OBJECT ARRAY CREATE, RANDOM PICK, REMOVE"

