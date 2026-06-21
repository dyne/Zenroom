/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2022-2026 Dyne.org foundation
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

// external API function for streaming hash
#include <stdio.h>
#include <string.h>
#include <strings.h>

#if defined(_WIN32)
#include <malloc.h>
#else
#include <stdlib.h>
#endif

#include <amcl.h>
#include <ecdh_support.h> // AMCL

#include <zen_error.h>
#include <encoding.h> // zenroom
#include <zenroom.h>

// first byte is type
#define ZEN_SHA512 '4'
#define ZEN_SHA256 '2'

int print_ctx_hex(char prefix, void *sh, int len) {
	char *hash_ctx = malloc((len << 1) + 2);
	if (!hash_ctx) {
		_err("%s :: cannot allocate hash_ctx", __func__);
		return 1;
	}
	hash_ctx[0] = prefix;
	buf2hex(hash_ctx + 1, (const char *)sh, (const size_t)len);
	hash_ctx[(len << 1) + 1] = 0x0; // null terminated string
	_out("%s", hash_ctx);
	free(hash_ctx);
	return 0;
}

static int api_hash_type_is_safe(const char *hash_type) {
	size_t i;
	if (!hash_type || !hash_type[0]) {
		return 0;
	}
	for (i = 0; hash_type[i] != 0x0; i++) {
		const char c = hash_type[i];
		if (!((c >= 'a' && c <= 'z') ||
			  (c >= 'A' && c <= 'Z') ||
			  (c >= '0' && c <= '9') ||
			  c == '_')) {
			return 0;
		}
	}
	return 1;
}

static int api_run_hash_script(const char *script,
							   const char *data,
							   const char *keys,
							   char *stdout_buf, size_t stdout_len,
							   char *stderr_buf, size_t stderr_len) {
	if (stderr_buf && stderr_len > 0) {
		stderr_buf[0] = 0x0;
	}
	return zenroom_exec_tobuf(script, NULL, keys, data, NULL, NULL,
							  stdout_buf, stdout_len, stderr_buf, stderr_len);
}

/**
   Hash a hex-encoded message using the named algorithm and write the hex digest
   into the caller-provided output buffer.
 */
int zenroom_hash_hex_tobuf(const char *hash_type, const char *msg_hex,
						   char *stdout_buf, size_t stdout_len,
						   char *stderr_buf, size_t stderr_len) {
	char script[160];
	if (!hash_type) {
		if (stderr_buf && stderr_len > 0) {
			snprintf(stderr_buf, stderr_len, "%s :: missing arg: hash_type", __func__);
		}
		if (stdout_buf && stdout_len > 0) {
			stdout_buf[0] = 0x0;
		}
		return FAIL();
	}
	if (!msg_hex) {
		if (stderr_buf && stderr_len > 0) {
			snprintf(stderr_buf, stderr_len, "%s :: missing arg: msg_hex", __func__);
		}
		if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
		return FAIL();
	}
	if (!api_hash_type_is_safe(hash_type)) {
		if (stderr_buf && stderr_len > 0) {
			snprintf(stderr_buf, stderr_len, "%s :: invalid hash type: %s", __func__, hash_type);
		}
		if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
		return FAIL();
	}
	snprintf(script, sizeof(script),
			 "local h = HASH.new('%s')\n"
			 "print(h:process(O.from_hex(DATA)):hex())",
			 hash_type);
	return api_run_hash_script(script, msg_hex, NULL,
							   stdout_buf, stdout_len, stderr_buf, stderr_len);
}

int zenroom_hash_hex(const char *hash_type, const char *msg_hex) {
	char stdout_buf[1024] = {0};
	char stderr_buf[512] = {0};
	int res = zenroom_hash_hex_tobuf(hash_type, msg_hex,
									 stdout_buf, sizeof(stdout_buf),
									 stderr_buf, sizeof(stderr_buf));
	if (res == OK()) {
		_out("%s", stdout_buf);
	} else if (stderr_buf[0] != 0x0) {
		_err("%s", stderr_buf);
	}
	return res;
}

/**
   Derive a hex-encoded key using PBKDF2 with the named hash algorithm.
 */
