-- Test dictionary and array detection

dict = { pippo = "dog",
	 pluto = "dog",
	 paperino = "duck",
	 topolino = "mouse" }

arr = { "one", "two", "three", "four", "five" }

ele = "single element"

for k, v in pairs(arr) do -- check that all keys are numbers
   assert(luatype(k) == "number", "array index not a number")
end
for k, v in pairs(dict) do
   assert(luatype(k) == "string", "dictionary index not a string")
end


assert(isarray(arr), "isarray() error: can't recognize array")
assert(not isarray(dict), "isarray() error: mismatch dictionary for array")
assert(not isarray(ele), "isarray() error: mismatch element for array")


assert(isdictionary(dict), "isdictionary() error: can't recognize dictionary")
assert(not isdictionary(arr), "isdictionary() error: mismatch array for dictionary")
assert(not isdictionary(ele), "isdictionary() error: mismatch element for dictionary")
