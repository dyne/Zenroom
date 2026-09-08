#include <stdint.h>
#include <string.h>

#include <zenroom.h>

int main(void) {
	zenroom_t first = {0};
	zenroom_t second = {0};
	uint8_t seed[RANDOM_SEED_LEN];
	uint8_t split[RANDOM_SEED_LEN];
	uint8_t whole[RANDOM_SEED_LEN];

	for(size_t i = 0; i < sizeof(seed); i++) seed[i] = (uint8_t)i;
	if(zen_entropy_fill(NULL, 0) != 0 || zen_entropy_fill(NULL, 1) == 0) return 1;
	if(zen_rng_fill(NULL, NULL, 0) != 0 || zen_rng_fill(NULL, seed, 1) == 0) return 2;
	if(zen_rng_init(NULL, seed, sizeof(seed)) == 0) return 3;
	if(zen_rng_init(&first, seed, sizeof(seed)) != 0) return 3;
	if(zen_rng_init(&first, seed, sizeof(seed)) == 0) return 3;
	if(zen_rng_init(&second, seed, sizeof(seed)) != 0) return 4;
	if(zen_rng_fill(&first, split, 1) != 0 ||
	   zen_rng_callback_fill(&first, split + 1, sizeof(split) - 1) != 0 ||
	   zen_rng_fill(&second, whole, sizeof(whole)) != 0 ||
	   memcmp(split, whole, sizeof(whole)) != 0) return 5;
	if(zen_rng_reseed(&first, seed, sizeof(seed)) != 0 ||
	   zen_rng_fill(&first, split, sizeof(split)) != 0 ||
	   memcmp(split, whole, sizeof(whole)) != 0) return 6;
	if(zen_rng_reseed(&first, NULL, sizeof(seed)) == 0 ||
	   zen_rng_reseed(&first, seed, 0) == 0) return 7;
	zen_rng_clear(&first);
	zen_rng_clear(&second);
	zen_rng_clear(&second);
	if(zen_rng_fill(&first, split, sizeof(split)) == 0) return 8;
	if(zen_rng_reseed(&first, seed, sizeof(seed)) == 0) return 9;
	return 0;
}
