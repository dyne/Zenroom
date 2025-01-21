// test x509 with P256 lib from zenroom

#include <stdio.h>
#include <amcl.h>  // for octet support only
#include <x509.h>

 // "-----BEGIN CERTIFICATE-----"
char didroom_selfsign_p256[]=
	"MIIB5zCCAY2gAwIBAgIBATAKBggqhkjOPQQDAjAgMR4wHAYDVQQDDBVEaWRyb29t"
	"IC0gbWF0dGVvIPCfm7gwHhcNMjUwMTIwMDg1ODEwWhcNMjYwMTIxMDg1ODEwWjAg"
	"MR4wHAYDVQQDDBVEaWRyb29tIC0gbWF0dGVvIPCfm7gwWTATBgcqhkjOPQIBBggq"
	"hkjOPQMBBwNCAATUtxD9sLQNnsl2eLtW58u7RI5e6CB9nHA3aGAMZrI6hZBzU04K"
	"oxyteoM/f5RbCTFjcGFby66D6xyciBDFFkXno4G3MIG0MBIGA1UdEwEB/wQIMAYB"
	"Af8CAQIwHAYDVR0lAQH/BBIwEAYGKgMEBQYHBgZTBAUGBwgwDgYDVR0PAQH/BAQD"
	"AgEGMB0GA1UdDgQWBBTuz5prI2WpFQJjXzyTu7ZUhj0/QjBRBgNVHREESjBIhkZk"
	"aWQ6ZHluZTpzYW5kYm94LnNpZ25yb29tOjRLRXltV2dMRFVmMUxOY2tleFk5NmRm"
	"S3o1dkg3OWRpRGVrZ0xNUjlGV3BIMAoGCCqGSM49BAMCA0gAMEUCIQCVetesj1HI"
	"U43l7wzHuj+lX5ZJA9P019HuGazQA3RTVgIgSHXU5Brj7rSaBBUdY8uBdKPE/h0Z"
	"oBqKuv/u9Qf8mdM=";
// "-----END CERTIFICATE-----";
// "-----BEGIN EC PRIVATE KEY-----"
char didroom_privkey_p256[]=
	"MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgB648VWj7/K+tQ4eZ"
	"82blPBV4jwi1qSCWWIyT7xf3J0OhRANCAATUtxD9sLQNnsl2eLtW58u7RI5e6CB9"
	"nHA3aGAMZrI6hZBzU04KoxyteoM/f5RbCTFjcGFby66D6xyciBDFFkXn";
// "-----END EC PRIVATE KEY-----";

char io[5000];
octet IO = {0, sizeof(io), io};

#define MAXMODBYTES 72
#define MAXFFLEN 16
char sig[MAXMODBYTES * MAXFFLEN];
octet SIG = {0, sizeof(sig), sig};
char r[MAXMODBYTES];
octet R = {0, sizeof(r), r};
char s[MAXMODBYTES];
octet S = {0, sizeof(s), s};
char cakey[MAXMODBYTES * MAXFFLEN];
octet CAKEY = {0, sizeof(cakey), cakey};
char certkey[MAXMODBYTES * MAXFFLEN];
octet CERTKEY = {0, sizeof(certkey), certkey};

// extracted cert
char h[5000];
octet H = {0, sizeof(h), h};

char hh[5000];
octet HH = {0, sizeof(hh), hh};

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

	OCT_frombase64(&IO, didroom_selfsign_p256);
	printf("CA Self-Signed Cert= \n");
	OCT_output(&IO);
	printf("\n");

	// extract R and S from P256 sig
	st = X509_extract_cert_sig(&IO, &SIG);

	if (st.type == X509_ECC) {
		OCT_chop(&SIG, &S, SIG.len / 2);
		OCT_copy(&R, &SIG);
		printf("ECC SIG= \n");
		OCT_output(&R);
		OCT_output(&S);
		printf("\n");
	} else {
		printf("Unable to extract cert signature type: %i\n",st.type);
		return 0;
	}
    if (st.hash == X509_H256) printf("Hashed with SHA256\n");
    if (st.hash == X509_H384) printf("Hashed with SHA384\n");
    if (st.hash == X509_H512) printf("Hashed with SHA512\n");

    c = X509_extract_cert(&IO, &H);
    printf("\nCert= \n");
    OCT_output(&H);
    printf("\n");
// show some details
    printf("Issuer Details\n");
    ic = X509_find_issuer(&H,&len);
    c = X509_find_entity_property(&H, &X509_ON, ic, &len);
    print_out("owner=", &H, c, len);
    c = X509_find_entity_property(&H, &X509_CN, ic, &len);
    print_out("country=", &H, c, len);
    c = X509_find_entity_property(&H, &X509_EN, ic, &len);
    print_out("email=", &H, c, len);
    c = X509_find_entity_property(&H, &X509_MN, ic, &len);
    print_out((char *)"Common Name=", &H, c, len);
    printf("\n");

    ca = X509_extract_public_key(&H, &CAKEY);
    if (ca.type != st.type)    {
	    printf("Certificate is not self-signed\n");
    }
    if (ca.type == 0)    {
	    printf("CA Type 0 not supported\n");
	    return 0;
    } else {
	    printf("CA type: %u\n",ca.type);
    }
    printf("EXTRACTED PUBLIC KEY= \n");
    OCT_output(&CAKEY);

    ic = X509_find_validity(&H);
    c = X509_find_start_date(&H, ic);
    print_date("start date= ", &H, c);
    c = X509_find_expiry_date(&H, ic);
    print_date("expiry date=", &H, c);
    printf("\n");

}
