#include <amcl.h>
#include <rsa_2048.h>
#include <rsa_4096.h>

#include <jutils.h>
#include <zen_rsa.h>

// setup bits, hash, max, publen and privlen in rsa
int bitchoice(rsa *r, int bits) {
	r->bits = bits;
	r->max = bits/8;  // maximum bytes (instead of MAX_RSA_BYTES
	// always to 512 (4096bit) as in rsa_support.h)
	// used for all new octets
	switch(bits) {
	case 2048:
		r->hash = HASH_TYPE_RSA_2048;
		r->publen = RFS_2048; // sizeof(sign32)+(FFLEN_2048*sizeof(BIG_1024_28));
		r->privlen = (RFS_2048*5)/2;
		return 1;

	case 4096:
		r->hash = HASH_TYPE_RSA_4096;
		r->publen = RFS_4096; // sizeof(sign32)+(FFLEN_4096*sizeof(BIG_512_29));
		r->privlen = (RFS_4096*5)/2;
		return 1;

	default:
		error("RSA bit size not supported: %u",bits);
		return 0;
	}

	return 1;
}


int rsa_priv_to_oct(rsa *r, octet *dst, void *priv) {

	// typedef struct
	// {
	// 	BIG_1024_28 p[FFLEN_2048/2];  /**< secret prime p  */
	// 	BIG_1024_28 q[FFLEN_2048/2];  /**< secret prime q  */
	// 	BIG_1024_28 dp[FFLEN_2048/2]; /**< decrypting exponent mod (p-1)  */
	// 	BIG_1024_28 dq[FFLEN_2048/2]; /**< decrypting exponent mod (q-1)  */
	// 	BIG_1024_28 c[FFLEN_2048/2];  /**< 1/p mod q */
	// } rsa_private_key_2048;

	octet *tmp = (octet *)malloc(sizeof(octet));
	if(r->bits == 2048) {
		int bigs = FFLEN_2048/2;
		int fflen = bigs * sizeof(BIG_1024_28);
		tmp->val=malloc(fflen);
		tmp->max=fflen; tmp->len=0;
		// cast input
		rsa_private_key_2048 *priv2k = (rsa_private_key_2048*)priv;
		// _toOctet takes size of FF in BIGS
		FF_2048_toOctet(tmp, priv2k->p,  bigs); OCT_joctet(dst,tmp);
		FF_2048_toOctet(tmp, priv2k->q,  bigs); OCT_joctet(dst,tmp);
		FF_2048_toOctet(tmp, priv2k->dp, bigs); OCT_joctet(dst,tmp);
		FF_2048_toOctet(tmp, priv2k->dq, bigs); OCT_joctet(dst,tmp);
		FF_2048_toOctet(tmp, priv2k->c,  bigs); OCT_joctet(dst,tmp);
		free(tmp->val);
		free(tmp);
		return dst->len;
	} else if(r->bits == 4096) {
		int bigs = FFLEN_4096/2;
		int fflen = bigs * sizeof(BIG_512_29);
		tmp->val=malloc(fflen);
		tmp->max=fflen; tmp->len=0;
		// cast input
		rsa_private_key_4096 *priv4k = (rsa_private_key_4096*)priv;
		// _toOctet takes size of FF in BIGS
		FF_4096_toOctet(tmp, priv4k->p,  bigs); OCT_joctet(dst,tmp);
		FF_4096_toOctet(tmp, priv4k->q,  bigs); OCT_joctet(dst,tmp);
		FF_4096_toOctet(tmp, priv4k->dp, bigs); OCT_joctet(dst,tmp);
		FF_4096_toOctet(tmp, priv4k->dq, bigs); OCT_joctet(dst,tmp);
		FF_4096_toOctet(tmp, priv4k->c,  bigs); OCT_joctet(dst,tmp);
		free(tmp->val);
		free(tmp);
		return dst->len;
	}
	// fail
	return 0;
}

int rsa_pub_to_oct(rsa *r, octet *dst, void *pub) {
	if(r->bits == 2048) {
		rsa_public_key_2048 *pub2k = (rsa_public_key_2048*) pub;
		FF_2048_toOctet(dst, pub2k->n, FFLEN_2048); // discards exponent
	} else if(r->bits == 4096) {
		rsa_public_key_4096 *pub4k = (rsa_public_key_4096*) pub;
		FF_4096_toOctet(dst, pub4k->n, FFLEN_4096); // discards exponent
	}
	return dst->len;
}
