-- Zencode data schemas for validation

schemas = {

   -- packets encoded with AES GCM
   aes_gcm = S.record {
      checksum = S.hex,
      iv = S.hex,
      schema = S.Optional(S.string),
      text = S.hex,
      zenroom = S.Optional(S.string),
      encoding = S.string,
      curve = S.string,
      pubkey = S.ecp
   },

   -- zencode_keypair
   keypair = S.record {
      schema = S.Optional(S.string),
      private = S.Optional(S.hex),
      public = S.ecp
   },

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

   -- zencode_coconut
   coconut_ca_sk = S.record {
      x = S.int,
      y = S.int
   },
   -- coconut_ca_keypair = S.record {
   --    schema = S.Optional(S.string),
   --    version = S.Optional(S.string),
   --    verify = S.table,
   --    sign = S.table
   -- },

   -- coconut_req_keypair = S.record {
   --    schema = S.Optional(S.string),
   --    version = S.Optional(S.string),
   --    public = S.ecp,
   --    private = S.hex
   -- },

   coconut_pi_s = S.record {
	  rr = S.int,
	  rm = S.int,
	  rk = S.int,
	  c = S.int
   },

   coconut_pi_v = S.record {
	  rr = S.int,
	  rm = S.int,
	  c = S.int
   },

   coconut_sigmaprime = S.record {
	  h_prime = S.ecp,
	  s_prime = S.ecp
   },

   coconut_req_keypair = function(obj,conv)
	  local req = { public = ECP.new(obj.public),
					private = INT.new(obj.private) }
	  if conv == nil then return req
	  else -- export
		 return map(req,conv)
	  end
   end,

   coconut_ca_keypair = function(obj,conv)
	  local req = { }
	  req.sign = { x = INT.new(obj.sign.x),
				   y = INT.new(obj.sign.y) }
	  req.verify = { alpha = ECP2.new(obj.verify.alpha),
					 beta = ECP2.new(obj.verify.beta),
					 g2 = ECP2.new(obj.verify.g2) }
	  if conv == nil then return req
	  else -- export
		 return { sign = map(req.sign, conv),
				  verify = map(req.verify, conv) }
	  end
   end,

   coconut_ca_vk = function(obj,conv)
	  local req = { }
	  req.alpha = ECP2.new(obj.alpha)
	  req.beta = ECP2.new(obj.beta)
	  req.g2 = ECP2.new(obj.g2)
	  if conv == nil then return req
	  else -- export
		 local out = map(req,conv)
		 return out
	  end
   end,

   coconut_request = function(obj,conv)
	  local req = { }
	  req.c = { a = ECP.new(obj.c.a),
				b = ECP.new(obj.c.b) }
	  req.pi_s = { rr = INT.new(obj.pi_s.rr),
				   rm = INT.new(obj.pi_s.rm),
				   rk = INT.new(obj.pi_s.rk),
				   c =  INT.new(obj.pi_s.c)  }
	  req.cm = ECP.new(obj.cm)
	  if conv == nil then return req
	  else -- export
		 local out = map(req,conv)
		 out.pi_s = map(req.pi_s, conv)
		 out.c = map(req.c, conv)
		 return out
	  end
   end,

   coconut_lambda = function(obj,conv)
	  local lambda = { }
	  lambda.pi_s = { rr = INT.new(obj.pi_s.rr),
					  rm = INT.new(obj.pi_s.rm),
					  rk = INT.new(obj.pi_s.rk),
					  c =  INT.new(obj.pi_s.c)  }
	  lambda.cm = ECP.new(obj.cm)
	  lambda.c = { a = ECP.new(obj.c.a),
				   b = ECP.new(obj.c.b) }
	  lambda.public = ECP.new(obj.public)
	  if conv == nil then return lambda
	  else -- export
		 local out = map(lambda,conv)
		 out.pi_s = map(lambda.pi_s, conv)
		 out.c = map(lambda.c, conv)
		 return out
	  end
   end,

   coconut_sigmatilde = function(obj,conv)
	  local ret = { }
	  ret.h = ECP.new(obj.h)
	  ret.b_tilde = ECP.new(obj.b_tilde)
	  ret.a_tilde = ECP.new(obj.a_tilde)
	  if conv == nil then return ret
	  else -- export
		 local out = { }
		 out = map(ret,conv)
		 out.version = VERSION
		 out.schema = 'coconut_sigmatilde'
		 return out
	  end
   end,

   coconut_aggsigma = function(obj,conv)
	  local ret = { }
	  ret.h = ECP.new(obj.h)
	  ret.s = ECP.new(obj.s)
	  if conv == nil then return ret
	  else -- export
		 local out = { }
		 out = map(ret,conv)
		 out.version = VERSION
		 out.schema = 'coconut_aggsigma'
		 return out
	  end
   end,

   coconut_theta = function(obj, conv)
	  local ret = { }
	  ret.nu = ECP.new(obj.nu)
	  ret.kappa = ECP2.new(obj.kappa)
	  ret.pi_v = map(obj.pi_v, INT.new)
	  ret.sigma_prime = map(obj.sigma_prime, ECP.new)

	  if conv == nil then -- import
		 return ret
	  else -- export
		 -- TODO: check conv is a function
		 local out = { }
		 -- TODO: validation of kappa and nu
		 out = map(obj, conv)
		 out.sigma_prime = map(obj.sigma_prime, conv)
		 out.pi_v = map(obj.pi_v, conv)
		 out.version = VERSION
		 out.schema = 'coconut_theta'
		 return out
	  end
   end
}

-- function schemas:validate(obj, sname, err)
--    local s = self[sname]
--    ZEN.assert(s ~= nil, "Schema not found: "..sname)
--    ZEN.assert(s(self, obj), err)
--    return true
-- end

_G['schemas'] = schemas
