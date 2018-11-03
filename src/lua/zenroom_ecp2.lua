local ecp2 = require'ecp2'

function ecp2.hashtopoint(s)
   return ecp2.mapit(sha512(s))
end

return ecp2
