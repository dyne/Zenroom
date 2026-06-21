/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2024-2026 Dyne.org foundation
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

#include <stdio.h>
#include <stdarg.h>
#include <unistd.h>
#include <string.h>
#include <strings.h>
#include <inttypes.h>

#if defined(_WIN32)
#include <malloc.h>
#else
#include <stdlib.h>
#endif

#include <zen_error.h>
#include <zenroom.h>
#include <encoding.h>
#include <mutt_sprintf.h>

#include <ed25519.h>
#include <randombytes.h>

#include <time.h>
#include <amcl.h>

#define RANDOM_SEED_LEN 64
#define MAX_KEY_BUF 12288

static void *api_rng_alloc(const char *hexseed) {
	csprng *rng = (csprng*)malloc(sizeof(csprng));
	if(!rng) {
		_err("%s : cannot allocate the random generator", __func__);
		return NULL;
	}
	char tseed[RANDOM_SEED_LEN];
	if(hexseed) {
		int seedlen = strlen(hexseed);
		if(seedlen!=128) {
			_err("%s : seed is not 64 bytes long (128 chars in hex): %u",__func__,seedlen);
			free(rng);
			return NULL;
		}
		hex2buf(tseed, hexseed);
	} else {
		randombytes(tseed,RANDOM_SEED_LEN-4);
		unsign32 ttmp = (unsign32)time(NULL);
		tseed[60] = (ttmp >> 24) & 0xff;
		tseed[61] = (ttmp >> 16) & 0xff;
		tseed[62] = (ttmp >>  8) & 0xff;
		tseed[63] =  ttmp & 0xff;
	}
	AMCL_(RAND_seed)(rng, RANDOM_SEED_LEN, tseed);
	return(rng);
}

static int api_write_error(char *stderr_buf, size_t stderr_len,
						   const char *fmt, ...) {
	va_list args;
	char msg[256];
	int len;
	va_start(args, fmt);
	len = mutt_vsnprintf(msg, sizeof(msg) - 1, fmt, args);
	va_end(args);
	msg[len] = 0x0;
	if (stderr_buf && stderr_len > 0) {
		snprintf(stderr_buf, stderr_len, "%s", msg);
	} else {
		_err("%s", msg);
	}
	return FAIL();
}

static int api_write_hex_to_buf(const uint8_t *in, size_t len,
								char *stdout_buf, size_t stdout_len,
								char *stderr_buf, size_t stderr_len,
								const char *caller) {
	const size_t needed = (len << 1) + 1;
	if (!stdout_buf || stdout_len == 0) {
		return api_write_error(stderr_buf, stderr_len,
							   "%s :: missing output buffer", caller);
	}
	if (needed > stdout_len) {
		stdout_buf[0] = 0x0;
		return api_write_error(stderr_buf, stderr_len,
							   "%s :: output buffer too small", caller);
	}
	buf2hex(stdout_buf, (const char *)in, len);
	stdout_buf[len << 1] = 0x0;
	if (stderr_buf && stderr_len > 0) {
		stderr_buf[0] = 0x0;
	}
	return OK();
}

static int api_write_text_to_buf(const char *text,
								 char *stdout_buf, size_t stdout_len,
								 char *stderr_buf, size_t stderr_len,
								 const char *caller) {
	size_t needed;
	if (!text) {
		return api_write_error(stderr_buf, stderr_len,
							   "%s :: missing output value", caller);
	}
	needed = strlen(text) + 1;
	if (!stdout_buf || stdout_len == 0) {
		return api_write_error(stderr_buf, stderr_len,
							   "%s :: missing output buffer", caller);
	}
	if (needed > stdout_len) {
		stdout_buf[0] = 0x0;
		return api_write_error(stderr_buf, stderr_len,
							   "%s :: output buffer too small", caller);
	}
	memcpy(stdout_buf, text, needed);
	if (stderr_buf && stderr_len > 0) {
		stderr_buf[0] = 0x0;
	}
	return OK();
}

