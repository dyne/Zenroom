#include <zenroom.h>
#include <zen_error.h>
#include <lua_functions.h>
#include <zen_octet.h>

#include "../lib/pqclean/kyber512/kyber_larkg.h"
#include "../lib/pqclean/kyber512/skem.h"
#include "../lib/pqclean/kyber512/params.h"

#define LARKG_SK_BYTES KYBER_INDCPA_SECRETKEYBYTES
#define LARKG_PK_BYTES KYBER_INDCPA_PUBLICKEYBYTES
#define LARKG_CRED_BYTES (sizeof(larkg_cred_t))

// Imported from Zenroom
extern int randombytes(void *buf, size_t n);

// skem_context is shared global state
// Here it is serialised as the 32 byte seed rho and is rebuilt on demand since gen_matrix is deterministic

// --- Internal functions ---

// Rebuild the skem_context from the seed rho
static void _ctx_from_rho(skem_context *ctx, const octet *rho) {
	PQCLEAN_KYBER512_CLEAN_skem_init(ctx, (const uint8_t *)rho->val);
}

// Serialise larkg_cred_t to a octet: B_prime || c || mu
static void _cred_to_octet(octet *oct, const larkg_cred_t *cred) {
	size_t offset = 0;
	memcpy(oct->val + offset, cred->B_prime, KYBER_POLYVECBYTES);
	offset += KYBER_POLYVECBYTES;
	memcpy(oct->val + offset, cred->c, KYBER_POLYCOMPRESSEDBYTES);
	offset += KYBER_POLYCOMPRESSEDBYTES;
	memcpy(oct->val + offset, cred->mu, KYBER_SSBYTES);
	oct->len = offset + KYBER_SSBYTES;
}

// Deserialise larkg_cred_t from a octet: B_prime || c || mu
static int _octet_to_cred(larkg_cred_t *cred, const octet *oct) {
	if(oct->len != LARKG_CRED_BYTES) {
		return 0;
	}
	size_t offset = 0;
	memcpy(cred->B_prime, oct->val + offset, KYBER_POLYVECBYTES);
	offset += KYBER_POLYVECBYTES;
	memcpy(cred->c, oct->val + offset, KYBER_POLYCOMPRESSEDBYTES);
	offset += KYBER_POLYCOMPRESSEDBYTES;
	memcpy(cred->mu, oct->val + offset, KYBER_SSBYTES);
	return 1;
}

// --- Lua bindings ---

// Generate initial LARKG keypair (sk, pk) and the shared rho seed
static int larkg_keygen(lua_State *L) {
	
	BEGIN();
	char *failed_msg = NULL;

	lua_createtable(L, 0, 3);

	octet *sk = o_new(L, LARKG_SK_BYTES); SAFE_GOTO(sk, "Could not allocate LARKG secret key");
	lua_setfield(L, -2, "private");

	octet *pk = o_new(L, LARKG_PK_BYTES); SAFE_GOTO(pk, "Could not allocate LARKG public key");
	lua_setfield(L, -2, "public");

	octet *rho = o_new(L, KYBER_SYMBYTES); SAFE_GOTO(rho, "Could not allocate LARKG rho seed");
	lua_setfield(L, -2, "rho");

	randombytes((uint8_t *)rho->val, KYBER_SYMBYTES);
	rho->len = KYBER_SYMBYTES;

	skem_context ctx;
	_ctx_from_rho(&ctx, rho);
	PQCLEAN_KYBER512_CLEAN_skem_keygen((uint8_t *)pk->val, (uint8_t *)sk->val, &ctx);

	pk->len = LARKG_PK_BYTES;
	sk->len = LARKG_SK_BYTES;

end:
	if(failed_msg) {
		THROW(failed_msg);
	}

	END(1);
}

