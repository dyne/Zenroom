local big = require'big'

function big._import(s, f)
   if f == nil then
	  return big.new(s)
   elseif getmetatable(s).__name == 'zenroom.octet' then
	  return big.new(s)
   else
	  -- metatable returns nil, use function to convert
	  return big.new(f(s))
   end
end

function big.hex(s) return big._import(s, octet.hex) end

function big.base64(s) return big._import(s, octet.base64) end

function big.string(s) return big._import(s, octet.string) end

function big.generic(s)  return big._import(s, nil) end

big.octet   = big.generic
big.int     = big.generic
big.number  = big.generic
big.integer = big.generic

return big