static char* hex2buf_alloc(const char *name, const char *hex, size_t *size) {
	const size_t hexlen = strlen(hex) >>1;
	char *out = NULL;
	if(*size>0 && *size!=hexlen) {
		_err("api_sign %s :: wrong size, found %lu instead of %lu",name,(unsigned long)hexlen,(unsigned long)*size);
		return NULL;
	}
	out = malloc(hexlen);
	if(!out) {
		_err("api_sign %s :: cannot allocate %lu bytes",name,(unsigned long)hexlen);
		return NULL;
	}
	if(hex2buf(out,hex) < 0) {
		free(out);
		_err("api_sign %s :: cannot do hex2buf %s",name,hex);
		return NULL;
	};
	if(*size<=0) *size = hexlen;
	return(out);
}

static int api_is_valid_hex(const char *hex, const char *label,
							char *stderr_buf, size_t stderr_len,
							const char *caller) {
	size_t i;
	if (!hex || !hex[0]) {
		return api_write_error(stderr_buf, stderr_len,
							   "%s :: missing %s", caller, label);
	}
	const size_t len = strlen(hex);
	if (len & 1) {
		return api_write_error(stderr_buf, stderr_len,
							   "%s :: %s has odd hex length", caller, label);
	}
	for (i = 0; i < len; i++) {
		char c = hex[i];
		if (!((c >= '0' && c <= '9') ||
			  (c >= 'a' && c <= 'f') ||
			  (c >= 'A' && c <= 'F'))) {
			return api_write_error(stderr_buf, stderr_len,
								   "%s :: %s is not valid hex", caller, label);
		}
	}
	return 0;
}

static int api_run_sign_script(const char *script,
							   char *stdout_buf, size_t stdout_len,
							   char *stderr_buf, size_t stderr_len) {
	if (stderr_buf && stderr_len > 0) {
		stderr_buf[0] = 0x0;
	}
	return zenroom_exec_tobuf(script, NULL, "{}", NULL, NULL, NULL,
							  stdout_buf, stdout_len, stderr_buf, stderr_len);
}

static int api_sign_print_result(int res,
								 const char *stdout_buf,
								 const char *stderr_buf) {
	if (res == OK()) {
		if (stdout_buf[0]) {
			_out("%s", stdout_buf);
		}
	} else {
		if (stderr_buf && stderr_buf[0]) {
			_err("%s", stderr_buf);
		}
	}
	return res;
}

// ---- p256 (P-256 ECDSA) via Lua VM ----

static int api_sign_keygen_p256_tobuf(const char *seed_hex,
									  char *stdout_buf, size_t stdout_len,
									  char *stderr_buf, size_t stderr_len) {
	char script[256];
	if (seed_hex) {
		snprintf(script, sizeof(script),
				 "local P256 = require'es256'\n"
				 "local sk = P256.keygen()\n"
				 "print(sk:hex())");
	} else {
		snprintf(script, sizeof(script),
				 "local P256 = require'es256'\n"
				 "local sk = P256.keygen()\n"
				 "print(sk:hex())");
	}
	return api_run_sign_script(script, stdout_buf, stdout_len,
							   stderr_buf, stderr_len);
}

static int api_sign_pubgen_p256_tobuf(const char *key_hex,
									  char *stdout_buf, size_t stdout_len,
									  char *stderr_buf, size_t stderr_len) {
	char script[320];
	if (api_is_valid_hex(key_hex, "key", stderr_buf, stderr_len, __func__)) {
		return FAIL();
	}
	snprintf(script, sizeof(script),
			 "local P256 = require'es256'\n"
			 "local sk = O.from_hex('%s')\n"
			 "local pk = P256.pubgen(sk)\n"
			 "print(pk:hex())", key_hex);
	return api_run_sign_script(script, stdout_buf, stdout_len,
							   stderr_buf, stderr_len);
}

