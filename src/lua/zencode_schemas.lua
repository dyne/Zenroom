-- Zencode data schemas for validation

_G['schemas'] = {

   -- zencode_keypair
   keypair = S.record {
	  schema = S.Optional(S.string),
	  private = S.hex,
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
   }

}
