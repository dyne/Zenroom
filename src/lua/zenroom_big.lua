local big = require'big'

function big._import(s, f)
   if getmetatable(s).__name == 'zenroom.octet' then
	  return big.new(s)
   else
	  -- metatable returns nil, use function to convert
	  return big.new(f(s))
   end
end

function big.hex(s, f) return big._import(s, octet.from_hex) end

function big.base64(s) return big._import(s, octet.from_base64) end

function big.string(s) return big._import(s, octet.from_string) end

return big
