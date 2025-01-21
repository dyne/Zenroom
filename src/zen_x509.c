/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2025 Dyne.org foundation
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
#include <zenroom.h>
#include <zen_error.h>
#include <zen_memory.h>
#include <lua_functions.h>
#include <zen_octet.h>
#include <zen_error.h>
#include <encoding.h>

#include <x509.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUF_SIZE 8192
#define SAFE(x) if(!x) { failed_msg="NULL var"; goto end; }

static int pem_to_base64(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const char *begin_marker = "-----BEGIN";
	const char *end_marker = "-----END";
	const char *in = lua_tostring(L, 1);
	luaL_argcheck(L, in != NULL, 1, "string argument expected");
	char *dst = calloc(strlen(in)+2,1);
	char *output = dst;
	const char *begin = strstr(in, begin_marker);
	const char *end = strstr(in, end_marker);

	if (begin && end) {
		const char *base64_start = strchr(begin, '\n');
		if (base64_start) {
			base64_start++;
			const char *base64_end = strstr(base64_start, end_marker);
			if (base64_end) {
				while (base64_start < base64_end) {
					if (*base64_start != '\n' && *base64_start != '\r') {
						*output++ = *base64_start;
					}
					base64_start++;
				}
				*output = '\0';  // Null-terminate the output string
			}
		}
	}
 end:
	lua_pushlstring(L, dst, strlen(dst));
	free(dst);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);

}

static int extract_cert(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *in = o_arg(L, 1); SAFE(in);
	octet *c = o_new(L,BUF_SIZE); SAFE(c);
	X509_extract_cert((octet*)in, c);
 end:
	o_free(L,in);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int extract_cert_sig(lua_State *L) {
	BEGIN();
	pktype st;
	char *failed_msg = NULL;
	const octet *in = o_arg(L, 1); SAFE(in);
	octet *sig = o_new(L,BUF_SIZE); SAFE(sig);
	st = X509_extract_cert_sig((octet*)in, sig);
	func(L,"SIG type: %u",st.type);
 end:
	o_free(L,in);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int extract_pubkey(lua_State *L) {
	BEGIN();
	pktype ca;
	char *failed_msg = NULL;
	const octet *in = o_arg(L, 1); SAFE(in);
	octet *raw = o_alloc(L,BUF_SIZE); SAFE(raw);
	ca = X509_extract_public_key((octet*)in, raw);
	octet *pk = o_new(L,raw->len); SAFE(pk);
	// shave the leftmost byte on P256 ( 0x04 )
	memcpy(pk->val,raw->val+1,raw->len-1);
	pk->len = raw->len-1;
	o_free(L,raw);
	func(L,"CA type: %u",ca.type);
	// TODO: ca.type switch/case and return string and hash
	// lua_pushlstring(L, ca.type..., strlen(ca.type));
 end:
	o_free(L,in);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int extract_seckey(lua_State *L) {
	BEGIN();
	pktype sk_t;
	char *failed_msg = NULL;
	const octet *in = o_arg(L, 1); SAFE(in);
	octet *sk = o_new(L,in->len); SAFE(sk);
	sk_t = X509_extract_private_key((octet*)in,sk);
	func(L,"SK type: %u",sk_t.type);
end:
	o_free(L,in);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

int luaopen_x509(lua_State *L) {
	(void)L;
	const struct luaL_Reg x509_class[] = {
		{"pem_to_base64", pem_to_base64},
		{"extract_cert", extract_cert},
		{"extract_cert_sig", extract_cert_sig},
		{"extract_pubkey", extract_pubkey},
		{"extract_seckey", extract_seckey},
		{NULL,NULL}
	};
	const struct luaL_Reg x509_methods[] = {
		{NULL,NULL}
	};
	zen_add_class(L, "x509", x509_class, x509_methods);
	return 1;
}
