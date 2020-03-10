# Functional programming on complex data structures in Zenroom

The LAMBDA module is an extension which provides support for
functional programming.  It provides common operations on tables,
arrays, lists, collections, objects, and a lot more.

The LAMBDA module is a slight adaptation of __Moses__, which is also
deeply inspired by Underscore.js.

# <a name='TOC'>Table of Contents</a>

* [Table functions](#table)
* [Array functions](#array)
* [Utility functions](#utility)
* [Object functions](#object)
* [Chaining](#chaining)
* [Import](#import)

# <a name='adding'>Adding the functional module to your script</a>

A large set of functions that can be classified into four categories:

* __Table functions__, which are mostly meant for tables, i.e Lua tables which contains both an array-part and a hash-part,
* __Array functions__, meant for array lists (or sequences),
* __Utility functions__,
* __Object functions__.

**[🔝](#TOC)**

## <a name='table'>Table functions</a>

### clear (t)

Clears a table. All its values becomes nil. It returns the passed-in table.

```lua
local t = LAMBDA.clear({1,2,'hello',true}) -- => {}
```

### each (t, f, ...)
*Aliases: `LAMBDA.forEach`*.

Iterates over each key-value pair in table.

```lua
LAMBDA.each({1,2,3},print)

-- => 1 1
-- => 2 2
-- => 3 3
```

The table can be map-like (array part and hash-part).

```lua
LAMBDA.each({one = 1, two = 2, three = 3},print)

-- => one 1
-- => two 2
-- => three 3
```

Can index and assign in an outer table or in the passed-in table:

```lua
t = {'a','b','c'}
LAMBDA.each(t,function(i,v)
  t[i] = v:rep(2)
  print(t[i])
end)

-- => 1 aa
-- => 2 bb
-- => 3 cc
```

### eachi (t, f, ...)
*Aliases: `LAMBDA.forEachi`*.

Iterates only on integer keys in a sparse array table.

```lua
LAMBDA.eachi({1,2,3},print)

-- => 1 1
-- => 2 2
-- => 3 3
```

The given array can be sparse, or even have a hash-like part.

```lua
local t = {a = 1, b = 2, [0] = 1, [-1] = 6, 3, x = 4, 5}
LAMBDA.eachi(t,function(i,v)
  print(i,v)
end)

-- => -1 6
-- => 0	1
-- => 1	3
-- => 2	5
```

### at (t, ...)

Collects all values at some specific keys and returns them in an array.

```lua
local t = {4,5,6}
LAMBDA.at(t,1,3) -- => "{4,6}"

local t = {a = 4, bb = true, ccc = false}
LAMBDA.at(t,'a', 'ccc') -- => "{4, false}"
```

### count (t, value)

Counts the number of occurences of a given value in a table.

```lua
LAMBDA.count({1,1,2,3,3,3,2,4,3,2},1) -- => 2
LAMBDA.count({1,1,2,3,3,3,2,4,3,2},2) -- => 2
LAMBDA.count({1,1,2,3,3,3,2,4,3,2},3) -- => 4
LAMBDA.count({false, false, true},false) -- => 2
LAMBDA.count({false, false, true},true) -- => 1
```

Returns the size of the list in case no value was provided.

```lua
LAMBDA.count({1,1,2,3,3}) -- => 5
```

### countf (t, f, ...)

Count the number of occurences of all values passing an iterator test.

```lua
LAMBDA.countf({1,2,3,4,5,6}, function(i,v)
  return v%2==0
end) -- => 3

LAMBDA.countf({print, pairs, os, assert, ipairs}, function(i,v)
  return type(v)=='function'
end) -- => 4
```

### cycle (t, n)
*Aliases: `LAMBDA.loop`*.

Returns a function which iterates on each key-value pair in a given table (similarly to `LAMBDA.each`), except that it restarts iterating again `n` times.
If `n` is not provided, it defaults to 1.

```lua
local t = {'a,'b','c'}
for k,v in LAMBDA.cycle(t, 2) do
  print(k,v)
end

-- => 1 'a'
-- => 2 'b'
-- => 3 'c'
-- => 1 'a'
-- => 2 'b'
-- => 3 'c'
```

Supports array-like tables and map-like tables.

```lua
local t = {x = 1, y = 2, z = 3}
for k,v in LAMBDA.cycle(t) do
  print(k,v)
end

-- => y	2
-- => x	1
-- => z	3
```

### map (t, f, ...)
*Aliases: `LAMBDA.collect`*.

Executes a function on each key-value pairs.

```lua
LAMBDA.map({1,2,3},function(i,v) 
  return v+10 
end) -- => "{11,12,13}"
```

```lua
LAMBDA.map({a = 1, b = 2},function(k,v) 
  return k..v 
end) -- => "{a = 'a1', b = 'b2'}"
```

It also maps key-value pairs to key-value pairs

```lua
LAMBDA.map({a = 1, b = 2},function(k,v) 
  return k..k, v*2 
end) -- => "{aa = 2, bb = 4}"
```

### reduce (t, f, state)
*Aliases: `LAMBDA.inject`, `LAMBDA.foldl`*.

Can sums all values in a table.

```lua
LAMBDA.reduce({1,2,3,4},function(memo,v)
  return memo+v 
end) -- => 10
```

Or concatenates all values.

```lua	
LAMBDA.reduce({'a','b','c','d'},function(memo,v) 
  return memo..v 
end) -- => abcd	 
```

### reduceby (t, f, state, pred, ...)

Reduces a table considering only values matching a predicate.
For example,let us define a set of values.

```lua
local val = {-1, 8, 0, -6, 3, -1, 7, 1, -9}
```
We can also define some predicate functions.

```lua
-- predicate for negative values
local function neg(_, v) return v<=0 end

-- predicate for positive values
local function pos(_, v) return v>=0 end
```

Then we can perform reduction considering only negative values :

```lua
LAMBDA.reduceby(val, function(memo,v)
  return memo+v
end, 0, neg) -- => -17
```

Or only positive values :

```lua
LAMBDA.reduceby(val, function(memo,v)
  return memo+v
end, 0, pos) -- => 19
```

### reduceRight (t, f, state)
*Aliases: `LAMBDA.injectr`, `LAMBDA.foldr`*.

Similar to `LAMBDA.reduce`, but performs from right to left.

```lua
local initial_state = 256
LAMBDA.reduceRight({1,2,4,16},function(memo,v) 
  return memo/v 
end,initial_state) -- => 2
```

### mapReduce (t, f, state)
*Aliases: `LAMBDA.mapr`*.

Reduces while saving intermediate states.

```lua
LAMBDA.mapReduce({'a','b','c'},function(memo,v) 
  return memo..v 
end) -- => "{'a', 'ab', 'abc'}"
```

### mapReduceRight (t, f, state)
*Aliases: `LAMBDA.maprr`*.

Reduces from right to left, while saving intermediate states.

```lua
LAMBDA.mapReduceRight({'a','b','c'},function(memo,v) 
  return memo..v 
end) -- => "{'c', 'cb', 'cba'}"
```

### include (t, value)
*Aliases: `LAMBDA.any`, `LAMBDA.some`, `LAMBDA.contains`*.

Looks for a value in a table.

```lua
LAMBDA.include({6,8,10,16,29},16) -- => true
LAMBDA.include({6,8,10,16,29},1) -- => false

local complex_table = {18,{2,{3}}}
local collection = {6,{18,{2,6}},10,{18,{2,{3}}},29}
LAMBDA.include(collection, complex_table) -- => true
```

Handles iterator functions.

```lua
local function isUpper(v) return v:upper()== v end
LAMBDA.include({'a','B','c'},isUpper) -- => true
```

### detect (t, value)

Returns the index of a value in a table.

```lua
LAMBDA.detect({6,8,10,16},8) -- => 2
LAMBDA.detect({nil,true,0,true,true},false) -- => nil

local complex_table = {18,{2,6}}
local collection = {6,{18,{2,6}},10,{18,{2,{3}}},29}
LAMBDA.detect(collection, complex_table) -- => 2
```

Handles iterator functions.

```lua
local function isUpper(v)
  return v:upper()==v
end
LAMBDA.detect({'a','B','c'},isUpper) -- => 2
```

### where (t, props)

Looks through a table and returns all the values that matches all of the key-value pairs listed in `props`. 

```lua
local tA = {a = 1, b = 2, c = 0}
local tB = {a = 1, b = 4, c = 1}
local tC = {a = 4, b = 4, c = 3}
local tD = {a = 1, b = 2, c = 3}
local found = LAMBDA.where({tA, tB, tC, tD}, {a = 1})

-- => found = {tA, tB, tD}

found = LAMBDA.where({tA, tB, tC, tD}, {b = 4})

-- => found = {tB, tC}

found = LAMBDA.where({tA, tB, tC, tD}, {b = 4, c = 3})

-- => found = {tC}
```

### findWhere (t, props)

Looks through a table and returns the first value that matches all of the key-value pairs listed in `props`. 

```lua
local a = {a = 1, b = 2, c = 3}
local b = {a = 2, b = 3, d = 4}
local c = {a = 3, b = 4, e = 5}
LAMBDA.findWhere({a, b, c}, {a = 3, b = 4}) == c -- => true
```

### select (t, f, ...)
*Aliases: `LAMBDA.filter`*.

Collects values passing a validation test.

```lua
-- Even values
LAMBDA.select({1,2,3,4,5,6,7}, function(key,value) 
  return (value%2==0)
end) -- => "{2,4,6}"

-- Odd values
LAMBDA.select({1,2,3,4,5,6,7}, function(key,value) 
  return (value%2~=0)
end) -- => "{1,3,5,7}"
```

### reject (t, f, ...)
*Aliases: `LAMBDA.reject`*.

Removes all values failing a validation test:

```lua
LAMBDA.reject({1,2,3,4,5,6,7}, function(key,value) 
  return (value%2==0)
end) -- => "{1,3,5,7}"

LAMBDA.reject({1,2,3,4,5,6,7}, function(key,value) 
  return (value%2~=0)
end) -- => "{2,4,6}"
```

### all (t, f, ...)
*Aliases: `LAMBDA.every`*.

Checks whether or not all elements pass a validation test.

```lua
LAMBDA.all({2,4,6}, function(key,value) 
  return (value%2==0)
end) -- => true
```

### invoke (t, method, ...)

Invokes a given function on each value in a table

```lua
LAMBDA.invoke({'a','bea','cdhza'},string.len) -- => "{1,3,5}"
```

Can reference the method of the same name in each value.

```lua
local a = {}
function a:call() return 'a' end
local b, c, d = {}, {}, {}
b.call, c.call, d.call = a.call, a.call, a.call

LAMBDA.invoke({a,b,c,d},'call') -- => "{'a','a','a','a'}"
```

### pluck (t, property)

Fetches all values indexed with specific key in a table of objects.

```lua
local peoples = {
  {name = 'John', age = 23},{name = 'Peter', age = 17},
  {name = 'Steve', age = 15},{age = 33}}

LAMBDA.pluck(peoples,'age') -- => "{23,17,15,33}"
LAMBDA.pluck(peoples,'name') -- => "{'John', 'Peter', 'Steve'}"
```

### max (t, transform, ...)

Returns the maximum value in a collection.

```lua
LAMBDA.max {1,2,3} -- => 3
LAMBDA.max {'a','b','c'} -- => 'c'
```

Can take an iterator function to extract a specific property.

```lua
local peoples = {
  {name = 'John', age = 23},{name = 'Peter', age = 17},
  {name = 'Steve', age = 15},{age = 33}}
LAMBDA.max(peoples,function(people) return people.age end) -- => 33
```

### min (t, transform, ...)

Returns the minimum value in a collection.

```lua
LAMBDA.min {1,2,3} -- => 1
LAMBDA.min {'a','b','c'} -- => 'a'
```

Can take an iterator function to extract a specific property.

```lua
local peoples = {
  {name = 'John', age = 23},{name = 'Peter', age = 17},
  {name = 'Steve', age = 15},{age = 33}}
LAMBDA.min(peoples,function(people) return people.age end) -- => 15
```

### shuffle (t, seed)

Shuffles a collection.

```lua
local list = LAMBDA.shuffle {1,2,3,4,5,6} -- => "{3,2,6,4,1,5}"
LAMBDA.each(list,print)
```

### same (a, b)

Tests whether or not all values in each of the passed-in tables exists in both tables.

```lua
local a = {'a','b','c','d'}      
local b = {'b','a','d','c'}
LAMBDA.same(a,b) -- => true

b[#b+1] = 'e'
LAMBDA.same(a,b) -- => false
```

### sort (t, comp)

Sorts a collection.

```lua
LAMBDA.sort({'b','a','d','c'}) -- => "{'a','b','c','d'}"
```

Handles custom comparison functions.

```lua
LAMBDA.sort({'b','a','d','c'}, function(a,b) 
  return a:byte() > b:byte() 
end) -- => "{'d','c','b','a'}"
```

### sortBy (t, transform, comp)

Sorts items in a collection based on the result of running a transform function through every item in the collection.

```lua
local r = LAMBDA.sortBy({1,2,3,4,5}, math.sin)
print(table.concat(r,','))

-- => {5,4,3,1,2}
```

The transform function can also be a string name property.

```lua
local people ={
	{name = 'albert', age = 40},
	{name = 'louis', age = 55},
	{name = 'steve', age = 35},
	{name = 'henry', age = 19},
}
local r = LAMBDA.sortBy(people, 'age')
LAMBDA.each(r, function(__,v) print(v.age, v.name)	end)

-- => 19	henry
-- => 35	steve
-- => 40	albert
-- => 55	louis
```

As seen above, the defaut comparison function is the '<' operator. For example, let us supply a different one to sort
the list of people by decreasing age order :

```lua
local people ={
	{name = 'albert', age = 40},
	{name = 'louis', age = 55},
	{name = 'steve', age = 35},
	{name = 'henry', age = 19},
}
local r = LAMBDA.sortBy(people, 'age', function(a,b) return a > b end)
LAMBDA.each(r, function(__,v) print(v.age, v.name)	end)

-- => 55	louis
-- => 40	albert
-- => 35	steve
-- => 19	henry
```

The `transform` function defaults to `LAMBDA.indentity` and in that case, `LAMBDA.sortBy` behaves like `LAMBDA.sort`.

```lua
local r = LAMBDA.sortBy({1,2,3,4,5})
print(table.concat(r,','))

-- => {1,2,3,4,5}
```

### groupBy (t, iter, ...)

Groups values in a collection depending on their return value when passed to a predicate test.

```lua
LAMBDA.groupBy({0,1,2,3,4,5,6},function(i,value) 
  return value%2==0 and 'even' or 'odd'
end) -- => "{odd = {1,3,5}, even = {0,2,4,6}}"

LAMBDA.groupBy({0,'a',true, false,nil,b,0.5},function(i,value) 
  return type(value) 
end) -- => "{number = {0,0.5}, string = {'a'}, boolean = {true, false}}"		
```

### countBy (t, iter, ...)

Splits a table in subsets and provide the count for each subset.

```lua
LAMBDA.countBy({0,1,2,3,4,5,6},function(i,value) 
  return value%2==0 and 'even' or 'odd'
end) -- => "{odd = 3, even = 4}"
```

### size (...)

When given a table, provides the count for the very number of values in that table.

```lua
LAMBDA.size {1,2,3} -- => 3
LAMBDA.size {one = 1, two = 2} -- => 2
```

When given a vararg list of argument, returns the count of these arguments.

```lua
LAMBDA.size(1,2,3) -- => 3
LAMBDA.size('a','b',{}, function() end) -- => 4
```

### containsKeys (t, other)

Checks whether a table has all the keys existing in another table.

```lua
LAMBDA.contains({1,2,3,4},{1,2,3}) -- => true
LAMBDA.contains({1,2,'d','b'},{1,2,3,5}) -- => true
LAMBDA.contains({x = 1, y = 2, z = 3},{x = 1, y = 2}) -- => true
```

### sameKeys (tA, tB)

Checks whether both tables features the same keys:

```lua
LAMBDA.sameKeys({1,2,3,4},{1,2,3}) -- => false
LAMBDA.sameKeys({1,2,'d','b'},{1,2,3,5}) -- => true
LAMBDA.sameKeys({x = 1, y = 2, z = 3},{x = 1, y = 2}) -- => false
```

**[🔝](#TOC)**

## <a name='array'>Array functions</a>

### sample (array, n, seed)

Samples `n` values from array.

```lua
local array = LAMBDA.range(1,20)
local sample = LAMBDA.sample(array, 3)
print(table.concat(sample,','))

-- => {12,11,15}
```

`n` defaults to 1. In that case, a single value will be returned.

```lua
local array = LAMBDA.range(1,20)
local sample = LAMBDA.sample(array)
print(sample)

-- => 12
```

An optional 3rd argument `seed` can be passed for deterministic random sampling.

### sampleProb (array, prob, seed)

Returns an array of values randomly selected from a given array.
In case `seed` is provided, it is used for deterministic sampling.

```lua
local array = LAMBDA.range(1,20)
local sample = LAMBDA.sampleProb(array, 0.2)
print(table.concat(sample,','))

-- => 5,11,12,15

sample = LAMBDA.sampleProb(array, 0.2, os.time())
print(table.concat(sample,','))

-- => 1,6,10,12,15,20 (or similar)
```

### toArray (...)

Converts a vararg list of arguments to an array.

```lua
LAMBDA.toArray(1,2,8,'d','a',0) -- => "{1,2,8,'d','a',0}"
```

### find (array, value, from)

Looks for a value in a given array and returns the position of the first occurence.

```lua
LAMBDA.find({{4},{3},{2},{1}},{3}) -- => 2
```

It can also start the search at a specific position in the array:

```lua
-- search value 4 starting from index 3
LAMBDA.find({1,4,2,3,4,5},4,3) -- => 5
```

### reverse (array)

Reverses an array.

```lua
LAMBDA.reverse({1,2,3,'d'}) -- => "{'d',3,2,1}"
```

### fill (array, value, i, j)

Replaces all elements in a given array with a given value.

```lua
local array = LAMBDA.range(1,5)
LAMBDA.fill(array, 0) -- => {0,0,0,0,0}
```

It can start replacing value at a specific index.

```lua
local array = LAMBDA.range(1,5)
LAMBDA.fill(array,0,3) -- => {1,2,0,0,0}
```

It can replace only values within a specific range.

```lua
local array = LAMBDA.range(1,5)
LAMBDA.fill(array,0,2,4) -- => {1,0,0,0,5}
```

In case the upper bound index i greather than the array size, it will enlarge the array.

```lua
local array = LAMBDA.range(1,5)
LAMBDA.fill(array,0,5,10) -- => {1,2,3,4,0,0,0,0,0,0}
```

### selectWhile (array, f, ...
*Aliases: `LAMBDA.takeWhile`*.

Collects values as long as they pass a given test. Stops on the first non-passing test.

```lua
LAMBDA.selectWhile({2,4,5,8}, function(i,v)
  return v%2==0
end) -- => "{2,4}"
```

### dropWhile (array, f, ...
*Aliases: `LAMBDA.rejectWhile`*.

Removes values as long as they pass a given test. Stops on the first non-passing test.

```lua
LAMBDA.dropWhile({2,4,5,8}, function(i,v)
  return v%2==0
end) -- => "{5,8}"
```

### sortedIndex (array, value, comp, sort)

Returns the index at which a value should be inserted to preserve order.

```lua
LAMBDA.sortedIndex({1,2,3},4) -- => 4
```

Can take a custom comparison functions.

```lua
local comp = function(a,b) return a<b end
LAMBDA.sortedIndex({-5,0,4,4},3,comp) -- => 3
```

### indexOf (array, value)

Returns the index of a value in an array.

```lua
LAMBDA.indexOf({1,2,3},2) -- => 2
```

### lastIndexOf (array, value)

Returns the index of the last occurence of a given value in an array.

```lua
LAMBDA.lastIndexOf({1,2,2,3},2) -- => 3
```

### findIndex (array, predicate, ...)

Returns the first index at which a predicate passes a truth test.

```lua
local array = {1,2,3,4,5,6}
local function multipleOf3(__,v) return v%3==0 end
LAMBDA.findIndex(array, multipleOf3) -- => 3
```

### findLastIndex (array, predicate, ...)

Returns the last index at which a predicate passes a truth test.

```lua
local array = {1,2,3,4,5,6}
local function multipleOf3(__,v) return v%3==0 end
LAMBDA.findLastIndex(array, multipleOf3) -- => 6
```

### addTop (array, ...)

Adds given values at the top of an array. The latter values bubbles at the top.

```lua
local array = {1}
LAMBDA.addTop(array,1,2,3,4) -- => "{4,3,2,1,1}"
```

### push (array, ...)

Adds given values at the end of an array.

```lua
local array = {1}
LAMBDA.push(array,1,2,3,4) -- => "{1,1,2,3,4}"
```

### pop (array, n)
*Aliases: `LAMBDA.shift`*.

Removes and returns the first value in an array.

```lua
local array = {1,2,3}
local pop = LAMBDA.pop(array) -- => "pop = 1", "array = {2,3}"
```

### unshift (array, n)

Removes and returns the last value in an array.

```lua
local array = {1,2,3}
local value = LAMBDA.unshift(array) -- => "value = 3", "array = {1,2}"
```

### pull (array, ...)
*Aliases: `LAMBDA.remove`*.

Removes all provided values from a given array.

```lua
LAMBDA.pull({1,2,1,2,3,4,3},1,2,3) -- => "{4}"
```

### removeRange (array, start, finish)
*Aliases: `LAMBDA.rmRange`, `LAMBDA.chop`*.

Trims out all values index within a range.

```lua
local array = {1,2,3,4,5,6,7,8,9}
LAMBDA.removeRange(array, 3,8) -- => "{1,2,9}"
```

### chunk (array, f, ...)

Iterates over an array aggregating consecutive values in subsets tables, on the basis of the return
value of `f(key,value,...)`. Consecutive elements which return the same value are aggregated together.

```lua
local t = {1,1,2,3,3,4}
LAMBDA.chunk(t, function(k,v) return v%2==0 end) -- => "{{1,1},{2},{3,3},{4}}"
```

### slice (array, start, finish)
*Aliases: `LAMBDA.sub`*.

Slices and returns a part of an array.

```lua
local array = {1,2,3,4,5,6,7,8,9}
LAMBDA.slice(array, 3,6) -- => "{3,4,5,6}"
```

### first (array, n)
*Aliases: `LAMBDA.head`, `LAMBDA.take`*.

Returns the first N elements in an array.

```lua
local array = {1,2,3,4,5,6,7,8,9}
LAMBDA.first(array,3) -- => "{1,2,3}"
```

### initial (array, n)

Excludes the last N elements in an array.

```lua
local array = {1,2,3,4,5,6,7,8,9}
LAMBDA.initial(array,5) -- => "{1,2,3,4}"
```

### last (array, n)
*Aliases: `LAMBDA.skip`*.

Returns the last N elements in an array.

```lua
local array = {1,2,3,4,5,6,7,8,9}
LAMBDA.last(array,3) -- => "{7,8,9}"
```

### rest (array, index)
*Aliases: `LAMBDA.tail`*.

Trims out all values indexed before *index*.

```lua
local array = {1,2,3,4,5,6,7,8,9}
LAMBDA.rest(array,6) -- => "{6,7,8,9}"
```

### nth (array, index)

Returns the value at *index*.

```lua
local array = {1,2,3,4,5,6}
LAMBDA.nth(array,3) -- => "3"
```

### compact (array)

Trims out all falsy values.

```lua
LAMBDA.compact {a,'aa',false,'bb',true} -- => "{'aa','bb',true}"
```

### flatten (array, shallow)

Flattens a nested array.

```lua
LAMBDA.flatten({1,{2,3},{4,5,{6,7}}}) -- => "{1,2,3,4,5,6,7}"
```

When given arg "shallow", flatten only at the first level.

```lua
LAMBDA.flatten({1,{2},{{3}}},true) -- => "{1,{2},{{3}}}"
```

### difference (array, array2)
*Aliases: `LAMBDA.without`, `LAMBDA.diff`*.

Returns values in the given array not present in a second array.

```lua
local array = {1,2,'a',4,5}
LAMBDA.difference(array,{1,'a'}) -- => "{2,4,5}"
```

### union (...)

Produces a duplicate-free union of all passed-in arrays.

```lua
local A = {'a'}
local B = {'a',1,2,3}
local C = {2,10}
LAMBDA.union(A,B,C) -- => "{'a',1,2,3,10}"
```

### intersection (array, ...)

Returns the intersection (common-part) of all passed-in arrays:

```lua
local A = {'a'}
local B = {'a',1,2,3}
local C = {2,10,1,'a'}
LAMBDA.intersection(A,B,C) -- => "{'a',2,1}"
```

### symmetricDifference (array, array2)
*Aliases: `LAMBDA.symdiff`,`LAMBDA.xor`*.

Returns values in the first array not present in the second and also values in the second array not present in the first one.

```lua
local array = {1,2,3}
local array2 = {1,4,5}
LAMBDA.symmetricDifference(array, array2) -- => "{2,3,4,5}"
```

### unique (array)
*Aliases: `LAMBDA.uniq`*.

Makes an array duplicate-free.

```lua
LAMBDA.unique {1,1,2,2,3,3,4,4,4,5} -- => "{1,2,3,4,5}"
```

### isunique (array)
*Aliases: `LAMBDA.isuniq`*.

Checks if a given array contains no duplicate value.

```lua
LAMBDA.isunique({1,2,3,4,5}) -- => true
LAMBDA.isunique({1,2,3,4,4}) -- => false
```

### zip (...)
*Aliases: `LAMBDA.transpose`*.

Zips values from different arrays, on the basis on their common keys.

```lua
local names = {'Bob','Alice','James'}
local ages = {22, 23}
LAMBDA.zip(names,ages) -- => "{{'Bob',22},{'Alice',23},{'James'}}"
```

### append (array, other)

Appends two arrays.

```lua
LAMBDA.append({1,2,3},{'a','b'}) -- => "{1,2,3,'a','b'}"
```

### interleave (...)

Interleaves values from passed-in arrays.

```lua
t1 = {1, 2, 3}
t2 = {'a', 'b', 'c'}
LAMBDA.interleave(t1, t2) -- => "{1,'a',2,'b',3,'c'}"
```

### interpose (value, array)

Interposes a value between consecutive values in an arrays.

```lua
LAMBDA.interleave('a', {1,2,3}) -- => "{1,'a',2,'a',3}"
```

### range (...)

Generates an arithmetic sequence.

```lua
LAMBDA.range(1,4) -- => "{1,2,3,4}"
```

In case a single value is provided, it generates a sequence from 0 to that value.

```
LAMBDA.range(3) -- => "{0,1,2,3}"
```

The incremental step can also be provided as third argument.

```lua
LAMBDA.range(0,2,0.7) -- => "{0,0.7,1.4}"
```

### rep (value, n)

Generates a list of n repetitions of a value.

```lua
LAMBDA.rep(4,3) -- => "{4,4,4}"
```

### partition (array, n, pad)
*Aliases: `LAMBDA.part`*.

Returns an iterator function for partitions of a given array.

```lua
local t = {1,2,3,4,5,6}
for p in LAMBDA.partition(t,2) do
  print(table.concat(p, ','))
end

-- => 1,2
-- => 3,4
-- => 5,6

local t = {1,2,3,4,5,6}
for p in LAMBDA.partition(t,4) do
  print(table.concat(p, ','))
end

-- => 1,2,3,4
-- => 5,6
```

In case the last partition has less elements than desired, a 3rd argument can be supplied to adjust the partition size.

```lua
local t = {1,2,3,4,5,6}
for p in LAMBDA.partition(t,4,0) do
  print(table.concat(p, ','))
end

-- => 1,2,3,4
-- => 5,6,0,0
```

### sliding (array, n, pad)

Returns an iterator function which provides overlapping subsequences of a given array.

```lua
local t = {1,2,3,4,5,6,7}
for p in LAMBDA.sliding(t,3) do
	print(table.concat(p,','))
end

-- => 1,2,3
-- => 3,4,5
-- => 5,6,7

for p in LAMBDA.sliding(t,4) do
	print(table.concat(p,','))
end

-- => 1,2,3,4
-- => 4,5,6,7

for p in LAMBDA.sliding(t,5) do
	print(table.concat(p,','))
end

-- => 1,2,3,4,5
-- => 5,6,7
```

In case the last subsequence wil not match the exact desired length, it can be adjusted with a 3rd argument `pad`.

```lua
local t = {1,2,3,4,5,6,7}
for p in LAMBDA.sliding(t,5,0) do
	print(table.concat(p,','))
end

-- => 1,2,3,4,5
-- => 5,6,7,0,0
```

### permutation (array)
*Aliases: `LAMBDA.perm`*.

Returns an iterator function for permutations of a given array.

```lua
t = {'a','b','c'}
for p in LAMBDA.permutation(t) do
  print(table.concat(p))
end

-- => 'bca'
-- => 'cba'
-- => 'cab'
-- => 'acb'
-- => 'bac'
-- => 'abc'
```

### invert (array)
*Aliases: `LAMBDA.mirror`*.

Switches <tt>key-value</tt> pairs:

```lua
LAMBDA.invert {'a','b','c'} -- => "{a=1, b=2, c=3}"
```

### concat (array, sep, i, j)
*Aliases: `LAMBDA.join`*.

Concatenates a given array values:

```lua
LAMBDA.concat({'a',1,0,1,'b'}) -- => 'a101b'
```

**[🔝](#TOC)**

## <a name='utility'>Utility functions</a>

### noop ()

The no-operation function. Takes nothing, returns nothing. It is being used internally.

```lua
LAMBDA.noop() -- => nil
```

### identity (value)

Returns the passed-in value. <br/>
This function is internally used as a default transformation function.

```lua
LAMBDA.identity(1)-- => 1
LAMBDA.identity(false) -- => false
LAMBDA.identity('hello!') -- => 'hello!'
```

### constant (value)

Creates a constant function. This function will continuously yield the same output.

```lua
local pi = LAMBDA.constant(math.pi)
pi(1) -- => 3.1415926535898
pi(2) -- => 3.1415926535898
pi(math.pi) -- => 3.1415926535898
```

### memoize (f, hash)
*Aliases: `LAMBDA.cache`*.

Memoizes a slow-running function. It caches the result for a specific input, so that the next time the function is called with the same input, it will lookup the result in its cache, instead of running again the function body.

```lua
local function fibonacci(n)
  return n < 2 and n or fibonacci(n-1)+fibonacci(n-2)
end  
local mem_fibonacci = LAMBDA.memoize(fibonacci)
fibonacci(20) -- => 6765 (but takes some time)
mem_fibonacci(20) -- => 6765 (takes less time)
```

### once (f)

Produces a function that runs only once. Successive calls to this function will still yield the same input.

```lua
local sq = LAMBDA.once(function(a) return a*a end)
sq(1) -- => 1
sq(2) -- => 1
sq(3) -- => 1
sq(4) -- => 1
sq(5) -- => 1
```

### before (f, count)

Returns a version of `f` that will run no more than `count` times. Next calls will keep yielding the results of the (n-th)-1 call.

```lua
local function greet(someone) return 'hello '..someone end
local greetOnly3people = LAMBDA.before(greet, 3)
greetOnly3people('John') -- => 'hello John'
greetOnly3people('Moe') -- => 'hello Moe'
greetOnly3people('James') -- => 'hello James'
greetOnly3people('Joseph') -- => 'hello James'
greetOnly3people('Allan') -- => 'hello James'
```

### after (f, count)

Produces a function that will respond only after a given number of calls.

```lua
local f = LAMBDA.after(LAMBDA.identity,3)
f(1) -- => nil
f(2) -- => nil
f(3) -- => 3
f(4) -- => 4
```

### compose (...)

Composes functions. Each function consumes the return value of the one that follows.

```lua
local function f(x) return x^2 end
local function g(x) return x+1 end
local function h(x) return x/2 end
local compositae = LAMBDA.compose(f,g,h)
compositae(10) -- => 36
compositae(20) -- => 121
```

### pipe (value, ...)

Pipes a value through a series of functions.

```lua
local function f(x) return x^2 end
local function g(x) return x+1 end
local function h(x) return x/2 end
LAMBDA.pipe(10,f,g,h) -- => 36
LAMBDA.pipe(20,f,g,h) -- => 121
```

### complement (f)

Returns a function which returns the logical complement of a given function.

```lua
LAMBDA.complement(function() return true end)() -- => false
```

### juxtapose (value, ...)
*Aliases: `LAMBDA.juxt`*.

Calls a sequence of functions with the same input.

```lua
local function f(x) return x^2 end
local function g(x) return x+1 end
local function h(x) return x/2 end
LAMBDA.juxtapose(10, f, g, h) -- => 100, 11, 5
```

### wrap (f, wrapper)

Wraps a function inside a wrapper. Allows the wrapper to execute code before and after function run.

```lua
local greet = function(name) return "hi: " .. name end
local greet_backwards = LAMBDA.wrap(greet, function(f,arg)
  return f(arg) ..'\nhi: ' .. arg:reverse()
end) 
greet_backwards('John')

-- => hi: John
-- => hi: nhoJ
```

### times (n, iter, ...)

Calls a given function `n` times.

```lua
local f = ('Lua programming'):gmatch('.')
LAMBDA.times(3,f) -- => {'L','u','a'}
```

### bind (f, v)

Binds a value to be the first argument to a function.

```lua
local sqrt2 = LAMBDA.bind(math.sqrt,2)
sqrt2() -- => 1.4142135623731
```

### bind2 (f, v)

Binds a value to be the second argument to a function.

```lua
local last2 = LAMBDA.bind(LAMBDA.last,2)
last2({1,2,3,4,5,6}) -- => {5,6}
```

### bindn (f, ...)

Binds a variable number of values to be the first arguments to a function.

```lua
local function out(...) return table.concat {...} end
local out = LAMBDA.bindn(out,'OutPut',':',' ')
out(1,2,3) -- => OutPut: 123
out('a','b','c','d') -- => OutPut: abcd
```

### bindAll (obj, ...)

Binds methods to object. As such, when calling any of these methods, they will receive object as a first argument.

```lua
local window = {
	setPos = function(w,x,y) w.x, w.y = x, y end, 
	setName = function(w,name) w.name = name end,
	getName = function(w) return w.name end,
}
window = LAMBDA.bindAll(window, 'setPos', 'setName', 'getName')
window.setPos(10,15)
print(window.x, window.y) -- => 10,15

window.setName('fooApp')
print(window.name) -- => 'fooApp'

print(window.getName()) -- => 'fooApp'
```

### uniqueId (template, ...)
*Aliases: `LAMBDA.uid`*.

Returns an unique integer ID.

```lua
LAMBDA.uniqueId() -- => 1
```

Can handle string templates for formatted output.

```lua
LAMBDA.uniqueId('ID%s') -- => 'ID2'
```

Or a function, for the same purpose.

```lua
local formatter = function(ID) return '$'..ID..'$' end
LAMBDA.uniqueId(formatter) -- => '$ID1$'
```

### iterator(f, x)
*Aliases: `LAMBDA.iter`*.

Returns an iterator function which constinuously applies a function `f` onto an input `x`.
For example, let us go through the powers of two.

```lua
local function po2(x) return x*2 end
local function iter_po2 = LAMBDA.iterator(po2, 1)
iter_po2() -- => 2
iter_po2() -- => 4
iter_po2() -- => 8
```

### array (...)

Iterates a given iterator function and returns its values packed in an array.

```lua
local text = 'letters'
local chars = string.gmatch(text, '.')
local letters = LAMBDA.array(chars) -- => {'l','e','t','t','e','r','s'}
```

### flip (f)

Creates a function of `f` with arguments flipped in reverse order.

```lua
local function f(...) return table.concat({...}) end
local flipped = LAMBDA.flip(f)
flipped('a','b','c') -- => 'cba'
```

### over (...)

Creates a function that invokes a set of transforms with the arguments it receives.<br/>
One can use use for example to get the tuple of min and max values from a set of values

```lua
local minmax = LAMBDA.over(math.min, math.max)
minmax(5,10,12,4,3) -- => {3,12}
```

### overEvery (...)

Creates a validation function. The returned function checks if all of the given predicates return truthy when invoked with the arguments it receives.

```lua
local function alleven(...) 
	for i, v in ipairs({...}) do 
		if v%2~=0 then return false end 
	end 
	return true 
end

local function allpositive(...)
	for i, v in ipairs({...}) do 
		if v < 0 then return false end 
	end 
	return true 	
end

local allok = LAMBDA.overEvery(alleven, allpositive)

allok(2,4,-1,8) -- => false
allok(10,3,2,6) -- => false
allok(8,4,6,10) -- => true
```

### overSome (...)

Creates a validation function. The returned function checks if any of the given predicates return truthy when invoked with the arguments it receives.

```lua
local function alleven(...) 
	for i, v in ipairs({...}) do 
		if v%2~=0 then return false end 
	end 
	return true 
end

local function allpositive(...)
	for i, v in ipairs({...}) do 
		if v < 0 then return false end 
	end 
	return true 	
end

local anyok = LAMBDA.overSome(alleven,allpositive)

anyok(2,4,-1,8) -- => false
anyok(10,3,2,6) -- => true
anyok(-1,-5,-3) -- => false
```

### overArgs (f, ...)

Creates a function that invokes `f` with its arguments transformed

```lua
local function f(x, y) return x, y end
local function triple(x) retun x*3 end
local function square(x) retun x^2 end
local new_f = LAMBDA.overArgs(f, triple, square)

new_f(1,2) -- => 3, 4
new_f(10,10) -- => 30, 100
```

In case the number of arguments is greater than the number of transforms, the remaining args will be left as-is.

```lua
local function f(x, y, z) return x, y, z end
local function triple(x) retun x*3 end
local function square(x) retun x^2 end
local new_f = LAMBDA.overArgs(f, triple, square)

new_f(1,2,3) -- => 3, 4, 3
new_f(10,10,10) -- => 30, 100, 10
```

### partial (f, ...)

Partially apply a function by filling in any number of its arguments. 

```lua
local function diff(a, b) return a - b end
local diffFrom20 = LAMBDA.partial(diff, 20) -- arg 'a' will be 20 by default
diffFrom20(5) -- => 15
```

The string `'_'` can be used as a placeholder in the list of arguments to specify an argument that should not be pre-filled, but is rather left open to be supplied at call-time.

```lua
local function diff(a, b) return a - b end
local remove5 = LAMBDA.partial(diff, '_', 5) -- arg 'a' will be given at call-time, but 'b' is set to 5
remove5(20) -- => 15
```

### partialRight (f, ...)

Like `LAMBDA.partial`, it partially applies a function by filling in any number of its arguments, but from the right.

```lua
local function concat(...) return table.concat({...},',') end
local concat_right = LAMBDA.partialRight(concat,'a','b','c')
concat_right('d') -- => d,a,b,c

concat_right = LAMBDA.partialRight(concat,'a','b')
concat_right('c','d') -- => c,d,a,b

concat_right = LAMBDA.partialRight(concat,'a')
concat_right('b','c','d') -- => b,c,d,a
```

The string `'_'`, as always, can be used as a placeholder in the list of arguments to specify an argument that should not be pre-filled, but is rather left open to be supplied at call-time.
In that case, the first args supplied at runtime will be used to fill the initial list of args while the remaining will be prepended.

```lua
local function concat(...) return table.concat({...},',') end
local concat_right = LAMBDA.partialRight(concat,'a','_','c')
concat_right('d','b') -- => b,a,d,c

concat_right = LAMBDA.partialRight(concat,'a','b','_')
concat_right('c','d') -- => d,a,b,c

concat_right = LAMBDA.partialRight(concat,'_','a')
concat_right('b','c','d') -- => c,d,b,a
```

### curry (f, n_args)

Curries a function. If the given function `f` takes multiple arguments, it returns another version of `f` that takes a single argument 
(the first of the arguments to the original function) and returns a new function that takes the remainder of the arguments and returns the result.

```lua
local function sumOf3args(x,y,z) return x + y + z end
local curried_sumOf3args = LAMBDA.curry(sumOf3args, 3)
sumOf3args(1)(2)(3)) -- => 6
sumOf3args(0)(6)(9)) -- => 15
```

`n_args` defaults to 2.

```lua
local function product(x,y) return x * y end
local curried_product = LAMBDA.curry(product)
curried_product(5)(4) -- => 20
curried_product(3)(-5) -- => -15
curried_product(0)(1) -- => 0
```

### time (f, ...)

Returns the execution time of `f (...)` in seconds and its results.

```lua
local function wait_count(n) 
	local i = 0
	while i < n do i = i + 1 end
	return i
end

local time, i = LAMBDA.time(wait_count, 1e6) -- => 0.002 1000000
local time, i = LAMBDA.time(wait_count, 1e7) -- => 0.018 10000000
```

**[🔝](#TOC)**

## <a name='object'>Object functions</a>

### keys (obj)

Collects the names of an object attributes.

```lua
LAMBDA.keys({1,2,3}) -- => "{1,2,3}"
LAMBDA.keys({x = 0, y = 1}) -- => "{'y','x'}"
```

### values (obj)

Collects the values of an object attributes.

```lua
LAMBDA.values({1,2,3}) -- => "{1,2,3}"
LAMBDA.values({x = 0, y = 1}) -- => "{1,0}"
```

### kvpairs (obj)

Converts an object to an array-list of key-value pairs.

```lua
local obj = {x = 1, y = 2, z = 3}
LAMBDA.each(LAMBDA.kvpairs(obj), function(k,v)
	print(k, table.concat(v,','))	
end)

-- => 1	y,2
-- => 2	x,1
-- => 3	z,3
```

### toObj

Converts an array list of `kvpairs` to an object where keys are taken from the 1rst column in the `kvpairs` sequence, associated with values in the 2nd column.

```lua
local list_pairs = {{'x',1},{'y',2},{'z',3}}
obj = LAMBDA.toObj(list_pairs)

-- => {x = 1, y = 2, z = 3}
```

### property (key)

Returns a function that will return the key property of any passed-in object.

```lua
local who = LAMBDA.property('name')
local people = {name = 'Henry'}
who(people) -- => 'Henry'
```

### propertyOf (obj)

Returns a function that will return the key property of any passed-in object.

```lua
local people = {name = 'Henry'}
print(LAMBDA.propertyOf(people)('name')) -- => 'Henry'
```

### toBoolean (value)

Converts a given value to a boolean.

```lua
LAMBDA.toBoolean(true) -- => true
LAMBDA.toBoolean(false) -- => false
LAMBDA.toBoolean(nil) -- => false
LAMBDA.toBoolean({}) -- => true
LAMBDA.toBoolean(1) -- => true
```

### extend (destObj, ...)

Extends a destination object with the properties of some source objects.

```lua
LAMBDA.extend({},{a = 'b', c = 'd'}) -- => "{a = 'b', c = 'd'}"
```

### functions (obj, recurseMt)
*Aliases: `LAMBDA.methods`*.

Returns all functions names within an object.

```lua
LAMBDA.functions(coroutine) -- => "{'create','resume','running','status','wrap','yield'}"
```

### clone (obj, shallow)

Clones a given object.

```lua
local obj = {1,2,3}
local obj2 = LAMBDA.clone(obj)
print(obj2 == obj) -- => false
print(LAMBDA.isEqual(obj2, obj)) -- => true
```

### tap (obj, f, ...)

Invokes a given interceptor function on some object, and then returns the object itself. Useful to tap into method chaining to hook intermediate results.
The pased-interceptor is prototyped as `f(obj,...)`.

```lua
local v = LAMBDA.chain({1,2,3,4,5,6,7,8,9,10)
  :filter(function(k,v) return v%2~=0 end) -- filters even values
  :tap(function(v) print('Max is', LAMBDA.max(v) end) -- Tap max values 
  :map(function(k,v) return k^2)
  :value() -- =>	 Max is 9
```

### has (obj, key)

Checks if an object has a given attribute.

```lua
LAMBDA.has(_,'has') -- => true
LAMBDA.has(coroutine,'resume') -- => true
LAMBDA.has(math,'random') -- => true
```

### pick (obj, ...)
*Aliases: `LAMBDA.choose`*.

Collects whilelisted properties of a given object.

```lua
local object = {a = 1, b = 2, c = 3}
LAMBDA.pick(object,'a','c') -- => "{a = 1, c = 3}"
```

### omit (obj, ...)
*Aliases: `LAMBDA.drop`*.

Omits blacklisted properties of a given object.

```lua
local object = {a = 1, b = 2, c = 3}
LAMBDA.omit(object,'a','c') -- => "{b = 2}"
```

### template (obj, template)
*Aliases: `LAMBDA.defaults`*.

Applies a template on an object, preserving existing properties.

```lua
local obj = {a = 0}
LAMBDA.template(obj,{a = 1, b = 2, c = 3}) -- => "{a=0, c=3, b=2}"
```

### isEqual (objA, objB, useMt)
*Aliases: `LAMBDA.compare`*.

Compares objects:

```lua
LAMBDA.isEqual(1,1) -- => true
LAMBDA.isEqual(true,false) -- => false
LAMBDA.isEqual(3.14,math.pi) -- => false
LAMBDA.isEqual({3,4,5},{3,4,{5}}) -- => false
```

### result (obj, method, ...)

Calls an object method, passing it as a first argument the object itself.

```lua
LAMBDA.result('abc','len') -- => 3
LAMBDA.result({'a','b','c'},table.concat) -- => 'abc'
```

### isTable (t)

Is the given argument an object (i.e a table) ?

```lua
LAMBDA.isTable({}) -- => true
LAMBDA.isTable(math) -- => true
LAMBDA.isTable(string) -- => true
```

### isCallable (obj)

Is the given argument callable ?

```lua
LAMBDA.isCallable(print) -- => true
LAMBDA.isCallable(function() end) -- => true
LAMBDA.isCallable(setmetatable({},{__index = string}).upper) -- => true
LAMBDA.isCallable(setmetatable({},{__call = function() return end})) -- => true
```

### isArray (obj)

Is the given argument an array (i.e. a sequence) ?

```lua
LAMBDA.isArray({}) -- => true
LAMBDA.isArray({1,2,3}) -- => true
LAMBDA.isArray({'a','b','c'}) -- => true
```

### isIterable (obj)

Checks if the given object is iterable with `pairs`.

```lua
LAMBDA.isIterable({}) -- => true
LAMBDA.isIterable(function() end) -- => false
LAMBDA.isIterable(false) -- => false
LAMBDA.isIterable(1) -- => false
```

### isEmpty (obj)

Is the given argument empty ?

```lua
LAMBDA.isEmpty('') -- => true
LAMBDA.isEmpty({})  -- => true
LAMBDA.isEmpty({'a','b','c'}) -- => false
```

### isString (obj)

Is the given argument a string ?

```lua
LAMBDA.isString('') -- => true
LAMBDA.isString('Hello') -- => false
LAMBDA.isString({}) -- => false
```

### isFunction (obj)

Is the given argument a function ?

```lua
LAMBDA.isFunction(print) -- => true
LAMBDA.isFunction(function() end) -- => true
LAMBDA.isFunction({}) -- => false
```

### isNil (obj)

Is the given argument nil ?

```lua
LAMBDA.isNil(nil) -- => true
LAMBDA.isNil() -- => true
LAMBDA.isNil({}) -- => false
```

### isNumber (obj)

Is the given argument a number ?

```lua
LAMBDA.isNumber(math.pi) -- => true
LAMBDA.isNumber(math.huge) -- => true
LAMBDA.isNumber(0/0) -- => true
LAMBDA.isNumber() -- => false
```

### isNaN (obj)

Is the given argument NaN ?

```lua
LAMBDA.isNaN(1) -- => false
LAMBDA.isNaN(0/0) -- => true
```

### isFinite (obj)

Is the given argument a finite number ?

```lua
LAMBDA.isFinite(99e99) -- => true
LAMBDA.isFinite(math.pi) -- => true
LAMBDA.isFinite(math.huge) -- => false
LAMBDA.isFinite(1/0) -- => false
LAMBDA.isFinite(0/0) -- => false
```

### isBoolean (obj)

Is the given argument a boolean ?

```lua
LAMBDA.isBoolean(true) -- => true
LAMBDA.isBoolean(false) -- => true
LAMBDA.isBoolean(1==1) -- => true
LAMBDA.isBoolean(print) -- => false
```

### isInteger (obj)

Is the given argument an integer ?

```lua
LAMBDA.isInteger(math.pi) -- => false
LAMBDA.isInteger(1) -- => true
LAMBDA.isInteger(-1) -- => true
```

**[🔝](#TOC)**

## <a name='chaining'>Chaining</a>

*Method chaining* (also known as *name parameter idiom*), is a technique for invoking consecutively method calls in object-oriented style.
Each method returns an object, and methods calls are chained together.
The @functional module offers chaining for your perusal. <br/>
Let's use chaining to get the count of evey single word in some lyrics (case won't matter here).


```lua
local lyrics = {
  "I am a lumberjack and I am okay",
  "I sleep all night and I work all day",
  "He is a lumberjack and he is okay",
  "He sleeps all night and he works all day"
}

local stats = LAMBDA.chain(lyrics)
  :map(function(k,line)
	local t = {}
	for w in line:gmatch('(%w+)') do
	  t[#t+1] = w
	end
	return t
  end)
  :flatten()
  :countBy(function(i,v) return v:lower() end)
  :value() 

-- => "{
-- =>    sleep = 1, night = 2, works = 1, am = 2, is = 2,
-- =>    he = 2, and = 4, I = 4, he = 2, day = 2, a = 2,
-- =>    work = 1, all = 4, okay = 2
-- =>  }"
```

For convenience, you can also use `_(value)` to start chaining methods, instead of `LAMBDA.chain(value)`.

Note that one can use `:value()` to unwrap a chained object.

```lua
local t = {1,2,3}
print(_(t):value() == t) -- => true
```

**[🔝](#TOC)**

## <a name='import'>Import</a>

All library functions can be imported in a context using `import` into a specified context.

```lua
local context = {}
LAMBDA.import(context)

context.each({1,2,3},print)

-- => 1 1
-- => 2 2
-- => 3 3
```

When no `context` was provided, it defaults to the global environment `_G`.

```lua
LAMBDA.import()

each({1,2,3},print)

-- => 1 1
-- => 2 2
-- => 3 3
```

Passing `noConflict` argument leaves untouched conflicting keys while importing into the context.

```lua
local context = {each = 1}
LAMBDA.import(context, true)

print(context.each) -- => 1
context.eachi({1,2,3},print)

-- => 1 1
-- => 2 2
-- => 3 3
```

**[🔝](#TOC)**

