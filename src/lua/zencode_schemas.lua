-- Zencode data schemas for validation

ZEN.get = function(conv, obj, key)
   ZEN.assert(obj[key], "Key not found in object conversion: "..key)
   local res = conv(obj[key])
   assert(res, "Error converting object key: ".. key)
   return res
end
local get = ZEN.get

schemas = {

   aes_gcm = { import = function(obj)
				  return { checksum = get(O.from_hex, obj, 'checksum'),
						   iv = get(O.from_hex, obj, 'iv'),
						   text = get(O.from_hex, obj, 'text'), -- may be MSGpack
						   encoding = obj.encoding,
						   curve = obj.curve,
						   pubkey = get(ECP.new, obj, 'pubkey') } end,
			   export = function(obj,conv)
				  return { checksum = conv(obj.checksum),
						   iv = conv(obj.iv),
						   text = conv(obj.text),
						   encoding = obj.encoding,
						   curve = obj.curve,
						   pubkey = conv(obj.pubkey) } end,
			 },

   -- zencode_keypair
   ecdh_keypair = {
	  import = function(obj)
		 return { private = get(O.from_hex, obj, 'private'),
				  public = get(ECP.new, obj, 'public') } end,
	  export = function(obj, conv)
		 return map(obj, conv) end },

   -- zencode_ecqv
   certificate = S.record {
      schema = S.Optional(S.string),
      private = S.Optional(S.big),
      public = S.ecp,
      hash = S.big,
      from = S.string,
      authkey = S.ecp
   },

   certificate_hash = S.Record {
      schema = S.Optional(S.string),
      public = S.ecp,
      requester = S.string,
      statement = S.string,
      certifier = S.string
   },

   declaration = S.record {
      schema = S.Optional(S.string),
      from = S.string,
      to = S.string,
      statement = S.string,
      public = S.ecp
   },

   declaration_keypair = S.record {
      schema = S.Optional(S.string),
      requester = S.string,
      statement = S.string,
      public = S.ecp,
      private = S.hex
   },

   coconut_req_keypair =
	  { import = function(obj)
		   return { public = get(ECP.new, obj, 'public'),
					private = get(INT.new, obj, 'private') } end,
		export = function(obj, conv)
		   return map(obj,conv) end },

   coconut_ca_keypair =
	  { import = function(obj)
		   return { sign = { x = get(INT.new, obj.sign, 'x'),
							 y = get(INT.new, obj.sign, 'y') },
					verify = { alpha = get(ECP2.new,obj.verify, 'alpha'),
							   beta = get(ECP2.new, obj.verify, 'beta'),
							   g2 = get(ECP2.new, obj.verify, 'g2') } } end,
		export = function(obj,conv)
		   return { sign   = map(obj.sign, conv),
					verify = map(obj.verify, conv) } end },

   coconut_ca_vk =
	  { import = function(obj)
		   return { alpha = get(ECP2.new, obj, 'alpha'),
					beta = get(ECP2.new, obj, 'beta'),
					g2 = get(ECP2.new, obj, 'g2') } end,
		export = function(obj,conv)
		   return map(obj,conv) end },

   coconut_request = {
	  import = function(obj)
		 return { c = { a = get(ECP.new, obj.c, 'a'),
						b = get(ECP.new, obj.c, 'b') },
				  pi_s = { rr = get(INT.new, obj.pi_s, 'rr'),
						   rm = get(INT.new, obj.pi_s, 'rm'),
						   rk = get(INT.new, obj.pi_s, 'rk'),
						   c =  get(INT.new, obj.pi_s, 'c')  },
				  cm = get(ECP.new, obj, 'cm') } end,
	  export = function(obj,conv)
		 local ret = map(obj, conv)
		 ret.pi_s = map(obj.pi_s, conv)
		 ret.c = map(obj.c, conv)
		 return ret
   end },

   coconut_lambda = {
	  import = function(obj)
		 return { pi_s = { rr = get(INT.new, obj.pi_s, 'rr'),
						   rm = get(INT.new, obj.pi_s, 'rm'),
						   rk = get(INT.new, obj.pi_s, 'rk'),
						   c =  get(INT.new, obj.pi_s, 'c')  },
				  cm = get(ECP.new, obj, 'cm'),
				  c = { a = get(ECP.new, obj.c, 'a'),
						b = get(ECP.new, obj.c, 'b') },
				  public = get(ECP.new, obj, 'public') } end,
	  export = function(obj,conv)
		 local out = map(obj,conv)
		 out.pi_s = map(obj.pi_s, conv)
		 out.c = map(obj.c, conv)
		 return out
	  end },

   coconut_sigmatilde = {
	  import = function(obj)
	  return { h = get(ECP.new, obj, 'h'),
			   b_tilde = get(ECP.new, obj, 'b_tilde'),
			   a_tilde = get(ECP.new, obj, 'a_tilde') } end,
	  export = function(obj,conv)
		 return map(obj,conv) end },

   coconut_aggsigma = {
	  import = function(obj)
		 return { h = get(ECP.new, obj, 'h'),
				  s = get(ECP.new, obj, 's') } end,
	  export = function(obj,conv)
		 return map(obj,conv) end },

   coconut_theta = {
	  import = function(obj)
		 return { nu = get(ECP.new, obj, 'nu'),
				  kappa = get(ECP2.new, obj, 'kappa'),
				  pi_v = map(obj.pi_v, INT.new), -- TODO map wrappers
				  sigma_prime = map(obj.sigma_prime, ECP.new) } end,
	  export = function(obj, conv)
		 -- TODO: validation of kappa and nu		 
		 local out = map(obj, conv)
		 out.sigma_prime = map(obj.sigma_prime, conv)
		 out.pi_v = map(obj.pi_v, conv)
		 return out
	  end }

}

_G['schemas'] = schemas
function import(obj, sname)
   ZEN.assert(obj, "Import error: obj is nil")
   ZEN.assert(sname, "Import error: schema is nil")
   local s = schemas[sname]
   ZEN.assert(s ~= nil, "Import error: schema not found '"..sname.."'")
   return s.import(obj)
end
function export(obj, sname, conv)
   ZEN.assert(obj, "Export error: obj is nil")
   ZEN.assert(type(sname) == "string", "Export error: invalid schema string")
   ZEN.assert(type(conv) == "function", "Export error: invalid conversion function")
   local s = schemas[sname]
   ZEN.assert(s ~= nil, "Export error: schema not found '"..sname.."'")
   local out = s.export(obj, conv)
   ZEN.assert(out, "Export error: returned nil for schema '"..sname.."'")
   out.encoding = 'hex' -- hardcoded
   out.curve = 'bls383'
   out.schema = sname
   out.zenroom = VERSION
   return out
end
