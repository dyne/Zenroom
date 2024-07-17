/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2024 Dyne.org foundation
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
#include <unistd.h>
#include <strings.h>
#include <inttypes.h>
#include <zen_error.h>
#include <encoding.h> // zenroom
#include <mutt_sprintf.h>

// #include <zen_memory.h>
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
		_err( "%s : cannot allocate the random generator");
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

#define MAX_ERRMSG 256 // maximum length of an error message line

static int debugf(const char *fmt, ...) {
	char msg[MAX_ERRMSG+4];
	int len, res;
	va_list argp, argp_copy;
	va_start(argp, fmt);
	va_copy(argp_copy, argp);
	len = mutt_vsnprintf(msg, MAX_ERRMSG, fmt, argp);
	msg[len] = '\n';
	msg[len+1] = 0x0;
	res = write(3,"XXX: ",5);
	res = write(3,msg,len+1);
	(void)res; // avoid warnings
	va_end(argp);
	va_end(argp_copy);
	return(len);
}

static int print_buf_hex(const uint8_t *in, const size_t len) {
	char *out = malloc((len<<1)+2);
	if(!out) {
		_err("%s :: cannot allocate output buffer",__func__);
		return -1;
	}
	buf2hex(out, (const char*)in, len);
	out[(len<<1)+1] = 0x0;
	_out("%s",out);
	free(out);
	return(1);
}

int zenroom_sign_keygen(const char *algo, const char *rngseed) {
	if(!algo) { _err("%s :: missing argument: algo",__func__); return FAIL(); }
	if(strcmp(algo,"eddsa")==0) {
		register const size_t sksize = sizeof(ed25519_secret_key);
		uint8_t *sk = malloc(sksize);
		if(!sk) {
			_err("%s :: cannot allocate output buffer",__func__);
			return FAIL();
		}
		csprng *rng = api_rng_alloc(rngseed);
		if(!rng) {
			_err("%s :: error initializing the random generator",__func__);
			return FAIL();
		}
		register size_t i;
		for(i=0; i < sksize; i++)
			sk[i] = RAND_byte(rng);
		if( print_buf_hex(sk, sksize) < 1 ) {
			_err("%s :: cannot print hex result",__func__);
			free(sk); free(rng);
			return FAIL();
		}
		free(sk);
		free(rng);
	} else {
		_err("%s :: unknown sign algo: %s",__func__,algo);
		return FAIL();
	}
	return OK();
}


int zenroom_sign_pubgen(const char *algo, const char *key) {
	if(!algo) { _err("%s :: missing argument: algo",__func__); return FAIL(); }
	if(!key)  { _err("%s :: missing argument: key", __func__); return FAIL(); }
	unsigned char *pk = NULL;
	if(strcmp(algo,"eddsa")==0) {
		register const size_t sksize = sizeof(ed25519_secret_key);
		size_t keylen= strlen(key) /2;
		if(keylen!=sksize) {
			_err("%s :: wrong key size: %u",__func__,keylen);
			return FAIL(); }
		char *sk = malloc(sksize);
		if(!sk) { _err("%s :: cannot allocate sk",__func__); return FAIL(); }
		hex2buf(sk,key); // TODO: more safety?
		pk = malloc(sizeof(ed25519_public_key));
		if(!pk) { _err("%s :: cannot allocate pk",__func__); return FAIL(); }
		ed25519_publickey((const unsigned char*)sk,pk);
		free(sk);
	} else { _err("%s :: unknown sign algo: %s",__func__,algo); return FAIL(); }
	if(!pk) { _err("%s :: error in pk",__func__); return FAIL(); }
	print_buf_hex(pk,sizeof(ed25519_public_key));
	free(pk);
	return OK();
}
