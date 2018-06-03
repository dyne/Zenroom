-- init script embedded at compile time.  executed in
-- zen_load_extensions(L) usually after zen_init()

json   = require('json')
schema = require('schema')
octet  = require('octet')
ecdh   = require('ecdh')
fun    = require('functional')
i      = require('inspect')

function read_json(data, validation)
   if not data then
	  error("read_json: missing data")
	  os.exit()
   end
   out,res = json.decode(data)
   if not out then
	  if res then
		 error("read_json: invalid json")
		 error(res)
		 os.exit()
	  end
   else
	  -- operate schema validation if argument is present
	  if validation then
		 local err = schema.CheckSchema(out, validation)
		 if err then
			error "read_json: schema validation failed"
			error(schema.FormatOutput(err))
			os.exit()
		 end
	  end
	  return out
   end
end

function write_json(data)
   i.print(data)
end
