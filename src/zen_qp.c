/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2025 Dyne.org foundation
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

/// <h1> POST QUANTUM (QP) </h1>
//
// Post-quantum cryptography (PQC) refers to cryptographic algorithms that are designed to be secure against attacks by quantum computers. 
// Traditional cryptographic systems, such as RSA and ECC (Elliptic Curve Cryptography), rely on mathematical problems (e.g., integer factorization and discrete logarithms) 
// that are hard for classical computers but can be efficiently solved by quantum computers using algorithms like Shor's algorithm. 
// Post-quantum cryptography aims to address this vulnerability by developing new algorithms based on mathematical problems that are believed to be resistant to quantum attacks.
//
// In this section two post-quantum schemes are described: ML-KEM and ML-DSA. The first one deals with key encapsulation and the second one is a signature scheme.
//
// All function inputs (secret key, public key, message, ciphertext, signature, seed and context) are octets and some of them have a fixed length. Only the version for ML-KEM is passed to the functions as a string.
// @module QP
//

#include <zenroom.h>
#include <zen_error.h>
#include <lua_functions.h>
#include <zen_octet.h>
#include <zen_error.h>

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
	MLKEM (FIPS203)
*/
#define MLKEM512_SECRETKEYBYTES 1632
#define MLKEM512_PUBLICKEYBYTES 800
#define MLKEM512_CIPHERTEXTBYTES 768
#define MLKEM768_SECRETKEYBYTES 2400
#define MLKEM768_PUBLICKEYBYTES 1184
#define MLKEM768_CIPHERTEXTBYTES 1088
#define MLKEM1024_SECRETKEYBYTES 3168
#define MLKEM1024_PUBLICKEYBYTES 1568
#define MLKEM1024_CIPHERTEXTBYTES 1568
#define MLKEM_BYTES 32
#define MLKEM512_BYTES MLKEM_BYTES
#define MLKEM768_BYTES MLKEM_BYTES
#define MLKEM1024_BYTES MLKEM_BYTES
#define MLKEM_POLYBYTES 384
#define MLKEM512_INDCPA_SECRETKEYBYTES  (MLKEM_POLYBYTES * 2)
#define MLKEM768_INDCPA_SECRETKEYBYTES  (MLKEM_POLYBYTES * 3)
#define MLKEM1024_INDCPA_SECRETKEYBYTES (MLKEM_POLYBYTES * 4)
extern int mlkem512_keypair_derand(uint8_t *pk, uint8_t *sk,
								   const uint8_t *coins);
extern int mlkem512_keypair(uint8_t *pk, uint8_t *sk);
extern int mlkem512_enc_derand(uint8_t *ct, uint8_t *ss, const uint8_t *pk,
							   const uint8_t *coins);
extern int mlkem512_enc(uint8_t *ct, uint8_t *ss, const uint8_t *pk);
extern int mlkem512_dec(uint8_t *ss, const uint8_t *ct, const uint8_t *sk);
extern int mlkem768_keypair_derand(uint8_t *pk, uint8_t *sk,
								   const uint8_t *coins);
extern int mlkem768_keypair(uint8_t *pk, uint8_t *sk);
extern int mlkem768_enc_derand(uint8_t *ct, uint8_t *ss, const uint8_t *pk,
							   const uint8_t *coins);
extern int mlkem768_enc(uint8_t *ct, uint8_t *ss, const uint8_t *pk);
extern int mlkem768_dec(uint8_t *ss, const uint8_t *ct, const uint8_t *sk);
extern int mlkem1024_keypair_derand(uint8_t *pk, uint8_t *sk,
								   const uint8_t *coins);
extern int mlkem1024_keypair(uint8_t *pk, uint8_t *sk);
extern int mlkem1024_enc_derand(uint8_t *ct, uint8_t *ss, const uint8_t *pk,
							   const uint8_t *coins);
extern int mlkem1024_enc(uint8_t *ct, uint8_t *ss, const uint8_t *pk);
extern int mlkem1024_dec(uint8_t *ss, const uint8_t *ct, const uint8_t *sk);


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


/*
  Quantum proof ML-DSA-44 with pqcrystals dilithium2
*/
#define pqcrystals_ml_dsa_44_PUBLICKEYBYTES 1312
#define pqcrystals_ml_dsa_44_SECRETKEYBYTES 2560
#define pqcrystals_ml_dsa_44_BYTES 2420
extern int pqcrystals_ml_dsa_44_zen_keypair(uint8_t *pk, uint8_t *sk, const uint8_t *randbytes);
extern int pqcrystals_ml_dsa_44_zen_signature(uint8_t *sig, size_t *siglen, const uint8_t *m, size_t mlen, const uint8_t *ctx, size_t ctxlen, const uint8_t *sk, const uint8_t *randbytes);
extern int pqcrystals_ml_dsa_44_ref_verify(const uint8_t *sig, size_t siglen, const uint8_t *m, size_t mlen, const uint8_t *ctx, size_t ctxlen, const uint8_t *pk);
extern int pqcrystals_ml_dsa_44_zen_pub_gen(uint8_t *pk, uint8_t *sk);


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
	const octet *sk = NULL;
	octet *pk = NULL;
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
	const octet *pk = o_arg(L, 1);
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
	const octet *sk = NULL, *m = NULL;
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
	const octet *sk = NULL, *m = NULL;
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
	const octet *pk = NULL, *sm = NULL;
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
	const octet *pk = NULL, *sig = NULL, *m = NULL;
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
	const octet *sign = o_arg(L, 1);
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
	octet *private = o_new(L, PQCLEAN_KYBER512_CLEAN_CRYPTO_SECRETKEYBYTES);
	lua_setfield(L, -2, "private");
	octet *public = o_new(L, PQCLEAN_KYBER512_CLEAN_CRYPTO_PUBLICKEYBYTES);
	lua_setfield(L, -2, "public");

	PQCLEAN_KYBER512_CLEAN_crypto_kem_keypair((unsigned char*)public->val, (unsigned char*)private->val);
	public->len = PQCLEAN_KYBER512_CLEAN_CRYPTO_PUBLICKEYBYTES;
	private->len = PQCLEAN_KYBER512_CLEAN_CRYPTO_SECRETKEYBYTES;

	END(1);
}

