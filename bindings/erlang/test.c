#include <erl_nif.h>
static ERL_NIF_TERM hello(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
	return enif_make_string(env, "Hello world!", ERL_NIF_LATIN1);
}
static ErlNifFunc nif_funcs[] =
{
	{"hello", 0, hello}
};

ERL_NIF_INIT(test, nif_funcs, NULL, NULL, NULL, NULL)


