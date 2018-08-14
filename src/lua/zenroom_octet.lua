local octet = require'octet'

function hex(data)    return octet.hex(data) end
function str(data)    return octet.string(data) end
function base64(data) return octet.base64(data) end
function base58(data) return octet.base58(data) end

function zero(len)    return octet.new(len):zero(len) end

return octet
