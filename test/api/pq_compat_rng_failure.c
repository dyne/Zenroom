#include <stdint.h>
#include <string.h>

#include "../../lib/pqclean/dilithium2/api.h"
#include "../../lib/pqclean/kyber512/api.h"

int main(void) {
	uint8_t dilithium_pk[PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_PUBLICKEYBYTES];
	uint8_t dilithium_sk[PQCLEAN_DILITHIUM2_CLEAN_CRYPTO_SECRETKEYBYTES];
	uint8_t kyber_pk[PQCLEAN_KYBER512_CLEAN_CRYPTO_PUBLICKEYBYTES];
	uint8_t kyber_sk[PQCLEAN_KYBER512_CLEAN_CRYPTO_SECRETKEYBYTES];
	uint8_t ciphertext[PQCLEAN_KYBER512_CLEAN_CRYPTO_CIPHERTEXTBYTES];
	uint8_t shared_secret[PQCLEAN_KYBER512_CLEAN_CRYPTO_BYTES];

	memset(dilithium_pk, 0xa5, sizeof(dilithium_pk));
	memset(dilithium_sk, 0xa5, sizeof(dilithium_sk));
	memset(kyber_pk, 0xa5, sizeof(kyber_pk));
	memset(kyber_sk, 0xa5, sizeof(kyber_sk));
	memset(ciphertext, 0xa5, sizeof(ciphertext));
	memset(shared_secret, 0xa5, sizeof(shared_secret));

	if(PQCLEAN_DILITHIUM2_CLEAN_crypto_sign_keypair(
			dilithium_pk, dilithium_sk) == 0) return 1;
	if(PQCLEAN_KYBER512_CLEAN_crypto_kem_keypair(kyber_pk, kyber_sk) == 0)
		return 2;
	if(PQCLEAN_KYBER512_CLEAN_crypto_kem_enc(
			ciphertext, shared_secret, kyber_pk) == 0) return 3;

	for(size_t i = 0; i < sizeof(dilithium_pk); i++)
		if(dilithium_pk[i] != 0xa5) return 4;
	for(size_t i = 0; i < sizeof(dilithium_sk); i++)
		if(dilithium_sk[i] != 0xa5) return 5;
	for(size_t i = 0; i < sizeof(kyber_pk); i++)
		if(kyber_pk[i] != 0xa5) return 6;
	for(size_t i = 0; i < sizeof(kyber_sk); i++)
		if(kyber_sk[i] != 0xa5) return 7;
	for(size_t i = 0; i < sizeof(ciphertext); i++)
		if(ciphertext[i] != 0xa5) return 8;
	for(size_t i = 0; i < sizeof(shared_secret); i++)
		if(shared_secret[i] != 0xa5) return 9;

	return 0;
}
