/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2025 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
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

/// <h1>Elliptic Curve Diffie-Hellman encryption (ECDH)</h1>
//
//  Asymmetric public/private key encryption technologies.
//
//  ECDH encryption and ECDSA signing functionalities are provided by
//  this module. New keyring instances are instantiated by calling the
//  new() method, keys can be imported using the
//
//  <code>
//  Alice = ECDH.new()
//  Bob = ECDH.new()
//  </code>
//
//  One can create more keyrings in the same script and call them with
//  meaningful variable names to help making code more
//  understandable. Each keyring instance offers methods prefixed with
//  a double-colon that operate on arguments as well keys contained by
//  the keyring: this way scripting can focus on the identities
//  represented by each keyring, giving them names as 'Alice' or
//  'Bob'.
//
//  @module ECDH
//  @author Denis "Jaromil" Roio
//  @license AGPLv3
//  @copyright Dyne.org foundation 2017-2020

#include <ecdh_support.h>

#include <zen_error.h>
#include <zen_octet.h>
#include <randombytes.h>
#include <lua_functions.h>

#include <zenroom.h>
#include <zen_hash.h>
#include <zen_ecdh.h>
#include <zen_big_factory.h>

// #include <ecp_SECP256K1.h>
#include <zen_big.h>

#define KEYPROT(alg, key)	  \
	zerror(L, "%s engine has already a %s set:", alg, key); \
	lerror(L, "Zenroom won't overwrite. Use a .new() instance.");

// from zen_ecdh_factory.h to setup function pointers
extern void ecdh_init(lua_State *L, ecdh *e);

ecdh ECDH;

/// Instance Methods
// @type keyring

/**
   Generate an ECDH public/private key pair for a keyring

   Keys generated are both returned and stored inside the keyring
   table as public and private properties.

   @function keyring:keygen()
   @treturn[1] OCTET public key
   @treturn[1] OCTET private key
*/
static int ecdh_keygen(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	// return a table
	lua_createtable(L, 0, 2);
	octet *pk = o_new(L,ECDH.fieldsize*2 +1);
	if(pk == NULL) {
		failed_msg = "Could not create public key";
		goto end;
	}
	lua_setfield(L, -2, "public");
	octet *sk = o_new(L,ECDH.fieldsize);
	if(sk == NULL) {
		failed_msg = "Could not create secret key";
		goto end;
	}
	lua_setfield(L, -2, "private");
	Z(L);
	(*ECDH.ECP__KEY_PAIR_GENERATE)(Z->random_generator,sk,pk);
end:
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}


/**
   Generate an ECDH public key from a secret key

   Public key is returned.

   @function keyring:pubgen()
   @return OCTET public key
*/
static int ecdh_pubgen(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *sk = o_arg(L, 1);
	if(sk == NULL || sk->len > ECDH.fieldsize) {
		failed_msg = "Could not allocate secret key";
		goto end;
	}
	octet *tmp = o_new(L, ECDH.fieldsize);
	if(tmp == NULL) {
		failed_msg = "Could not duplicate secret key";
		goto end;
	}
	OCT_copy(tmp, (octet*)sk);
	OCT_pad(tmp, ECDH.fieldsize);
	octet *pk = o_new(L,ECDH.fieldsize*2 +1);
	if(pk == NULL) {
		failed_msg = "Could not create public key";
		goto end;
	}
	// If RNG is NULL then the private key is provided externally in S
	// otherwise it is generated randomly internally
	(*ECDH.ECP__KEY_PAIR_GENERATE)(NULL,tmp,pk);
end:
	o_free(L, sk);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}


/*
   Validate an ECDH public key.
   This is done by:
   1. Checking that it is not the point at infinity
   2. Validating that it is on the correct group.

   @param key the input public key octet to be validated
   @function keyring:checkpub(key)
   @return true if public key is OK, or false if not.
*/

static int ecdh_pubcheck(lua_State *L) {
	BEGIN();
	const octet *pk = o_arg(L, 1);
	if(pk == NULL) {
		lerror(L, "Could not allocate public key");
		lua_pushboolean(L, 0);
	} else {
		lua_pushboolean(L, (*ECDH.ECP__PUBLIC_KEY_VALIDATE)((octet*)pk)==0);
		o_free(L, pk);
	}
	END(1);
}