static int api_sign_create_p256_tobuf(const char *key_hex, const char *msg_hex,
									  char *stdout_buf, size_t stdout_len,
									  char *stderr_buf, size_t stderr_len) {
	char script[640];
	if (api_is_valid_hex(key_hex, "key", stderr_buf, stderr_len, __func__)) {
		return FAIL();
	}
	if (api_is_valid_hex(msg_hex, "msg", stderr_buf, stderr_len, __func__)) {
		return FAIL();
	}
	snprintf(script, sizeof(script),
			 "local P256 = require'es256'\n"
			 "local sk = O.from_hex('%s')\n"
			 "local msg = O.from_hex('%s')\n"
			 "local sig = P256.sign(sk, msg)\n"
			 "print(sig:hex())", key_hex, msg_hex);
	return api_run_sign_script(script, stdout_buf, stdout_len,
							   stderr_buf, stderr_len);
}

static int api_sign_verify_p256_tobuf(const char *pk_hex, const char *msg_hex,
									  const char *sig_hex,
									  char *stdout_buf, size_t stdout_len,
									  char *stderr_buf, size_t stderr_len) {
	char script[1024];
	if (api_is_valid_hex(pk_hex, "pk", stderr_buf, stderr_len, __func__)) {
		return FAIL();
	}
	if (api_is_valid_hex(msg_hex, "msg", stderr_buf, stderr_len, __func__)) {
		return FAIL();
	}
	if (api_is_valid_hex(sig_hex, "sig", stderr_buf, stderr_len, __func__)) {
		return FAIL();
	}
	snprintf(script, sizeof(script),
			 "local P256 = require'es256'\n"
			 "local pk = O.from_hex('%s')\n"
			 "local msg = O.from_hex('%s')\n"
			 "local sig = O.from_hex('%s')\n"
			 "local ok = P256.verify(pk, msg, sig)\n"
			 "print(ok and '1' or '0')", pk_hex, msg_hex, sig_hex);
	return api_run_sign_script(script, stdout_buf, stdout_len,
							   stderr_buf, stderr_len);
}

// ---- mldsa44 (ML-DSA-44 FIPS 204) via Lua VM ----

static int api_sign_keygen_mldsa44_tobuf(const char *seed_hex,
										 char *stdout_buf, size_t stdout_len,
										 char *stderr_buf, size_t stderr_len) {
	char script[512];
	if (seed_hex) {
		if (api_is_valid_hex(seed_hex, "rngseed", stderr_buf, stderr_len,
							 __func__)) {
			return FAIL();
		}
		snprintf(script, sizeof(script),
				 "local QP = require'qp'\n"
				 "local kp = QP.mldsa44_keypair(O.from_hex('%s'))\n"
				 "print(kp.private:hex())", seed_hex);
	} else {
		snprintf(script, sizeof(script),
				 "local QP = require'qp'\n"
				 "local kp = QP.mldsa44_keypair()\n"
				 "print(kp.private:hex())");
	}
	return api_run_sign_script(script, stdout_buf, stdout_len,
							   stderr_buf, stderr_len);
}

static int api_sign_pubgen_mldsa44_tobuf(const char *key_hex,
										 char *stdout_buf, size_t stdout_len,
										 char *stderr_buf, size_t stderr_len) {
	char script[8000];
	if (api_is_valid_hex(key_hex, "key", stderr_buf, stderr_len, __func__)) {
		return FAIL();
	}
	snprintf(script, sizeof(script),
			 "local QP = require'qp'\n"
			 "local sk = O.from_hex('%s')\n"
			 "local pk = QP.mldsa44_pubgen(sk)\n"
			 "print(pk:hex())", key_hex);
	return api_run_sign_script(script, stdout_buf, stdout_len,
							   stderr_buf, stderr_len);
}

static int api_sign_create_mldsa44_tobuf(const char *key_hex,
										 const char *msg_hex,
										 char *stdout_buf, size_t stdout_len,
										 char *stderr_buf, size_t stderr_len) {
	char script[12000];
	if (api_is_valid_hex(key_hex, "key", stderr_buf, stderr_len, __func__)) {
		return FAIL();
	}
	if (api_is_valid_hex(msg_hex, "msg", stderr_buf, stderr_len, __func__)) {
		return FAIL();
	}
	snprintf(script, sizeof(script),
			 "local QP = require'qp'\n"
			 "local sk = O.from_hex('%s')\n"
			 "local msg = O.from_hex('%s')\n"
			 "local sig = QP.mldsa44_signature(sk, msg)\n"
			 "print(sig:hex())", key_hex, msg_hex);
	return api_run_sign_script(script, stdout_buf, stdout_len,
							   stderr_buf, stderr_len);
}

