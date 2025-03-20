/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2023 Dyne.org foundation
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

#include <p256-m.h>

#include <zen_error.h>
#include <zen_octet.h>
#include <zenroom.h>
#include <lua_functions.h>

#define PK_SIZE 64
#define UNCOMPRESSED_PK_SIZE 65
#define COMPRESSED_PK_SIZE 33
#define PK_COORD_SIZE 32
#define SK_SIZE 32
#define HASH_SIZE 32
#define SIG_SIZE 64

#define ASSERT_OCT_LEN(OCT, SIZE, MSG) \
	if ((OCT)->len != SIZE)        \
	{                              \
		failed_msg = (MSG);    \
		lua_pushnil(L);        \
		goto end;              \
	}


static int allocate_raw_public_key(lua_State *L, int pk_pos, octet **res_pk, char **failed_msg) {
	const octet* pk = o_arg(L, pk_pos);
	if (!pk) {
		*failed_msg = "Could not allocate public key";
		return 1;
	}
	*res_pk = o_alloc(L, PK_SIZE);
	if(*res_pk == NULL) {
		o_free(L, pk);
		*failed_msg = "Could not allocate raw public key";
		return 1;
	}
	(*res_pk)->len = PK_SIZE;
	if (pk->len == PK_SIZE) {
		for(uint8_t i=0; i<PK_SIZE; i++) (*res_pk)->val[i] = pk->val[i];
		o_free(L, pk);
		return 0;
	}
	if (pk->len == UNCOMPRESSED_PK_SIZE) {
		// Check for correct prefix in long public key
		if (pk->val[0] != 0x04) {
			*failed_msg = "Invalid long public key prefix: 0x04 expected";
			o_free(L, pk);
			return 1;
		}
		for(uint8_t i=0; i<PK_SIZE; i++) (*res_pk)->val[i] = pk->val[i+1];
		o_free(L, pk);
		return 0;
	}
	if (pk->len == COMPRESSED_PK_SIZE) {
		// Handle compressed public key
		if (pk->val[0] != 0x02 && pk->val[0] != 0x03) {
			*failed_msg = "Invalid compressed public key prefix: 0x02 or 0x03 expected";
			o_free(L, pk);
			return 1;
		}
		int res = p256_uncompress_publickey((uint8_t*)(*res_pk)->val, (uint8_t*)pk->val);
		o_free(L, pk);
		return res;
	}
	o_free(L, pk);
	*failed_msg = "Invalid public key length";
	return 1;
}

/// <h1>P256 </h1>
//P-256 (also known as secp256r1 or prime256v1) is one of the most widely used elliptic curves in modern cryptography. It is defined by the National Institute of Standards and Technology (NIST) and is part of the Suite B cryptographic standards. P-256 is based on elliptic curve cryptography (ECC), which provides strong security with relatively small key sizes, making it efficient for a wide range of applications. It operates over a finite field of 256 bits, providing a balance between security and performance.
//
//ES256 is a cryptographic algorithm used for digital signatures. It is part of the Elliptic Curve Digital Signature Algorithm (ECDSA) and is based on the P-256 elliptic curve (also known as secp256r1 or prime256v1). ES256 is widely used in modern cryptography, particularly in JSON Web Tokens (JWTs) and secure communication protocols.
//
//To work with this module, we define P256 by loading the es256 library using the require function:
//
//<code> P256 = require('es256'). </code>
//
//Once the module is loaded, you can access its functions using the <code>P256.function()</code> syntax.
//  @module P256


/// Global P256 Functions
// @section P256

/*** Generate a P-256 elliptic curve key pair (a private key and a public key). 
	*However it only returns the private key.
	*A key pair consists of:
	-a private key (secret scalar, a large random number).
	-a public key (a point on the elliptic curve derived from the private key).

	@function P256.keygen
	@return the secret key value
	@usage
	--generate a random private key and print it in hex
	P256 = require('es256')
	print(P256.keygen():hex())
	--print for example: a43f787303d65596a708cee586cbad7f3e17c0a2d513ccb653f4c1ad6f37600e 	
 */
