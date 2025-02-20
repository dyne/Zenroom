/*
 * Copyright (c) 2024-2025 The mlkem-native project authors
 * SPDX-License-Identifier: Apache-2.0
 */
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include "indcpa.h"
#include "kem.h"
#include "randombytes.h"
#include "symmetric.h"
#include "verify.h"

/* Static namespacing
 * This is to facilitate building multiple instances
 * of mlkem-native (e.g. with varying security levels)
 * within a single compilation unit. */
#define check_pk MLK_NAMESPACE_K(check_pk)
#define check_sk MLK_NAMESPACE_K(check_sk)
#define check_pct MLK_NAMESPACE_K(check_pct)
/* End of static namespacing */

#if defined(CBMC)
/* Redeclaration with contract needed for CBMC only */
int memcmp(const void *str1, const void *str2, size_t n)
__contract__(
  requires(memory_no_alias(str1, n))
  requires(memory_no_alias(str2, n))
);
#endif

/*************************************************
 * Name:        check_pk
 *
 * Description: Implements modulus check mandated by FIPS 203,
 *              i.e., ensures that coefficients are in [0,q-1].
 *
 * Arguments:   - const uint8_t *pk: pointer to input public key
 *                (an already allocated array of MLKEM_INDCCA_PUBLICKEYBYTES
 *                 bytes)
 *
 * Returns: - 0 on success
 *          - -1 on failure
 *
 * Specification: Implements [FIPS 203, Section 7.2, 'modulus check']
 *
 **************************************************/
MLK_MUST_CHECK_RETURN_VALUE
static int check_pk(const uint8_t pk[MLKEM_INDCCA_PUBLICKEYBYTES])
{
  int res;
  polyvec p;
  uint8_t p_reencoded[MLKEM_POLYVECBYTES];

  polyvec_frombytes(&p, pk);
  polyvec_reduce(&p);
  polyvec_tobytes(p_reencoded, &p);

  /* We use a constant-time memcmp here to avoid having to
   * declassify the PK before the PCT has succeeded. */
  res = ct_memcmp(pk, p_reencoded, MLKEM_POLYVECBYTES) ? -1 : 0;

  /* Specification: Partially implements
   * [FIPS 203, Section 3.3, Destruction of intermediate values] */
  ct_zeroize(p_reencoded, sizeof(p_reencoded));
  ct_zeroize(&p, sizeof(p));
  return res;
}

/*************************************************
 * Name:        check_sk
 *
 * Description: Implements public key hash check mandated by FIPS 203,
 *              i.e., ensures that
 *              sk[768𝑘+32 ∶ 768𝑘+64] = H(pk)= H(sk[384𝑘 : 768𝑘+32])
 *
 * Arguments:   - const uint8_t *sk: pointer to input private key
 *                (an already allocated array of MLKEM_INDCCA_SECRETKEYBYTES
 *                 bytes)
 *
 * Returns: - 0 on success
 *          - -1 on failure
 *
 * Specification: Implements [FIPS 203, Section 7.3, 'hash check']
 *
 **************************************************/
MLK_MUST_CHECK_RETURN_VALUE
static int check_sk(const uint8_t sk[MLKEM_INDCCA_SECRETKEYBYTES])
{
  int res;
  MLK_ALIGN uint8_t test[MLKEM_SYMBYTES];
  /*
   * The parts of `sk` being hashed and compared here are public, so
   * no public information is leaked through the runtime or the return value
   * of this function.
   */

  /* Declassify the public part of the secret key */
  MLK_CT_TESTING_DECLASSIFY(sk + MLKEM_INDCPA_SECRETKEYBYTES,
                            MLKEM_INDCCA_PUBLICKEYBYTES);
  MLK_CT_TESTING_DECLASSIFY(
      sk + MLKEM_INDCCA_SECRETKEYBYTES - 2 * MLKEM_SYMBYTES, MLKEM_SYMBYTES);

  hash_h(test, sk + MLKEM_INDCPA_SECRETKEYBYTES, MLKEM_INDCCA_PUBLICKEYBYTES);
  res = memcmp(sk + MLKEM_INDCCA_SECRETKEYBYTES - 2 * MLKEM_SYMBYTES, test,
               MLKEM_SYMBYTES)
            ? -1
            : 0;

  /* Specification: Partially implements
   * [FIPS 203, Section 3.3, Destruction of intermediate values] */
  ct_zeroize(test, sizeof(test));
  return res;
}

MLK_MUST_CHECK_RETURN_VALUE
static int check_pct(uint8_t const pk[MLKEM_INDCCA_PUBLICKEYBYTES],
                     uint8_t const sk[MLKEM_INDCCA_SECRETKEYBYTES])
