local octet = require'octet'

--- implicit convertion functions going both ways
-- if input is an encoded string, will become an octet
-- if input is a non-encoded string, it will become a base64 string
-- if input is an octet, will become an encoded string
function hex(data)
   local t = type(data)
   if(t == "string") then
	  if O.is_hex(data) then return O.from_hex(data)
	  else return O.from_str(data):hex() end
   elseif(t == "zenroom.octet") then return data:hex()
   elseif iszen(t) then return data:octet():hex() -- any zenroom type to octet
   end
end
function str(data)
   if    (type(data) == "string")        then return octet.from_string(data)
   elseif(type(data) == "zenroom.octet") then return data:string()
   end
end
function bin(data)
   local t = type(data)
   if(t == "string") then
	  if O.is_bin(data) then return O.from_bin(data)
	  else return O.from_str(data):bin() end
   elseif(t == "zenroom.octet") then return data:bin()
   elseif iszen(t) then return data:octet():bin() -- any zenroom type to octet
   end
end
function base64(data)
   local t = type(data)
   if(t == "string") then
	  if O.is_base64(data) then return O.from_base64(data)
	  else return O.from_str(data):base64() end
   elseif(t == "zenroom.octet") then return data:base64()
   elseif iszen(t) then return data:octet():base64() -- any zenroom type to octet
   end
end
function base58(data)
   local t = type(data)
   if(t == "string") then
	  if O.is_base58(data) then return O.from_base58(data)
	  else return O.from_str(data):base58() end
   elseif(t == "zenroom.octet") then return data:base58()
   elseif iszen(t) then return data:octet():base58() -- any zenroom type to octet
   end
end

-- serialize an array containing any type of cryptographic numbers
octet.serialize = function(arr)
   concat = O.new()
   map(arr,function(e)
		  t = type(e)
		  -- supported lua native types
		  if(t == "string") then concat = concat .. str(e) return
		  elseif not iszen(t) then
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
