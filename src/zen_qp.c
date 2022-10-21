/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2020 Dyne.org foundation
 * designed, written and maintained by Alberto Lerda <albertolerda97@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 */

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <zenroom.h>
#include <zen_error.h>
#include <zen_memory.h>
#include <lua_functions.h>
#include <zen_octet.h>

/*
  Quantum proof dilithium digital signature
*/
#define PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_PUBLICKEYBYTES 1312
#define PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_SECRETKEYBYTES 2528
#define PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_BYTES          2420
#define PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_ALGNAME        "Dilithium2"
extern int PQCLEAN_DILITHIUM2_CLEAN_crypto_sign_keypair(uint8_t *pk, uint8_t *sk);
extern int PQCLEAN_DILITHIUM2_CLEAN_crypto_pub_gen(uint8_t *pk, uint8_t *sk);
extern int PQCLEAN_DILITHIUM2_CLEAN_crypto_sign_signature(
	uint8_t *sig, size_t *siglen,
	const uint8_t *m, size_t mlen, const uint8_t *sk);
extern int PQCLEAN_DILITHIUM2_CLEAN_crypto_sign_verify(
	const uint8_t *sig, size_t siglen,
	const uint8_t *m, size_t mlen, const uint8_t *pk);
extern int PQCLEAN_DILITHIUM2_CLEAN_crypto_sign(
	uint8_t *sm, size_t *smlen,
	const uint8_t *m, size_t mlen, const uint8_t *sk);
extern int PQCLEAN_DILITHIUM2_CLEAN_crypto_sign_open(
	uint8_t *m, size_t *mlen,
	const uint8_t *sm, size_t smlen, const uint8_t *pk);

/*
  Quantum proof kyber kem/cipher
*/
#define PQCLEAN_KYBER512_CLEAN_CRYPTO_SECRETKEYBYTES  1632
#define PQCLEAN_KYBER512_CLEAN_CRYPTO_PUBLICKEYBYTES  800
#define PQCLEAN_KYBER512_CLEAN_CRYPTO_CIPHERTEXTBYTES 768
#define PQCLEAN_KYBER512_CLEAN_CRYPTO_BYTES           32
#define PQCLEAN_KYBER512_CLEAN_CRYPTO_ALGNAME         "Kyber512"
#define KYBER_SSBYTES                                 32   /* size in bytes of shared key */
extern int PQCLEAN_KYBER512_CLEAN_crypto_kem_keypair(uint8_t *pk, uint8_t *sk);
extern int PQCLEAN_KYBER512_CLEAN_crypto_pub_gen(uint8_t *pk, uint8_t *sk);
extern int PQCLEAN_KYBER512_CLEAN_crypto_kem_enc(uint8_t *ct, uint8_t *ss, const uint8_t *pk);
extern int PQCLEAN_KYBER512_CLEAN_crypto_kem_dec(uint8_t *ss, const uint8_t *ct, const uint8_t *sk);

/*
  Quantum proof Streamlined NTRU Prime kem/cipher
*/
#define PQCLEAN_SNTRUP761_CLEAN_CRYPTO_SECRETKEYBYTES  1763
#define PQCLEAN_SNTRUP761_CLEAN_CRYPTO_PUBLICKEYBYTES  1158
#define PQCLEAN_SNTRUP761_CLEAN_CRYPTO_CIPHERTEXTBYTES 1039
#define PQCLEAN_SNTRUP761_CLEAN_CRYPTO_BYTES           32
#define PQCLEAN_SNTRUP761_CLEAN_CRYPTO_ALGNAME         "sntrup761"
extern int PQCLEAN_SNTRUP761_CLEAN_crypto_kem_keypair(uint8_t *pk, uint8_t *sk);
extern int PQCLEAN_SNTRUP761_CLEAN_crypto_kem_pubgen(uint8_t *pk, uint8_t *sk);
extern int PQCLEAN_SNTRUP761_CLEAN_crypto_kem_enc(uint8_t *ct, uint8_t *ss, const uint8_t *pk);
extern int PQCLEAN_SNTRUP761_CLEAN_crypto_kem_dec(uint8_t *ss, const uint8_t *ct, const uint8_t *sk);



