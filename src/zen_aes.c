/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2020 Dyne.org foundation
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


#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <ecdh_support.h>

#include <zen_error.h>
#include <zen_octet.h>
#include <randombytes.h>
#include <lua_functions.h>

#include <zenroom.h>
#include <zen_memory.h>

/// <h1>Advanced Encryption Standard (AES)</h1>
//
//  AES Block cipher in varoius modes.
//
//  AES encryption and decryption functionalities are provided by
//  this module.
//
//  @module AES
//  @author Denis "Jaromil" Roio
//  @license AGPLv3
//  @copyright Dyne.org foundation 2017-2020

// from milagro's pbc_support.h
extern void AES_GCM_ENCRYPT(octet *K, octet *IV, octet *H, octet *P, octet *C, octet *T);
extern void AES_GCM_DECRYPT(octet *K, octet *IV, octet *H, octet *C, octet *P, octet *T);

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
   @function gcm_encrypt(key, message, iv, h)
   @treturn[1] octet containing the output ciphertext
   @treturn[1] octet containing the authentication tag (checksum)
*/
static int gcm_encrypt(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *k = NULL, *in = NULL, *iv = NULL, *h = NULL;
	k =  o_arg(L, 1);
	if(k == NULL) {
		failed_msg = "failed to allocate space for the aes key";
		goto end;
	}
        // AES key size nk can be 16, 24 or 32 bytes
	if(k->len > 32 || k->len < 16) {
		zerror(L, "ECDH.aead_encrypt accepts only keys of 16, 24, 32, this is %u", k->len);
		failed_msg = "ECDH encryption aborted";
		goto end;
	}
	in = o_arg(L, 2);
	if(in == NULL) {
		failed_msg = "failed to allocate space for the messsage text";
		goto end;
	}
	iv = o_arg(L, 3);
	if(iv == NULL) {
		failed_msg = "failed to allocate space for the iv";
		goto end;
	}
        if (iv->len < 12) {
		zerror(L, "ECDH.aead_encrypt accepts an iv of 12 bytes minimum, this is %u", iv->len);
		failed_msg = "ECDH encryption aborted";
		goto end;
	}
	h =  o_arg(L, 4);
	if(h == NULL) {
		failed_msg = "failed to allocate space for the header";
		goto end;
	}
	// output is padded to next word
	octet *out = o_new(L, in->len+16);
	if(out == NULL) {
		failed_msg = "failed to allocate space for the output";
		goto end;
	}
	octet *t = o_new(L, 16);
	if(t == NULL) {
		failed_msg = "failed to allocate space for the checksum";
		goto end;
	}
	AES_GCM_ENCRYPT(k, iv, h, in, out, t);
end:
	o_free(L, h);
	o_free(L, iv);
	o_free(L, in);
	o_free(L, k);
	if(failed_msg != NULL) {
		THROW(failed_msg);
		lua_pushnil(L);
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
   @function gcm_decrypt(key, ciphertext, iv, h)
*/

static int gcm_decrypt(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *k = NULL, *in = NULL, *iv = NULL, *h = NULL;
	k = o_arg(L, 1);
	if(k == NULL) {
		failed_msg = "failed to allocate space for the aes key";
		goto end;
	}
	if(k->len > 32 || k->len < 16) {
		zerror(L, "ECDH.aead_decrypt accepts only keys of 16, 24, 32, this is %u", k->len);
		failed_msg = "ECDH decryption aborted";
		goto end;
	}
	in = o_arg(L, 2);
	if(in == NULL) {
		failed_msg = "failed to allocate space for the messsage text";
		goto end;
	}
	iv = o_arg(L, 3);
	if(iv == NULL) {
		failed_msg = "failed to allocate space for the iv";
		goto end;
	}
        if (iv->len < 12) {
		zerror(L, "ECDH.aead_decrypt accepts an iv of 12 bytes minimum, this is %u", iv->len);
		failed_msg = "ECDH decryption aborted";
		goto end;
	}
	h = o_arg(L, 4);
	if(h == NULL) {
		failed_msg = "failed to allocate space for the header";
		goto end;
	}
	// output is padded to next word
	octet *out = o_new(L, in->len+16);
	if(out == NULL) {
		failed_msg = "failed to allocate space for the output";
		goto end;
	}
	octet *t2 = o_new(L, 16);
	if(t2 == NULL) {
		failed_msg = "failed to allocate space for the checksum";
		goto end;
	}
	AES_GCM_DECRYPT(k, iv, h, in, out, t2);
end:
	o_free(L, h);
	o_free(L, iv);
	o_free(L, in);
	o_free(L, k);
	if(failed_msg != NULL) {
		THROW(failed_msg);
		lua_pushnil(L);
	}
	END(2);
}

static int ctr_process(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *k = NULL, *in = NULL, *iv = NULL;
	amcl_aes a;
	k = o_arg(L, 1);
	if(k == NULL) {
		failed_msg = "failed to allocate space for the aes key";
		goto end;
	}
	if(k->len != 16 && k->len != 32) {
		zerror(L, "AES.ctr_process accepts only keys of 16 or 32 bytes, this is %u", k->len);
		failed_msg = "AES-CTR process aborted";
		goto end;
	}
	in = o_arg(L, 2);
	if(in == NULL) {
		failed_msg = "failed to allocate space for the messsage text";
		goto end;
	}
	iv = o_arg(L, 3);
	if(iv == NULL) {
		failed_msg = "failed to allocate space for the iv";
		goto end;
	}
	if (iv->len < 12) {
		zerror(L, "AES.ctr_process accepts an iv of 12 bytes minimum, this is %u", iv->len);
		failed_msg = "AES-CTR process aborted";
		goto end;
	}
	AES_init(&a, CTR16, k->len, k->val, iv->val);
	octet *out = o_dup(L, in);
	if(out == NULL) {
		failed_msg = "failed to allocate space for the output";
		goto end;
	}
	AMCL_(AES_encrypt)(&a, out->val);
	AES_end(&a);
end:
	o_free(L, iv);
	o_free(L, in);
	o_free(L, k);
	if(failed_msg != NULL) {
		THROW(failed_msg);
	}
	END(1);
}


int luaopen_aes(lua_State *L) {
	(void)L;
	const struct luaL_Reg aes_class[] = {
		{"gcm_encrypt", gcm_encrypt},
		{"gcm_decrypt", gcm_decrypt},
		{"ctr_process", ctr_process},
		{"ctr", ctr_process},
		{NULL, NULL}};
	const struct luaL_Reg aes_methods[] = {
		{NULL, NULL}
	};


	zen_add_class(L, "aes", aes_class, aes_methods);
	return 1;
}
