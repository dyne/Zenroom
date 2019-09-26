-- Example demonstrating how to manipulate complex data structures
-- (called tables) and convert them back and forth to JSON strings

-- using the "inspection module" to print contents of complex data
-- structures: inside.print() instead of print()

-- this converts the JSON string to a table on which various
-- operations can be done (see @tables and @functions modules)
superheroes = JSON.decode(DATA)

-- iterate through the members array and print
-- out only names. ipairs is very unelegand
print "import from JSON"
I.print(superheroes)

print "flatten tree"
superflat = flatten(superheroes)
I.print(superflat)

