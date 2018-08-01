-- 
-- Generates the public key from the private key
--
g = ECP.G() -- get the curve's generator coordinates
h = g * 2 -- hashtopoint "h0"
h1 = g * 20 -- hashtopoint "h1"
order = ECP.order() -- get the curves order in a big

local KEYS_TABLE = JSON.decode(KEYS)

function readBig(str)
	return BIG.new(hex(str))
end

function writeEcp(ecp)
	local x = ecp:x()
	local y = ecp:y()
	
	return { x = tostring(x), y = tostring(y) }
end

private = readBig(KEYS_TABLE["private"])
public = g * private


export = JSON.encode(
   {
      public  = writeEcp(public)
   }
)
print(export)