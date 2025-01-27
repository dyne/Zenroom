printerr'TEST memmem operations on octets (substr etc.)'

haystack = O.from_string'Lorem ipsum dolor amet' -- 22 chars
needle = O.from_string'dolor'
-- I.print({hay_len=#haystack,
--          hay_last=haystack:copy(#haystack-1,1):string()})
assert(haystack:copy(#haystack-1,1):string()=='t')
assert(haystack:copy(0,1):string()=='L')
-- I.print{haystack=haystack, needle=needle}
pos = haystack:find(needle)
-- I.print({pos=pos,needle_len=#needle})
assert(haystack:copy(pos,#needle):string()=='dolor')
assert(not haystack:find(needle,16))