__contract__(
  requires(memory_no_alias(pk, MLKEM_INDCCA_PUBLICKEYBYTES))
  requires(memory_no_alias(sk, MLKEM_INDCCA_SECRETKEYBYTES)));

#if defined(MLK_KEYGEN_PCT)
/* Specification:
 * Partially implements 'Pairwise Consistency Test' [FIPS 140-3 IG] and
 * [FIPS 203, Section 7.1, Pairwise Consistency].
 */
static int check_pct(uint8_t const pk[MLKEM_INDCCA_PUBLICKEYBYTES],
                     uint8_t const sk[MLKEM_INDCCA_SECRETKEYBYTES])
{
  int res;
  uint8_t ct[MLKEM_INDCCA_CIPHERTEXTBYTES];
  uint8_t ss_enc[MLKEM_SSBYTES], ss_dec[MLKEM_SSBYTES];

  res = crypto_kem_enc(ct, ss_enc, pk);
  if (res != 0)
  {
    goto cleanup;
  }

  res = crypto_kem_dec(ss_dec, ct, sk);
  if (res != 0)
  {
    goto cleanup;
  }

#if defined(MLK_KEYGEN_PCT_BREAKAGE_TEST)
  /* Deliberately break PCT for testing purposes */
  if (mlk_break_pct())
  {
    ss_enc[0] = ~ss_enc[0];
  }
#endif /* MLK_KEYGEN_PCT_BREAKAGE_TEST */

  res = ct_memcmp(ss_enc, ss_dec, sizeof(ss_dec));

cleanup:
  /* The result of the PCT is public. */
  MLK_CT_TESTING_DECLASSIFY(&res, sizeof(res));

  /* Specification: Partially implements
   * [FIPS 203, Section 3.3, Destruction of intermediate values] */
  ct_zeroize(ct, sizeof(ct));
  ct_zeroize(ss_enc, sizeof(ss_enc));
  ct_zeroize(ss_dec, sizeof(ss_dec));
  return res;
}
#else  /* !MLKEM_KEYGEN_PCT */
static int check_pct(uint8_t const pk[MLKEM_INDCCA_PUBLICKEYBYTES],
                     uint8_t const sk[MLKEM_INDCCA_SECRETKEYBYTES])
{
  /* Skip PCT */
  ((void)pk);
  ((void)sk);
  return 0;
}
#endif /* MLKEM_KEYGEN_PCT */

MLK_EXTERNAL_API
int crypto_kem_keypair_derand(uint8_t pk[MLKEM_INDCCA_PUBLICKEYBYTES],
                              uint8_t sk[MLKEM_INDCCA_SECRETKEYBYTES],
                              const uint8_t *coins)
{
  indcpa_keypair_derand(pk, sk, coins);
  memcpy(sk + MLKEM_INDCPA_SECRETKEYBYTES, pk, MLKEM_INDCCA_PUBLICKEYBYTES);
  hash_h(sk + MLKEM_INDCCA_SECRETKEYBYTES - 2 * MLKEM_SYMBYTES, pk,
         MLKEM_INDCCA_PUBLICKEYBYTES);
  /* Value z for pseudo-random output on reject */
  memcpy(sk + MLKEM_INDCCA_SECRETKEYBYTES - MLKEM_SYMBYTES,
         coins + MLKEM_SYMBYTES, MLKEM_SYMBYTES);

  /* Declassify public key */
  MLK_CT_TESTING_DECLASSIFY(pk, MLKEM_INDCCA_PUBLICKEYBYTES);

  /* Pairwise Consistency Test (PCT) (FIPS 140-3 IPG) */
  if (check_pct(pk, sk))
  {
    return -1;
  }

  return 0;
}

MLK_EXTERNAL_API
int crypto_kem_keypair(uint8_t pk[MLKEM_INDCCA_PUBLICKEYBYTES],
                       uint8_t sk[MLKEM_INDCCA_SECRETKEYBYTES])
{
  int res;
  MLK_ALIGN uint8_t coins[2 * MLKEM_SYMBYTES];

  /* Acquire necessary randomness, and mark it as secret. */
  randombytes(coins, 2 * MLKEM_SYMBYTES);
  MLK_CT_TESTING_SECRET(coins, sizeof(coins));

  res = crypto_kem_keypair_derand(pk, sk, coins);

  /* Specification: Partially implements
   * [FIPS 203, Section 3.3, Destruction of intermediate values] */
  ct_zeroize(coins, sizeof(coins));
  return res;
}

