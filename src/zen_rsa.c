#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <zenroom.h>
#include <zen_error.h>
#include <zen_memory.h>
#include <lua_functions.h>
#include <zen_octet.h>
#include <zen_error.h>
#include <amcl.h>
#include <rsa_4096.h>

#define RSA_4096_PRIVATE_KEY_BIG_SIZE FFLEN_4096 / 2
#define RSA_4096_PRIVATE_KEY_BIG_BYTES MODBYTES_512_29 * FFLEN_4096 / 2
#define RSA_4096_PRIVATE_KEY_BYTES  5 *RSA_4096_PRIVATE_KEY_BIG_BYTES
#define RSA_4096_PUBLIC_KEY_BYTES MODBYTES_512_29*FFLEN_4096+4
#define RSA_4096_PUBLIC_EXPONENT (int32_t) 65537

void RSA_sk_to_octet(lua_State *L, rsa_private_key_4096 *sk, octet *o) {
    octet *x = o_alloc(L,RSA_4096_PRIVATE_KEY_BIG_BYTES);
    FF_4096_toOctet(x, sk->p, RSA_4096_PRIVATE_KEY_BIG_SIZE);
    OCT_copy(o, x);
    FF_4096_toOctet(x, sk->q, RSA_4096_PRIVATE_KEY_BIG_SIZE);
    OCT_joctet(o, x);
    FF_4096_toOctet(x, sk->dp, RSA_4096_PRIVATE_KEY_BIG_SIZE);
    OCT_joctet(o, x);
    FF_4096_toOctet(x, sk->dq, RSA_4096_PRIVATE_KEY_BIG_SIZE);
    OCT_joctet(o, x);
    FF_4096_toOctet(x, sk->c, RSA_4096_PRIVATE_KEY_BIG_SIZE);
    OCT_joctet(o, x);
	o_free(L, x);
}


void RSA_pk_to_octet(rsa_public_key_4096 *pk, octet *o){
	FF_4096_toOctet(o,pk->n ,FFLEN_4096);
	OCT_jint(o, pk->e, 4);
}

void RSA_octet_to_pk(octet *o, rsa_public_key_4096 *pk){

	FF_4096_fromOctet(pk->n, o, FFLEN_4096);
	OCT_shl(o, MODBYTES_512_29 * FFLEN_4096);
	OCT_output(o);
	pk->e =  ((uint32_t)o->val[3] & 0xFF) |
                     ((uint32_t)o->val[2] << 8 & 0xFF00) |
                     ((uint32_t)o->val[1] << 16 & 0xFF0000) |
                     ((uint32_t)o->val[0] << 24 & 0xFF000000);
}

void RSA_octet_to_sk(octet *o, rsa_private_key_4096 *sk){
	FF_4096_fromOctet(sk->p, o, RSA_4096_PRIVATE_KEY_BIG_SIZE);
	OCT_shl(o, RSA_4096_PRIVATE_KEY_BIG_BYTES);
	FF_4096_fromOctet(sk->q, o, RSA_4096_PRIVATE_KEY_BIG_SIZE);
	OCT_shl(o, RSA_4096_PRIVATE_KEY_BIG_BYTES);
	FF_4096_fromOctet(sk->dp, o, RSA_4096_PRIVATE_KEY_BIG_SIZE);
	OCT_shl(o, RSA_4096_PRIVATE_KEY_BIG_BYTES);
	FF_4096_fromOctet(sk->dq, o, RSA_4096_PRIVATE_KEY_BIG_SIZE);
	OCT_shl(o, RSA_4096_PRIVATE_KEY_BIG_BYTES);
	FF_4096_fromOctet(sk->c, o, RSA_4096_PRIVATE_KEY_BIG_SIZE);
	OCT_shl(o, RSA_4096_PRIVATE_KEY_BIG_BYTES);
}

static int rsa_keypair(lua_State *L)   {
	BEGIN();
	sign32 e = RSA_4096_PUBLIC_EXPONENT;
	csprng *RNG = NULL;
	octet *P = NULL;
	octet *Q = NULL;
	char *failed_msg = NULL;
	if (lua_gettop(L)==1){
		if(!lua_isinteger(L,1)){
		failed_msg= "Wrong type argument, expected int";
		goto end;
		}
		e = (sign32) lua_tointeger(L, 1);

	} else if (lua_gettop(L)==2){
		void *p =luaL_testudata(L,1,"zenroom.octet");
		if (p){

			P = (octet*) p; SAFE(P);
			if (P->len > RSA_4096_PRIVATE_KEY_BIG_BYTES) {
				failed_msg = "Wrong prime size";
				goto end;	
			}
		}
		void* q =luaL_testudata(L,2,"zenroom.octet");
		if (q){
			Q = (octet*) q; SAFE(Q);
			if (Q->len > RSA_4096_PRIVATE_KEY_BIG_BYTES) {
				failed_msg = "Wrong prime size";
				goto end;	
			}
		}
	} else if (lua_gettop(L)==3){
		if(!lua_isinteger(L,1)){
		failed_msg= "Wrong first type argument, expected int";
		goto end;
		}
		e = (sign32) lua_tointeger(L, 1);
		void *p = luaL_testudata(L,2,"zenroom.octet");
		if (p){
			P = (octet*) p; SAFE(P);
			if (P->len > RSA_4096_PRIVATE_KEY_BIG_BYTES) {
				failed_msg = "Wrong prime size";
				goto end;	
			}
		}
		void *q = luaL_testudata(L,3,"zenroom.octet");
		if (q){
			Q = (octet*) q; SAFE(Q);
			if (Q->len > RSA_4096_PRIVATE_KEY_BIG_BYTES) {
				failed_msg = "Wrong prime size";
				goto end;	
			}
		}
	
	} else {
		Z(L);
		RNG = Z->random_generator;
	}

	lua_createtable(L, 0, 2);
	octet *private = o_new(L, RSA_4096_PRIVATE_KEY_BYTES); SAFE(private);
	
	if(private == NULL) {
		failed_msg = "Could not allocate private key";
		goto end;
	}
	lua_setfield(L, -2, "private");
	octet *public = o_new(L, RSA_4096_PUBLIC_KEY_BYTES); SAFE(public);
	if(public == NULL) {
		failed_msg = "Could not allocate public key";
		goto end;
	}
	lua_setfield(L, -2, "public");

	rsa_private_key_4096 priv;
	rsa_public_key_4096 pub;

	RSA_4096_KEY_PAIR(RNG, e, &priv , &pub ,P, Q);
	RSA_sk_to_octet(L,&priv, private);
	RSA_pk_to_octet(&pub,public);

end:
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

int luaopen_rsa(lua_State *L) {
	(void)L;
	const struct luaL_Reg qp_class[] = {
		{"keygen",rsa_keypair},

		{NULL,NULL}
	};
	const struct luaL_Reg qp_methods[] = {
		{NULL,NULL}
	};

	zen_add_class(L, "rsa", qp_class, qp_methods);
	return 1;
}
