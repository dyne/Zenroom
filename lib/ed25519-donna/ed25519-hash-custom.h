/*
	a custom hash must have a 512bit digest and implement:

	struct ed25519_hash_context;

	void ed25519_hash_init(ed25519_hash_context *ctx);
	void ed25519_hash_update(ed25519_hash_context *ctx, const uint8_t *in, size_t inlen);
	void ed25519_hash_final(ed25519_hash_context *ctx, uint8_t *hash);
	void ed25519_hash(uint8_t *hash, const uint8_t *in, size_t inlen);
*/

#include <amcl.h>

typedef hash512 ed25519_hash_context;

extern void HASH512_init(hash512 *sh);
extern void HASH512_process(hash512 *sh,int byt);
extern void HASH512_hash(hash512 *sh,char *hash);

void ed25519_hash_init(ed25519_hash_context *ctx) {
	HASH512_init(ctx);
}
void ed25519_hash_update(ed25519_hash_context *ctx, const uint8_t *in, size_t inlen) {
	for(size_t i = 0; i < inlen; i++) {
		HASH512_process(ctx, in[i]);
	}
}
void ed25519_hash_final(ed25519_hash_context *ctx, uint8_t *hash) {
	HASH512_hash(ctx, hash);
}

static void
ed25519_hash(uint8_t *hash, const uint8_t *in, size_t inlen) {
	ed25519_hash_context ctx;
	ed25519_hash_init(&ctx);
	ed25519_hash_update(&ctx, in, inlen);
	ed25519_hash_final(&ctx, hash);
}
