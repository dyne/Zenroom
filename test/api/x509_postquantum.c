// test x509 for post-quantum safe zenroom
// incomplete. for the generation of the certificate see:
// https://gist.github.com/jaromil/5cdd0580c643d040d8cad0c026a98931

#include <stdio.h>
#include <amcl.h>  // for octet support only
#include <x509.h>

 // "-----BEGIN CERTIFICATE-----"
char selfsign_pq[]=
"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"
"AAAAAAAAAAAAAAAPHis8";


char io[5000*2];
octet IO = {0, sizeof(io), io};
// extracted cert
char h[5000*2];
octet H = {0, sizeof(h), h};

#define MAXMODBYTES 6000
#define MAXFFLEN 6000
char sig[MAXMODBYTES * MAXFFLEN];
octet SIG = {0, sizeof(sig), sig};
char r[MAXMODBYTES];
octet R = {0, sizeof(r), r};
char s[MAXMODBYTES];
octet S = {0, sizeof(s), s};

void print_out(char *des, octet *c, int index, int len)
{
    int i;
    printf("%s [", des);
    for (i = 0; i < len; i++)
        printf("%c", c->val[index + i]);
    printf("]\n");
}

void print_date(char *des, octet *c, int index)
{
    int i = index;
    printf("%s [", des);
    if (i == 0) printf("]\n");
    else printf("20%c%c-%c%c-%c%c %c%c:%c%c:%c%c]\n", c->val[i], c->val[i + 1], c->val[i + 2], c->val[i + 3], c->val[i + 4], c->val[i + 5], c->val[i + 6], c->val[i + 7], c->val[i + 8], c->val[i + 9], c->val[i + 10], c->val[i + 11]);
}


int main(int argc, char **argv) {
    int res, len, sha;
    int c, ic;
    pktype st, ca, pt;

	OCT_frombase64(&IO, selfsign_pq);
	printf("CA Self-Signed Cert= \n");
	OCT_output(&IO);
	printf("\n");

	// extract R and S from P256 sig
	st = X509_extract_cert_sig(&IO, &SIG);
	printf("type: %u\n",st.type);
	printf("hash: %u\n",st.hash);
	printf("curve: %u\n",st.curve);
	OCT_output(&SIG);
	printf("\n");
}
