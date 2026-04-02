#include <zenroom.h>
#include <zen_error.h>
#include <lua_functions.h>
#include <zen_octet.h>

// MAYO parameters and build configuration
#define MAYO_VARIANT MAYO_5
#define MAYO_BUILD_TYPE_REF 1

#include "api.h"
#include "mayo.h"

static int zen_mayo_secgen(lua_State *L) {
	BEGIN();
	zenroom_t *Z = zen_get_context(L);
	register const size_t sksize = CRYPTO_SECRETKEYBYTES; 
	octet *sk = o_new(L, sksize); SAFE(sk, "Could not create secret key");
	register size_t i;
	for(i=0; i < sksize; i++)
		sk->val[i] = RAND_byte(Z->random_generator);
	sk->len = sksize;
	END(1);
}

static int zen_mayo_pubgen(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *pk = NULL;
	const octet *sk = NULL;
	sk = o_arg(L, 1); SAFE_GOTO(sk, "Could not allocate secret key");
	SAFE_GOTO(sk->len == CRYPTO_SECRETKEYBYTES, "Invalid size for MAYO_5 secret key");
	pk = o_new(L, CRYPTO_PUBLICKEYBYTES); SAFE_GOTO(pk, "Could not create public key");
	pk->len = CRYPTO_PUBLICKEYBYTES;

	// params = NULL if compiling with ENABLE_PARAMS_DYNAMIC off (static)
	mayo_derive_cpk(NULL, (unsigned char*)pk->val, (const unsigned char*)sk->val);
end:
	o_free(L, sk);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

// For generating directly the keypair (as in Dilithium)
// static int zen_mayo_keygen(lua_State *L) {
//     BEGIN();
//     char *failed_msg = NULL;
//     lua_createtable(L, 0, 2);
	
//     int sk_len = CRYPTO_SECRETKEYBYTES; 
//     int pk_len = CRYPTO_PUBLICKEYBYTES;

//     octet *private = o_new(L, sk_len); SAFE_GOTO(private, "Could not create private key");
//     lua_setfield(L, -2, "private");
//     octet *public = o_new(L, pk_len); SAFE_GOTO(public, "Could not create public key");
//     lua_setfield(L, -2, "public");

//     crypto_sign_keypair((unsigned char*)public->val, (unsigned char*)private->val);
//     public->len = pk_len;
//     private->len = sk_len;

// end:
//     if(failed_msg) {
//         THROW(failed_msg);
//     }
//     END(1);
// }

static int zen_mayo_sign(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *sk = NULL, *m = NULL;
	sk = o_arg(L, 1); SAFE_GOTO(sk, "Could not allocate secret key");
	SAFE_GOTO(sk->len == CRYPTO_SECRETKEYBYTES, "Invalid size for MAYO_5 secret key");
	m = o_arg(L, 2); SAFE_GOTO(m, "Could not allocate message");
	octet *sig = o_new(L, CRYPTO_BYTES); SAFE_GOTO(sig, "Could not create signature");
	SAFE_GOTO(
		!crypto_sign_signature(
			(unsigned char*)sig->val,
			(size_t*)&sig->len,
			(unsigned char*)m->val, m->len,
			(unsigned char*)sk->val
		) || sig->len <= 0,
		"Could not sign the message"
	);
end:
	o_free(L, m);
	o_free(L, sk);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int zen_mayo_signature_pubcheck(lua_State *L) {
	BEGIN();
	const octet *pk = o_arg(L, 1); SAFE(pk, "Could not allocate public key");
	if(pk->len == CRYPTO_PUBLICKEYBYTES)
		lua_pushboolean(L, 1);
	else
		lua_pushboolean(L, 0);
	o_free(L, pk);
	END(1);
}

static int zen_mayo_signed_message(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *sk = NULL, *m = NULL;
	sk = o_arg(L, 1); SAFE_GOTO(sk, "Could not allocate secret key");
	SAFE_GOTO(sk->len == CRYPTO_SECRETKEYBYTES, "Invalid size for MAYO_5 secret key");
	m = o_arg(L, 2); SAFE_GOTO(m, "Could not allocate message");
	octet *sig = o_new(L, CRYPTO_BYTES + m->len); SAFE_GOTO(sig, "Could not create signature");
	SAFE_GOTO(
		!crypto_sign(
			(unsigned char*)sig->val,
			(size_t*)&sig->len,
			(unsigned char*)m->val, m->len,
			(unsigned char*)sk->val
		) || sig->len <= 0,
		"Could not sign the message"
	);
end:
	o_free(L, m);
	o_free(L, sk);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int zen_mayo_verified_message(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *pk = NULL, *sm = NULL;
	pk = o_arg(L, 1); SAFE_GOTO(pk, "Could not allocate public key");
	SAFE_GOTO(pk->len == CRYPTO_PUBLICKEYBYTES, "Invalid size for MAYO_5 public key");
	sm = o_arg(L, 2); SAFE_GOTO(sm, "Could not allocate signed message");
	octet *msg = o_new(L, sm->len); SAFE_GOTO(msg, "Could not create message");
	int result = crypto_sign_open(
		(unsigned char*)msg->val,
		(size_t*)&msg->len,
		(unsigned char*)sm->val, sm->len,
		(unsigned char*)pk->val) == 0
		&& msg->len > 0;
	if(!result) {
		lua_pushboolean(L, 0);
	}
end:
	o_free(L, sm);
	o_free(L, pk);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int zen_mayo_verify(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *pk = NULL, *sig = NULL, *m = NULL;
	pk = o_arg(L, 1); SAFE_GOTO(pk, "Could not allocate public key");
	SAFE_GOTO(pk->len == CRYPTO_PUBLICKEYBYTES, "Invalid size for MAYO_5 public key");
	sig = o_arg(L, 2); SAFE_GOTO(sig, "Could not allocate signature");
	m = o_arg(L, 3); SAFE_GOTO(m, "Could not allocate message");
	int result = crypto_sign_verify(
		(unsigned char*)sig->val,
		(size_t)sig->len,
		(unsigned char*)m->val, m->len,
		(unsigned char*)pk->val
	);
	lua_pushboolean(L, result == 0);
end:
	o_free(L, m);
	o_free(L, sig);
	o_free(L, pk);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int zen_mayo_signature_len(lua_State *L){
	BEGIN();
	lua_pushinteger(L, CRYPTO_BYTES);
	END(1);
}

static int zen_mayo_signature_check(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *sign = o_arg(L, 1); SAFE_GOTO(sign, "Could not allocate signature");
	if(sign->len == CRYPTO_BYTES)
		lua_pushboolean(L, 1);
	else
		lua_pushboolean(L, 0);
end:
	o_free(L, sign);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

int luaopen_mayo(lua_State *L) {
	const struct luaL_Reg mayo_class[] = {
		{"keygen", zen_mayo_secgen},
		{"secgen", zen_mayo_secgen},
		{"pubgen", zen_mayo_pubgen},
		{"pubcheck", zen_mayo_signature_pubcheck},
		{"checkpub", zen_mayo_signature_pubcheck},
		{"sign", zen_mayo_sign},
		{"verify", zen_mayo_verify},
		{"signed_msg", zen_mayo_signed_message},
		{"verified_msg", zen_mayo_verified_message},
		{"signature_len", zen_mayo_signature_len},
		{"signature_check", zen_mayo_signature_check},
		{NULL, NULL}
	};
	
	const struct luaL_Reg mayo_methods[] = {
		{NULL, NULL}
	};

	zen_add_class(L, "mayo", mayo_class, mayo_methods);
	return 1;
}
