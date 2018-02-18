/*  Zenroom (DECODE project)
 *
 *  (c) Copyright 2017-2018 Dyne.org foundation
 *  designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This source code is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Public License as published
 * by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 *
 * This source code is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * Please refer to the GNU Public License for more details.
 *
 * You should have received a copy of the GNU Public License along with
 * this source code; if not, write to:
 * Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#ifndef __LUAZEN_H__
#define __LUAZEN_H__

#include <luasandbox.h>

int lz_randombytes(lua_State *L);
int lz_aead_encrypt(lua_State *L);
int lz_aead_decrypt(lua_State *L);
int lz_x25519_keypair(lua_State *L);
int lz_x25519_public_key(lua_State *L);
int lz_key_exchange(lua_State *L);
int lz_blake2b(lua_State *L);
int lz_blake2b_init(lua_State *L);
int lz_blake2b_update(lua_State *L);
int lz_blake2b_final(lua_State *L);
int lz_sign_keypair(lua_State *L);
int lz_sign_public_key(lua_State *L);
int lz_sign(lua_State *L);
int lz_check(lua_State *L);
int lz_argon2i(lua_State *L);
int lz_blz(lua_State *L);
int lz_unblz(lua_State *L);
int lz_lzf(lua_State *L);
int lz_unlzf(lua_State *L);
int lz_xor(lua_State *L);
int lz_rc4raw(lua_State *L);
int lz_rc4(lua_State *L);
int lz_md5(lua_State *L);
int lz_b64encode(lua_State *L);
int lz_b64decode(lua_State *L);
int lz_b58encode(lua_State *L);
int lz_b58decode(lua_State *L);

const struct luaL_Reg luazen[] = {
	{"randombytes", lz_randombytes},

	// Symmetric encryption with Norx AEAD
	{"encrypt_norx", lz_aead_encrypt},
	{"decrypt_norx", lz_aead_decrypt},
	// Mostly obsolete symmetric stream-cipher
	// encrypt and decrypt with same function
	{"crypt_rc4", lz_rc4},
	{"crypt_rc4raw", lz_rc4raw},

	// Asymmetric shared secret session with x25519
	// all secrets are 32 bytes long
	{"keygen_session_x25519", lz_x25519_keypair},
	{"pubkey_session_x25519", lz_x25519_public_key},
	// session shared secret hashed by blake2b
	{"exchange_session_x25519", lz_key_exchange},

	// Blake2b hashing function
	{"hash_blake2b", lz_blake2b},
	{"hash_init_blake2b", lz_blake2b_init},
	{"hash_update_blake2b", lz_blake2b_update},
	{"hash_final_blake2b", lz_blake2b_final},
	// simple MD5 hashing function
	{"hash_md5", lz_md5},

	// Asymmetric signing with ed25519
	{"keygen_sign_ed25519", lz_sign_keypair},
	{"pubkey_sign_ed25519", lz_sign_public_key},
	{"sign_ed25519", lz_sign},
	{"check_ed25519", lz_check},

	// Key Derivation Function
	{"kdf_argon2i", lz_argon2i},
	
	{"xor", lz_xor},
	// brieflz compression
	{"compress_blz", lz_blz},
	{"decompress_blz", lz_unblz},
	// lzf compression
	{"compress_lzf", lz_lzf},
	{"decompress_lzf", lz_unlzf},

	// TODO: rename in all tests
	{"rc4", lz_rc4},
	{"rc4raw", lz_rc4raw},
	{"md5", lz_md5},

	{"encode_b64",	lz_b64encode},
	{"decode_b64",	lz_b64decode},
	{"encode_b58",	lz_b58encode},
	{"decode_b58",	lz_b58decode},
	//
	{NULL, NULL},
};

#endif
