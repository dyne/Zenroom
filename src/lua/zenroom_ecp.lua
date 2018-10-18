local ecp = require'ecp'

function ecp.hashtopoint(s) return ecp.mapit(BIG.new(sha512(s))) end

return ecp
