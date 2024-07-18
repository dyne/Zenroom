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

void RSA_octet_to_pk(lua_State *L, octet *o, rsa_public_key_4096 *pk){
	octet *x = o_alloc(L,o->len);
	OCT_copy(x, o);
	FF_4096_fromOctet(pk->n, x, FFLEN_4096);
	OCT_shl(x, MODBYTES_512_29 * FFLEN_4096);
	pk->e =  ((uint32_t)x->val[3] & 0xFF) |
                     ((uint32_t)x->val[2] << 8 & 0xFF00) |
                     ((uint32_t)x->val[1] << 16 & 0xFF0000) |
                     ((uint32_t)x->val[0] << 24 & 0xFF000000);
	o_free(L,x);
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

	rsa_private_key_4096 priv;
	rsa_public_key_4096 pub;

	
	char *failed_msg = NULL;
	if (lua_gettop(L)==1){
		if(!lua_isinteger(L,1)){
		failed_msg= "Wrong type argument, expected int";
		goto end;
		}
		Z(L);
		csprng *RNG = Z->random_generator;
		sign32 e = (int32_t) lua_tointeger(L, 1);
		RSA_4096_KEY_PAIR(RNG, e, &priv , &pub ,NULL, NULL);

	} else if (lua_gettop(L)==2){
		void *p =luaL_testudata(L,1,"zenroom.octet");
		void* q =luaL_testudata(L,2,"zenroom.octet");
		if ((p) && (q)){
			octet *P = o_alloc(L, sizeof(p));
			P = (octet*) p; SAFE(P);
			if (P->len > RSA_4096_PRIVATE_KEY_BIG_BYTES) {
				failed_msg = "Wrong prime size";
				goto end;	
			}
		octet *Q = o_alloc(L, sizeof(q));
			Q = (octet*) q; SAFE(Q);
			if (Q->len > RSA_4096_PRIVATE_KEY_BIG_BYTES) {
				failed_msg = "Wrong prime size";
				goto end;	
			}
		RSA_4096_KEY_PAIR(NULL, RSA_4096_PUBLIC_EXPONENT, &priv , &pub ,P, Q);
		o_free(L,P);
		o_free(L,Q);
	}
	} else if (lua_gettop(L)==3){
		
		if(!lua_isinteger(L,1)){
		failed_msg= "Wrong first type argument, expected int";
		goto end;
		}
		sign32 e = (int32_t) lua_tointeger(L, 1);
		void *p =luaL_testudata(L,1,"zenroom.octet");
		void* q =luaL_testudata(L,2,"zenroom.octet");
		if ((p) && (q)){
			octet *P = o_alloc(L, sizeof(p));
			P = (octet*) p; SAFE(P);
			if (P->len > RSA_4096_PRIVATE_KEY_BIG_BYTES) {
				failed_msg = "Wrong prime size";
				goto end;	
			}
		octet *Q = o_alloc(L, sizeof(q));
			Q = (octet*) q; SAFE(Q);
			if (Q->len > RSA_4096_PRIVATE_KEY_BIG_BYTES) {
				failed_msg = "Wrong prime size";
				goto end;	
			}
		RSA_4096_KEY_PAIR(NULL, e, &priv , &pub ,P, Q);
		o_free(L,P);
		o_free(L,Q);
	}
	} else {
		Z(L);
		csprng *RNG = Z->random_generator;
		sign32 e = RSA_4096_PUBLIC_EXPONENT;
		RSA_4096_KEY_PAIR(RNG, e, &priv , &pub ,NULL, NULL);
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
	RSA_sk_to_octet(L,&priv, private);
	RSA_pk_to_octet(&pub,public);

end:
	RSA_4096_PRIVATE_KEY_KILL(&priv);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int rsa_encrypt(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *octet_pk = NULL, *msg = NULL;
	octet_pk =  o_arg(L, 1);

	if(octet_pk == NULL) {
		failed_msg = "failed to allocate space for the public key";
		goto end;
	}
	if(octet_pk->len != 516) {
		zerror(L, "Public key size should be 516 byte, this is %u", octet_pk->len);
		failed_msg = "RSA encryption aborted";
		goto end;
	}
	msg = o_arg(L, 2);
	if(msg == NULL) {
		failed_msg = "failed to allocate space for the messsage text";
		goto end;
	}
    /* convert octet of public key into struct rsa_public_key_4096 */
    rsa_public_key_4096 pk;
    RSA_octet_to_pk(L, octet_pk, &pk);
    octet *padmsg = o_alloc(L, RFS_4096);
	Z(L);
	csprng *RNG = Z-> random_generator;

    OAEP_ENCODE(HASH_TYPE_RSA_4096, msg, RNG, NULL, padmsg);
    octet *c = o_new(L, RFS_4096);
    RSA_4096_ENCRYPT(&pk, padmsg, c);
end:
	o_free(L, padmsg);
	o_free(L, octet_pk);
	o_free(L, msg);
	if(failed_msg != NULL) {
		THROW(failed_msg);
	}
	END(1);
}

static int rsa_decrypt(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *octet_sk = NULL, *c = NULL;
	octet_sk =  o_arg(L, 1);
	if(octet_sk == NULL) {
		failed_msg = "failed to allocate space for the private key";
		goto end;
	}
	if(octet_sk->len != RSA_4096_PRIVATE_KEY_BYTES) {
		zerror(L, "Public key size should be %u byte, this is %u",RSA_4096_PRIVATE_KEY_BYTES, octet_sk->len);
		failed_msg = "RSA encryption aborted";
		goto end;
	}
	c = o_arg(L, 2);
	if(c == NULL) {
		failed_msg = "failed to allocate space for the messsage text";
		goto end;
	}
	
    /* convert octet of public key into struct rsa_public_key_4096 */
    rsa_private_key_4096 sk; 
	RSA_octet_to_sk(octet_sk, &sk);
    octet *p = o_new(L, RFS_4096);
    RSA_4096_DECRYPT(&sk, c, p);
    OAEP_DECODE(HASH_TYPE_RSA_4096,NULL,p);



end:
	o_free(L, octet_sk);
	o_free(L, c);
	if(failed_msg != NULL) {
		THROW(failed_msg);
	}
	END(1);
}
int luaopen_rsa(lua_State *L) {
	(void)L;
	const struct luaL_Reg rsa_class[] = {
		{"keygen",rsa_keypair},
		{"encrypt", rsa_encrypt},
		{"decrypt", rsa_decrypt},

		{NULL,NULL}
	};
	const struct luaL_Reg rsa_methods[] = {
		{NULL,NULL}
	};

	zen_add_class(L, "rsa", rsa_class, rsa_methods);
	return 1;
}