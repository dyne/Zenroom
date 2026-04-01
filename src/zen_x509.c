/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2025-2026 Dyne.org foundation
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
#include <lua_functions.h>
#include <zen_octet.h>
#include <encoding.h>

#include <x509.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <ctype.h>

#define BUF_SIZE 8192

static const char *find_bytes(const char *buf, size_t buf_len,
			      const char *needle, size_t needle_len) {
	size_t i;

	if(needle_len == 0 || needle_len > buf_len) {
		return NULL;
	}
	for(i = 0; i + needle_len <= buf_len; i++) {
		if(memcmp(buf + i, needle, needle_len) == 0) {
			return buf + i;
		}
	}
	return NULL;
}

static int is_pem_base64_char(unsigned char c) {
	return isalnum(c) || c == '+' || c == '/' || c == '=';
}

static void push_octet_slice(lua_State *L, const octet *src, int offset, int len) {
	if(offset < 0 || len < 0 || offset > src->len || len > src->len - offset) {
		lua_pushliteral(L, "");
		return;
	}
	lua_pushlstring(L, (const char *)src->val + offset, (size_t)len);
}

static int read_asn1_length(const uint8_t *buf, size_t buf_len,
			    size_t *value_len, size_t *header_len) {
	size_t i;
	size_t count;
	size_t len;

	if(buf_len == 0) {
		return 0;
	}
	if((buf[0] & 0x80) == 0) {
		*value_len = buf[0];
		*header_len = 1;
		return *value_len <= buf_len - 1;
	}

	count = buf[0] & 0x7f;
	if(count == 0 || count > sizeof(size_t) || count >= buf_len) {
		return 0;
	}
	len = 0;
	for(i = 0; i < count; i++) {
		len = (len << 8) | buf[i + 1];
	}
	if(len > buf_len - count - 1) {
		return 0;
	}
	*value_len = len;
	*header_len = count + 1;
	return 1;
}

static const char *san_type_name(uint8_t type) {
	switch(type) {
	case 0x81: return "email";
	case 0x82: return "dns";
	case 0x83: return "X400";
	case 0x85: return "dir";
	case 0x86: return "url";
	case 0xA0: return "RFC822";
	case 0x87: return "ip";
	case 0x88: return "OID";
	default: return "unknown";
	}
}

static int pem_to_base64(lua_State *L) {
	BEGIN();
	const char *begin_marker = "-----BEGIN";
	const char *end_marker = "-----END";
	size_t in_len = 0;
	size_t begin_len = strlen(begin_marker);
	size_t end_len = strlen(end_marker);
	size_t out_len = 0;
	const char *in = luaL_checklstring(L, 1, &in_len);
	char *dst = calloc(in_len + 1, 1); SAFE(dst, MALLOC_ERROR);
	const char *begin = find_bytes(in, in_len, begin_marker, begin_len);

	if(begin) {
		const char *body = memchr(begin, '\n', in_len - (size_t)(begin - in));
		if(body) {
			const char *end = find_bytes(body + 1,
						    in_len - (size_t)(body + 1 - in),
						    end_marker, end_len);
			const char *cursor;

			if(end) {
				for(cursor = body + 1; cursor < end; cursor++) {
					unsigned char ch = (unsigned char)*cursor;
					if(is_pem_base64_char(ch)) {
						dst[out_len++] = (char)ch;
					}
				}
			}
		}
	}
	lua_pushlstring(L, dst, out_len);
	free(dst);
	END(1);
}