int zenroom_pbkdf2_hex_tobuf(const char *hash_type,
							 const char *password_hex,
							 const char *salt_hex,
							 int iterations,
							 int keylen,
							 char *stdout_buf, size_t stdout_len,
							 char *stderr_buf, size_t stderr_len) {
	char script[256];
	if (!hash_type) {
		if (stderr_buf && stderr_len > 0) {
			snprintf(stderr_buf, stderr_len, "%s :: missing arg: hash_type", __func__);
		}
		if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
		return FAIL();
	}
	if (!password_hex) {
		if (stderr_buf && stderr_len > 0) {
			snprintf(stderr_buf, stderr_len, "%s :: missing arg: password_hex", __func__);
		}
		if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
		return FAIL();
	}
	if (!salt_hex) {
		if (stderr_buf && stderr_len > 0) {
			snprintf(stderr_buf, stderr_len, "%s :: missing arg: salt_hex", __func__);
		}
		if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
		return FAIL();
	}
	if (iterations <= 0) {
		if (stderr_buf && stderr_len > 0) {
			snprintf(stderr_buf, stderr_len, "%s :: iterations must be positive", __func__);
		}
		if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
		return FAIL();
	}
	if (keylen <= 0) {
		if (stderr_buf && stderr_len > 0) {
			snprintf(stderr_buf, stderr_len, "%s :: keylen must be positive", __func__);
		}
		if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
		return FAIL();
	}
	if (!api_hash_type_is_safe(hash_type)) {
		if (stderr_buf && stderr_len > 0) {
			snprintf(stderr_buf, stderr_len, "%s :: invalid hash type: %s", __func__, hash_type);
		}
		if (stdout_buf && stdout_len > 0) stdout_buf[0] = 0x0;
		return FAIL();
	}
	snprintf(script, sizeof(script),
			 "local h = HASH.new('%s')\n"
			 "local out = h:pbkdf2(O.from_hex(DATA), {\n"
			 "  salt = O.from_hex(KEYS),\n"
			 "  iterations = %d,\n"
			 "  length = %d\n"
			 "})\n"
			 "print(out:hex())",
			 hash_type, iterations, keylen);
	return api_run_hash_script(script, password_hex, salt_hex,
							   stdout_buf, stdout_len, stderr_buf, stderr_len);
}

int zenroom_pbkdf2_hex(const char *hash_type,
					   const char *password_hex,
					   const char *salt_hex,
					   int iterations,
					   int keylen) {
	char stdout_buf[1024] = {0};
	char stderr_buf[512] = {0};
	int res = zenroom_pbkdf2_hex_tobuf(hash_type, password_hex, salt_hex,
									   iterations, keylen,
									   stdout_buf, sizeof(stdout_buf),
									   stderr_buf, sizeof(stderr_buf));
	if (res == OK()) {
		_out("%s", stdout_buf);
	} else if (stderr_buf[0] != 0x0) {
		_err("%s", stderr_buf);
	}
	return res;
}

// returns a fills hash_ctx, which must be pre-allocated externally
int zenroom_hash_init(const char *hash_type) {
	register char prefix = '0';
	// size tests
	register int len = 0;
	void *sh = NULL;
	if (strcasecmp(hash_type, "sha512") == 0) {
		prefix = ZEN_SHA512;
		len = sizeof(hash512); // amcl struct
		sh = calloc(len, 1);
		if (!sh) {
			_err("%s :: cannot allocate sh", __func__);
			return FAIL();
		}
		HASH512_init((hash512 *)sh); // amcl init
	} else if (strcasecmp(hash_type, "sha256") == 0) {
		prefix = ZEN_SHA256;
		len = sizeof(hash256);
		sh = calloc(len, 1);
		if (!sh) {
			_err("%s :: cannot allocate hash", __func__);
			return FAIL();
		}
		HASH256_init((hash256 *)sh); // amcl init
	} else {
		_err("%s :: invalid hash type: %s", __func__, hash_type);
		return FAIL();
	}
	if (print_ctx_hex(prefix, sh, len) == 1) {
		free(sh);
		return FAIL();
	};
	free(sh);
	return OK();
}