static int p256_keygen(lua_State *L)
{
	BEGIN();
	Z(L);
	uint8_t pub[PK_SIZE];
	octet *sk = o_new(L, SK_SIZE);
	sk->len = SK_SIZE;
	if(!sk) {
		THROW("Could not allocate secret key");
	} else {
		p256_gen_keypair(Z, NULL, (uint8_t*)sk->val, pub);
	}
	END(1);
}

/*** Generate a P-256 public key from a given private key.

	@function P256.pubgen
	@param sk the secret key
	@return the public key value
	@usage 					
	--generate a private key that will be the input of P256.pubgen()		
	P256 = require('es256')							
	print(P256.pubgen(P256.keygen()):hex())
	--the print in hexadecimal will be a random value of 64 bytes, for example
	--print: 138380d70b0d492b8edf5c10ef9fa0c7c77287cbe92115270f75057a4dae3e86d264a5d0e13d215c3bc630357592f15e629f84de07c11df6663bb9b03d1e1912
 */
static int p256_pubgen(lua_State *L)
{
	BEGIN();
	char *failed_msg = NULL;
	const octet *sk = NULL;
	octet *pk = NULL;
	sk = o_arg(L, 1);
	if (!sk)
	{
		failed_msg = "Could not allocate secret key";
		goto end;
	}

	ASSERT_OCT_LEN(sk, SK_SIZE, "Invalid size for P256 secret key")

	pk = o_new(L, PK_SIZE);
	if (!pk)
	{
		failed_msg = "Could not allocate public key";
		goto end;
	}
	pk->len = PK_SIZE;

	int ret = p256_publickey((uint8_t *)sk->val, (uint8_t *)pk->val);
	if (ret != 0)
	{
		failed_msg = "Could not generate public key";
		goto end;
	}
end:
	o_free(L, sk);
	if (failed_msg != NULL)
	{
		THROW(failed_msg);
	}
	END(1);
}

static int p256_session(lua_State *L)
{
	BEGIN();
	// TODO: is there a KEM session function in our p256 lib?
	END(1);
}

/*** Validate whether a given P-256 public key is valid. It takes a public key as input, checks its validity using the <code>p256\_validate_pubkey</code> function.
	*It takes a 64-byte uncompressed public key as input (the public key is represented as a concatenation of the x and y coordinates of the elliptic curve point), decodes it into elliptic curve coordinates, and checks if the coordinates represent a valid point on the P-256 curve.

	@function P256.pubcheck
	@param pk the public key passed as an octet
	@return true if pk is valid, false otherwise
	@usage 
	P256 = require('es256')
	--create secret key
	sk = P256.keygen()           
	--create public key                              
	pk = P256.pubgen(sk) 										
	if (P256.pubcheck(pk)) then print("public key is valid")
	else print("public key is invalid")
	end
	--print: public key is valid
 */
static int p256_pubcheck(lua_State *L) {
	BEGIN();
	octet *raw_pk = NULL;
	char *failed_msg = NULL;
	int ret = allocate_raw_public_key(L, 1, &raw_pk, &failed_msg);
	if (ret != 0) goto end;
	lua_pushboolean(L, p256_validate_pubkey((uint8_t*)raw_pk->val)==0);
end:
	o_free(L, raw_pk);
	if (failed_msg != NULL) {
		THROW(failed_msg);
	}
	END(1);
}

/*** Sign a message using the P-256 elliptic curve digital signature algorithm (ECDSA). It takes a private key, a message, and an optional ephemeral key as inputs, 
	*computes the signature, and returns the signature to Lua. It computes the signature using the <code>p256\_ecdsa_sign</code> function.

	@function P256.sign
	@param sk the private key (32 bytes)
	@param m the message to be signed
	@param  k ephemeral key (optional)
	@return the signature
	@usage 
	P256 = require('es256')
	--generate the secret and the public keys
	sk = P256.keygen()
	pk = P256.pubgen(sk)
	--give a message to sign
	m = O.from_str([[
	Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
	eiusmod tempor incididunt ut labore et dolore magna aliqua.]])
	--sign the message 
	sig = P256.sign(sk,m)
 */