static int extract_cert(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *in = o_arg(L, 1); SAFE_GOTO(in, ALLOCATE_OCT_ERR);
	octet *c = o_new(L, BUF_SIZE); SAFE_GOTO(c, CREATE_OCT_ERR);
	X509_extract_cert((octet*)in, c);
end:
	o_free(L, in);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int extract_cert_sig(lua_State *L) {
	BEGIN();
	pktype st;
	char *failed_msg = NULL;
	const octet *in = o_arg(L, 1); SAFE_GOTO(in, ALLOCATE_OCT_ERR);
	octet *sig = o_new(L,BUF_SIZE); SAFE_GOTO(sig, CREATE_OCT_ERR);
	st = X509_extract_cert_sig((octet*)in, sig);
	func(L,"SIG type: %u",st.type);
end:
	o_free(L, in);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int extract_pubkey(lua_State *L) {
	BEGIN();
	pktype ca;
	char *failed_msg = NULL;
	octet *raw = NULL;
	const octet *in = o_arg(L, 1); SAFE_GOTO(in, ALLOCATE_OCT_ERR);
	raw = o_alloc(L,BUF_SIZE); SAFE_GOTO(raw, ALLOCATE_OCT_ERR);
	ca = X509_extract_public_key((octet*)in, raw);
	octet *pk = o_new(L,raw->len); SAFE_GOTO(pk, CREATE_OCT_ERR);
	// shave the leftmost byte on P256 ( 0x04 )
	memcpy(pk->val,raw->val+1,raw->len-1);
	pk->len = raw->len-1;
	func(L,"CA type: %u",ca.type);
	// TODO: ca.type switch/case and return string and hash
	// lua_pushlstring(L, ca.type..., strlen(ca.type));
end:
	o_free(L, raw);
	o_free(L, in);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int extract_seckey(lua_State *L) {
	BEGIN();
	pktype sk_t;
	char *failed_msg = NULL;
	const octet *in = o_arg(L, 1); SAFE_GOTO(in, ALLOCATE_OCT_ERR);
	octet *sk = o_new(L,in->len); SAFE_GOTO(sk, CREATE_OCT_ERR);
	sk_t = X509_extract_private_key((octet*)in,sk);
	func(L,"SK type: %u",sk_t.type);
end:
	o_free(L, in);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static void push_entity(lua_State *L, const octet *H, int c, int len) {
	push_octet_slice(L, H, c, len);
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
	const octet *H = o_arg(L, 1); SAFE_GOTO(H, ALLOCATE_OCT_ERR);
    ic = X509_find_issuer((octet*)H,&len); SAFE_GOTO(ic, "Could not found issuer x509 credential");
	lua_newtable(L);
	_extract_property(X509_ON,"owner");
	_extract_property(X509_CN,"country");
	_extract_property(X509_EN,"email");
	_extract_property(X509_LN,"local");
	_extract_property(X509_UN,"unit");
	_extract_property(X509_MN,"name");
	_extract_property(X509_SN,"state");
end:
	o_free(L, H);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int extract_subject(lua_State *L) {
	BEGIN();
	int c, ic, len;
	char *failed_msg = NULL;
	const octet *H = o_arg(L, 1); SAFE_GOTO(H, ALLOCATE_OCT_ERR);
    ic = X509_find_subject((octet*)H,&len); SAFE_GOTO(ic, "Could not found sbject x509 credential");
	lua_newtable(L);
	_extract_property(X509_ON,"owner");
	_extract_property(X509_CN,"country");
	_extract_property(X509_EN,"email");
	_extract_property(X509_LN,"local");
	_extract_property(X509_UN,"unit");
	_extract_property(X509_MN,"name");
	_extract_property(X509_SN,"state");
end:
	o_free(L, H);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}


static int extract_extensions(lua_State *L) {
	BEGIN();
	int c, ic, len;
	char *failed_msg = NULL;
	const octet *H = o_arg(L, 1); SAFE_GOTO(H, ALLOCATE_OCT_ERR);
    ic = X509_find_extensions((octet*)H); SAFE_GOTO(ic, "Could not found extensions in x509 credential");
	lua_newtable(L);
	_extract_extension(X509_AN,"SAN");
	_extract_extension(X509_KU,"key");
	_extract_extension(X509_BC,"constraints");
end:
	o_free(L, H);
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
	const octet *H = o_arg(L, 1); SAFE_GOTO(H, ALLOCATE_OCT_ERR);
	lua_newtable(L);
	ic = X509_find_extensions((octet*)H); SAFE_GOTO(ic, "Could not found extensions in x509 credential");
	c = X509_find_extension((octet*)H, &X509_AN, ic, &len);
	if(c!=0) {
		const uint8_t *ext = (const uint8_t *)H->val + c;
		size_t ext_len = (size_t)len;
		size_t inner_len = 0;
		size_t inner_hdr_len = 0;
		size_t seq_len = 0;
		size_t seq_hdr_len = 0;
		const uint8_t *cursor;
		const uint8_t *end;
		int index = 1;

		if(ext_len < 2 || ext[0] != 0x04 ||
		   !read_asn1_length(ext + 1, ext_len - 1, &inner_len, &inner_hdr_len)) {
			failed_msg = "Malformed SAN extension";
			goto end;
		}
		cursor = ext + 1 + inner_hdr_len;
		if(inner_len > (size_t)(ext + ext_len - cursor) || inner_len < 2 || cursor[0] != 0x30 ||
		   !read_asn1_length(cursor + 1, inner_len - 1, &seq_len, &seq_hdr_len)) {
			failed_msg = "Malformed SAN sequence";
			goto end;
		}
		cursor += 1 + seq_hdr_len;
		if(seq_len > (size_t)(ext + ext_len - cursor)) {
			failed_msg = "Malformed SAN sequence length";
			goto end;
		}
		end = cursor + seq_len;

		while(cursor < end) {
			size_t entry_len = 0;
			size_t entry_hdr_len = 0;
			uint8_t type;

			if((size_t)(end - cursor) < 2 ||
			   !read_asn1_length(cursor + 1, (size_t)(end - cursor - 1),
					     &entry_len, &entry_hdr_len)) {
				failed_msg = "Malformed SAN entry";
				goto end;
			}
			type = cursor[0];
			cursor += 1 + entry_hdr_len;
			if(entry_len > (size_t)(end - cursor)) {
				failed_msg = "Malformed SAN entry length";
				goto end;
			}

			lua_pushnumber(L,index++);
			lua_newtable(L);
			lua_pushstring(L,"data");
			lua_pushlstring(L, (const char *)cursor, entry_len);
			lua_settable(L,-3);
			lua_pushstring(L,"type");
			lua_pushstring(L, san_type_name(type));
			lua_settable(L,-3);
			lua_settable(L,-3);
			cursor += entry_len;
		}
	}
end:
	o_free(L, H);
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
	const octet *H = o_arg(L, 1); SAFE_GOTO(H, ALLOCATE_OCT_ERR);
    ic = X509_find_validity((octet*)H); SAFE_GOTO(ic, "Could not found validity in x509 credential");
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
	o_free(L, H);
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