// Derive the next public key (sender side)
static int larkg_derive_pk(lua_State *L) {

	BEGIN();
	char *failed_msg = NULL;
	const octet *pk = NULL;
	const octet *rho = NULL;

	pk = o_arg(L, 1); SAFE_GOTO(pk, "Could not allocate LARKG current public key");
	SAFE_GOTO(pk->len == LARKG_PK_BYTES, "Invalid LARKG public key length");

	rho = o_arg(L, 2); SAFE_GOTO(rho, "Could not allocate LARKG rho seed");
	SAFE_GOTO(rho->len == KYBER_SYMBYTES, "Invalid LARKG rho seed length");

	lua_createtable(L, 0, 1);

	octet *next_pk = o_new(L, LARKG_PK_BYTES); SAFE_GOTO(next_pk, "Could not allocate LARKG next public key");
	lua_setfield(L, -2, "next_public");

	octet *cred_oct = o_new(L, LARKG_CRED_BYTES); SAFE_GOTO(cred_oct, "Could not allocate LARKG credential octet");
	lua_setfield(L, -2, "credential");

	skem_context ctx;
	_ctx_from_rho(&ctx, rho);

	larkg_cred_t cred;
	int ret = PQCLEAN_KYBER512_CLEAN_larkg_derive_pk((uint8_t *)next_pk->val, &cred, (const uint8_t *)pk->val, &ctx);
	SAFE_GOTO(ret == 0, "LARKG derive_pk failed");

	next_pk->len = LARKG_PK_BYTES;
	_cred_to_octet(cred_oct, &cred);

end:
	o_free(L, rho);
	o_free(L, pk);
	if(failed_msg) {
		THROW(failed_msg);
	}

	END(1);
}

// Derive the next secret key (receiver side)
static int larkg_derive_sk(lua_State *L) {
	
	BEGIN();
	char *failed_msg = NULL;
	const octet *sk = NULL;
	const octet *cred_oct = NULL;

	sk = o_arg(L, 1); SAFE_GOTO(sk, "Could not allocate LARKG current secret key");
	SAFE_GOTO(sk->len == LARKG_SK_BYTES, "Invalid LARKG secret key length");

	cred_oct = o_arg(L, 2); SAFE_GOTO(cred_oct, "Could not allocate LARKG credential octet");
	SAFE_GOTO(cred_oct->len == LARKG_CRED_BYTES, "Invalid LARKG credential octet length");

	larkg_cred_t cred;
	SAFE_GOTO(_octet_to_cred(&cred, cred_oct), "Failed to deserialise LARKG credential");

	octet *next_sk = o_new(L, LARKG_SK_BYTES); SAFE_GOTO(next_sk, "Could not allocate LARKG next secret key");

	int ret;
	// Retry on rejection (-1) abort on auth failure (-2)
	do {
		ret = PQCLEAN_KYBER512_CLEAN_larkg_derive_sk((uint8_t *)next_sk->val, (const uint8_t *)sk->val, &cred);
	} while (ret == -1);

	SAFE_GOTO(ret == 0, "LARKG authentication failed");
	next_sk->len = LARKG_SK_BYTES;

end:
	o_free(L, cred_oct);
	o_free(L, sk);
	if(failed_msg) {
		THROW(failed_msg);
	}

	END(1);
}

// --- Size checks ---

static int larkg_sk_check(lua_State *L) {
	BEGIN();
	const octet *sk = o_arg(L, 1); SAFE(sk, "Could not allocate LARKG secret key");
	lua_pushboolean(L, sk->len == LARKG_SK_BYTES);
	o_free(L, sk);
	END(1);
}

static int larkg_pk_check(lua_State *L) {
	BEGIN();
	const octet *pk = o_arg(L, 1); SAFE(pk, "Could not allocate LARKG public key");
	lua_pushboolean(L, pk->len == LARKG_PK_BYTES);
	o_free(L, pk);
	END(1);
}

static int larkg_cred_check(lua_State *L) {
	BEGIN();
	const octet *cred_oct = o_arg(L, 1); SAFE(cred_oct, "Could not allocate LARKG credential octet");
	lua_pushboolean(L, cred_oct->len == LARKG_CRED_BYTES);
	o_free(L, cred_oct);
	END(1);
}


int luaopen_larkg(lua_State *L) {
	(void)L;
	const struct luaL_Reg larkg_class[] = {
		{"keygen", larkg_keygen},
		{"derive_pk", larkg_derive_pk},
		{"derive_sk", larkg_derive_sk},
		{"seccheck", larkg_sk_check},
		{"pubcheck", larkg_pk_check},
		{"credcheck", larkg_cred_check},
		{NULL, NULL}
	};

	const struct luaL_Reg larkg_methods[] = {
		{NULL, NULL}
	};

	zen_add_class(L, "larkg", larkg_class, larkg_methods);
	return 1;
}