static int p256_sign(lua_State *L)
{
	BEGIN();
	Z(L);

	int n_args = lua_gettop(L);
	hash256 sha256;
	char hash[HASH_SIZE];
	char *failed_msg = NULL;
	const octet *sk = NULL, *m = NULL, *k = NULL;
	octet *sig = NULL;
	sk = o_arg(L, 1);
	if (!sk)
	{
		failed_msg = "Could not allocate secret key";
		goto end;
	}
	m = o_arg(L, 2);
	if (!m)
	{
		failed_msg = "Could not allocate message";
		goto end;
	}

	ASSERT_OCT_LEN(sk, SK_SIZE, "Invalid size for ECDSA secret key")
	HASH256_init(&sha256);
	for (int i = 0; i < m->len; i++)
	{
		HASH256_process(&sha256, m->val[i]);
	}
	HASH256_hash(&sha256, hash);

	sig = o_new(L, SIG_SIZE);
	if (!sig)
	{
		failed_msg = "Could not allocate signature";
		goto end;
	}
	sig->len = SIG_SIZE;

	if(n_args > 2) {
		k = o_arg(L, 3);
		if(k == NULL) {
			failed_msg = "Could not allocate ephemeral key";
			goto end;
		}
	}

	int ret = p256_ecdsa_sign(Z, k, (uint8_t *)sig->val, (uint8_t *)sk->val,
				  (uint8_t *)hash, HASH_SIZE);
	if (ret != 0)
	{
		failed_msg = "Could not sign message";
		goto end;
	}

end:
	o_free(L, m);
	o_free(L, sk);
	o_free(L, k);
	if (failed_msg != NULL)
	{
		THROW(failed_msg);
	}
	END(1);
}

/*** Verify an ECDSA signature using the P-256 elliptic curve. It takes a public key, a message, and a signature as inputs, 
	*hashes the message, and verifies the signature against the public key and message hash.
	*It uses the  <code>p256\_ecdsa_verify</code> function.
	@function P256.verify
	@param pk the public key (64 bytes)
	@param m the message that was signed
	@param sig a 64 bytes ECDSA signature
	@return a boolean value
	@usage
	--from @{sign}, check if the signature is valid
	if (P256.verify(pk, m, sig)) then print("valid signature")
	else print("invalid signature")
	end
	--print: valid signature
 */
static int p256_verify(lua_State *L)
{
	BEGIN();
	hash256 sha256;
	char hash[HASH_SIZE];
	char *failed_msg = NULL;
	octet *raw_pk = NULL;
	const octet *sig = NULL, *m = NULL;
	int ret = allocate_raw_public_key(L, 1, &raw_pk, &failed_msg);
	if (ret != 0) goto end;
	m = o_arg(L, 2);
	if (!m)
	{
		failed_msg = "Could not allocate message";
		goto end;
	}
	sig = o_arg(L, 3);
	if (!sig)
	{
		failed_msg = "Could not allocate signature";
		goto end;
	}

	ASSERT_OCT_LEN(sig, SIG_SIZE, "Invalid size for P256 signature")

	HASH256_init(&sha256);
	for (int i = 0; i < m->len; i++)
	{
		HASH256_process(&sha256, m->val[i]);
	}
	HASH256_hash(&sha256, hash);

	lua_pushboolean(L, p256_ecdsa_verify((uint8_t *)sig->val,
					     (uint8_t *)raw_pk->val,
					     (uint8_t *)hash, HASH_SIZE) == 0);
end:
	o_free(L, m);
	o_free(L, sig);
	o_free(L, raw_pk);
	if (failed_msg != NULL)
	{
		THROW(failed_msg);
	}
	END(1);
}

