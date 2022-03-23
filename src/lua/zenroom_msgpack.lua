local mpack = require'msgpack'

local _str = mpack.encoder_functions.string

-- local function zdata(value)
--    local o = value:octet()
--    local len = #o
--    if len < 256 then
--       return pack('>Bs1', 0xe4, o:string())
--    elseif len < 65536 then
--       return pack('>Bs2', 0xe5, o:string())
--    else
--       return pack('>Bs4', 0xe6, o:string())
--    end
-- end



mpack.encoder_functions['zenroom.octet'] = function(value) return _str( value:octet():base64() ) end
mpack.encoder_functions['zenroom.big']   = function(value) return _str( value:octet():base64() ) end
mpack.encoder_functions['zenroom.ecp']   = function(value) return _str( value:octet():base64() ) end
mpack.encoder_functions['zenroom.ecp2']  = function(value) return _str( value:octet():base64() ) end


return mpack
