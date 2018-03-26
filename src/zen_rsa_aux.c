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
		r->publen = sizeof(rsa_public_key_2048); // sizeof(sign32)+(FFLEN_2048*sizeof(BIG_1024_28));
		r->privlen = sizeof(rsa_private_key_2048); // (r->publen*5)/2;
		r->fflen = FFLEN_2048;
		r->bigsize = sizeof(BIG_1024_28);
		r->modbytes = MODBYTES_1024_28;
		r->rfs = RFS_2048;
		break;

	case 4096:
		r->hash = HASH_TYPE_RSA_4096;
		r->publen = sizeof(rsa_public_key_4096); // sizeof(sign32)+(FFLEN_4096*sizeof(BIG_512_29));
		r->privlen = sizeof(rsa_private_key_4096); // (r->publen*5)/2;
		r->fflen = FFLEN_4096;
		r->bigsize = sizeof(BIG_512_29);
		r->modbytes = MODBYTES_512_29;
		r->rfs = RFS_4096;
		break;

	default:
		error("RSA bit size not supported: %u",bits);
		return 0;
	}
	return 1;
}

void error_protect_keys(char *what) {
	error("RSA engine has already a %s set:",what);
	error("Zenroom won't overwrite. Use a rsa.new() instance.");
}

// typedef struct
// {
// 	BIG_1024_28 p[FFLEN_XXX/2];  /**< secret prime p  */
// 	BIG_1024_28 q[FFLEN_XXX/2];  /**< secret prime q  */
// 	BIG_1024_28 dp[FFLEN_XXX/2]; /**< decrypting exponent mod (p-1)  */
// 	BIG_1024_28 dq[FFLEN_XXX/2]; /**< decrypting exponent mod (q-1)  */
// 	BIG_1024_28 c[FFLEN_XXX/2];  /**< 1/p mod q */
// } rsa_private_key_;

int rsa_priv_to_oct(rsa *r, octet *dst, char *priv) {
	func("%s",__func__);
	int i;
	if(r->privlen > dst->max) {
		error("%s: not enough space in destination octet (%u > %u)",
		      __func__, r->privlen, dst->max);
		return 0; }
	dst->len=0; // overwrite everything in destination
	for(i=0;  i < r->privlen && i < dst->max; i++)
		dst->val[i] = priv[i];
	dst->len = i;
	return i;
}

int rsa_oct_to_priv(rsa *r, char *priv, octet *src) {
	func("%s",__func__);
	if(src->len > r->privlen) {
		error("%s: octet contents exceed private key size (%u > %u)",
		      __func__, src->len, r->privlen);
		return 0; }
	int i;
	for(i=0; i < src->len; i++)
		priv[i] = src->val[i];
	return i;
}

int rsa_oct_to_pub(rsa *r, void *pub, octet *src) {
	func("%s",__func__);
	if(r->bits == 2048) {
		rsa_public_key_2048 *pub2k = (rsa_public_key_2048*) pub;
		FF_2048_fromOctet(pub2k->n, src, FFLEN_2048);
		pub2k->e = r->exponent;

	} else if(r->bits == 4096) {
		rsa_public_key_4096 *pub4k = (rsa_public_key_4096*) pub;
		FF_4096_fromOctet(pub4k->n, src, FFLEN_4096);
		pub4k->e = r->exponent;
	}
	return r->publen;
}

int rsa_pub_to_oct(rsa *r, octet *dst, void *pub) {
	func("%s",__func__);
	if(r->bits == 2048) {
		rsa_public_key_2048 *pub2k = (rsa_public_key_2048*) pub;
		FF_2048_toOctet(dst, pub2k->n, FFLEN_2048); // discards exponent
	} else if(r->bits == 4096) {
		rsa_public_key_4096 *pub4k = (rsa_public_key_4096*) pub;
		FF_4096_toOctet(dst, pub4k->n, FFLEN_4096); // discards exponent
	}
	return dst->len;
}
