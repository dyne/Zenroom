#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <zenroom.h>
#include <luazen.h>
#include <amcl.h>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

int luaopen_crypto(lua_State *L) {
	const struct luaL_Reg crypto[] = {
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

		{"encode_b64",  lz_b64encode},
		{"decode_b64",  lz_b64decode},
		{"encode_b58",  lz_b58encode},
		{"decode_b58",  lz_b58decode},
		//
		{NULL, NULL},
	};

	luaL_newlib(L, crypto);
	lua_getfield(L, -1, "crypto");
	lua_setglobal(L, "crypto");
	return 1;
}
