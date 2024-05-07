#include <stdint.h>
#include <string.h>

#include "params.h"
#include "sign.h"
#include "packing.h"
#include "polyvec.h"
#include "poly.h"
#include "randombytes.h"
#include "symmetric.h"
#include "fips202.h"

int pqcrystals_ml_dsa_44_ipd_zen_keypair(uint8_t *pk, uint8_t *sk, const uint8_t *randbytes) {
  uint8_t seedbuf[2*SEEDBYTES + CRHBYTES];
  uint8_t tr[TRBYTES];
  const uint8_t *rho, *rhoprime, *key;
  polyvecl mat[K];
  polyvecl s1, s1hat;
  polyveck s2, t1, t0;

  // random from caller
  memcpy(seedbuf, randbytes, RNDBYTES);

  shake256(seedbuf, 2*SEEDBYTES + CRHBYTES, seedbuf, SEEDBYTES);
  rho = seedbuf;
  rhoprime = rho + SEEDBYTES;
  key = rhoprime + CRHBYTES;

  /* Expand matrix */
  polyvec_matrix_expand(mat, rho);

  /* Sample short vectors s1 and s2 */
  polyvecl_uniform_eta(&s1, rhoprime, 0);
  polyveck_uniform_eta(&s2, rhoprime, L);

  /* Matrix-vector multiplication */
  s1hat = s1;
  polyvecl_ntt(&s1hat);
  polyvec_matrix_pointwise_montgomery(&t1, mat, &s1hat);
  polyveck_reduce(&t1);
  polyveck_invntt_tomont(&t1);

  /* Add error vector s2 */
  polyveck_add(&t1, &t1, &s2);

  /* Extract t1 and write public key */
  polyveck_caddq(&t1);
  polyveck_power2round(&t1, &t0, &t1);
  pack_pk(pk, rho, &t1);

  /* Compute H(rho, t1) and write secret key */
  shake256(tr, TRBYTES, pk, CRYPTO_PUBLICKEYBYTES);
  pack_sk(sk, rho, tr, key, &t0, &s1, &s2);

  return 0;
}


int pqcrystals_ml_dsa_44_ipd_zen_pub_gen(uint8_t *pk, uint8_t *sk){
  uint8_t rho[SEEDBYTES], key[SEEDBYTES], tr[TRBYTES];
  polyveck s2, t1, t0;
  polyvecl mat[K];
  polyvecl s1;

  /* Unpack the secret-key */
  unpack_sk(rho, tr, key, &t0, &s1, &s2, sk);
  
  /* Expand matrix */
  polyvec_matrix_expand(mat, rho);

  /* Matrix-vector multiplication */
  polyvecl_ntt(&s1); 
  polyvec_matrix_pointwise_montgomery(&t1, mat, &s1);  
  polyveck_reduce(&t1);
  polyveck_invntt_tomont(&t1);
  /* Add error vector s2 */
  polyveck_add(&t1, &t1, &s2);

  /* Extract t1 and write public key */
  polyveck_caddq(&t1);
  polyveck_power2round(&t1, &t0, &t1);
  pack_pk(pk, rho, &t1);

  return 0;  
}


int pqcrystals_ml_dsa_44_ipd_zen_signature(uint8_t *sig,
			size_t *siglen,
			const uint8_t *m,
			size_t mlen,
			const uint8_t *sk,
			const uint8_t *randbytes)
{
  unsigned int n;
  uint8_t seedbuf[2*SEEDBYTES + TRBYTES + RNDBYTES + 2*CRHBYTES];
  uint8_t *rho, *tr, *key, *mu, *rhoprime, *rnd;
  uint16_t nonce = 0;
  polyvecl mat[K], s1, y, z;
  polyveck t0, s2, w1, w0, h;
  poly cp;
  shake256incctx state;

  rho = seedbuf;
  tr = rho + SEEDBYTES;
  key = tr + TRBYTES;
  rnd = key + SEEDBYTES;
  mu = rnd + RNDBYTES;
  rhoprime = mu + CRHBYTES;
  unpack_sk(rho, tr, key, &t0, &s1, &s2, sk);


  /* Compute mu = CRH(tr, msg) */
  shake256_inc_init(&state);
  shake256_inc_absorb(&state, tr, TRBYTES);
  shake256_inc_absorb(&state, m, mlen);
  shake256_inc_finalize(&state);
  shake256_inc_squeeze(mu, CRHBYTES, &state);

  // random from caller
  memcpy(rnd, randbytes, RNDBYTES);

  shake256(rhoprime, CRHBYTES, key, SEEDBYTES + RNDBYTES + CRHBYTES);

  /* Expand matrix and transform vectors */
  polyvec_matrix_expand(mat, rho);
  polyvecl_ntt(&s1);
  polyveck_ntt(&s2);
  polyveck_ntt(&t0);

rej:
  /* Sample intermediate vector y */
  polyvecl_uniform_gamma1(&y, rhoprime, nonce++);

  /* Matrix-vector multiplication */
  z = y;
  polyvecl_ntt(&z);
  polyvec_matrix_pointwise_montgomery(&w1, mat, &z);
  polyveck_reduce(&w1);
  polyveck_invntt_tomont(&w1);

  /* Decompose w and call the random oracle */
  polyveck_caddq(&w1);
  polyveck_decompose(&w1, &w0, &w1);
  polyveck_pack_w1(sig, &w1);

  shake256_inc_ctx_reset(&state);
  shake256_inc_absorb(&state, mu, CRHBYTES);
  shake256_inc_absorb(&state, sig, K*POLYW1_PACKEDBYTES);
  shake256_inc_finalize(&state);
  shake256_inc_squeeze(sig, CTILDEBYTES, &state);
  poly_challenge(&cp, sig); /* uses only the first SEEDBYTES bytes of sig */
  poly_ntt(&cp);

  /* Compute z, reject if it reveals secret */
  polyvecl_pointwise_poly_montgomery(&z, &cp, &s1);
  polyvecl_invntt_tomont(&z);
  polyvecl_add(&z, &z, &y);
  polyvecl_reduce(&z);
  if(polyvecl_chknorm(&z, GAMMA1 - BETA))
    goto rej;

  /* Check that subtracting cs2 does not change high bits of w and low bits
   * do not reveal secret information */
  polyveck_pointwise_poly_montgomery(&h, &cp, &s2);
  polyveck_invntt_tomont(&h);
  polyveck_sub(&w0, &w0, &h);
  polyveck_reduce(&w0);
  if(polyveck_chknorm(&w0, GAMMA2 - BETA))
    goto rej;

  /* Compute hints for w1 */
  polyveck_pointwise_poly_montgomery(&h, &cp, &t0);
  polyveck_invntt_tomont(&h);
  polyveck_reduce(&h);
  if(polyveck_chknorm(&h, GAMMA2))
    goto rej;

  polyveck_add(&w0, &w0, &h);
  n = polyveck_make_hint(&h, &w0, &w1);
  if(n > OMEGA)
    goto rej;

  shake256_inc_ctx_release(&state);

  /* Write signature */
  pack_sig(sig, sig, &z, &h);
  *siglen = CRYPTO_BYTES;
  return 0;
}