/*
   Generate a Diffie-Hellman shared session key. This function uses
   two keyrings to calculate a shared key, then process it internally
   through @{keyring:kdf2} to make it ready for use in
   @{keyring:aead_encrypt}. This is compliant with the IEEE-1363
   Diffie-Hellman shared secret specification for asymmetric key
   encryption. It can be found here:
   https://perso.telecom-paristech.fr/guilley/recherche/cryptoprocesseurs/ieee/00891000.pdf, section 6.2

   @param keyring containing the public key to be used
   @function keyring:session(keyring)
   @treturn[1] octet KDF2 hashed session key ready for @{keyring:aead_encrypt}
   @treturn[1] octet a @{BIG} number result of (private * public) % curve_order (before KDF2)
   @see keyring:aead_encrypt
*/
static int ecdh_session(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *f = o_arg(L, 1);
	if(f == NULL) {
		failed_msg = "Could not allocate session key";
		goto end;
	}
	const octet *s = o_arg(L, 2);
	if(s == NULL) {
		failed_msg = "Could not allocate session key";
		goto end;
	}
	// ECDH_OK is 0 in milagro's ecdh.h.in
	const octet *pk = (*ECDH.ECP__PUBLIC_KEY_VALIDATE)((octet*)s)== 0 ? s : NULL;
	if(!pk) pk = (*ECDH.ECP__PUBLIC_KEY_VALIDATE)((octet*)f)== 0 ? f : NULL;
	if(!pk) {
		failed_msg = "public key not found in any argument";
		goto end;
	}
	const octet *sk = (pk == s) ? f : s;
	octet *kdf = o_new(L, SHA256);
	if(!kdf) {
		failed_msg = "Could not create KDF";
		goto end;
	}
	octet *ses = o_new(L, 64); // modbytes of ecdh curve
	if(!ses) {
		failed_msg = "Could not create shared key";
		goto end;
	}
	(*ECDH.ECP__SVDP_DH)((octet*)sk,(octet*)pk,ses);
	// NULL would be used internally by KDF2 as 'p' in the hash
	// function ehashit(sha,z,counter,p,&H,0);
	KDF2(SHA256,ses,NULL,SHA256,kdf);
end:
	o_free(L, s);
	o_free(L, f);
	if(failed_msg) {
		THROW(failed_msg);
		lua_pushnil(L);
	}
	END(2);
}


/**
   Returns X and Y coordinates of a public key

   @function ECDH.xy(public_key)
   @treturn[1] OCTET coordinate X of public key
   @treturn[1] OCTET coordinate Y of public key

*/
static int ecdh_pub_xy(lua_State *L) {
	BEGIN();
	int res = 1;
	char *failed_msg = NULL;
	const octet *pk = o_arg(L, 1);
	if(pk == NULL) {
		failed_msg = "Could not allocate public key";
		goto end;
	}
	if((*ECDH.ECP__PUBLIC_KEY_VALIDATE)((octet*)pk)!=0) {
		failed_msg = "Invalid public key passed as argument";
		goto end;
	}
	// Export public key to octet.  This is like o_dup but skips
	// first byte since that is used internally by Milagro as a
	// prefix for Montgomery (2) or non-Montgomery curves (4)
	register int i;
	octet *x = o_new(L, ECDH.fieldsize+1);
	if(x == NULL) {
		failed_msg = "Could not create x coordinate";
		goto end;
	}
	for(i=0; i < ECDH.fieldsize; i++)
		x->val[i] = pk->val[i+1]; // +1 skips first byte
	x->val[ECDH.fieldsize+1] = 0x0;
	x->len = ECDH.fieldsize;
	// make sure y is there:
	// could be omitted in montgomery notation
	if(pk->len > ECDH.fieldsize<<1) {
		octet *y = o_new(L, ECDH.fieldsize+1);
		if(y == NULL) {
			failed_msg = "Could not create y coordinate";
			goto end;
		}
		for(i=0; i < ECDH.fieldsize; i++)
			y->val[i] = pk->val[ECDH.fieldsize+i+1]; // +1 skips first byte
		y->val[ECDH.fieldsize+1] = 0x0;
		y->len = ECDH.fieldsize;
		res = 2;
	}
end:
	o_free(L, pk);
	if(failed_msg) {
		THROW(failed_msg);
		lua_pushnil(L);
	}
	END(res);
}


/**
   Elliptic Curve Digital Signature Algorithm (ECDSA) signing
   function. This method uses the private key inside a keyring to sign
   a message, returning a signature to be used in @{keyring:verify}.

   @param kp.private @{OCTET} of a public key
   @param message string or @{OCTET} message to sign
   @function ECDH.sign(kp.private, message)
   @return table containing signature parameters octets (r,s)
   @usage
   kp = ECDH.keygen() -- generate keys or import them
   m = "Message to be signed"
   signature = ECDH.sign(kp.private, m)
   assert( ECDH.verify(kp.public, m, signature) )
*/