static int api_sign_verify_mldsa44_tobuf(const char *pk_hex, const char *msg_hex,
										 const char *sig_hex,
										 char *stdout_buf, size_t stdout_len,
										 char *stderr_buf, size_t stderr_len) {
	char script[22000];
	if (api_is_valid_hex(pk_hex, "pk", stderr_buf, stderr_len, __func__)) {
		return FAIL();
	}
	if (api_is_valid_hex(msg_hex, "msg", stderr_buf, stderr_len, __func__)) {
		return FAIL();
	}
	if (api_is_valid_hex(sig_hex, "sig", stderr_buf, stderr_len, __func__)) {
		return FAIL();
	}
	snprintf(script, sizeof(script),
			 "local QP = require'qp'\n"
			 "local pk = O.from_hex('%s')\n"
			 "local msg = O.from_hex('%s')\n"
			 "local sig = O.from_hex('%s')\n"
			 "local ok = QP.mldsa44_verify(pk, sig, msg)\n"
			 "print(ok and '1' or '0')", pk_hex, msg_hex, sig_hex);
	return api_run_sign_script(script, stdout_buf, stdout_len,
							   stderr_buf, stderr_len);
}

// ---- Public API ----

int zenroom_sign_keygen(const char *algo, const char *rngseed) {
	char stdout_buf[MAX_KEY_BUF] = {0};
	char stderr_buf[512] = {0};
	int res = zenroom_sign_keygen_tobuf(algo, rngseed,
										stdout_buf, sizeof(stdout_buf),
										stderr_buf, sizeof(stderr_buf));
	return api_sign_print_result(res, stdout_buf, stderr_buf);
}

int zenroom_sign_keygen_tobuf(const char *algo, const char *rngseed,
							  char *stdout_buf, size_t stdout_len,
							  char *stderr_buf, size_t stderr_len) {
	if(!algo) {
		if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
		return api_write_error(stderr_buf, stderr_len, "%s :: missing arg: algo", __func__);
	}
	if(strcmp(algo,"eddsa")==0) {
		register const size_t sksize = sizeof(ed25519_secret_key);
		uint8_t *sk = malloc(sksize);
		csprng *rng = NULL;
		register size_t i;
		int res;
		if(!sk) {
			if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
			return api_write_error(stderr_buf, stderr_len,
								   "%s :: cannot allocate output buffer", __func__);
		}
		rng = api_rng_alloc(rngseed);
		if(!rng) {
			free(sk);
			if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
			return api_write_error(stderr_buf, stderr_len,
								   "%s :: error initializing the random generator", __func__);
		}
		for(i=0; i < sksize; i++) {
			sk[i] = RAND_byte(rng);
		}
		res = api_write_hex_to_buf(sk, sksize, stdout_buf, stdout_len,
								   stderr_buf, stderr_len, __func__);
		free(sk);
		free(rng);
		return res;
	}
	if(strcmp(algo,"p256")==0) {
		return api_sign_keygen_p256_tobuf(rngseed, stdout_buf, stdout_len,
										  stderr_buf, stderr_len);
	}
	if(strcmp(algo,"mldsa44")==0) {
		return api_sign_keygen_mldsa44_tobuf(rngseed, stdout_buf, stdout_len,
											 stderr_buf, stderr_len);
	}
	if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
	return api_write_error(stderr_buf, stderr_len,
						   "%s :: unknown sign algo: %s", __func__, algo);
}

int zenroom_sign_pubgen(const char *algo, const char *key) {
	char stdout_buf[MAX_KEY_BUF] = {0};
	char stderr_buf[512] = {0};
	int res = zenroom_sign_pubgen_tobuf(algo, key,
										stdout_buf, sizeof(stdout_buf),
										stderr_buf, sizeof(stderr_buf));
	return api_sign_print_result(res, stdout_buf, stderr_buf);
}

