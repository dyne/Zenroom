local ecp = require'ecp'

function ecp.hashtopoint(s) return ecp.mapit(sha512(s)) end

return ecp
