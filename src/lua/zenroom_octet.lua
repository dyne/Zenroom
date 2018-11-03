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
   if(type(data) == "zenroom.octet") then return data:base64()
   elseif zentype(data) then return(data) -- skip other zenroom types
   elseif not O.is_base64(data) then return(data) -- skip non base64
   elseif(type(data) == "string") then return octet.base64(data)
   end
end
function base58(data)
   if    (type(data) == "string")        then return octet.base58(data)
   elseif(type(data) == "zenroom.octet") then return data:base58()
   end
end

-- serialize an array containing any type of cryptographic numbers
octet.serialize = function(arr)
   concat = O.new()
   map(arr,function(e)
		  t = type(e)
		  if not iszen(t) then
			 error("OCTET.serialize: unsupported type: "..t)
		  end
		  if(t == "zenroom.octet") then
			 concat = concat .. e
		  elseif(t == "zenroom.big"
				 or
				 t == "zenroom.ecp"
				 or
				 t == "zenroom.ecp2") then
			 concat = concat .. e:octet()
		  else
			 error("OCTET.serialize: unsupported zenroom type: "..t)
		  end
   end)
   return concat
end

function zero(len)    return octet.new(len):zero(len) end

return octet
