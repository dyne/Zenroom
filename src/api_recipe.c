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

#include <stdio.h>
#include <string.h>
#include <strings.h>

#if defined(_WIN32)
#include <malloc.h>
#else
#include <stdlib.h>
#endif

#include <zen_error.h>
#include <zenroom.h>

static int api_recipe_name_is_safe(const char *name) {
	size_t i;
	if (!name || !name[0]) {
		return 0;
	}
	for (i = 0; name[i] != 0x0; i++) {
		const char c = name[i];
		if (!((c >= 'a' && c <= 'z') ||
			  (c >= 'A' && c <= 'Z') ||
			  (c >= '0' && c <= '9') ||
			  c == '_' || c == '.')) {
			return 0;
		}
	}
	return 1;
}

int zenroom_recipe_exec(const char *name,
						const char *conf, const char *keys,
						const char *data, const char *extra,
						const char *context) {
	char stdout_buf[8192] = {0};
	char stderr_buf[2048] = {0};
	int res = zenroom_recipe_exec_tobuf(name, conf, keys, data, extra, context,
										stdout_buf, sizeof(stdout_buf),
										stderr_buf, sizeof(stderr_buf));
	if (res == OK()) {
		if (stdout_buf[0]) {
			_out("%s", stdout_buf);
		}
	} else {
		if (stderr_buf[0]) {
			_err("%s", stderr_buf);
		}
	}
	return res;
}

static const char *recipe_merkle_root_script =
	"local J = require'json'\n"
	"local data = DATA and J.raw_decode(DATA) or {}\n"
	"local MT = require'crypto_merkle'\n"
	"local leaves = {}\n"
	"for _, h in ipairs(data.leaves or {}) do table.insert(leaves, O.from_hex(h)) end\n"
	"local root = MT.create_merkle_root(leaves, data.hash or 'sha256')\n"
	"local out = J.raw_encode({root = root:hex()})\n"
	"print(out)\n";

static const char *recipe_merkle_verify_proof_script =
	"local J = require'json'\n"
	"local data = DATA and J.raw_decode(DATA) or {}\n"
	"local MT = require'crypto_merkle'\n"
	"local proof = {}\n"
	"for _, p in ipairs(data.proof or {}) do table.insert(proof, O.from_hex(p)) end\n"
	"local ok = MT.verify_proof(proof, data.position or 0, O.from_hex(data.root or ''), data.leaf_count or 0, data.hash or 'sha256')\n"
	"local out = J.raw_encode({valid = ok})\n"
	"print(out)\n";

int zenroom_recipe_exec_tobuf(const char *name,
							  const char *conf, const char *keys,
							  const char *data, const char *extra,
							  const char *context,
							  char *stdout_buf, size_t stdout_len,
							  char *stderr_buf, size_t stderr_len) {
	const char *script = NULL;

	if (!name) {
		if (stderr_buf && stderr_len > 0) {
			snprintf(stderr_buf, stderr_len, "%s :: missing arg: name", __func__);
		}
		if (stdout_buf && stdout_len > 0) {
			stdout_buf[0] = 0x0;
		}
		return FAIL();
	}
	if (!api_recipe_name_is_safe(name)) {
		if (stderr_buf && stderr_len > 0) {
			snprintf(stderr_buf, stderr_len, "%s :: invalid recipe name: %s", __func__, name);
		}
		if (stdout_buf && stdout_len > 0) {
			stdout_buf[0] = 0x0;
		}
		return FAIL();
	}

	if (!strcmp(name, "merkle.root")) {
		script = recipe_merkle_root_script;
	} else if (!strcmp(name, "merkle.verify_proof")) {
		script = recipe_merkle_verify_proof_script;
	} else {
		if (stderr_buf && stderr_len > 0) {
			snprintf(stderr_buf, stderr_len, "%s :: unknown recipe: %s", __func__, name);
		}
		if (stdout_buf && stdout_len > 0) {
			stdout_buf[0] = 0x0;
		}
		return FAIL();
	}

	return zenroom_exec_tobuf(script, conf, keys, data, extra, context,
							  stdout_buf, stdout_len, stderr_buf, stderr_len);
}
