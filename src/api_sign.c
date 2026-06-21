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

// external API function for signatures
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
#include <encoding.h> // zenroom
#include <mutt_sprintf.h>

#include <ed25519.h>
#include <randombytes.h>

// RNG
#include <time.h>
#include <amcl.h>

// defined also in zenroom.h
#define RANDOM_SEED_LEN 64

// hexseed is an optional hex input sequence
// result is an opaque struct to be used with RAND_byte()
// it should be free'd before exiting
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
		// gather system random using randombytes()
		randombytes(tseed,RANDOM_SEED_LEN-4);
		// using time() from milagro
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

// allocate a binary buffer (pointer returned) from a hex value
// args:
// name is needed for correct debugging
// hex is the input hexadecimal to be converted in binary output
// size is a pointer to size_t value, if 0 then is filled with length
//   of result, else it indicates the desired size to be enforced on
//   input
// REMEMBER TO FREE THE OUTPUT AFTER USE
static char* hex2buf_alloc(const char *name, const char *hex, size_t *size) {
	// check that size is desired
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

int zenroom_sign_keygen(const char *algo, const char *rngseed) {
	char stdout_buf[(sizeof(ed25519_secret_key) << 1) + 1] = {0};
	char stderr_buf[256] = {0};
	int res = zenroom_sign_keygen_tobuf(algo, rngseed,
										stdout_buf, sizeof(stdout_buf),
										stderr_buf, sizeof(stderr_buf));
	if (res == OK()) {
		_out("%s", stdout_buf);
	} else if (stderr_buf[0] != 0x0) {
		_err("%s", stderr_buf);
	}
	return res;
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
	if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
	return api_write_error(stderr_buf, stderr_len,
						   "%s :: unknown sign algo: %s", __func__, algo);
}

int zenroom_sign_pubgen(const char *algo, const char *key) {
	char stdout_buf[(sizeof(ed25519_public_key) << 1) + 1] = {0};
	char stderr_buf[256] = {0};
	int res = zenroom_sign_pubgen_tobuf(algo, key,
										stdout_buf, sizeof(stdout_buf),
										stderr_buf, sizeof(stderr_buf));
	if (res == OK()) {
		_out("%s", stdout_buf);
	} else if (stderr_buf[0] != 0x0) {
		_err("%s", stderr_buf);
	}
	return res;
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
	if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
	return api_write_error(stderr_buf, stderr_len,
						   "%s :: unknown algo: %s", __func__, algo);
}

int zenroom_sign_create(const char *algo, const char *key, const char *msg) {
	char stdout_buf[(sizeof(ed25519_signature) << 1) + 1] = {0};
	char stderr_buf[256] = {0};
	int res = zenroom_sign_create_tobuf(algo, key, msg,
										stdout_buf, sizeof(stdout_buf),
										stderr_buf, sizeof(stderr_buf));
	if (res == OK()) {
		_out("%s", stdout_buf);
	} else if (stderr_buf[0] != 0x0) {
		_err("%s", stderr_buf);
	}
	return res;
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
	if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
	return api_write_error(stderr_buf, stderr_len,
						   "%s :: unknown sign algo: %s", __func__, algo);
}

int zenroom_sign_verify(const char *algo, const char *pk, const char *msg, const char *sig) {
	char stdout_buf[4] = {0};
	char stderr_buf[256] = {0};
	int res = zenroom_sign_verify_tobuf(algo, pk, msg, sig,
										stdout_buf, sizeof(stdout_buf),
										stderr_buf, sizeof(stderr_buf));
	if (res == OK()) {
		_out("%s", stdout_buf);
	} else if (stderr_buf[0] != 0x0) {
		_err("%s", stderr_buf);
	}
	return res;
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
	if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
	return api_write_error(stderr_buf, stderr_len,
						   "%s :: unknown sign algo: %s", __func__, algo);
}
