local rng = require'rng'

-- global facility function
function random(len) return RNG.new():octet(len) end

return rng
