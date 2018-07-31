-- introspective script to compile a list of completion terms

local modules = { 
   ["OCTET"] = OCTET, ["octet"] = OCTET.new(),
   ["ECDH"] = ECDH, ["ecdh"] = ECDH.new(),
   ["ECP"] = ECP, ["ecp"] = ECP.new(),
   ["BIG"] = BIG, ["big"] = BIG.new(),
   ["RNG"] = RNG, ["rng"] = RNG.new(),
   ["HASH"] = HASH, ["hash"] = HASH.new() }
for n,m in pairs(modules) do
   if inspect(m)=='table' then
	  for k,v in pairs(m) do 
		 if inspect(v)~='table' and string.sub(k,1,1)~='_' then
			print(n.."."..k)
		 end
	  end
   else
	  for s,f in pairs(getmetatable(m)) do
		 if(string.sub(s,1,2)~='__') then print(":"..s) end
	  end
   end
end
-- for k,v in pairs(octet) do print(":"..k) end
