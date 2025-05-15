/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2022-2025 Dyne.org foundation
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

// first byte is type
#define ZEN_SHA512 '4'
#define ZEN_SHA256 '2'

int print_ctx_hex(char prefix, void *sh, int len) {
	char *hash_ctx = malloc((len << 1) + 2);
	if (!hash_ctx) {
		_err("%s :: cannot allocate hash_ctx", __func__);
		return FAIL();
	}
	hash_ctx[0] = prefix;
	buf2hex(hash_ctx + 1, (const char *)sh, (const size_t)len);
	hash_ctx[(len << 1) + 1] = 0x0; // null terminated string
	_out("%s", hash_ctx);
	free(hash_ctx);
	return OK();
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
	}
	else if (strcasecmp(hash_type, "sha256") == 0) {
		prefix = ZEN_SHA256;
		len = sizeof(hash256);
		sh = calloc(len, 1);
		if (!sh) {
			_err("%s :: cannot allocate hash", __func__);
			return FAIL();
		}
		HASH256_init((hash256 *)sh); // amcl init
	}
	else {
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
	}
	else if (prefix == ZEN_SHA256) {
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
	}
	else {
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
	char *hash_result = malloc(90);
	if (!hash_result) {
		failed_msg = "cannot allocate hash_result";
		goto end;
	}
	octet tmp;
	char *sh;
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
	}
	else if (prefix == ZEN_SHA256) {
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
	}
	else {
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
