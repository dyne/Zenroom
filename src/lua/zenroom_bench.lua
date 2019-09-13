local bench = { }

bench.random_hamming_freq = function ()
   -- ECP coordinates are 97 bytes
   local new = O.random(97)
   local tot = 0
   local old
   for i=5000,1,-1 do
	  old = new
	  new = O.random(97)
	  tot = tot + O.hamming(old,new)
   end
   return tot / 5000
end

return bench
