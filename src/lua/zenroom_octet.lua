local octet = require'octet'

-- implicit functions to convert both ways
function hex(data)
   if    (type(data) == "string")        then return octet.hex(data)
   elseif(type(data) == "zenroom.octet") then return data:hex()
   end
end
function str(data)
   if    (type(data) == "string")        then return octet.string(data)
   elseif(type(data) == "zenroom.octet") then return data:string()
   end
end
function bin(data)
   if    (type(data) == "string")        then return octet.bin(data)
   elseif(type(data) == "zenroom.octet") then return data:bin()
   end
end
function base64(data)
   if    (type(data) == "string")        then return octet.base64(data)
   elseif(type(data) == "zenroom.octet") then return data:base64()
   end
end
function base58(data)
   if    (type(data) == "string")        then return octet.base58(data)
   elseif(type(data) == "zenroom.octet") then return data:base58()
   end
end

-- explicit functions to import/export octets
octet.to_base64 = function(o)
   if(type(o) ~= "zenroom.octet") then
	  error("OCTET.to_base64: argument is not an octet") return end
   return o:base64()
end
octet.from_base64 = function(s)
   if(type(s) == "zenroom.octet") then
	  error("OCTET.from_base64: argument is already an octet") return end
   return O.base64(s)
end

function pack(data)
   if (type(data) == "zenroom.octet") then return MSG.pack(data:string()) end
   -- else
   return MSG.pack(data)
end
function unpack(data)
   if (type(data) == "table") then error("unpack: argument is already a table") return
   elseif(type(data) == "zenroom.octet") then return MSG.unpack(data:string())
   elseif(type(data) == "string") then return MSG.unpack(data)
   else error("unpack: argument of unknown type") return
   end
end


function zero(len)    return octet.new(len):zero(len) end

return octet
