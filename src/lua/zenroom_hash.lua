local hash = require'hash'

-- when using facility functions, global hashers are created only once
SHA256 = nil
SHA512 = nil
function sha256(data)
   if SHA256==nil then SHA256 = hash.new('sha256') end -- optimization
   return SHA256:process(data)
end
function sha512(data)
   if SHA512==nil then SHA512 = hash.new('sha512') end -- optimization
   return SHA512:process(data)
end

return hash
