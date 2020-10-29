/*  Zenroom (DECODE project)
 *
 *  (c) Copyright 2020 Dyne.org foundation
 *  designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This source code is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Public License as published
 * by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 *
 * This source code is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * Please refer to the GNU Public License for more details.
 *
 * You should have received a copy of the GNU Public License along with
 * this source code; if not, write to:
 * Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <string.h>
#include <stdint.h>

#include <erl_nif.h>

#include <zenroom.h>

#define MAX_STDOUT 2048000 // max 2MiB
#define MAX_STDERR 2048000 // max 2MiB

static ERL_NIF_TERM
zencode_exec_erl(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
	zenroom_t *Z;
	ErlNifBinary script;
	ErlNifBinary conf;
	ErlNifBinary data;
	ErlNifBinary keys;

	ErlNifBinary stderr;
	ErlNifBinary stdout;

	if (enif_inspect_binary(env, argv[0], &script) == 0)
		return enif_make_badarg(env);
	if (enif_inspect_binary(env, argv[1], &conf) == 0)
		return enif_make_badarg(env);
	if (enif_inspect_binary(env, argv[2], &data) == 0)
		return enif_make_badarg(env);
	if (enif_inspect_binary(env, argv[3], &keys) == 0)
		return enif_make_badarg(env);

	if (script.size < 1) return argv[0];
	char *zconf = conf.size < 1 ? NULL : conf.data;
	char *zkeys = keys.size < 1 ? NULL : keys.data;
	char *zdata = data.size < 1 ? NULL : data.data;

	// allocate stdout and stderr
	enif_alloc_binary(MAX_STDOUT, &stdout);
	enif_alloc_binary(MAX_STDERR, &stderr);

	zencode_exec_tobuf((char*) script.data, zconf, zkeys, zdata,
	                   (char*) stdout.data, MAX_STDOUT,
	                   (char*) stderr.data, MAX_STDERR);

	enif_release_binary(&script);
	enif_release_binary(&conf);
	enif_release_binary(&keys);
	enif_release_binary(&data);
	// TODO: return stderr somewhere
	enif_release_binary(&stderr);

	return enif_make_binary(env, &stdout);
}

static ErlNifFunc funcs[] = {
	{ "zencode_exec", 4, zencode_exec_erl }
};

static int load(ErlNifEnv* env, void** priv, ERL_NIF_TERM info) {
	// may be: *priv = (void*) private_data;
	return 0;
}

static int reload(ErlNifEnv* env, void** priv, ERL_NIF_TERM info) {
	return 0;
}

static int
upgrade(ErlNifEnv* env, void** priv, void** old_priv, ERL_NIF_TERM info) {
	return 0; // may be: load(env, priv, info);
}

static void unload(ErlNifEnv* env, void* priv) {
	// may be: enif_free(priv);
}

ERL_NIF_INIT(Elixir.Zenroom, funcs, &load, &reload, &upgrade, &unload)
