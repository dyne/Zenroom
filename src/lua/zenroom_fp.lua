local fp = require'fp'

function meta(s)
   return getmetatable(s).__name
end

function fp._import(s, f)
   if meta(s) == 'zenroom.big' then
	  return fp.big(s)
   else
	  -- metatable returns nil, use function to convert
	  return fp.big(f(s))
   end
end

function fp.hex(s) return fp._import(s, big.hex) end

function fp.base64(s) return fp._import(s, big.base64) end

function fp.string(s) return fp._import(s, big.string) end

function fp.octet(s)  return fp._import(s, big.octet) end

return fp