static int ecdh_dsa_sign(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *sk = o_arg(L,1);
	if(sk == NULL) {
		failed_msg = "Could not allocate secret key";
		goto end;
	}
	const octet *m = o_arg(L,2);
	if(m == NULL) {
		failed_msg = "Could not allocate message";
		goto end;
	}
	// IEEE ECDSA Signature, R and S are signature on F using private
	// key S. One can either pass an RNG or have K already
	// provide. For a correct K's generation see also RFC6979, however
	// this argument is provided here mostly for testing purposes with
	// pre-calculated vectors.
	int max_size = 64;
	octet *r = NULL, *s = NULL, *k = NULL;
	if(lua_isnoneornil(L, 3)) {
		// return a table
		lua_createtable(L, 0, 2);
		r = o_new(L,max_size);
		if(r == NULL) {
			failed_msg = "Could not create signautre.r";
			goto end;
		}
		lua_setfield(L, -2, "r");
		s = o_new(L,max_size);
		if(s == NULL) {
			failed_msg = "Could not create signautre.s";
			goto end;
		}
		lua_setfield(L, -2, "s");
		Z(L);
		(*ECDH.ECP__SP_DSA)( max_size, Z->random_generator, NULL,
							 (octet*)sk, (octet*)m, r, s);
	} else {
		k = (octet*)o_arg(L, 3);
		if(k == NULL) {
			failed_msg = "Could not allocate ephemeral key";
			goto end;
		}
		// return a table
		lua_createtable(L, 0, 2);
		r = o_new(L,max_size);
		if(r == NULL) {
			failed_msg = "Could not create signautre.r";
			goto end;
		}
		lua_setfield(L, -2, "r");
		s = o_new(L,max_size);
		if(s == NULL) {
			failed_msg = "Could not create signautre.s";
			goto end;
		}
		lua_setfield(L, -2, "s");
		(*ECDH.ECP__SP_DSA)( max_size, NULL,
							 k, (octet*)sk, (octet*)m, r, s );
	}
end:
	o_free(L, k);
	o_free(L, m);
	o_free(L, sk);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/**
   Elliptic Curve Digital Signature Algorithm (ECDSA) signing
   function with deterministic generation of k (see RFC6979 https://www.rfc-editor.org/rfc/rfc6979).
   This method uses the private key inside a keyring to sign
   a message, returning a signature to be used in @{keyring:verify_deterministic}.

   @param kp.private @{OCTET} of a public key
   @param message string or @{OCTET} message to sign
   @param sha int length in bytes of the digest of the SHA function
   @function ECDH.sign_deterministic(kp.private, message, sha)
   @return table containing signature parameters octets and k (r,s,k)
   @usage
   kp = ECDH.keygen() -- generate keys or import them
   m = "Message to be signed"
   sha = 32 -- This is SHA256. Also 48 = SHA384 or 64 = SHA512 may be used.
   signature = ECDH.sign_deterministic(kp.private, m, sha)
   assert( ECDH.verify_determinitsic(kp.public, m, signature, sha) )
*/
static int ecdh_dsa_sign_det(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *sk = o_arg(L,1);
	if(sk == NULL) {
		failed_msg = "Could not allocate secret key";
		goto end;
	}
	const octet *m = o_arg(L,2);
	if(m == NULL) {
		failed_msg = "Could not allocate message";
		goto end;
	}
	
	int max_size = 0;
	lua_Integer n = lua_tointegerx(L, 3, &max_size);
	if(max_size == 0) {
		failed_msg = "invalid size zero for material to sign";
		goto end;
	}
	
	// return a table
	lua_createtable(L, 0, 2);
	octet *r = o_new(L, (int) n);
	if(r == NULL) {
		failed_msg = "Could not create signautre.r";
		goto end;
	}
	lua_setfield(L, -2, "r");
	octet *s = o_new(L,(int) n);
	if(s == NULL) {
		failed_msg = "Could not create signautre.s";
		goto end;
	}
	lua_setfield(L, -2, "s");
	octet *k = o_new(L, (int) n);
	if(k == NULL) {
		failed_msg = "Could not create signautre.s";
		goto end;
	}
	(*ECDH.ECP__SP_DSA_DET)( (int) n, (octet*)sk, (octet*)m, r, s, k);

end:
	o_free(L, m);
	o_free(L, sk);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(2);
}

/* Same as ecdha_dsa_sign_det but input message is already hashed.
For the generation of the k parameter we use HMAC with the SHA function of corresponding length.
 */
static int ecdh_dsa_sign_det_hashed(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *sk = o_arg(L, 1);
	if(sk == NULL) {
		failed_msg = "Could not allocate secret key";
		goto end;
	}
	const octet *m = o_arg(L, 2);
	if(m == NULL) {
		failed_msg = "Could not allocate message";
		goto end;
	}

	int max_size;
	int parity;
	lua_Integer n = lua_tointegerx(L, 3, &max_size);
	if(max_size==0) {
		failed_msg = "missing 3rd argument: byte size of octet to sign";
		goto end;
	}
	if (m->len != (int)n) {
		failed_msg = "size of input does not match";
		goto end;
	}

	// return a table
	lua_createtable(L, 0, 2);
	octet *r = o_new(L, (int)n);
	if(r == NULL) {
		failed_msg = "Could not create signautre.r";
		goto end;
	}
	lua_setfield(L, -2, "r");
	octet *s = o_new(L, (int)n);
	if(s == NULL) {
		failed_msg = "Could not create signautre.s";
		goto end;
	}
	lua_setfield(L, -2, "s");
	// Size of a big256 used with SECP256k1
	(*ECDH.ECP__SP_DSA_DET_NOHASH)
		((int)n, (octet*)sk, (octet*)m, r, s, &parity);

	lua_pushboolean(L, parity);
end:
	o_free(L, m);
	o_free(L, sk);
	if(failed_msg) {
		THROW(failed_msg);
		lua_pushnil(L);
	}
	END(2);
}

/**
 * Sign a message directly, without taking the hash (the input in an hashed message
 * that is it is already hashed)
 * @param sk private key
 * @param m hashed message
 * @param n size of the message
 * @param k ephemeral private key (not mandatory)
 * @return[1] table with r and s (r is the x of the ephemeral public key)
 * @return[2] y of the ephemeral public key
 */
static int ecdh_dsa_sign_hashed(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *sk = o_arg(L, 1);
	if(sk == NULL) {
		failed_msg = "Could not allocate secret key";
		goto end;
	}
	const octet *m = o_arg(L, 2);
	if(m == NULL) {
		failed_msg = "Could not allocate message";
		goto end;
	}
	// IEEE ECDSA Signature, R and S are signature on F using private
	// key S. One can either pass an RNG or have K already
	// provide. For a correct K's generation see also RFC6979, however
	// this argument is provided here mostly for testing purposes with
	// pre-calculated vectors.
	int max_size;
	int parity;
	lua_Integer n = lua_tointegerx(L, 3, &max_size);
	if(max_size==0) {
		failed_msg = "missing 3rd argument: byte size of octet to sign";
		goto end;
	}
	if (m->len != (int)n) {
		failed_msg = "size of input does not match";
		goto end;
	}
	octet *k = NULL;
	if(lua_isnoneornil(L, 4)) {
		// return a table
		lua_createtable(L, 0, 2);
		octet *r = o_new(L, (int)n);
		if(r == NULL) {
			failed_msg = "Could not create signautre.r";
			goto end;
		}
		lua_setfield(L, -2, "r");
		octet *s = o_new(L, (int)n);
		if(s == NULL) {
			failed_msg = "Could not create signautre.s";
			goto end;
		}
		lua_setfield(L, -2, "s");
		// Size of a big256 used with SECP256k1
		Z(L);
		(*ECDH.ECP__SP_DSA_NOHASH)
			((int)n, Z->random_generator, NULL,
			 (octet*)sk, (octet*)m, r, s, &parity);
	} else {
		k = (octet*)o_arg(L, 4);
		if(k == NULL) {
			failed_msg = "Could not allocate ephemeral key";
			goto end;
		}
		// return a table
		lua_createtable(L, 0, 2);
		octet *r = o_new(L, (int)n);
		if(r == NULL) {
			failed_msg = "Could not create signautre.r";
			goto end;
		}
		lua_setfield(L, -2, "r");
		octet *s = o_new(L, (int)n);
		if(s == NULL) {
			failed_msg = "Could not create signautre.s";
			goto end;
		}
		lua_setfield(L, -2, "s");
		// Size of a big256 used with SECP256k1
		(*ECDH.ECP__SP_DSA_NOHASH)
			((int)n, NULL, k, (octet*)sk, (octet*)m, r, s, &parity);
	}
	lua_pushboolean(L, parity);
end:
	o_free(L, k);
	o_free(L, m);
	o_free(L, sk);
	if(failed_msg) {
		THROW(failed_msg);
		lua_pushnil(L);
	}
	END(2);
}

// Internal function: sometimes signatures come into a serialized form
// while r and s may be each 31 bytes long, so we end up with 63 byte
// sized signatures and more seldomly with 62 (at least theoretical,
// never seen one) so we try all possible combinations since the
// serialization does not say where one ends and the other continues.
HEDLEY_WARN_UNUSED_RESULT
HEDLEY_NON_NULL(1, 2, 3)
int verify64_with_partition_attempts
	(const octet *pk, const octet *m,
	 const octet* input, octet* left, octet* right) {
    // validate input size (62-64 bytes)
    if (!input || input->len < 62 || input->len > 64)
        return 0;
    // possible partition combinations to try (left, right)
    const int splits[][2] = {
        {32, 32}, {31, 33}, {33, 31},  // For 64-byte input
		{31, 32}, {32, 31},            // For 63-byte input
        {31, 31}, {30, 32}, {32, 30}   // For 62-byte input
    };
    for (size_t i = 0; i < sizeof(splits)/sizeof(splits[0]); i++) {
        int l = splits[i][0];
        int r = splits[i][1];
        // skip impossible splits for current input size
        if (l + r != input->len) continue;
        // validate partition sizes (30-32 bytes)
        if ((l >= 30 && l <= 32) && (r >= 30 && r <= 32)) {
            memcpy(left->val, input->val, l);
            memcpy(right->val, input->val + l, r);
            left->len = l;
            right->len = r;
			int res = (*ECDH.ECP__VP_DSA)
				(64, (octet*)pk, (octet*)m, left, right);
			if(res>=0) return 1;
        }
    }
    return 0;
}

/**
   Elliptic Curve Digital Signature Algorithm (ECDSA) verification
   function. This method uses the public key inside a keyring to verify
   a message, returning true or false. The signature parameters are
   returned as 'r' and 's' in this same order by @{keyring:sign}.

   @param message the message whose signature has to be verified
   @param signature the signature table returned by @{keyring:sign}
   @function ECDH.verify(kp.public, message,signature)
   @return true if the signature is OK, or false if not.
   @see ECDH.sign
*/
static int ecdh_dsa_verify(lua_State *L) {
	BEGIN();
	// IEEE1363 ECDSA Signature Verification. Signature C and D on F
	// is verified using public key W
	char *failed_msg = NULL;
	const octet *pk = o_arg(L, 1);
	if(pk == NULL) {
		failed_msg = "Could not allocate public key";
		goto end;
	}
	const octet *m = o_arg(L, 2);
	if(m == NULL) {
		failed_msg = "Could not allocate message";
		goto end;
	}
	octet *r = NULL, *s = NULL;
	if(lua_type(L, 3) == LUA_TUSERDATA) {
		r = (octet *)o_arg(L, 3);
		if(r->len < 62 || r->len > 64) {
			warning(L,"signature argument is %u bytes long",r->len);
			failed_msg = "wrong signature argument size: 62 <= sig <= 64";
			goto end;
		}
		octet *left = o_alloc(L, 32);
		octet *right = o_alloc(L, 32);
		int res = verify64_with_partition_attempts(pk, m, r, left, right);
		o_free(L, left);
		o_free(L, right);
		if(res) lua_pushboolean(L, 1);
		else    lua_pushboolean(L, 0);
		goto end;
	} else if(lua_type(L, 3) == LUA_TTABLE) {
		lua_getfield(L, 3, "r");
		lua_getfield(L, 3, "s"); // -2 stack
		r = (octet *)o_arg(L, -2);
		if(r == NULL) {
			failed_msg = "Could not allocate signature.r";
			goto end;
		}
		s = (octet *)o_arg(L, -1);
		if(s == NULL) {
			failed_msg = "Could not allocate signautre.s";
			goto end;
		}
	} else {
		failed_msg = "signature argument invalid";
		goto end;
	}
	int max_size = 64;
	int res = (*ECDH.ECP__VP_DSA)(max_size, (octet*)pk, (octet*)m, r, s);
	if(res <0) // ECDH_INVALID in milagro/include/ecdh.h.in (!?!)
		// TODO: maybe suggest fixing since there seems to be
		// no criteria between ERROR (used in the first check
		// in VP_SDA) and INVALID (in the following two
		// checks...)
		lua_pushboolean(L, 0);
	else
		lua_pushboolean(L, 1);
end:
	o_free(L, s);
	o_free(L, r);
	o_free(L, m);
	o_free(L, pk);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/**
   Elliptic Curve Digital Signature Algorithm (ECDSA) verification
   function. The main difference between ecdh_dsa_verify and this function
   is that here we also consider the input parameter sha int.
   This method uses the public key inside a keyring to verify
   a message, returning true or false. The signature parameters are
   returned as 'r' and 's' in this same order by @{keyring:sign_deterministic}.

   @param message the message whose signature has to be verified
   @param signature the signature table returned by @{keyring:sign_deterministic}
   @param sha int length in bytes of the digest of the SHA function
   @function ECDH.verify_deterministic(kp.public, message, signature, sha)
   @return true if the signature is OK, or false if not.
   @see ECDH.sign_deterministic
*/
static int ecdh_dsa_verify_det(lua_State *L) {
	BEGIN();
	// IEEE1363 ECDSA Signature Verification. Signature C and D on F
	// is verified using public key W
	char *failed_msg = NULL;
	const octet *pk = o_arg(L, 1);
	if(pk == NULL) {
		failed_msg = "Could not allocate public key";
		goto end;
	}
	const octet *m = o_arg(L, 2);
	if(m == NULL) {
		failed_msg = "Could not allocate message";
		goto end;

	}
	octet *r = NULL, *s = NULL;
	if(lua_type(L, 3) == LUA_TTABLE) {
		lua_getfield(L, 3, "r");
		lua_getfield(L, 3, "s"); // -2 stack
		r = (octet*)o_arg(L, -2);
		if(r == NULL) {
			failed_msg = "Could not allocate signature.r";
			goto end;
		}
		s = (octet*)o_arg(L, -1);
		if(s == NULL) {
			failed_msg = "Could not allocate signautre.s";
			goto end;
		}
	} else {
		failed_msg = "signature argument invalid: not a table";
		goto end;
	}
	int max_size = 0;
	lua_Integer n = lua_tointegerx(L, 4, &max_size);
	if(max_size == 0) {
		failed_msg = "invalid size zero for material to sign";
		goto end;
	}
	int res = (*ECDH.ECP__VP_DSA)((int) n, (octet*)pk, (octet*)m, r, s);
	if(res <0) // ECDH_INVALID in milagro/include/ecdh.h.in (!?!)
		// TODO: maybe suggest fixing since there seems to be
		// no criteria between ERROR (used in the first check
		// in VP_SDA) and INVALID (in the following two
		// checks...)
		lua_pushboolean(L, 0);
	else
		lua_pushboolean(L, 1);
end:
	o_free(L, s);
	o_free(L, r);
	o_free(L, m);
	o_free(L, pk);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int ecdh_dsa_verify_hashed(lua_State *L) {
	BEGIN();
	// IEEE1363 ECDSA Signature Verification. Signature C and D on F
	// is verified using public key W
	char *failed_msg = NULL;
	const octet *pk = o_arg(L, 1);
	if(pk == NULL) {
		failed_msg = "Could not allocate public key";
		goto end;
	}
	const octet *m = o_arg(L, 2);
	if(m == NULL) {
		failed_msg = "Could not allocate message";
		goto end;
	}
	octet *r = NULL, *s = NULL;
	if(lua_type(L, 3) == LUA_TTABLE) {
		lua_getfield(L, 3, "r");
		lua_getfield(L, 3, "s"); // -2 stack
		r = (octet*)o_arg(L, -2);
		if(r == NULL) {
			failed_msg = "Could not allocate signautre.r";
			goto end;
		}
		s = (octet*)o_arg(L, -1);
		if(s == NULL) {
			failed_msg = "Could not allocate signautre.s";
			goto end;
		}
	} else {
		failed_msg = "signature argument invalid: not a table";
		goto end;
	}
	int max_size = 0;
	lua_Integer n = lua_tointegerx(L, 4, &max_size);
	if(max_size == 0) {
		failed_msg = "invalid size zero for material to sign";
		goto end;
	}
	if (m->len != (int)n) {
		failed_msg = "size of input does not match";
	}
	int res = (*ECDH.ECP__VP_DSA_NOHASH)
		((int)n, (octet*)pk, (octet*)m, r, s);
	if(res <0) // ECDH_INVALID in milagro/include/ecdh.h.in (!?!)
		// TODO: maybe suggest fixing since there seems to be
		// no criteria between ERROR (used in the first check
		// in VP_SDA) and INVALID (in the following two
		// checks...)
		lua_pushboolean(L, 0);
	else
		lua_pushboolean(L, 1);
end:
	o_free(L, s);
	o_free(L, r);
	o_free(L, m);
	o_free(L, pk);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/*
   AES-GCM encrypt with Additional Data (AEAD) encrypts and
   authenticate a plaintext to a ciphtertext. Function compatible with
   IEEE P802.1 specification. Errors out if encryption fails, else
   returns the secret ciphertext and a SHA256 of the header to
   checksum the integrity of the accompanying plaintext, to be
   compared with the one obtained by @{aead_decrypt}.

   @param key AES key octet (must be 16, 24 or 32 bytes long)
   @param message input text in an octet
   @param iv initialization vector. If the key is reused several times,
          this param should be random, so the iv/key is different every time.
          Follow RFC5116, section 3.1 for recommendations
   @param header clear text, authenticated for integrity (checksum)
   @param tag the authenticated tag. As per RFC5116, this should be 16 bytes
          long
   @function aead_encrypt(key, message, iv, h)
   @treturn[1] octet containing the output ciphertext
   @treturn[1] octet containing the authentication tag (checksum)
*/
static int ecdh_aead_encrypt(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *k =  o_arg(L, 1);
	if(k == NULL) {
		failed_msg = "Could not allocate aes key";
		goto end;
	}
	// AES key size nk can be 16, 24 or 32 bytes
	if(k->len > 32 || k->len < 16) {
		zerror(L, "ECDH.aead_encrypt accepts only keys of 16, 24, 32, this is %u", k->len);
		failed_msg = "ECDH encryption aborted";
		goto end;
	}
	const octet *in = o_arg(L, 2);
	if(in == NULL) {
		failed_msg = "Could not allocate message";
		goto end;
	}
	const octet *iv = o_arg(L, 3);
	if(iv == NULL) {
		failed_msg = "Could not allocate iv";
		goto end;
	}
	if (iv->len < 12) {
		zerror(L, "ECDH.aead_encrypt accepts an iv of 12 bytes minimum, this is %u", iv->len);
		failed_msg = "ECDH encryption aborted";
		goto end;
	}
	const octet *h = o_arg(L, 4);
	HEDLEY_ASSUME(h != NULL);
	if(h == NULL) {
		failed_msg = "Could not allocate header";
		goto end;
	}
	// output is padded to next word
	octet *out = o_new(L, in->len+16);
	if(out == NULL) {
		failed_msg = "Could not create ciphertext";
		goto end;
	}
	octet *t = o_new(L, 16);
	if(t == NULL) {
		failed_msg = "Could not create authentication tag";
		goto end;
	}
	AES_GCM_ENCRYPT
		((octet*)k, (octet*)iv, (octet*)h, (octet*)in, out, t);
end:
	o_free(L, h);
	o_free(L, iv);
	o_free(L, in);
	o_free(L, k);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(2);
}

/*
   AES-GCM decrypt with Additional Data (AEAD) decrypts and
   authenticate a plaintext to a ciphtertext . Compatible with IEEE
   P802.1 specification.

   @param key AES key octet
   @param message input text in an octet
   @param iv initialization vector
   @param header the additional data
   @treturn[1] octet containing the output ciphertext
   @treturn[1] octet containing the authentication tag (checksum)
   @function aead_decrypt(key, ciphertext, iv, h)
*/

static int ecdh_aead_decrypt(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *k = o_arg(L, 1);
	if(k == NULL) {
		failed_msg = "Could not allocate aes key";
		goto end;
	}
	if(k->len > 32 || k->len < 16) {
		zerror(L, "ECDH.aead_decrypt accepts only keys of 16, 24, 32, this is %u", k->len);
		failed_msg = "ECDH decryption aborted";
		goto end;
	}
	const octet *in = o_arg(L, 2);
	if(in == NULL) {
		failed_msg = "Could not allocate messsage";
		goto end;
	}
	const octet *iv = o_arg(L, 3);
	if(iv == NULL) {
		failed_msg = "Could not allocate iv";
		goto end;
	}
	if (iv->len < 12) {
		zerror(L, "ECDH.aead_decrypt accepts an iv of 12 bytes minimum, this is %u", iv->len);
		failed_msg = "ECDH decryption aborted";
		goto end;
	}
	const octet *h = o_arg(L, 4);
	if(h == NULL) {
		failed_msg = "Could not allocate header";
		goto end;
	}
	// output is padded to next word
	octet *out = o_new(L, in->len+16);
	if(out == NULL) {
		failed_msg = "Could not create ciphertext";
		goto end;
	}
	octet *t2 = o_new(L, 16);
	if(t2 == NULL) {
		failed_msg = "Could not create authentication tag";
		goto end;
	}
	AES_GCM_DECRYPT((octet*)k, (octet*)iv, (octet*)h, (octet*)in, out, t2);
end:
	o_free(L, h);
	o_free(L, iv);
	o_free(L, in);
	o_free(L, k);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(2);
}

/**
   Order of the curve underlying the ECDH implementation


   @function ECDH.order()
   @return BIG with the order
*/
static int ecdh_order(lua_State *L) {
	BEGIN();
	if(!ECDH.order || ECDH.mod_size <= 0) {
		lerror(L, "%s: ECDH order not implemented", __func__);
		return 0;
	}
	big *o = big_new(L);
	big_init(L,o);
	BIG_fromBytesLen(o->val, ECDH.order, ECDH.mod_size);
	END(1);
}

/**
   Modulus of the curve underlying the ECDH implementation

   @function ECDH.prime()
   @return BIG with the modulus
*/
static int ecdh_prime(lua_State *L) {
	BEGIN();
	if(!ECDH.prime || ECDH.mod_size <= 0) {
		lerror(L, "%s: ECDH modulus not implemented", __func__);
		return 0;
	}
	big *p = big_new(L);
	big_init(L,p);
	BIG_fromBytesLen(p->val, ECDH.prime, ECDH.mod_size);
	END(1);
}

/**
   Cofactor of the curve underlying the ECDH implementation

   @function ECDH.cofactor()
   @return int with the cofactor
*/
static int ecdh_cofactor(lua_State *L) {
	BEGIN();
	if(!ECDH.cofactor) {
		lerror(L, "%s: ECDH cofactor not implemented", __func__);
		return 0;
	}
	lua_pushinteger(L, ECDH.cofactor);
	END(1);
}

/**
   Elliptic Curve Digital Signature Algorithm (ECDSA) recovery function.
   This method is intended to be used over all the possible point (x,y)
   that create the ephemeral public key of the signature, i.e.
   x can be equal to r+j*n where j is in [0,..,h] (h cofactor of the curve),
   n is the order of the curve and r is the first component of the signature.
   While y is uniquely identified by its parity.
   This method, if it exists, will output a public key Q for which (r, s)
   is a valid signature on the hashed message m.

   @param x the x coordinate of the ephemeral public key
   @param y_parity parity of y coordinate of the ephemeral public key
   @param m hashed message
   @param sig the signature (r,s)
   @return[1] the recoverd public key in a compressed form
   @return[2] 1 if the above public key is valid, 0 otherwise
*/
static int ecdh_dsa_recovery(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *x = o_arg(L, 1);
	if(x == NULL) {
		failed_msg = "Could not allocate x-coordinate";
		goto end;
	}
	int i;
	lua_Integer y = lua_tointegerx(L, 2, &i);
	if(!i) {
		failed_msg = "parity of y coordinate has to be a integer";
		goto end;
	}
	const octet *m = o_arg(L, 3);
	if(m == NULL) {
		failed_msg = "Could not allocate message";
		goto end;
	}
	octet *r = NULL, *s = NULL;
	if(lua_type(L, 4) == LUA_TTABLE) {
		lua_getfield(L, 4, "r");
		lua_getfield(L, 4, "s");
		r = (octet*) o_arg(L, -2);
		if(r == NULL) {
			failed_msg = "Could not allocate signautre.r";
			goto end;
		}
		s = (octet*) o_arg(L, -1);
		if(s == NULL) {
			failed_msg = "Could not allocate signautre.s";
			goto end;
		}
	} else {
		failed_msg = "signature argument invalid: not a table";
		goto end;
	}
	octet *pk = o_new(L, ECDH.fieldsize*2 +1);
	if(pk == NULL) {
		failed_msg = "Could not create public key";
		goto end;
	}

	lua_pushboolean(L, !(*ECDH.ECP__PUBLIC_KEY_RECOVERY)
					((octet*)x, (int)y, (octet*)m, r, s, pk));
end:
	o_free(L, s);
	o_free(L, r);
	o_free(L, m);
	o_free(L, x);
	if(failed_msg) {
		THROW(failed_msg);
		lua_pushnil(L);
	}
	END(2);
}

extern int ecdh_add(lua_State *L);

int luaopen_ecdh(lua_State *L) {
	(void)L;
	const struct luaL_Reg ecdh_class[] = {
		{"keygen",ecdh_keygen},
		{"pubgen",ecdh_pubgen},
		{"order",ecdh_order},
		{"prime",ecdh_prime},
		{"cofactor",ecdh_cofactor},
		{"aead_encrypt",   ecdh_aead_encrypt},
		{"aead_decrypt",   ecdh_aead_decrypt},
		{"aesgcm_encrypt", ecdh_aead_encrypt},
		{"aesgcm_decrypt", ecdh_aead_decrypt},
		{"aes_encrypt",    ecdh_aead_encrypt},
		{"aes_decrypt",    ecdh_aead_decrypt},
		{"session", ecdh_session},
		{"checkpub", ecdh_pubcheck},
		{"pubcheck", ecdh_pubcheck},
		{"validate", ecdh_pubcheck},
		{"sign", ecdh_dsa_sign},
		{"verify", ecdh_dsa_verify},
		{"sign_deterministic", ecdh_dsa_sign_det},
		{"sign_det_hashed", ecdh_dsa_sign_det_hashed},
		{"verify_deterministic", ecdh_dsa_verify_det},
		{"sign_hashed", ecdh_dsa_sign_hashed},
		{"verify_hashed", ecdh_dsa_verify_hashed},
		{"recovery", ecdh_dsa_recovery},
		{"public_xy", ecdh_pub_xy},
		{"pubxy", ecdh_pub_xy},
		{"add", ecdh_add},
		{NULL,NULL}};
	const struct luaL_Reg ecdh_methods[] = {
		{NULL,NULL}
	 };

	ecdh_init(L, &ECDH);

	zen_add_class(L, "ecdh", ecdh_class, ecdh_methods);
	return 1;
}
