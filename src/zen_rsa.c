/*
 * This file is part of zenroom
 *
 * Copyright (C) 2017-2026 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License v3.0
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * Along with this program you should have received a copy of the
 * GNU Affero General Public License v3.0
 * If not, see http://www.gnu.org/licenses/agpl.txt
 *
 */

#include <zenroom.h>
#include <zen_error.h>
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

int RSA_sk_to_octet(lua_State *L, rsa_private_key_4096 *sk, octet *o) {
	octet *x = o_alloc(L,RSA_4096_PRIVATE_KEY_BIG_BYTES);
	if(!x) return 0;
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
	return 1;
}


void RSA_pk_to_octet(rsa_public_key_4096 *pk, octet *o){
	FF_4096_toOctet(o,pk->n ,FFLEN_4096);
	OCT_jint(o, pk->e, 4);
}

int RSA_octet_to_pk(lua_State *L, octet *o, rsa_public_key_4096 *pk){
	octet *x = o_alloc(L,o->len);
	if (!x) return 0;
	OCT_copy(x, o);
	FF_4096_fromOctet(pk->n, x, FFLEN_4096);
	OCT_shl(x, MODBYTES_512_29 * FFLEN_4096);
	pk->e =  ((uint32_t)x->val[3] & 0xFF) |
		((uint32_t)x->val[2] << 8 & 0xFF00) |
		((uint32_t)x->val[1] << 16 & 0xFF0000) |
		((uint32_t)x->val[0] << 24 & 0xFF000000);
	o_free(L,x);
	return 1;
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
	char *failed_msg = NULL;
	rsa_private_key_4096 priv;
	rsa_public_key_4096 pub;
	octet *P = NULL, *Q = NULL;
	if (lua_gettop(L)==1){
		SAFE_GOTO(lua_isinteger(L,1), "Invalid argument, expected int");
		Z(L);
		csprng *RNG = Z->random_generator;
		sign32 e = (int32_t) lua_tointeger(L, 1);
		RSA_4096_KEY_PAIR(RNG, e, &priv , &pub ,NULL, NULL);
	} else if (lua_gettop(L)==2){
		void *p =luaL_testudata(L,1,"zenroom.octet");
		void* q =luaL_testudata(L,2,"zenroom.octet");
		if ((p) && (q)){
			P = o_alloc(L, sizeof(p)); SAFE_GOTO(P, "Could not allocate prime");
			P = (octet*) p; SAFE_GOTO(P->len<=RSA_4096_PRIVATE_KEY_BIG_BYTES, "Invalid argument, prime size too big");
			Q = o_alloc(L, sizeof(q)); SAFE_GOTO(Q, "Could not allocate prime");
			Q = (octet*) q; SAFE_GOTO(Q->len<=RSA_4096_PRIVATE_KEY_BIG_BYTES, "Invalid argument, prime size too big");
			RSA_4096_KEY_PAIR(NULL, RSA_4096_PUBLIC_EXPONENT, &priv , &pub ,P, Q);
		}
	} else if (lua_gettop(L)==3){
		SAFE_GOTO(lua_isinteger(L,1), "Invalid argument, expected int");
		sign32 e = (int32_t) lua_tointeger(L, 1);
		void *p =luaL_testudata(L,2,"zenroom.octet");
		void* q =luaL_testudata(L,3,"zenroom.octet");
		if ((p) && (q)){
			P = o_alloc(L, sizeof(p)); SAFE_GOTO(P, "Could not allocate prime");
			P = (octet*) p; SAFE_GOTO(P->len <= RSA_4096_PRIVATE_KEY_BIG_BYTES, "Invalid argument, prime size too big");
			octet *Q = o_alloc(L, sizeof(q)); SAFE_GOTO(Q, "Could not allocate prime");
			Q = (octet*) q; SAFE_GOTO(Q->len <= RSA_4096_PRIVATE_KEY_BIG_BYTES, "Invalid argument, prime size too big");
			RSA_4096_KEY_PAIR(NULL, e, &priv , &pub ,P, Q);
		}
	} else {
		Z(L);
		csprng *RNG = Z->random_generator;
		sign32 e = RSA_4096_PUBLIC_EXPONENT;
		RSA_4096_KEY_PAIR(RNG, e, &priv , &pub ,NULL, NULL);
	}
	lua_createtable(L, 0, 2);
	octet *private = o_new(L, RSA_4096_PRIVATE_KEY_BYTES); SAFE_GOTO(private, "Could not create private key");
	lua_setfield(L, -2, "private");
	octet *public = o_new(L, RSA_4096_PUBLIC_KEY_BYTES); SAFE_GOTO(public, "Could not create public key");
	lua_setfield(L, -2, "public");
	SAFE(RSA_sk_to_octet(L,&priv, private), "Could not convert private key to octet");
	RSA_pk_to_octet(&pub,public);
end:
	o_free(L, P);
	o_free(L, Q);
	RSA_4096_PRIVATE_KEY_KILL(&priv);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int rsa_pubgen(lua_State *L){
	BEGIN();
	char *failed_msg = NULL;
	BIG_512_29 p[HFLEN_4096], e[HFLEN_4096], n[FFLEN_4096];
	octet *octet_sk = NULL, *e_octet = NULL;

	octet_sk = o_arg(L, 1); SAFE_GOTO(octet_sk, "Could not allocate secret key");
	rsa_private_key_4096 sk;
	RSA_octet_to_sk(octet_sk, &sk);

	FF_4096_mul(n, (&sk)->p ,(&sk)->q, HFLEN_4096);
	FF_4096_copy(p,(&sk)->p,HFLEN_4096);

	FF_4096_dec(p,1, HFLEN_4096);
	FF_4096_shr(p,HFLEN_4096);

	FF_4096_invmodp(e, (&sk)->dp, p, HFLEN_4096);
	if (FF_4096_parity(e)==0) FF_4096_add(e,e,p,HFLEN_4096);
	FF_4096_norm(e,HFLEN_4096);

	e_octet = o_alloc(L, RFS_4096); SAFE_GOTO(e_octet, "Could not allocate exponent");
	FF_4096_toOctet(e_octet,e, HFLEN_4096);
	OCT_shl(e_octet,RSA_4096_PRIVATE_KEY_BIG_BYTES-4);

	octet *octet_pk = o_new(L, RSA_4096_PUBLIC_KEY_BYTES); SAFE_GOTO(octet_pk, "Could not create public key");
	FF_4096_toOctet(octet_pk,n ,FFLEN_4096);
	OCT_joctet(octet_pk,e_octet);
end:
	o_free(L, octet_sk);
	o_free(L, e_octet);
	RSA_4096_PRIVATE_KEY_KILL(&sk);
	FF_4096_zero(p,HFLEN_4096);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int rsa_signature_pubcheck(lua_State *L) {
	BEGIN();
	const octet *pk = o_arg(L, 1); SAFE(pk, "Could not allocate public key");
	if(pk->len == RSA_4096_PUBLIC_KEY_BYTES)
		lua_pushboolean(L, 1);
	else
		lua_pushboolean(L, 0);
	o_free(L, pk);
	END(1);
}

static int rsa_signature_check(lua_State *L){
	BEGIN();
	const octet *sign = o_arg(L, 1); SAFE(sign, "Could not allocate signature");
	if(sign->len == 512)
		lua_pushboolean(L, 1);
	else
		lua_pushboolean(L, 0);
	o_free(L, sign);
	END(1);
}

static int rsa_encrypt(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *octet_pk = NULL, *msg = NULL, *padmsg = NULL;
	octet_pk =  o_arg(L, 1); SAFE_GOTO(octet_pk, "Could not allocate public key");
	SAFE_GOTO(octet_pk->len == RSA_4096_PUBLIC_KEY_BYTES, "Invalid public key size");
	msg = o_arg(L, 2); SAFE_GOTO(msg, "Could not allocate message");
	/* convert octet of public key into struct rsa_public_key_4096 */
	rsa_public_key_4096 pk;
	SAFE_GOTO(RSA_octet_to_pk(L, octet_pk, &pk), "Could not convert octet to public key");
	padmsg = o_alloc(L, RFS_4096); SAFE_GOTO(padmsg, "Could not allocate padded message");
	Z(L);
	csprng *RNG = Z-> random_generator;

	OAEP_ENCODE(HASH_TYPE_RSA_4096, msg, RNG, NULL, padmsg);
	octet *c = o_new(L, RFS_4096); SAFE_GOTO(c, "Could not create ciphertext");
	RSA_4096_ENCRYPT(&pk, padmsg, c);
end:
	o_free(L, octet_pk);
	o_free(L, msg);
	o_free(L, padmsg);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int rsa_decrypt(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *octet_sk = NULL, *c = NULL;
	octet_sk =  o_arg(L, 1); SAFE_GOTO(octet_sk, "Could not allocate private key");
	SAFE_GOTO(octet_sk->len == RSA_4096_PRIVATE_KEY_BYTES, "Invalid private key size");
	c = o_arg(L, 2); SAFE_GOTO(c, "Could not allocate ciphertext");

	rsa_private_key_4096 sk; 
	RSA_octet_to_sk(octet_sk, &sk);
	octet *p = o_new(L, RFS_4096); SAFE_GOTO(p, "Could not create plaintext");
	RSA_4096_DECRYPT(&sk, c, p);
	OAEP_DECODE(HASH_TYPE_RSA_4096,NULL,p);
end:
	RSA_4096_PRIVATE_KEY_KILL(&sk);
	o_free(L, octet_sk);
	o_free(L, c);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}
static int rsa_sign(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *octet_sk = NULL, *msg = NULL, *p = NULL;
	octet_sk =  o_arg(L, 1); SAFE_GOTO(octet_sk, "Could not allocate private key");
	SAFE_GOTO(octet_sk->len == RSA_4096_PRIVATE_KEY_BYTES, "Invalid private key size");
	msg = o_arg(L, 2); SAFE_GOTO(msg, "Could not allocate message");

	rsa_private_key_4096 sk; 
	RSA_octet_to_sk(octet_sk, &sk);
	p = o_alloc(L, RFS_4096); SAFE_GOTO(p, "Could not allocate padded message");
	octet *sig = o_new(L,RFS_4096); SAFE_GOTO(sig, "Could not create signature");
	PKCS15(HASH_TYPE_RSA_4096,msg,p);
	RSA_4096_DECRYPT(&sk, p, sig);
end:
	RSA_4096_PRIVATE_KEY_KILL(&sk);
	o_free(L, octet_sk);
	o_free(L, msg);
	o_free(L, p);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int rsa_verify(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *octet_pk = NULL, *msg = NULL, *sig = NULL, *p = NULL, *c = NULL;
	octet_pk =  o_arg(L, 1); SAFE_GOTO(octet_pk, "Could not allocate public key");
	SAFE_GOTO(octet_pk->len == RSA_4096_PUBLIC_KEY_BYTES, "Invalid public key size");
	msg = o_arg(L, 2); SAFE_GOTO(msg, "Could not allocate message");
	sig = o_arg(L, 3); SAFE_GOTO(sig, "Could not allocate signature");

	rsa_public_key_4096 pk;
	SAFE_GOTO(RSA_octet_to_pk(L, octet_pk, &pk), "Could not convert octet to public key");

	p = o_alloc(L, RFS_4096); SAFE_GOTO(p, "Could not allocate padded message");
	PKCS15(HASH_TYPE_RSA_4096,msg,p);

	c = o_alloc(L, RFS_4096); SAFE_GOTO(c, "Could not allocate ciphertext");
	RSA_4096_ENCRYPT(&pk, sig, c);

	lua_pushboolean(L, OCT_comp(c,p));
end:
	o_free(L, octet_pk);
	o_free(L, msg);
	o_free(L, sig);
	o_free(L, p);
	o_free(L, c);
	if(failed_msg) {
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
		{"sign", rsa_sign},
		{"verify", rsa_verify},
		{"pubgen", rsa_pubgen},
		{"pubcheck", rsa_signature_pubcheck},
		{"signature_check", rsa_signature_check},
		{NULL,NULL}
	};
	const struct luaL_Reg rsa_methods[] = {
		{NULL,NULL}
	};

	zen_add_class(L, "rsa", rsa_class, rsa_methods);
	return 1;
}