static int qp_kem_pubgen(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *sk = NULL;
	octet *pk = NULL;
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
	const octet *pk = o_arg(L, 1);
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
	const octet *ss = o_arg(L, 1);
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
	const octet *ct = o_arg(L, 1);
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
	const octet *pk = NULL;
	octet *ss = NULL, *ct = NULL;
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
	const octet *sk = NULL, *ct = NULL;
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


/// Global ML-KEM Functions
// @section ML-KEM 
//
// ML-KEM (Kyber Key Encapsulation Mechanism) is a post-quantum cryptographic key encapsulation mechanism (KEM) designed for secure key exchange. It is part of the NIST 
// Post-Quantum Cryptography Standardization process and has been selected as a standard for public-key encryption and KEMs.
// ML-KEM is based on Module Learning With Errors (MLWE), making it resistant to attacks from quantum computers.
//
// It provides different security levels (Kyber-512, Kyber-768, Kyber-1024) that correspond to classical and quantum security estimates.
// In particular, for each of the below functions, it is possible define in input which version of ML-KEM to use. The three possibilities are:
//
//- MLKEM512: size pk = 800 byte, size sk = 1632 byte
//
//- MLKEM768: size pk = 1184 byte, size sk = 2400 byte
//
//- MLKEM1024: size pk = 1568 byte, size sk = 3168 byte 
//
// Unlike traditional encryption schemes, ML-KEM encapsulates a symmetric key, which is then used for further encrypted communication.
//
// At the beginning of each function you require <code> QP = require("qp") </code>. In this way you load the QP module and assign it to the variable QP.
//

/*#######################################*/
/*               ML-KEM (FIPS203)        */
/*#######################################*/
typedef enum {
    MLKEM512,
    MLKEM768,
    MLKEM1024,
    UNKNOWN
} mlkem_type;
static mlkem_type _get_mlkem_type(const char *str) {
	if(strcmp(str,"mlkem512")==0) return MLKEM512;
	if(strcmp(str,"mlkem768")==0) return MLKEM768;
	if(strcmp(str,"mlkem1024")==0) return MLKEM1024;
	return UNKNOWN;
}

/*** Allow to create a couple (public key, secret key) taking in input two octet of 32 byte length.
	*The length of the public and secret keys generated depends on the version of MLKEM required. The version 
	*is passed as third argument of the function. If the third argument is NULL, the function applies MLKEM512. 
	*The function generates 64 bytes of random data: the first 32 bytes can be provided as the first argument (seed 1);
	*the next 32 bytes can be provided as the second argument (seed 2). If either seed is not provided, the function generates random bytes.

 @function QP.mlkem_keygen
 @param seed1 (optional)
 @param seed2 (optional)
 @param string where string can be: "mlkem512", "mlkem768", "mlkem1024"
 @return a couple of public key and and secret key
 @usage
 QP = require("qp")
 oct1 = OCTET.random(32)
 oct2 = OCTET.random(32)
 pk768 = QP.mlkem_keygen(oct1, oct2, "mlkem768").public
 sk768 = QP.mlkem_keygen(oct1, oct2, "mlkem768").private
 */ 

static int mlkem_keygen(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	uint8_t randbytes[64];
	// random can be passed as argument: two octets of 32 bytes each
	void *ud;
	ud = luaL_testudata(L,1,"zenroom.octet");
	if (ud){
		octet * rnd = (octet*) ud;
		if (rnd->len != 32) {
			failed_msg = "Wrong seed size";
			goto end; }
		memcpy(randbytes,rnd->val,32);
	} else {
		Z(L);
		for(uint8_t i=0;i<32;i++) {
			randbytes[i] = RAND_byte(Z->random_generator);
		}
	}
	ud = luaL_testudata(L,2,"zenroom.octet");
	if (ud){
		octet * rnd = (octet*) ud;
		if (rnd->len != 32) {
			failed_msg = "Wrong seed size";
			goto end; }
		memcpy(&randbytes[32],rnd->val,32);
	} else {
		Z(L);
		for(uint8_t i=32;i<64;i++) {
			randbytes[i] = RAND_byte(Z->random_generator);
		}
	}
	octet *private, *public;
	const char *s = lua_tostring(L, 3);
	if(!s) s = "mlkem512";
	switch(_get_mlkem_type(s)) {
	case MLKEM512:
		lua_createtable(L, 0, 2);
		private = o_new(L, MLKEM512_SECRETKEYBYTES);
		lua_setfield(L, -2, "private");
		public = o_new(L, MLKEM512_PUBLICKEYBYTES);
		lua_setfield(L, -2, "public");
		mlkem512_keypair_derand((unsigned char*)public->val,
								(unsigned char*)private->val,
								randbytes);
		public->len = MLKEM512_PUBLICKEYBYTES;
		private->len = MLKEM512_SECRETKEYBYTES;
		break;
	case MLKEM768:
		lua_createtable(L, 0, 2);
		private = o_new(L, MLKEM768_SECRETKEYBYTES);
		lua_setfield(L, -2, "private");
		public = o_new(L, MLKEM768_PUBLICKEYBYTES);
		lua_setfield(L, -2, "public");
		mlkem768_keypair_derand((unsigned char*)public->val,
								(unsigned char*)private->val,
								randbytes);
		public->len = MLKEM768_PUBLICKEYBYTES;
		private->len = MLKEM768_SECRETKEYBYTES;
		break;
	case MLKEM1024:
		lua_createtable(L, 0, 2);
		private = o_new(L, MLKEM1024_SECRETKEYBYTES);
		lua_setfield(L, -2, "private");
		public = o_new(L, MLKEM1024_PUBLICKEYBYTES);
		lua_setfield(L, -2, "public");
		mlkem1024_keypair_derand((unsigned char*)public->val,
								(unsigned char*)private->val,
								randbytes);
		public->len = MLKEM1024_PUBLICKEYBYTES;
		private->len = MLKEM1024_SECRETKEYBYTES;
		break;
	case UNKNOWN:
		zerror("Unknown MLKEM type: %s (%s)",s,__func__);
		failed_msg = "MLKEM error";
		break;
	}
 end:
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}


/***
 Generate a public key starting from an octet (the secret key). The number of bytes
 should coincide with the number of bytes of the secret key of the asscociated MLKEM version used. 

 @function QP.mlkem_pubgen
 @param sk a secret key
 @param string where string can be: "mlkem512", "mlkem768", "mlkem1024"
 @return pk, the public key associated to an octet
 @usage
 QP = require("qp")
 sk = OCTET.random(2400)   -- is the secret key 
 pk = QP.mlkem_pubgen(sk, "mlkem768")

 */ 
static int mlkem_pubgen(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *sk = NULL;
	octet *pk = NULL;
	sk = o_arg(L, 1);
	if(sk == NULL) {
		failed_msg = "Could not allocate secret key";
		goto end;
	}
	const char *s = lua_tostring(L, 2);
	if(!s) s = "mlkem512";
	switch(_get_mlkem_type(s)) {
	case MLKEM512:
		pk = o_new(L, MLKEM512_PUBLICKEYBYTES);
		if(pk == NULL) {
			failed_msg = "Could not allocate private key";
			goto end; }
		memcpy((unsigned char*)pk->val,
			   (unsigned char*)sk->val
			   + MLKEM512_INDCPA_SECRETKEYBYTES,
			   MLKEM512_PUBLICKEYBYTES);
		pk->len = MLKEM512_PUBLICKEYBYTES;
		break;
	case MLKEM768:
		pk = o_new(L, MLKEM768_PUBLICKEYBYTES);
		if(pk == NULL) {
			failed_msg = "Could not allocate private key";
			goto end; }
		memcpy((unsigned char*)pk->val,
			   (unsigned char*)sk->val
			   + MLKEM768_INDCPA_SECRETKEYBYTES,
			   MLKEM768_PUBLICKEYBYTES);
		pk->len = MLKEM768_PUBLICKEYBYTES;
		break;
	case MLKEM1024:
		pk = o_new(L, MLKEM1024_PUBLICKEYBYTES);
		if(pk == NULL) {
			failed_msg = "Could not allocate private key";
			goto end; }
		memcpy((unsigned char*)pk->val,
			   (unsigned char*)sk->val
			   + MLKEM1024_INDCPA_SECRETKEYBYTES,
			   MLKEM1024_PUBLICKEYBYTES);
		pk->len = MLKEM1024_PUBLICKEYBYTES;
		break;
	case UNKNOWN:
		zerror("Unknown MLKEM type: %s (%s)",s,__func__);
		failed_msg = "MLKEM error";
		break;
	}
end:
	o_free(L, sk);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/*** Check if the public key has the correct length (it depends on the version of MLKEM used).
 
@function QP.mlkem_pubcheck
 @param pk a public key
 @param string where string can be: "mlkem512", "mlkem768", "mlkem1024"
 @return a boolean value: true if the length is correct, false otherwise

@usage
QP = require("qp")
oct = OCTET.random(230)				-- an octet of the wrong length 230 bytes
pk = QP.mlkem_pubgen(oct, "mlkem768")		-- an octet generated with the correct algorithm
bool1 = QP.mlkem_pubcheck(oct, "mlkem768")
bool2 = QP.mlkem_pubcheck(pk, "mlkem768")
if bool1 then print("true" )				
else print("false")
end
-- Output: false
if bool2 then print("true")
else print("false")
end
-- Output: true
 */ 

// checks the public key length
static int mlkem_pubcheck(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *pk = o_arg(L, 1);
	if(pk == NULL) {
		failed_msg = "Could not allocate public key";
		goto end;
	} else {
		const char *s = lua_tostring(L, 2);
		if(!s) s = "mlkem512";
		switch(_get_mlkem_type(s)) {
		case MLKEM512:
			if(pk->len == MLKEM512_PUBLICKEYBYTES)
				lua_pushboolean(L, 1);
			else
				lua_pushboolean(L, 0);
			break;
		case MLKEM768:
			if(pk->len == MLKEM768_PUBLICKEYBYTES)
				lua_pushboolean(L, 1);
			else
				lua_pushboolean(L, 0);
			break;
		case MLKEM1024:
			if(pk->len == MLKEM1024_PUBLICKEYBYTES)
				lua_pushboolean(L, 1);
			else
				lua_pushboolean(L, 0);
			break;
		case UNKNOWN:
			zerror("Unknown MLKEM type: %s (%s)",s,__func__);
			failed_msg = "MLKEM error";
			break;
		}
	}
 end:
	o_free(L,pk);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

// checks the shared secret length
static int mlkem_sscheck(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *ss = o_arg(L, 1);
	if(ss == NULL) {
		failed_msg = "Could not allocate kem secret";
		goto end;
	} else {

		const char *s = lua_tostring(L, 2);
		if(!s) s = "mlkem512";
		switch(_get_mlkem_type(s)) {
		case MLKEM512:
			if(ss->len == MLKEM512_BYTES)
				lua_pushboolean(L, 1);
			else
				lua_pushboolean(L, 0);
			break;
		case MLKEM768:
			if(ss->len == MLKEM768_BYTES)
				lua_pushboolean(L, 1);
			else
				lua_pushboolean(L, 0);
			break;
		case MLKEM1024:
			if(ss->len == MLKEM1024_BYTES)
				lua_pushboolean(L, 1);
			else
				lua_pushboolean(L, 0);
			break;
		case UNKNOWN:
			zerror("Unknown MLKEM type: %s (%s)",s,__func__);
			failed_msg = "MLKEM error";
			break;
		}
	}
 end:
	o_free(L,ss);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}
/*** Check if the length of the shared secret coincides with the expected length of a plaintext encrypted with a version of MLKEM.

@function mlkem_sscheck
 @param ss shared secret
 @param string, where string can be: "mlkem512", "mlkem768", "mlkem1024"
 @return boolean value, it is true if the length is correct and false otherwise

@usage
 QP = require("qp")
 oct1 = OCTET.random(32)
 oct2 = OCTET.random(32)
 mess = OCTET.random(32) 
 pk768 = QP.mlkem_keygen(oct1,oct2, "mlkem768").public
 sk768 = QP.mlkem_keygen(oct1,oct2, "mlkem768").private
 ss = QP.mlkem_enc(pk768,mess,"mlkem768").secret
 if QP.mlkem_sscheck(ss, "mlkem768") then print("ok")
 end
 */ 
// check the ciphertext length
static int mlkem_ctcheck(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *ct = o_arg(L, 1);
	if(ct == NULL) {
		failed_msg = "Could not allocate kem ciphertext";
		goto end;
	} else {
		const char *s = lua_tostring(L, 2);
		if(!s) s = "mlkem512";
		switch(_get_mlkem_type(s)) {
		case MLKEM512:
			if(ct->len == MLKEM512_CIPHERTEXTBYTES)
				lua_pushboolean(L, 1);
			else
				lua_pushboolean(L, 0);
			break;
		case MLKEM768:
			if(ct->len == MLKEM768_CIPHERTEXTBYTES)
				lua_pushboolean(L, 1);
			else
				lua_pushboolean(L, 0);
			break;
		case MLKEM1024:
			if(ct->len == MLKEM1024_CIPHERTEXTBYTES)
				lua_pushboolean(L, 1);
			else
				lua_pushboolean(L, 0);
			break;
		case UNKNOWN:
			zerror("Unknown MLKEM type: %s (%s)",s,__func__);
			failed_msg = "MLKEM error";
			break;
		}
	}
 end:
	o_free(L, ct);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
 Encrypt a message of 32 bytes length and generate a shared secret using a public key generated from one 
 of the previous functions.
 
 @function QP.mlkem_enc
 @param pk a public key whose length depends on the kind of MLKEM used
 @param m an octet of 32 bytes length 
 @param string, where string can be: "mlkem512", "mlkem768", "mlkem1024"

 @return shared secret (an octet of 32 bytes length) 
 @return ciphertext associated to m 

 @usage
 QP = require("qp")
 oct1 = OCTET.random(32)
 oct2 = OCTET.random(32)
 mess = OCTET.random(32)
 pk768 = QP.mlkem_keygen(oct1,oct2, "mlkem768").public
 ss = QP.mlkem_enc(pk768,oct2,"mlkem768").secret
 ct = QP.mlkem_enc(pk768,oct2,"mlkem768").cipher
 */ 
static int mlkem_enc(lua_State *L) {
	BEGIN();
	uint8_t randbytes[32];
	char *failed_msg = NULL;
	const octet *pk = NULL;
	octet *ss = NULL, *ct = NULL;
	pk = o_arg(L, 1);
	if(pk == NULL) {
		failed_msg = "Cuold not allocate public key";
		goto end;
	}
	void *ud = luaL_testudata(L, 2, "zenroom.octet");
	if (ud){
		octet *rnd = (octet *) ud;
		if (rnd->len != 32) {
			failed_msg = "Wrong seed size";
			goto end;
		}
		memcpy(randbytes,rnd->val,32);
	} else {
		Z(L);
		for(uint8_t i = 0; i < 32; i++) {
			randbytes[i] = RAND_byte(Z -> random_generator);
		}
	}
	const char *s = lua_tostring(L, 3);
	if(!s) s = "mlkem512";
	switch(_get_mlkem_type(s)) {
	case MLKEM512:
		if(pk->len != MLKEM512_PUBLICKEYBYTES) {
			failed_msg = "invalid size for public key";
			goto end;
		}
		lua_createtable(L, 0, 2);
		ss = o_new(L, MLKEM512_BYTES);
		if(ss == NULL) {
			failed_msg = "Could not allocate kem secret";
			goto end;
		}
		lua_setfield(L, -2, "secret"); // shared secret
		ct = o_new(L, MLKEM512_CIPHERTEXTBYTES);
		if(ct == NULL) {
			failed_msg = "Could not allocate kem ciphertext";
			goto end;
		}
		lua_setfield(L, -2, "cipher");
		if(mlkem512_enc_derand((unsigned char*)ct->val,
							   (unsigned char*)ss->val,
							   (unsigned char*)pk->val,
							   randbytes)) {
			failed_msg = "error in the creation of the shared secret";
			goto end;
		}
		ss->len = MLKEM512_BYTES;
		ct->len = MLKEM512_CIPHERTEXTBYTES;
		break;
	case MLKEM768:
		if(pk->len != MLKEM768_PUBLICKEYBYTES) {
			failed_msg = "invalid size for public key";
			goto end;
		}
		lua_createtable(L, 0, 2);
		ss = o_new(L, MLKEM768_BYTES);
		if(ss == NULL) {
			failed_msg = "Could not allocate kem secret";
			goto end;
		}
		lua_setfield(L, -2, "secret"); // shared secret
		ct = o_new(L, MLKEM768_CIPHERTEXTBYTES);
		if(ct == NULL) {
			failed_msg = "Could not allocate kem ciphertext";
			goto end;
		}
		lua_setfield(L, -2, "cipher");
		if(mlkem768_enc_derand((unsigned char*)ct->val,
							   (unsigned char*)ss->val,
							   (unsigned char*)pk->val,
							   randbytes)) {
			failed_msg = "error in the creation of the shared secret";
			goto end;
		}
		ss->len = MLKEM768_BYTES;
		ct->len = MLKEM768_CIPHERTEXTBYTES;
		break;
	case MLKEM1024:
		if(pk->len != MLKEM1024_PUBLICKEYBYTES) {
			failed_msg = "invalid size for public key";
			goto end;
		}
		lua_createtable(L, 0, 2);
		ss = o_new(L, MLKEM1024_BYTES);
		if(ss == NULL) {
			failed_msg = "Could not allocate kem secret";
			goto end;
		}
		lua_setfield(L, -2, "secret"); // shared secret
		ct = o_new(L, MLKEM1024_CIPHERTEXTBYTES);
		if(ct == NULL) {
			failed_msg = "Could not allocate kem ciphertext";
			goto end;
		}
		lua_setfield(L, -2, "cipher");
		if(mlkem1024_enc_derand((unsigned char*)ct->val,
							   (unsigned char*)ss->val,
							   (unsigned char*)pk->val,
							   randbytes)) {
			failed_msg = "error in the creation of the shared secret";
			goto end;
		}
		ss->len = MLKEM1024_BYTES;
		ct->len = MLKEM1024_CIPHERTEXTBYTES;
		break;

	case UNKNOWN:
		zerror("Unknown MLKEM type: %s (%s)",s,__func__);
		failed_msg = "MLKEM error";
		break;
	}
end:
	o_free(L,pk);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/*** Decrypt a cyphertext retrieving the shared secret using a secret key generated from one of the previous functions.

 @function QP.mlkem_dec
 @param sk a secret key whose length depends on the kind of MLKEM used
 @param ct an ciphertext
 @param string where string can be: "mlkem512", "mlkem768", "mlkem1024"

 @return shared secret (an octet of 32 bytes length) 

 @usage
 oct1 = OCTET.random(32)
 oct2 = OCTET.random(32)
 mess = OCTET.random(32)
 sk768 = QP.mlkem_keygen(oct1,oct2, "mlkem768").private
 pk768 = QP.mlkem_keygen(oct1,oct2, "mlkem768").public
 ss = QP.mlkem_enc(pk768, mess, "mlkem768").secret
 ct = QP.mlkem_enc(pk768, mess, "mlkem768").cipher
 dec = QP.mlkem_dec(sk768, ct, "mlkem768")
 if ss == dec then print("ok")	-- Check if the shared secret coincides with the decryption of the ct
 end
 -- Output: ok 
 */ 
static int mlkem_dec(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *sk = NULL, *ct = NULL;
	octet *ss;
	sk = o_arg(L, 1);
	ct = o_arg(L, 2);
	if(sk == NULL || ct == NULL) {
		failed_msg = "Could not allocate memory during decription";
		goto end;
	}
	const char *s = lua_tostring(L, 3);
	if(!s) s = "mlkem512";
	switch(_get_mlkem_type(s)) {
	case MLKEM512:
		if(sk->len != MLKEM512_SECRETKEYBYTES) {
			failed_msg = "invalid size for secret key";
			goto end;
		}
		if(ct->len != MLKEM512_CIPHERTEXTBYTES) {
			failed_msg = "invalid size for ciphertext key";
			goto end;
		}
		ss = o_new(L, MLKEM512_BYTES);
		if(ss == NULL) {
			failed_msg = "Could not allocate kem secret";
			goto end;
		}
		if(mlkem512_dec((unsigned char*)ss->val,
						(unsigned char*)ct->val,
						(unsigned char*)sk->val)) {
			failed_msg = "error in while deciphering the shared secret";
			goto end;
		}
		ss->len = MLKEM512_BYTES;
		break;
	case MLKEM768:
		if(sk->len != MLKEM768_SECRETKEYBYTES) {
			failed_msg = "invalid size for secret key";
			goto end;
		}
		if(ct->len != MLKEM768_CIPHERTEXTBYTES) {
			failed_msg = "invalid size for ciphertext key";
			goto end;
		}
		ss = o_new(L, MLKEM768_BYTES);
		if(ss == NULL) {
			failed_msg = "Could not allocate kem secret";
			goto end;
		}
		if(mlkem768_dec((unsigned char*)ss->val,
						(unsigned char*)ct->val,
						(unsigned char*)sk->val)) {
			failed_msg = "error in while deciphering the shared secret";
			goto end;
		}
		ss->len = MLKEM768_BYTES;
		break;
	case MLKEM1024:
		if(sk->len != MLKEM1024_SECRETKEYBYTES) {
			failed_msg = "invalid size for secret key";
			goto end;
		}
		if(ct->len != MLKEM1024_CIPHERTEXTBYTES) {
			failed_msg = "invalid size for ciphertext key";
			goto end;
		}
		ss = o_new(L, MLKEM1024_BYTES);
		if(ss == NULL) {
			failed_msg = "Could not allocate kem secret";
			goto end;
		}
		if(mlkem1024_dec((unsigned char*)ss->val,
						(unsigned char*)ct->val,
						(unsigned char*)sk->val)) {
			failed_msg = "error in while deciphering the shared secret";
			goto end;
		}
		ss->len = MLKEM1024_BYTES;
		break;

	case UNKNOWN:
		zerror("Unknown MLKEM type: %s (%s)",s,__func__);
		failed_msg = "MLKEM error";
		break;
	}
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
	const octet *sk = o_arg(L, 1);
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
	const octet *pk = o_arg(L, 1);
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
	const octet *ss = o_arg(L, 1);
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
	const octet *ct = o_arg(L, 1);
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
	const octet *pk = NULL;
	octet *ss = NULL, *ct = NULL;
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
	const octet *sk = o_arg(L, 1);
	const octet *ct = o_arg(L, 2);
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

/// Global ML-DSA Functions
// @section ML-DSA
//
// ML-DSA-44 (Module Lattice-based Digital Signature Algorithm with a security level of 44) 
// is a post-quantum cryptographic scheme designed to provide secure digital signatures in a world where quantum 
// computers could potentially break traditional cryptographic algorithms like RSA and ECC (Elliptic Curve Cryptography). 
// It is part of the NIST Post-Quantum Cryptography Standardization Project, which aims to identify and standardize quantum-resistant cryptographic algorithms.
//
// The "44" in ML-DSA-44 refers to its security level, which corresponds to approximately 128 bits of classical security and 44 bits of quantum security.
// This makes it suitable for applications requiring strong security guarantees.
//
// ML-DSA-44 is designed to have relatively small key and signature sizes compared to other post-quantum signature schemes, making it efficient for storage and transmission.
// The key generation, signing, and verification algorithms are optimized for performance, making ML-DSA-44 practical for use in resource-constrained environments.
//
// ML-DSA-44 can be used in a wide range of applications, including: secure communication, digital identity, blockchain and cryptocurrencies, IoT device.
//
// At the beginning of each function you require <code> QP = require("qp") </code>. In this way you load the QP module and assign it to the variable QP.
//

/*#######################################*/
/*              ML-DSA-44                */
/*#######################################*/

/*** Generate a key pair for the ML-DSA-44 cryptographic scheme. 
	*It creates a public and a private key, optionally using a provided seed, and returns them in a Lua table. 
	*If the seed is not provided, the function generates random bytes using a random number generator.

	@function QP.ml_dsa_44_keypair
	@param seed an optional seed of 32 bytes
	@return a table containing the two keys
	@usage 
	QP = require("qp")
	--select a random seed and generate the key pair
	seed = OCTET.random(32)
	keys = QP.mldsa44_keypair(seed)
	--obtain sk and pk
	sk = keys.private
	pk = keys.public
 */
static int ml_dsa_44_keypair(lua_State *L)   {
/*************************************************
* Name:        crypto_sign_keypair
*
* Description: Generates public and private key.
*
* Arguments:   - uint8_t *pk: pointer to output public key (allocated
*                             array of CRYPTO_PUBLICKEYBYTES bytes)
*              - uint8_t *sk: pointer to output private key (allocated
*                             array of CRYPTO_SECRETKEYBYTES bytes)
*
* Returns 0 (success)
**************************************************/
	BEGIN();
	uint8_t randbytes[32];
	char *failed_msg = NULL;
	lua_createtable(L, 0, 2);
	octet *private = o_new(L, pqcrystals_ml_dsa_44_SECRETKEYBYTES);
	if(private == NULL) {
		failed_msg = "Could not allocate private key";
		goto end;
	}
	lua_setfield(L, -2, "private");
	octet *public = o_new(L, pqcrystals_ml_dsa_44_PUBLICKEYBYTES);
	if(public == NULL) {
		failed_msg = "Could not allocate public key";
		goto end;
	}
	lua_setfield(L, -2, "public");
	void *ud =luaL_testudata(L,1,"zenroom.octet");
	if (ud){
		octet * rnd = (octet*) ud;
		if (rnd->len != 32) {
			failed_msg = "Wrong seed size";
			goto end;	
		}
		for(uint8_t i=0;i<32;i++) randbytes[i] = rnd->val[i];
	}
	else {
		Z(L);
		for(uint8_t i=0;i<32;i++) randbytes[i] = RAND_byte(Z->random_generator);
	}
	pqcrystals_ml_dsa_44_zen_keypair((unsigned char*)public->val,
						     (unsigned char*)private->val, randbytes);
	public->len = pqcrystals_ml_dsa_44_PUBLICKEYBYTES;
	private->len = pqcrystals_ml_dsa_44_SECRETKEYBYTES;

end:
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/*** Generate a public key from a given private key for the 
	*ML-DSA-44 cryptographic scheme.

	@function QP.mldsa44_pubgen
	@param sk a private key
	@return a public key
	@usage 
	QP = require("qp")
	--generate a random seed and the key pair
	seed = OCTET.random(32)
	keys = QP.mldsa44_keypair(seed)
	--check if the public key is correct
	if (QP.mldsa44_pubgen(keys.private) == keys.public) then
    	print("ok")
	else print("different public key")
	end
	--print: ok

 */
static int ml_dsa_44_signature_pubgen(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *sk = NULL;
	octet *pk = NULL;
	sk = o_arg(L, 1);
	if(sk == NULL) {
		failed_msg = "failed to allocate space for secret key";
		goto end;
	}
	pk = o_new(L, pqcrystals_ml_dsa_44_PUBLICKEYBYTES);
	if(pk == NULL) {
		failed_msg = "failed to allocate space for public key";
		goto end;
	}

	pqcrystals_ml_dsa_44_zen_pub_gen((unsigned char*)pk->val,
						(unsigned char*)sk->val);
	pk->len = pqcrystals_ml_dsa_44_PUBLICKEYBYTES;

end:
	o_free(L,sk);
	if(failed_msg != NULL) {
		THROW(failed_msg);
	}

	END(1);
}

/*** Generate a signature for a given message using the ML-DSA-44 cryptographic scheme.
 	*The function takes in input also an optional parameter for the context. 
	*It provides additional flexibility and customization for the signature scheme, allowing you to bind the signature to specific contextual information.
	*The context is passed as an octet and can be up to 255 bytes in length.

	@function QP.mldsa44_signature
	@param sk a secret key
	@param m a message to sign
	@param ctx an optional context for the signature
	@usage 
	QP = require("qp")
	--generate a random seed, a key pair and a random message
	seed = OCTET.random(32)
	keys = QP.mldsa44_keypair(seed)
	m = OCTET.random(32)
	--sign the message
	sign = QP.mldsa44_signature(keys.private,m)
 */
static int ml_dsa_44_signature(lua_State *L) {
/*************************************************
* Name:        crypto_sign_signature
*
* Description: Computes signature.
*
* Arguments:   - uint8_t *sig:   pointer to output signature (of length CRYPTO_BYTES)
*              - size_t *siglen: pointer to output length of signature
*              - uint8_t *m:     pointer to message to be signed
*              - size_t mlen:    length of message
*              - uint8_t *sk:    pointer to bit_packed secret key
*
* Returns 0 (success)
**************************************************/
	BEGIN();
	uint8_t randbytes[32];
	char *failed_msg = NULL;
	const octet *sk = NULL, *m = NULL;
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
	if(sk->len != pqcrystals_ml_dsa_44_SECRETKEYBYTES) {
		failed_msg = "wrong secret key length";
		goto end;
	}
	octet *sig = o_new(L, pqcrystals_ml_dsa_44_BYTES);
	if(sig == NULL) {
		failed_msg = "failed to allocate space for signature";
		goto end;
	}
	Z(L);
	if ( Z->random_external){
		int sum = 0;
		for (int i = 0; i < 64; i++) {
			sum += Z->random_seed[i];
		}
		if (sum == 0) {
			for(uint8_t i=0;i<32;i++) randbytes[i] = 0;
			
		}
		else for(uint8_t i=0;i<32;i++) randbytes[i] = RAND_byte(Z->random_generator);
	}
	else for(uint8_t i=0;i<32;i++) randbytes[i] = RAND_byte(Z->random_generator);
	
	void *ud =luaL_testudata(L,3,"zenroom.octet");
	if (ud){
		octet * ctx = (octet*) ud;
		if (ctx->len > 255) {
			failed_msg = "Wrong ctx size";
			goto end;	
		}
		if (pqcrystals_ml_dsa_44_zen_signature((unsigned char *)sig->val,
						       (size_t *)&sig->len,
						       (unsigned char *)m->val, m->len,
						       (unsigned char *)ctx->val, ctx->len,
						       (unsigned char *)sk->val,
						       randbytes) && sig->len > 0) {
			failed_msg = "error in the signature";
			goto end;
		}
	} else {
		if (pqcrystals_ml_dsa_44_zen_signature((unsigned char *)sig->val,
						       (size_t *)&sig->len,
						       (unsigned char *)m->val, m->len,
						       NULL, 0,
						       (unsigned char *)sk->val,
						       randbytes) && sig->len > 0) {
			failed_msg = "error in the signature";
			goto end;
		}
	}

end:
	o_free(L,m);
	o_free(L,sk);

	if(failed_msg != NULL) {
		THROW(failed_msg);
	}
	END(1);
}

/*** Verify a signature for a given message using the ML-DSA-44 cryptographic scheme.

	@function QP.mldsa44_verify
	@param pk a public key
	@param sig a signature
	@param m a message 
	@param ctx an optional context	
	@usage 
	--from @{mldsa44_signature}, check if the signature is valid
	if (QP.mldsa44_verify(keys.public, sign, m)) then print("signature verified")
	else print("signature not verified")
	end
	--print: signature verified
 */
static int ml_dsa_44_verify(lua_State *L)    {/*************************************************
* Name:        crypto_sign_verify
*
* Description: Verifies signature.
*
* Arguments:   _ uint8_t *m: pointer to input signature
*              - size_t siglen: length of signature
*              - const uint8_t *m: pointer to message
*              - size_t mlen: length of message
*              - const uint8_t *pk: pointer to bit-packed public key
*
* Returns 0 if signature could be verified correctly and -1 otherwise
**************************************************/
	BEGIN();
	char *failed_msg = NULL;
	const octet *pk = NULL, *sig = NULL, *m = NULL;
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

	if(pk->len != pqcrystals_ml_dsa_44_PUBLICKEYBYTES) {
		failed_msg = "invalid size for public key";
		goto end;
	}
	void *ud =luaL_testudata(L,4,"zenroom.octet");
	if (ud){
		octet * ctx = (octet*) ud;
		int result = pqcrystals_ml_dsa_44_ref_verify((unsigned char*)sig->val,
								(size_t)sig->len,
								(unsigned char*)m->val, m->len,
								(unsigned char *)ctx->val,ctx->len,
								(unsigned char*)pk->val);
		lua_pushboolean(L, result == 0);
	} else {
		int result = pqcrystals_ml_dsa_44_ref_verify((unsigned char*)sig->val,
								(size_t)sig->len,
								(unsigned char*)m->val, m->len,
								NULL,0,
								(unsigned char*)pk->val);
		lua_pushboolean(L, result == 0);
	}
end:
	o_free(L, m);
	o_free(L, sig);
	o_free(L, pk);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/*** Check whether a given public key is valid for the ML-DSA-44 cryptographic scheme.
 	*The function checks if the public key has the correct length in bytes.

	@function QP.mldsa44_pubcheck
	@param pk a public key
	@return a boolean value
	@usage 
	QP = require("qp")
	--generate a random seed, and a key pair
	seed = OCTET.random(32)
	keys = QP.mldsa44_keypair(seed)
	--check if the pk is valid
	if (QP.mldsa44_pubcheck(keys.public)) then print("valid pk")
	else print("invalid pk")
	end
	--print: valid pk
 */
static int mldsa44_signature_pubcheck(lua_State *L) {
	BEGIN();
	const octet *pk = o_arg(L, 1);
	if(pk == NULL) {
		THROW("failed to allocate space for public key");
	} else {
		if(pk->len == pqcrystals_ml_dsa_44_PUBLICKEYBYTES)
			lua_pushboolean(L, 1);
		else
			lua_pushboolean(L, 0);
		o_free(L, pk);
	}
	END(1);
}

/*** Check whether a given signature is valid for the ML-DSA-44 cryptographic scheme. 
 	*Specifically, it verifies if the signature has the correct length.

	@function QP.mldsa44_signature_check
	@param sig a signature 
	@return a boolean value
	@usage 
	QP = require("qp")
	--generate a random seed and a key pair
	seed = OCTET.random(32)
	keys = QP.mldsa44_keypair(seed)
	m = OCTET.random(32)
	--generate a random message and sign it
	sign = QP.mldsa44_signature(keys.private,m)
	--check if the signature is valid
	if (QP.mldsa44_signature_check(sign)) then print("signature ok")
	else print("error in the signature")
	end
	--print: signature ok
 */
static int mldsa44_signature_check(lua_State *L){
	BEGIN();
	char *failed_msg = NULL;
	const octet *sign = o_arg(L, 1);
	if(sign == NULL) {
		failed_msg = "Cuold not allocate signature";
		goto end;
	}
	if(sign->len == pqcrystals_ml_dsa_44_BYTES)
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


int luaopen_qp(lua_State *L) {
	(void)L;
	const struct luaL_Reg qp_class[] = {
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
		// ML-KEM
		{"mlkem_keygen",   mlkem_keygen},
		{"mlkem_pubgen",   mlkem_pubgen},
		{"mlkem_pubcheck", mlkem_pubcheck},
		{"mlkem_sscheck",  mlkem_sscheck},
		{"mlkem_ctcheck",  mlkem_ctcheck},
		{"mlkem_enc",      mlkem_enc},
		{"mlkem_dec",      mlkem_dec},
		// SNTRUP761
		{"ntrup_keygen", qp_sntrup_kem_keygen},
		{"ntrup_pubgen", qp_sntrup_kem_pubgen},
		{"ntrup_pubcheck", qp_sntrup_kem_pubcheck},
		{"ntrup_sscheck", qp_sntrup_kem_sscheck},
		{"ntrup_ctcheck", qp_sntrup_kem_ctcheck},
		{"ntrup_enc", qp_sntrup_kem_enc},
		{"ntrup_dec", qp_sntrup_kem_dec},
		// ML-DSA-44
		{"mldsa44_keypair",   ml_dsa_44_keypair},
		{"mldsa44_signature", ml_dsa_44_signature},
		{"mldsa44_verify",    ml_dsa_44_verify},
		{"mldsa44_pubgen", ml_dsa_44_signature_pubgen},
		{"mldsa44_pubcheck", mldsa44_signature_pubcheck},
		{"mldsa44_signature_check", mldsa44_signature_check},
		{NULL,NULL}
	};
	const struct luaL_Reg qp_methods[] = {
		{NULL,NULL}
	};

	zen_add_class(L, "qp", qp_class, qp_methods);
	return 1;
}