/*#######################################*/
/*              Dilithium 2              */
/*#######################################*/
static int qp_signature_keygen(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	lua_createtable(L, 0, 2);
	octet *private = o_new(L, PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_SECRETKEYBYTES);
	if(private == NULL) {
		failed_msg = "Could not allocate private key";
		goto end;
	}
	lua_setfield(L, -2, "private");
	octet *public = o_new(L, PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_PUBLICKEYBYTES);
	if(public == NULL) {
		failed_msg = "Could not allocate public key";
		goto end;
	}
	lua_setfield(L, -2, "public");

	PQCLEAN_DILITHIUM2_CLEAN_crypto_sign_keypair((unsigned char*)public->val,
						     (unsigned char*)private->val);
	public->len = PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_PUBLICKEYBYTES;
	private->len = PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_SECRETKEYBYTES;

end:
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int qp_signature_pubgen(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *sk = NULL, *pk = NULL;
	sk = o_arg(L, 1);
	if(sk == NULL) {
		failed_msg = "failed to allocate space for secret key";
		goto end;
	}
	pk = o_new(L, PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_PUBLICKEYBYTES);
	if(pk == NULL) {
		failed_msg = "failed to allocate space for public key";
		goto end;
	}

	PQCLEAN_DILITHIUM2_CLEAN_crypto_pub_gen((unsigned char*)pk->val,
						(unsigned char*)sk->val);
	pk->len = PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_PUBLICKEYBYTES;

end:
	o_free(L,sk);
	if(failed_msg != NULL) {
		THROW(failed_msg);
	}

	END(1);
}

// checks the singature length
static int qp_signature_pubcheck(lua_State *L) {
	BEGIN();
	octet *pk = o_arg(L, 1);
	if(pk == NULL) {
		THROW("failed to allocate space for public key");
	} else {
		if(pk->len == PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_PUBLICKEYBYTES)
			lua_pushboolean(L, 1);
		else
			lua_pushboolean(L, 0);
		o_free(L, pk);
	}
	END(1);
}

static int qp_sign(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *sk = NULL, *m = NULL;
	sk = o_arg(L, 1);
	if(sk == NULL) {
		failed_msg = "failed to allocate space for secret key";
		goto end;
	}
	m = o_arg(L, 2);
	if(m == NULL) {
		failed_msg = "failed to allocate space for message";
		goto end;
	}

	if(sk->len != PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_SECRETKEYBYTES) {
		failed_msg = "wrong secret key length";
		goto end;
	}
	octet *sig = o_new(L, PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_BYTES);
	if(sig == NULL) {
		failed_msg = "failed to allocate space for signature";
		goto end;
	}
	if(PQCLEAN_DILITHIUM2_CLEAN_crypto_sign_signature((unsigned char*)sig->val,
							  (size_t*)&sig->len,
							  (unsigned char*)m->val, m->len,
							  (unsigned char*)sk->val)
	   && sig->len > 0) {
		failed_msg = "error in the signature";
		goto end;
	}
end:
	o_free(L,m);
	o_free(L,sk);

	if(failed_msg != NULL) {
		THROW(failed_msg);
	}
	END(1);
}

// generate an octet which is signature+message
static int qp_signed_message(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *sk = NULL, *m = NULL;
	sk = o_arg(L, 1);
	if(sk == NULL) {
		failed_msg = "failed to allocate space for secret key";
		goto end;
	}
	m = o_arg(L, 2);
	if(m == NULL) {
		failed_msg = "failed to allocate space for message";
		goto end;
	}

	if(sk->len != PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_SECRETKEYBYTES) {
		failed_msg = "invalid size for secret key";
		goto end;
	}
	octet *sig = o_new(L, PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_BYTES+m->len);
	if(sig == NULL) {
		failed_msg = "could not allocate space for signature";
		goto end;
	}

	if(PQCLEAN_DILITHIUM2_CLEAN_crypto_sign((unsigned char*)sig->val,
						(size_t*)&sig->len,
						(unsigned char*)m->val, m->len,
						(unsigned char*)sk->val)
	   && sig->len > 0) {
		failed_msg = "error in the signature";
		goto end;
	}

end:
	o_free(L,m);
	o_free(L,sk);
	if(failed_msg != NULL) {
		THROW(failed_msg);
	}
	END(1);
}

static int qp_verified_message(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *pk = NULL, *sm = NULL;
	pk = o_arg(L, 1);
	if(pk == NULL) {
		failed_msg = "Could not allocate space for public key";
		goto end;
	}
	sm = o_arg(L, 2);
	if(sm == NULL) {
		failed_msg = "Could not allocate space for secret message";
		goto end;
	}

	if(pk->len != PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_PUBLICKEYBYTES) {
		failed_msg = "invalid size for public key";
		goto end;
	}

	octet *msg = o_new(L, sm->len);
	if(msg == NULL) {
		failed_msg = "Could not allocate space for message";
		goto end;
	}

	int result = PQCLEAN_DILITHIUM2_CLEAN_crypto_sign_open((unsigned char*)msg->val,
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

static int qp_verify(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *pk = NULL, *sig = NULL, *m = NULL;
	pk = o_arg(L, 1);
	if(pk == NULL) {
		failed_msg = "Could not allocate space for public key";
		goto end;
	}
	sig = o_arg(L, 2);
	if(sig == NULL) {
		failed_msg = "Could not allocate space for signature";
		goto end;
	}
	m = o_arg(L, 3);
	if(m == NULL) {
		failed_msg = "Could not allocate space for message";
		goto end;
	}

	if(pk->len != PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_PUBLICKEYBYTES) {
		failed_msg = "invalid size for public key";
		goto end;
	}

	int result = PQCLEAN_DILITHIUM2_CLEAN_crypto_sign_verify((unsigned char*)sig->val,
								 (size_t)sig->len,
								 (unsigned char*)m->val, m->len,
								 (unsigned char*)pk->val);
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

static int qp_signature_len(lua_State *L){
	BEGIN();
	lua_pushinteger(L, PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_BYTES);
	END(1);
}

static int qp_signature_check(lua_State *L){
	BEGIN();
	char *failed_msg = NULL;
	octet *sign = o_arg(L, 1);
	if(sign == NULL) {
		failed_msg = "Cuold not allocate signature";
		goto end;
	}
	if(sign->len == PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_BYTES)
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

/*#######################################*/
/*               Kyber 512               */
/*#######################################*/
static int qp_kem_keygen(lua_State *L) {
	BEGIN();
	lua_createtable(L, 0, 2);
	octet *private = o_new(L, PQCLEAN_KYBER512_CLEAN_CRYPTO_SECRETKEYBYTES); SAFE(private);
	lua_setfield(L, -2, "private");
	octet *public = o_new(L, PQCLEAN_KYBER512_CLEAN_CRYPTO_PUBLICKEYBYTES); SAFE(public);
	lua_setfield(L, -2, "public");

	PQCLEAN_KYBER512_CLEAN_crypto_kem_keypair((unsigned char*)public->val, (unsigned char*)private->val);
	public->len = PQCLEAN_KYBER512_CLEAN_CRYPTO_PUBLICKEYBYTES;
	private->len = PQCLEAN_KYBER512_CLEAN_CRYPTO_SECRETKEYBYTES;

	END(1);
}

static int qp_kem_pubgen(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *sk = NULL, *pk = NULL;
	sk = o_arg(L, 1);
	if(sk == NULL) {
		failed_msg = "Could not allocate secret key";
		goto end;
	}
	pk = o_new(L, PQCLEAN_KYBER512_CLEAN_CRYPTO_PUBLICKEYBYTES);
	if(pk == NULL) {
		failed_msg = "Could not allocate private key";
		goto end;
	}

	PQCLEAN_KYBER512_CLEAN_crypto_pub_gen((unsigned char*)pk->val,
					      (unsigned char*)sk->val);
	pk->len = PQCLEAN_KYBER512_CLEAN_CRYPTO_PUBLICKEYBYTES;

end:
	o_free(L, sk);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

// checks the public key length
static int qp_kem_pubcheck(lua_State *L) {
	BEGIN();
	octet *pk = o_arg(L, 1);
	if(pk == NULL) {
		THROW("Could not allocate public key");
	} else {
		if(pk->len == PQCLEAN_KYBER512_CLEAN_CRYPTO_PUBLICKEYBYTES)
			lua_pushboolean(L, 1);
		else
			lua_pushboolean(L, 0);
		o_free(L,pk);
	}
	END(1);
}

// checks the shared secret length
static int qp_kem_sscheck(lua_State *L) {
	BEGIN();
	octet *ss = o_arg(L, 1);
	if(ss == NULL) {
		THROW("Could not allocate kem secret");
	} else {
		if(ss->len == KYBER_SSBYTES)
			lua_pushboolean(L, 1);
		else
			lua_pushboolean(L, 0);
		o_free(L, ss);
	}
	END(1);
}

// check the ciphertext length
static int qp_kem_ctcheck(lua_State *L) {
	BEGIN();
	octet *ct = o_arg(L, 1);
	if(ct == NULL) {
		THROW("Could not allocate kem ciphertext");
	} else {
		if(ct->len == PQCLEAN_KYBER512_CLEAN_CRYPTO_CIPHERTEXTBYTES)
			lua_pushboolean(L, 1);
		else
			lua_pushboolean(L, 0);
		o_free(L, ct);
	}
	END(1);
}

static int qp_enc(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *pk = NULL, *ss = NULL, *ct = NULL;
	pk = o_arg(L, 1);
	if(pk == NULL) {
		failed_msg = "Cuold not allocate public key";
		goto end;
	}
	if(pk->len != PQCLEAN_KYBER512_CLEAN_CRYPTO_PUBLICKEYBYTES) {
		failed_msg = "invalid size for public key";
		goto end;
	}
	lua_createtable(L, 0, 2);
	ss = o_new(L, KYBER_SSBYTES);
	if(ss == NULL) {
		failed_msg = "Could not allocate kem secret";
		goto end;
	}
	lua_setfield(L, -2, "secret"); // shared secret
	ct = o_new(L, PQCLEAN_KYBER512_CLEAN_CRYPTO_CIPHERTEXTBYTES);
	if(ct == NULL) {
		failed_msg = "Could not allocate kem ciphertext";
		goto end;
	}
	lua_setfield(L, -2, "cipher");

	if(PQCLEAN_KYBER512_CLEAN_crypto_kem_enc((unsigned char*)ct->val,
						 (unsigned char*)ss->val,
						 (unsigned char*)pk->val)) {
		failed_msg = "error in the creation of the shared secret";
		goto end;
	}
	ss->len = KYBER_SSBYTES;
	ct->len = PQCLEAN_KYBER512_CLEAN_CRYPTO_CIPHERTEXTBYTES;
end:
	o_free(L,pk);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int qp_dec(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *sk = NULL, *ct = NULL;
	sk = o_arg(L, 1);
	ct = o_arg(L, 2);
	if(sk == NULL || ct == NULL) {
		failed_msg = "Could not allocate memory during decription";
		goto end;
	}
	if(sk->len != PQCLEAN_KYBER512_CLEAN_CRYPTO_SECRETKEYBYTES) {
		failed_msg = "invalid size for secret key";
		goto end;
	}
	if(ct->len != PQCLEAN_KYBER512_CLEAN_CRYPTO_CIPHERTEXTBYTES) {
		failed_msg = "invalid size for ciphertext key";
		goto end;
	}
	octet *ss = o_new(L, KYBER_SSBYTES);
	if(ss == NULL) {
		failed_msg = "Could not allocate kem secret";
		goto end;
	}
	if(PQCLEAN_KYBER512_CLEAN_crypto_kem_dec((unsigned char*)ss->val,
						 (unsigned char*)ct->val,
						 (unsigned char*)sk->val)) {
		failed_msg = "error in while deciphering the shared secret";
		goto end;
	}
	ss->len = KYBER_SSBYTES;
end:
	o_free(L,sk);
	o_free(L,ct);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}


/*#######################################*/
/*              SNTRUP 761               */
/*#######################################*/
static int qp_sntrup_kem_keygen(lua_State *L) {
	BEGIN();
	lua_createtable(L, 0, 2);
	octet *private = o_new(L, PQCLEAN_SNTRUP761_CLEAN_CRYPTO_SECRETKEYBYTES);
	if(private == NULL) {
		THROW("Could not allocate private key");
		return 1;
	}
	lua_setfield(L, -2, "private");
	octet *public = o_new(L, PQCLEAN_SNTRUP761_CLEAN_CRYPTO_PUBLICKEYBYTES);
	if(private == NULL) {
		THROW("Could not allocate public key");
		return 1;
	}
	lua_setfield(L, -2, "public");

	PQCLEAN_SNTRUP761_CLEAN_crypto_kem_keypair((unsigned char*)public->val,
						   (unsigned char*)private->val);
	public->len = PQCLEAN_SNTRUP761_CLEAN_CRYPTO_PUBLICKEYBYTES;
	private->len = PQCLEAN_SNTRUP761_CLEAN_CRYPTO_SECRETKEYBYTES;
	END(1);
}

static int qp_sntrup_kem_pubgen(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *sk = o_arg(L, 1);
	if(sk == NULL) {
		failed_msg = "Could not allocate secret key";
		goto end;
	}
	octet *pk = o_new(L, PQCLEAN_SNTRUP761_CLEAN_CRYPTO_PUBLICKEYBYTES);
	if(pk == NULL) {
		failed_msg = "Could not allocate public key";
		goto end;
	}

	PQCLEAN_SNTRUP761_CLEAN_crypto_kem_pubgen((unsigned char*)pk->val,
						  (unsigned char*)sk->val);
	pk->len = PQCLEAN_SNTRUP761_CLEAN_CRYPTO_PUBLICKEYBYTES;

end:
	o_free(L, sk);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int qp_sntrup_kem_pubcheck(lua_State *L) {
	BEGIN();
	octet *pk = o_arg(L, 1);
	if(pk == NULL) {
		THROW("Could not allocate public key");
	} else {
		if(pk->len == PQCLEAN_SNTRUP761_CLEAN_CRYPTO_PUBLICKEYBYTES)
			lua_pushboolean(L, 1);
		else
			lua_pushboolean(L, 0);
		o_free(L, pk);
	}
	END(1);
}

static int qp_sntrup_kem_sscheck(lua_State *L) {
	BEGIN();
	octet *ss = o_arg(L, 1);
	if(ss == NULL) {
		THROW("Could not allocate kem secret");
	} else {
		if(ss->len == PQCLEAN_SNTRUP761_CLEAN_CRYPTO_BYTES)
			lua_pushboolean(L, 1);
		else
			lua_pushboolean(L, 0);
		o_free(L,ss);
	}
	END(1);
}

static int qp_sntrup_kem_ctcheck(lua_State *L) {
	BEGIN();
	octet *ct = o_arg(L, 1);
	if(ct == NULL) {
		THROW("Could not allocate kem ciphertext");
	} else {
		if(ct->len == PQCLEAN_SNTRUP761_CLEAN_CRYPTO_CIPHERTEXTBYTES)
			lua_pushboolean(L, 1);
		else
			lua_pushboolean(L, 0);
		o_free(L,ct);
	}
	END(1);
}

static int qp_sntrup_kem_enc(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *pk = NULL, *ss = NULL, *ct = NULL;
	pk = o_arg(L, 1);
	if(pk == NULL) {
		failed_msg = "Could not allocate public key";
		goto end;
	} else if(pk->len != PQCLEAN_SNTRUP761_CLEAN_CRYPTO_PUBLICKEYBYTES) {
		failed_msg = "invalid size for public key";
		goto end;
	}
	lua_createtable(L, 0, 2);
	ss = o_new(L, PQCLEAN_SNTRUP761_CLEAN_CRYPTO_BYTES);
	if(ss == NULL) {
		failed_msg = "Could not allocate kem secret";
		goto end;
	}
	lua_setfield(L, -2, "secret"); // shared secret
	ct = o_new(L, PQCLEAN_SNTRUP761_CLEAN_CRYPTO_CIPHERTEXTBYTES);
	if(ct == NULL) {
		failed_msg = "Could not allocate kem ciphertext";
		goto end;
	}
	lua_setfield(L, -2, "cipher");

	if(PQCLEAN_SNTRUP761_CLEAN_crypto_kem_enc((unsigned char*)ct->val,
						  (unsigned char*)ss->val,
						  (unsigned char*)pk->val)) {
		failed_msg = "error in the creation of the shared secret";
		goto end;
	}
	ss->len = PQCLEAN_SNTRUP761_CLEAN_CRYPTO_BYTES;
	ct->len = PQCLEAN_SNTRUP761_CLEAN_CRYPTO_CIPHERTEXTBYTES;
end:
	o_free(L,pk);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int qp_sntrup_kem_dec(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *sk = o_arg(L, 1);
	octet *ct = o_arg(L, 2);
	if(sk == NULL || ct == NULL) {
		failed_msg = "Could not allocate secret key or ciphertext";
		goto end;
	}
	if(sk->len != PQCLEAN_SNTRUP761_CLEAN_CRYPTO_SECRETKEYBYTES) {
		failed_msg = "invalid size for secret key";
		goto end;
	}
	if(ct->len != PQCLEAN_SNTRUP761_CLEAN_CRYPTO_CIPHERTEXTBYTES) {
		failed_msg = "invalid size for ciphertext key";
		goto end;
	}
	octet *ss = o_new(L, PQCLEAN_SNTRUP761_CLEAN_CRYPTO_BYTES);
	if(ss == NULL) {
		failed_msg = "Could not allocate kem secret";
		goto end;
	}

	if(PQCLEAN_SNTRUP761_CLEAN_crypto_kem_dec((unsigned char*)ss->val,
						  (unsigned char*)ct->val,
						  (unsigned char*)sk->val)) {
		failed_msg = "error in while deciphering the shared secret";
		goto end;
	}
	ss->len = PQCLEAN_SNTRUP761_CLEAN_CRYPTO_BYTES;
end:
	o_free(L,sk);
	o_free(L,ct);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

int luaopen_qp(lua_State *L) {
	(void)L;
	const struct luaL_Reg ecdh_class[] = {
		// Dilithium2
		{"sigkeygen", qp_signature_keygen},
		{"sigpubgen", qp_signature_pubgen},
		{"sigpubcheck", qp_signature_pubcheck},
		{"sign", qp_sign},
		{"signed_msg", qp_signed_message},
		{"verify", qp_verify},
		{"verified_msg", qp_verified_message},
		{"signature_len", qp_signature_len},
		{"signature_check", qp_signature_check},
		// Kyber512
		{"kemkeygen", qp_kem_keygen},
		{"kempubgen", qp_kem_pubgen},
		{"kempubcheck", qp_kem_pubcheck},
		{"kemsscheck", qp_kem_sscheck},
		{"kemctcheck", qp_kem_ctcheck},
		{"enc", qp_enc},
		{"dec", qp_dec},
		// SNTRUP761
		{"ntrup_keygen", qp_sntrup_kem_keygen},
		{"ntrup_pubgen", qp_sntrup_kem_pubgen},
		{"ntrup_pubcheck", qp_sntrup_kem_pubcheck},
		{"ntrup_sscheck", qp_sntrup_kem_sscheck},
		{"ntrup_ctcheck", qp_sntrup_kem_ctcheck},
		{"ntrup_enc", qp_sntrup_kem_enc},
		{"ntrup_dec", qp_sntrup_kem_dec},
		{NULL,NULL}
	};
	const struct luaL_Reg ecdh_methods[] = {
		{NULL,NULL}
	};

	zen_add_class(L, "qp", ecdh_class, ecdh_methods);
	return 1;
}
