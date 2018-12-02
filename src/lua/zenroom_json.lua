local J = require('json')

J.decode = function(str)
   -- fixes strange behavior of tables returned
   -- second value returned should be used
   -- first one becomes a string after first transformation
   -- TODO: investigate this behavior
   assert(str,      "JSON.decode error decoding nil string")
   assert(str ~= "","JSON.decode error decoding empty string")
   local t = JSON.raw_decode(str)
   local i = t
   assert(t, "JSON.decode error decoding string:\n"..str)
   return i,t
end

-- no problem found in encode
J.encode = function(tab)
   return JSON.raw_encode(tab)
end

return J