MLK_EXTERNAL_API
int crypto_kem_enc_derand(uint8_t ct[MLKEM_INDCCA_CIPHERTEXTBYTES],
                          uint8_t ss[MLKEM_SSBYTES],
                          const uint8_t pk[MLKEM_INDCCA_PUBLICKEYBYTES],
                          const uint8_t coins[MLKEM_SYMBYTES])
{
  MLK_ALIGN uint8_t buf[2 * MLKEM_SYMBYTES];
  /* Will contain key, coins */
  MLK_ALIGN uint8_t kr[2 * MLKEM_SYMBYTES];

  /* Specification: Implements [FIPS 203, Section 7.2, Modulus check] */
  if (check_pk(pk))
  {
    return -1;
  }

  memcpy(buf, coins, MLKEM_SYMBYTES);

  /* Multitarget countermeasure for coins + contributory KEM */
  hash_h(buf + MLKEM_SYMBYTES, pk, MLKEM_INDCCA_PUBLICKEYBYTES);
  hash_g(kr, buf, 2 * MLKEM_SYMBYTES);

  /* coins are in kr+MLKEM_SYMBYTES */
  indcpa_enc(ct, buf, pk, kr + MLKEM_SYMBYTES);

  memcpy(ss, kr, MLKEM_SYMBYTES);

  /* Specification: Partially implements
   * [FIPS 203, Section 3.3, Destruction of intermediate values] */
  ct_zeroize(buf, sizeof(buf));
  ct_zeroize(kr, sizeof(kr));

  return 0;
}

MLK_EXTERNAL_API
int crypto_kem_enc(uint8_t ct[MLKEM_INDCCA_CIPHERTEXTBYTES],
                   uint8_t ss[MLKEM_SSBYTES],
                   const uint8_t pk[MLKEM_INDCCA_PUBLICKEYBYTES])
{
  int res;
  MLK_ALIGN uint8_t coins[MLKEM_SYMBYTES];

  randombytes(coins, MLKEM_SYMBYTES);
  MLK_CT_TESTING_SECRET(coins, sizeof(coins));

  res = crypto_kem_enc_derand(ct, ss, pk, coins);

  /* Specification: Partially implements
   * [FIPS 203, Section 3.3, Destruction of intermediate values] */
  ct_zeroize(coins, sizeof(coins));
  return res;
}

MLK_EXTERNAL_API
int crypto_kem_dec(uint8_t ss[MLKEM_SSBYTES],
                   const uint8_t ct[MLKEM_INDCCA_CIPHERTEXTBYTES],
                   const uint8_t sk[MLKEM_INDCCA_SECRETKEYBYTES])
{
  uint8_t fail;
  MLK_ALIGN uint8_t buf[2 * MLKEM_SYMBYTES];
  /* Will contain key, coins */
  MLK_ALIGN uint8_t kr[2 * MLKEM_SYMBYTES];
  MLK_ALIGN uint8_t tmp[MLKEM_SYMBYTES + MLKEM_INDCCA_CIPHERTEXTBYTES];

  const uint8_t *pk = sk + MLKEM_INDCPA_SECRETKEYBYTES;

  /* Specification: Implements [FIPS 203, Section 7.3, Hash check] */
  if (check_sk(sk))
  {
    return -1;
  }

  indcpa_dec(buf, ct, sk);

  /* Multitarget countermeasure for coins + contributory KEM */
  memcpy(buf + MLKEM_SYMBYTES,
         sk + MLKEM_INDCCA_SECRETKEYBYTES - 2 * MLKEM_SYMBYTES, MLKEM_SYMBYTES);
  hash_g(kr, buf, 2 * MLKEM_SYMBYTES);

  /* Recompute and compare ciphertext */
  /* coins are in kr+MLKEM_SYMBYTES */
  indcpa_enc(tmp, buf, pk, kr + MLKEM_SYMBYTES);
  fail = ct_memcmp(ct, tmp, MLKEM_INDCCA_CIPHERTEXTBYTES);

  /* Compute rejection key */
  memcpy(tmp, sk + MLKEM_INDCCA_SECRETKEYBYTES - MLKEM_SYMBYTES,
         MLKEM_SYMBYTES);
  memcpy(tmp + MLKEM_SYMBYTES, ct, MLKEM_INDCCA_CIPHERTEXTBYTES);
  hash_j(ss, tmp, sizeof(tmp));

  /* Copy true key to return buffer if fail is 0 */
  ct_cmov_zero(ss, kr, MLKEM_SYMBYTES, fail);

  /* Specification: Partially implements
   * [FIPS 203, Section 3.3, Destruction of intermediate values] */
  ct_zeroize(buf, sizeof(buf));
  ct_zeroize(kr, sizeof(kr));
  ct_zeroize(tmp, sizeof(tmp));

  return 0;
}

/* To facilitate single-compilation-unit (SCU) builds, undefine all macros.
 * Don't modify by hand -- this is auto-generated by scripts/autogen. */
#undef check_pk
#undef check_sk
#undef check_pct
