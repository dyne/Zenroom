-- init script embedded at compile time.  executed in
-- zen_load_extensions(L) usually after zen_init()

octet = require('octet')
json = require('json')
schema = require('schema')


function import_json(data, validation)
   if not data then
	  print "ZEN SCRIPT ERROR: missing data"
	  os.exit()
   end
   out,res = json.decode(data)
   if not out then
	  if res then
		 print "ZEN SCRIPT ERROR: invalid json"
		 print(res)
		 os.exit()
	  end
   else
	  -- operate schema validation if argument is present
	  if validation then
		 local err = schema.CheckSchema(out, validation)
		 if err then
			print "ZEN SCRIPT ERROR: invalid data schema"
			print(schema.FormatOutput(err))
			os.exit()
		 end
	  end
	  return out
   end
end

