-- init script embedded at compile time.  executed in
-- zen_load_extensions(L) usually after zen_init()

json   = require('json')
schema = require('schema')
octet  = require('octet')
ecdh   = require('ecdh')
fun    = require('functional')

function read_json(data, validation)
   if not data then
	  print "read_json: missing data"
	  os.exit()
   end
   out,res = json.decode(data)
   if not out then
	  if res then
		 print "read_json: invalid json"
		 print(res)
		 os.exit()
	  end
   else
	  -- operate schema validation if argument is present
	  if validation then
		 local err = schema.CheckSchema(out, validation)
		 if err then
			print "read_json: invalid data schema"
			print(schema.FormatOutput(err))
			os.exit()
		 end
	  end
	  return out
   end
end