int zenroom_sign_pubgen_tobuf(const char *algo, const char *key,
							  char *stdout_buf, size_t stdout_len,
							  char *stderr_buf, size_t stderr_len) {
	unsigned char *pk = NULL;
	size_t outlen;
	int res;
	if(!algo) {
		if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
		return api_write_error(stderr_buf, stderr_len, "%s :: missing arg: algo", __func__);
	}
	if(!key) {
		if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
		return api_write_error(stderr_buf, stderr_len, "%s :: missing arg: key", __func__);
	}
	if(strcmp(algo,"eddsa")==0) {
		size_t sksize = sizeof(ed25519_secret_key);
		char *sk = hex2buf_alloc("ed25519_secret_key",key,&sksize);
		if(!sk) {
			if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
			return api_write_error(stderr_buf, stderr_len, "%s :: invalid arg", __func__);
		}
		outlen = sizeof(ed25519_public_key);
		pk = malloc(outlen);
		if(!pk) {
			free(sk);
			if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
			return api_write_error(stderr_buf, stderr_len, "%s :: cannot allocate pk", __func__);
		}
		ed25519_publickey((const unsigned char*)sk,pk);
		free(sk);
		res = api_write_hex_to_buf(pk, outlen, stdout_buf, stdout_len,
								   stderr_buf, stderr_len, __func__);
		free(pk);
		return res;
	}
	if(strcmp(algo,"p256")==0) {
		return api_sign_pubgen_p256_tobuf(key, stdout_buf, stdout_len,
										  stderr_buf, stderr_len);
	}
	if(strcmp(algo,"mldsa44")==0) {
		return api_sign_pubgen_mldsa44_tobuf(key, stdout_buf, stdout_len,
											 stderr_buf, stderr_len);
	}
	if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
	return api_write_error(stderr_buf, stderr_len,
						   "%s :: unknown sign algo: %s", __func__, algo);
}

int zenroom_sign_create(const char *algo, const char *key, const char *msg) {
	char stdout_buf[MAX_KEY_BUF] = {0};
	char stderr_buf[512] = {0};
	int res = zenroom_sign_create_tobuf(algo, key, msg,
										stdout_buf, sizeof(stdout_buf),
										stderr_buf, sizeof(stderr_buf));
	return api_sign_print_result(res, stdout_buf, stderr_buf);
}

int zenroom_sign_create_tobuf(const char *algo, const char *key, const char *msg,
							  char *stdout_buf, size_t stdout_len,
							  char *stderr_buf, size_t stderr_len) {
	size_t outlen;
	unsigned char *sig = NULL;
	if(!algo) {
		if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
		return api_write_error(stderr_buf, stderr_len, "%s :: missing arg: algo", __func__);
	}
	if(!key) {
		if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
		return api_write_error(stderr_buf, stderr_len, "%s :: missing arg: key", __func__);
	}
	if(!msg) {
		if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
		return api_write_error(stderr_buf, stderr_len, "%s :: missing arg: msg", __func__);
	}
	if(strcmp(algo,"eddsa")==0) {
		ed25519_public_key pk;
		size_t keysize = sizeof(ed25519_secret_key);
		char *sk = hex2buf_alloc("ed25519_secret_key",key,&keysize);
		size_t msglen = 0;
		char *msg_b = NULL;
		int res;
		if(!sk) {
			if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
			return api_write_error(stderr_buf, stderr_len, "%s :: invalid arg: sk", __func__);
		}
		ed25519_publickey((const unsigned char*)sk, pk);
		msg_b = hex2buf_alloc("message",msg,&msglen);
		if(!msg_b) {
			free(sk);
			if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
			return api_write_error(stderr_buf, stderr_len, "%s :: invalid arg: msg", __func__);
		}
		outlen = sizeof(ed25519_signature);
		sig = malloc(outlen);
		if(!sig) {
			free(sk);
			free(msg_b);
			if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
			return api_write_error(stderr_buf, stderr_len,
								   "%s :: cannot allocate signature buffer", __func__);
		}
		ed25519_sign((unsigned char*)msg_b, msglen,
					 (const unsigned char*)sk, pk, sig);
		free(sk);
		free(msg_b);
		res = api_write_hex_to_buf(sig, outlen, stdout_buf, stdout_len,
								   stderr_buf, stderr_len, __func__);
		free(sig);
		return res;
	}
	if(strcmp(algo,"p256")==0) {
		return api_sign_create_p256_tobuf(key, msg, stdout_buf, stdout_len,
										  stderr_buf, stderr_len);
	}
	if(strcmp(algo,"mldsa44")==0) {
		return api_sign_create_mldsa44_tobuf(key, msg, stdout_buf, stdout_len,
											 stderr_buf, stderr_len);
	}
	if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
	return api_write_error(stderr_buf, stderr_len,
						   "%s :: unknown sign algo: %s", __func__, algo);
}

