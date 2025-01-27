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

static void push_entity(lua_State *L, const octet *H, int c, int len) {
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
	if(c!=0) { \
	    if(!len)zerror(L,"X509 issuer property %s has zero length",_name_);\
		else { \
		lua_pushstring(L,_name_); \
		push_entity(L,H,c,len); \
		lua_settable(L,-3); } }

#define _extract_extension(_key_, _name_) \
    c = X509_find_extension((octet*)H, &_key_, ic, &len); \
	if(c!=0) { \
	    if(!len)zerror(L,"X509 issuer property %s has zero length",_name_);\
		else { \
		lua_pushstring(L,_name_); \
		push_entity(L,H,c,len); \
		lua_settable(L,-3); } }

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
	_extract_property(X509_ON,"owner");
	_extract_property(X509_CN,"country");
	_extract_property(X509_EN,"email");
	_extract_property(X509_LN,"local");
	_extract_property(X509_UN,"unit");
	_extract_property(X509_MN,"name");
	_extract_property(X509_SN,"state");
end:
	o_free(L,H);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int extract_subject(lua_State *L) {
	BEGIN();
	int c, ic, len;
	char *failed_msg = NULL;
	const octet *H = o_arg(L, 1); SAFE(H);
    ic = X509_find_subject((octet*)H,&len);
	if(!ic) {
		failed_msg = "Issuer not found in x509 credential";
		goto end;
	}
	lua_newtable(L);
	_extract_property(X509_ON,"owner");
	_extract_property(X509_CN,"country");
	_extract_property(X509_EN,"email");
	_extract_property(X509_LN,"local");
	_extract_property(X509_UN,"unit");
	_extract_property(X509_MN,"name");
	_extract_property(X509_SN,"state");
end:
	o_free(L,H);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}


static int extract_extensions(lua_State *L) {
	BEGIN();
	int c, ic, len;
	char *failed_msg = NULL;
	const octet *H = o_arg(L, 1); SAFE(H);
    ic = X509_find_extensions((octet*)H);
	if(!ic) {
		failed_msg = "Issuer not found in x509 credential";
		goto end;
	}
	lua_newtable(L);
	_extract_extension(X509_AN,"SAN");
	_extract_extension(X509_KU,"key");
	_extract_extension(X509_BC,"constraints");
end:
	o_free(L,H);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

// In an X.509 certificate's SAN (Subject Alternative Name) field, the
// GeneralName component can represent various types, each identified
// by unique ASN.1 tags. Apart from URIs, here are other types you may
// encounter, with their corresponding hex tags:
// - Email Address: 81 (IA5String, email)
// - DNS Name: 82 (IA5String, dnsName)
// - X.400 Address: 83
// - Directory Name: 85
// - RFC822 Name: A0 (otherName)
// - IP Address: 87 (OCTET STRING, iPAddress)
// - OID (Registered ID): 88 (OBJECT IDENTIFIER, registeredID)
// Each type has its specific encoding. Examples in Hex:
// - Email Address: 81 0c 6578616d706c65406578616d706c652e636f6d
//   (IA5String with email example@example.com)
// - DNS Name: 82 0c 6578616d706c652e636f6d
//   (IA5String with DNS example.com)
// - IP Address: 87 04 c0a80001 (OCTET STRING with IP 192.168.0.1)
// Within a SAN field, multiple GeneralNames can appear sequenced,
// each prefixed by its identifier hex value, to provide varied
// alternative names.

// extract subject alternative names
static int extract_san(lua_State *L) {
	BEGIN();
	int c, ic, len;
	char *failed_msg = NULL;
	char *tmp;
	const octet *H = o_arg(L, 1); SAFE(H);
    ic = X509_find_extensions((octet*)H);
	if(!ic) {
		failed_msg = "Issuer not found in x509 credential";
		goto end;
	}
    c = X509_find_extension((octet*)H, &X509_AN, ic, &len);
	if(c!=0 &&
	   H->val[c]==0x04 && // ASN.1 octet string
	   // H->val[ic+1] // octet length is unused
	   H->val[c+2]==0x30) // ASN.1 sequence
		{
			int seqlen = H->val[c+3];
			char *p = &H->val[c+4];
			char *end = p + seqlen;
			tmp = calloc(seqlen, 1);
			lua_newtable(L);
			for(int cc=1; p < end; cc++) {
				uint8_t type = *p++;
				int len = *p++;
				lua_pushnumber(L,cc);
				lua_newtable(L);
				lua_pushstring(L,"data");
				snprintf(tmp,len,"%s",p);
				lua_pushstring(L,tmp);
				lua_settable(L,-3);
				lua_pushstring(L,"type");
				sprintf(tmp,"%s",
						 type==0x81?"email":
						 type==0x82?"dns":
						 type==0x83?"X400":
						 type==0x85?"dir":
						 type==0x86?"url":
						 type==0xA0?"RFC822":
						 type==0x87?"ip":
						 type==0x88?"OID":
						 "unknown");
				lua_pushstring(L,tmp);
				lua_settable(L,-3);
				// Set the inner table to the outer table
				lua_settable(L, -3);
				p += len;
			}
			free(tmp);
		}
 end:
	o_free(L,H);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

	// _extract_property(X509_AN,"alternate");
	// _extract_property(X509_KU,"key");
	// _extract_property(X509_BC,"constraints");

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
		{"extract_subject", extract_subject},
		{"extract_extensions", extract_extensions},
		{"extract_san", extract_san},
		{"extract_dates", extract_dates},
		{NULL,NULL}
	};
	const struct luaL_Reg x509_methods[] = {
		{NULL,NULL}
	};
	zen_add_class(L, "x509", x509_class, x509_methods);
	return 1;
}