// returns hash_ctx updated
int zenroom_hash_update(const char *hash_ctx,
						const char *buffer, const int buffer_size) {
	char *failed_msg = NULL;
	register char prefix = hash_ctx[0];
	register int len, c;
	char *sh = NULL;
	int buffer_len = buffer_size >> 1;
	char *hex_buf = malloc(buffer_len);
	if (!hex_buf) {
		failed_msg = "cannot allocate hex_buf";
		goto end;
	}
	if (hex2buf(hex_buf, buffer) < 0) {
		failed_msg = "cannot do hex2buf for buffer";
		goto end;
	}
	if (prefix == ZEN_SHA512) {
		len = sizeof(hash512);
		sh = malloc(len);
		if (!sh) {
			failed_msg = "cannot allocate hash";
			goto end;
		}
		if (hex2buf(sh, hash_ctx + 1) < 0) {
			failed_msg = "cannot do hex2buf for hash_ctx";
			goto end;
		}
		for (c = 0; c < buffer_len; c++) {
			HASH512_process((hash512 *)sh, hex_buf[c]);
		}
	} else if (prefix == ZEN_SHA256) {
		len = sizeof(hash256);
		sh = malloc(len);
		if (!sh) {
			failed_msg = "cannot allocate hash";
			goto end;
		}
		if (hex2buf(sh, hash_ctx + 1) < 0) {
			failed_msg = "cannot do hex2buf for hash_ctx";
			goto end;
		}
		for (c = 0; c < buffer_len; c++) {
			HASH256_process((hash256 *)sh, hex_buf[c]);
		}
	} else {
		failed_msg = "invalid hash context prefix";
		goto end;
	}
	if (print_ctx_hex(prefix, sh, len) == 1) {
		failed_msg = "cannot print ctx as hex";
		goto end;
	};
end:
	if(hex_buf) free(hex_buf);
	if(sh) free(sh);
	if(failed_msg) {
		_err("%s :: %s", __func__, failed_msg);
		return FAIL();
	}
	return OK();
}

// returns the hash string base64 encoded
int zenroom_hash_final(const char *hash_ctx) {
	char *failed_msg = NULL;
	register char prefix = hash_ctx[0];
	register int len;
	octet tmp = {0};
	char *sh = NULL;
	char *hash_result = malloc(90);
	if (!hash_result) {
		failed_msg = "cannot allocate hash_result";
		goto end;
	}
	if (prefix == ZEN_SHA512) {
		tmp.len = 64;
		tmp.val = (char *)malloc(64);
		if (!tmp.val) {
			failed_msg = "cannot allocate tmp.val";
			goto end;
		}
		len = sizeof(hash512);
		sh = (char *)calloc(len, 1);
		if (!sh) {
			failed_msg = "cannot allocate sh";
			goto end;
		}
		if (hex2buf(sh, hash_ctx + 1) < 0) {
			failed_msg = "cannot do hex2buf for hash_ctx";
			goto end;
		};
		HASH512_hash((hash512 *)sh, tmp.val);
	} else if (prefix == ZEN_SHA256) {
		tmp.len = 32;
		tmp.val = (char *)malloc(32);
		if (!tmp.val) {
			failed_msg = "cannot allocate tmp.val";
			goto end;
		}
		len = sizeof(hash256);
		sh = (char *)calloc(len, 1);
		if (!sh) {
			failed_msg = "cannot allocate sh";
			goto end;
		}
		if (hex2buf(sh, hash_ctx + 1) < 0) {
			failed_msg = "cannot do hex2buf for hash_ctx";
			goto end;
		};
		HASH256_hash((hash256 *)sh, tmp.val);
	} else {
		failed_msg = "invalid hash context prefix";
		goto end;
	}
	OCT_tobase64(hash_result, &tmp);
	_out("%s", hash_result);
end:
	if (sh) free(sh);
	if (tmp.val) free(tmp.val);
	if (hash_result) free(hash_result);
	if (failed_msg) {
		_err("%s :: %s", __func__, failed_msg);
		return FAIL();
	}
	return OK();
}
