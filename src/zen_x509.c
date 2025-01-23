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

static void push_entity_property(lua_State *L, const octet *H, int c, int len) {
	char tmp[2048];
	snprintf(tmp,len,"%s",&H->val[c]);
	lua_pushstring(L,tmp);
}

static void push_date(lua_State *L, const octet *c, int i) {
	char tmp[24];
	snprintf(tmp,20,"20%c%c-%c%c-%c%c %c%c:%c%c:%c%c",
			 c->val[i], c->val[i + 1], c->val[i + 2],
			 c->val[i + 3], c->val[i + 4], c->val[i + 5],
			 c->val[i + 6], c->val[i + 7], c->val[i + 8],
			 c->val[i + 9], c->val[i + 10], c->val[i + 11]);
	lua_pushstring(L,tmp);
}

#define _extract_property(_key_, _name_) \
    c = X509_find_entity_property((octet*)H, &_key_, ic, &len); \
	if(c) { \
		lua_pushstring(L,_name_); \
		push_entity_property(L,H,c,len); \
		lua_settable(L,-3); }

static int extract_issuer(lua_State *L) {
	BEGIN();
	int c, ic, len;
	char *failed_msg = NULL;
	const octet *H = o_arg(L, 1); SAFE(H);
    ic = X509_find_issuer((octet*)H,&len);
	if(!ic) {
		failed_msg = "Issuer not found in x509 credential";
		goto end;
	}
	lua_newtable(L);
	_extract_property(X509_CN,"country");
	_extract_property(X509_ON,"org");
	_extract_property(X509_EN,"email");
	_extract_property(X509_LN,"local");
	_extract_property(X509_UN,"unit");
	_extract_property(X509_MN,"name");
	_extract_property(X509_SN,"state");
	_extract_property(X509_AN,"alternate");
	_extract_property(X509_KU,"key");
	_extract_property(X509_BC,"constraints");
end:
	o_free(L,H);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int extract_dates(lua_State *L) {
	BEGIN();
	int c, ic;
	char *failed_msg = NULL;
	const octet *H = o_arg(L, 1); SAFE(H);
    ic = X509_find_validity((octet*)H);
	if(!ic) {
		failed_msg = "Validity not found in x509 credential";
		goto end;
	}
	lua_newtable(L);
    c = X509_find_start_date((octet*)H, ic);
	if(c) {
		lua_pushstring(L,"created"); \
		push_date(L,H,c);
		lua_settable(L,-3);
	}
    c = X509_find_expiry_date((octet*)H, ic);
	if(c) {
		lua_pushstring(L,"expires"); \
		push_date(L,H,c);
		lua_settable(L,-3);
	}
end:
	o_free(L,H);
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
		{"extract_issuer", extract_issuer},
		{"extract_dates", extract_dates},
		{NULL,NULL}
	};
	const struct luaL_Reg x509_methods[] = {
		{NULL,NULL}
	};
	zen_add_class(L, "x509", x509_class, x509_methods);
	return 1;
}