int zenroom_sign_verify(const char *algo, const char *pk, const char *msg, const char *sig) {
	char stdout_buf[4] = {0};
	char stderr_buf[512] = {0};
	int res = zenroom_sign_verify_tobuf(algo, pk, msg, sig,
										stdout_buf, sizeof(stdout_buf),
										stderr_buf, sizeof(stderr_buf));
	return api_sign_print_result(res, stdout_buf, stderr_buf);
}

int zenroom_sign_verify_tobuf(const char *algo, const char *pk, const char *msg, const char *sig,
							  char *stdout_buf, size_t stdout_len,
							  char *stderr_buf, size_t stderr_len) {
	bool res = false;
	if(!algo) {
		if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
		return api_write_error(stderr_buf, stderr_len, "%s :: missing argument: algo", __func__);
	}
	if(!pk) {
		if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
		return api_write_error(stderr_buf, stderr_len, "%s :: missing argument: pk", __func__);
	}
	if(!msg) {
		if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
		return api_write_error(stderr_buf, stderr_len, "%s :: missing argument: msg", __func__);
	}
	if(!sig) {
		if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
		return api_write_error(stderr_buf, stderr_len, "%s :: missing argument: sig", __func__);
	}
	if(strcmp(algo,"eddsa")==0) {
		size_t pksize = sizeof(ed25519_public_key);
		const char *pk_b = hex2buf_alloc("ed25519_public_key",pk,&pksize);
		size_t sigsize = sizeof(ed25519_signature);
		const char *sig_b = NULL;
		size_t msglen = 0;
		const char *msg_b = NULL;
		if(!pk_b) {
			if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
			return api_write_error(stderr_buf, stderr_len, "%s :: invalid arg pk", __func__);
		}
		sig_b = hex2buf_alloc("ed25519_signature",sig,&sigsize);
		if(!sig_b) {
			free((void *)pk_b);
			if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
			return api_write_error(stderr_buf, stderr_len, "%s :: invalid arg sig", __func__);
		}
		msg_b = hex2buf_alloc("message",msg,&msglen);
		if(!msg_b) {
			free((void *)pk_b);
			free((void *)sig_b);
			if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
			return api_write_error(stderr_buf, stderr_len, "%s :: invalid arg: msg", __func__);
		}
		res = 0==ed25519_sign_open((const unsigned char*)msg_b, msglen,
								   (const unsigned char*)pk_b,
								   (const unsigned char*)sig_b);
		free((void *)pk_b);
		free((void *)sig_b);
		free((void *)msg_b);
		return api_write_text_to_buf(res ? "1" : "0",
									 stdout_buf, stdout_len,
									 stderr_buf, stderr_len, __func__);
	}
	if(strcmp(algo,"p256")==0) {
		return api_sign_verify_p256_tobuf(pk, msg, sig,
										  stdout_buf, stdout_len,
										  stderr_buf, stderr_len);
	}
	if(strcmp(algo,"mldsa44")==0) {
		return api_sign_verify_mldsa44_tobuf(pk, msg, sig,
											 stdout_buf, stdout_len,
											 stderr_buf, stderr_len);
	}
	if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
	return api_write_error(stderr_buf, stderr_len,
						   "%s :: unknown sign algo: %s", __func__, algo);
}
