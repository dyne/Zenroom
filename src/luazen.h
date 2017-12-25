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
	//
	{"encrypt_aead", lz_aead_encrypt},
	{"decrypt_aead", lz_aead_decrypt},
	//
	{"keypair_x25519", lz_x25519_keypair},
	{"pubkey_x25519", lz_x25519_public_key},
	{"dhxkey_x25519", lz_key_exchange},

	// Blake2b hashing function
	{"hash_blake2b", lz_blake2b},
	{"hash_init_blake2b", lz_blake2b_init},
	{"hash_update_blake2b", lz_blake2b_update},
	{"hash_final_blake2b", lz_blake2b_final},

	// TODO: ed25519 compare to milagro and choose
	{"keypair_sign", lz_sign_keypair},
	{"pubkey_sign", lz_sign_public_key},

	// TODO: specify algo
	{"sign", lz_sign},
	{"check", lz_check},

	// Key Derivation Function
	{"kdf_argon2i", lz_argon2i},
	
	{"xor", lz_xor},
	// brieflz compression
	{"compress_blz", lz_blz},
	{"decompress_blz", lz_unblz},
	// lzf compression
	{"compress_lzf", lz_lzf},
	{"decompress_lzf", lz_unlzf},
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
