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

#define RECIPE_MAX_SIZE 8192

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

static int api_recipe_read_file(const char *name,
								char *script, size_t script_size) {
	char path[256];
	FILE *fp;
	size_t n;
#ifdef __EMSCRIPTEN__
	snprintf(path, sizeof(path), "/api_recipes/%s.lua", name);
#else
	snprintf(path, sizeof(path), "src/api_recipes/%s.lua", name);
#endif
	fp = fopen(path, "r");
	if (!fp) {
		return -1;
	}
	n = fread(script, 1, script_size - 1, fp);
	fclose(fp);
	if (n == 0) {
		return -1;
	}
	script[n] = 0x0;
	return 0;
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

int zenroom_recipe_exec_tobuf(const char *name,
							  const char *conf, const char *keys,
							  const char *data, const char *extra,
							  const char *context,
							  char *stdout_buf, size_t stdout_len,
							  char *stderr_buf, size_t stderr_len) {
	char script[RECIPE_MAX_SIZE];

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

	if (api_recipe_read_file(name, script, sizeof(script)) != 0) {
		if (stderr_buf && stderr_len > 0) {
			snprintf(stderr_buf, stderr_len, "%s :: recipe not found: %s", __func__, name);
		}
		if (stdout_buf && stdout_len > 0) {
			stdout_buf[0] = 0x0;
		}
		return FAIL();
	}

	return zenroom_exec_tobuf(script, conf, keys, data, extra, context,
							  stdout_buf, stdout_len, stderr_buf, stderr_len);
}
