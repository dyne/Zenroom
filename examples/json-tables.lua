-- Example demonstrating how to manipulate complex data structures
-- (called tables) and convert them back and forth to JSON strings

-- using the "inspection module" to print contents of complex data
-- structures: inside.print() instead of print()

-- this converts the JSON string to a table on which various
-- operations can be done (see @tables and @functions modules)
superheroes = JSON.decode(DATA)

-- iterate through the members array and print
-- out only names. ipairs is very unelegand
print "procedural boredom"
for k,v in ipairs(superheroes['members']) do
   INSIDE.print(LAMBDA.at(v,"name"))
end

print "lambda fun."
-- let's try the functional / scheme way of doing things ;^)
INSIDE.print(
   LAMBDA.chain(superheroes['members'])
   :pluck("name")
   :value()
)

-- print out the json
-- print(
--    json.encode(superheroes['members'])
-- )