/*** Extract the x and y coordinates from a P-256 public key. 
	*It takes a 64-byte uncompressed public key as input, splits it into its x and y coordinates, and returns them to Lua.

	@function P256.public_xy
	@param pk the public key as an octet
	@return the x coordinate of the public key 
	@return the y coordinate of the public key
	@usage 
	P256 = require('es256')
	--generate private and public keys
	sk = P256.keygen()
	pk = P256.pubgen(sk)
	--find x and y coordinates for the public key
	x, y = P256.public_xy(pk)
 */
static int p256_pub_xy(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *raw_pk = NULL;
	int i;
	int ret = allocate_raw_public_key(L, 1, &raw_pk, &failed_msg);
	if (ret != 0) goto end;
	octet *x = o_new(L, PK_COORD_SIZE+1);
	if(x == NULL) {
		failed_msg = "Could not create x coordinate";
		goto end;
	}
	for(i=0; i < PK_COORD_SIZE; i++)
		x->val[i] = raw_pk->val[i];
	x->val[PK_COORD_SIZE+1] = 0x0;
	x->len = PK_COORD_SIZE;
	octet *y = o_new(L, PK_COORD_SIZE+1);
	if(y == NULL) {
		failed_msg = "Could not create y coordinate";
		goto end;
	}
	for(i=0; i < PK_COORD_SIZE; i++)
		y->val[i] = raw_pk->val[PK_COORD_SIZE+i];
	y->val[PK_COORD_SIZE+1] = 0x0;
	y->len = PK_COORD_SIZE;
end:
	o_free(L, raw_pk);
	if(failed_msg) {
		THROW(failed_msg);
		lua_pushnil(L);
	}
	END(2);
}

static int p256_destroy(lua_State *L)
{
	BEGIN();
	END(0);
}

/*** Compress a P-256 public key. 
	*It takes a 64-byte uncompressed public key as input, compresses it into a 33-byte compressed format, and returns the compressed key to Lua.
	*It uses the <code>p256\_compress_publickey</code> function.

	@function P256.compress_public_key
	@param pk the public key passed as an octet
	@return the compressed public key
	@usage 
	P256 = require('es256')
	--generate public and private keys
	sk = P256.keygen()
	pk = P256.pubgen(sk)
	--create the compressed public key
	pk_comp = P256.compress_public_key(pk)
	--print the length of the compress public key
	print(pk_comp:__len())
	--print: 33
 */
static int p256_compress_pub(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *raw_pk = NULL;
	int ret = allocate_raw_public_key(L, 1, &raw_pk, &failed_msg);
	if (ret != 0) goto end;
	octet *compressed_pk = o_new(L, COMPRESSED_PK_SIZE);
	if(compressed_pk == NULL) {
		failed_msg = "Could not create compressed public key";
		goto end;
	}
	compressed_pk->len = COMPRESSED_PK_SIZE;
	ret = p256_compress_publickey((uint8_t*)compressed_pk->val, (uint8_t*)raw_pk->val);
	if (ret != 0) {
		failed_msg = "Could not compress public key";
		goto end;
	}
end:
	o_free(L, raw_pk);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

int luaopen_p256(lua_State *L)
{
	(void)L;
	const struct luaL_Reg p256_class[] = {
	    {"keygen", p256_keygen},
	    {"pubgen", p256_pubgen},
	    {"session", p256_session},
	    {"checkpub", p256_pubcheck},
	    {"pubcheck", p256_pubcheck},
	    {"validate", p256_pubcheck},
	    {"sign", p256_sign},
	    {"verify", p256_verify},
	    {"public_xy", p256_pub_xy},
	    {"pubxy", p256_pub_xy},
		{"compress_public_key", p256_compress_pub},
	    {NULL, NULL}};
	const struct luaL_Reg p256_methods[] = {
	    {"__gc", p256_destroy},
	    {NULL, NULL}};

	zen_add_class(L, "p256", p256_class, p256_methods);
	return 1;
}
