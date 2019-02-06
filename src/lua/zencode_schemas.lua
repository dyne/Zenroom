-- Zencode data schemas for validation

ZEN.get = function(conv, obj, key)
   ZEN.assert(type(key) == "string", "Invalid key in object conversion")
   ZEN.assert(obj, "Object not found for conversion")
   ZEN.assert(obj[key], "Key not found in object conversion: "..key)
   local res = conv(obj[key])
   assert(res, "Error converting object key: ".. key)
   return res
end

function import(obj, sname)
   ZEN.assert(obj, "Import error: obj is nil")
   ZEN.assert(sname, "Import error: schema is nil")
   local s = ZEN.schemas[sname]
   ZEN.assert(s ~= nil, "Import error: schema not found '"..sname.."'")
   return s.import(obj)
end
function export(obj, sname, conv)
   ZEN.assert(obj, "Export error: obj is nil")
   ZEN.assert(type(sname) == "string", "Export error: invalid schema string")
   ZEN.assert(type(conv) == "function", "Export error: invalid conversion function")
   local s = ZEN.schemas[sname]
   ZEN.assert(s ~= nil, "Export error: schema not found '"..sname.."'")
   local out = s.export(obj, conv)
   ZEN.assert(out, "Export error: returned nil for schema '"..sname.."'")
   out.encoding = 'hex' -- hardcoded
   out.curve = 'bls383'
   out.schema = sname
   out.zenroom = VERSION
   return out
end
