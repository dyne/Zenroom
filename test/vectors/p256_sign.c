#include <stdlib.h>
#include <stdio.h>

#include "p256-m.h"

uint8_t k[32];

/* test version based on stdlib - never do this in production! */
int p256_generate_random(uint8_t *output, unsigned output_size)
{
    for (unsigned i = 0; i < output_size; i++) {
        output[i] = k[i];
    }

    return 0;
}

int hex_to_char(int len, uint8_t* buf, char* str){
	unsigned int u;
	while (buf < buf + len && sscanf(str, "%2x", &u) == 1)
	{
		*buf++ = u;
		str += 2;
	}

}

int main(void)
{	
	char* K_str[3] = {"94a1bbb14b906a61a280f245f9e93c7f3b4a6247824f5d33b9670787642a68de","6d3e71882c3b83b156bb14e0ab184aa9fb728068d3ae9fac421187ae0b2f34c6", "ad5e887eb2b380b8d8280ad6e5ff8a60f4d26243e0124c2f31a297b5d0835de2"};
	char* MSGS[3] = {"5905238877c77421f73e43ee3da6f2d9e2ccad5fc942dcec0cbd25482935faaf416983fe165b1a045ee2bcd2e6dca3bdf46c4310a7461f9a37960ca672d3feb5473e253605fb1ddfd28065b53cb5858a8ad28175bf9bd386a5e471ea7a65c17cc934a9d791e91491eb3754d03799790fe2d308d16146d5c9b0d0debd97d79ce8"};
	char* Ds[3] = {"519b423d715f8b581f4fa8ee59f4771a5b44c8130b4e3eacca54a56dda72b464", "0f56db78ca460b055c500064824bed999a25aaf48ebb519ac201537b85479813", "e283871239837e13b95f789e6e1af63bf61c918c992e62bca040d64cad1fc2ef"};
	char* PUBK[3] = {"1ccbe91c075fc7f4f033bfa248db8fccd3565de94bbfb12f3c59ff46c271bf83ce4014c68811f9a21a1fdb2c0e6113e06db7ca93b7404e78dc7ccd5ca89a4ca9",
			"e266ddfdc12668db30d4ca3e8f7749432c416044f2d2b8c10bf3d4012aeffa8abfa86404a2e9ffe67d47c587ef7a97a7f456b863b4d02cfc6928973ab5b1cb39",
			"74ccd8a62fba0e667c50929a53f78c21b8ff0c3c737b0b40b1750b2302b0bde829074e21f3a0ef88b9efdf10d06aa4c295cc1671f758ca0e4cd108803d0f2614"};
	char* Rs[3] = {"f3ac8061b514795b8843e3d6629527ed2afd6b1f6a555a7acabb5e6f79c8c2ac", "976d3a4e9d23326dc0baa9fa560b7c4e53f42864f508483a6473b6a11079b2db", "35fb60f5ca0f3ca08542fb3cc641c8263a2cab7a90ee6a5e1583fac2bb6f6bd1"};
	char* Ss[3] = {"8bf77819ca05a6b2786c76262bf7371cef97b218e96f175a3ccdda2acc058903", "1b766e9ceb71ba6c01dcd46e0af462cd4cfa652ae5017d4555b8eeefe36e1932", "ee59d81bc9db1055cc0ed97b159d8784af04e98511d0a9a407b99bb292572e96"};
	char* MSG_hash[3] = {"44acf6b7e36c1342c2c5897204fe09504e1e2efb1a900377dbc4e7a6a133ec56","9b2db89cb0e8fa3cc7608b4d6cc1dec0114e0b9ff4080bea12b134f489ab2bbc", "b804cf88af0c2eff8bbbfb3660ebb3294138e9d3ebd458884e19818061dacff0"};

	int ret = 0;
	for (int j=0; j<3; j++) {
		printf("Test %d\n", j+1);
		uint8_t priv[32], pub[64], secret[32], sig[64], hash[32], r[32], s[32], msg[64];
		char* k_str = K_str[j];
		char* msg_str = MSGS[j];
		char* d_str = Ds[j];
		char* pub_str = PUBK[j];
		char* R_str = Rs[j];
		char* S_str = Ss[j];
		hex_to_char(32, k, k_str);
		hex_to_char(64, pub, pub_str);
		hex_to_char(32, priv, d_str);
		hex_to_char(32, r, R_str);
		hex_to_char(32, s, S_str);
		char* msg_hash = MSG_hash[j];

		hex_to_char(32, hash, msg_hash);

		ret = p256_ecdsa_sign(sig, priv, hash, sizeof hash);
		for (unsigned i = 0; i < 32; i++) {
			if (sig[i] != r[i]) {
				printf("%s\n", "Wrong r value in ecdsa signature");
				break;
			}
		}
		for (unsigned i = 32; i < 64; i++) {
			if (sig[i] != s[i-32]) {
				printf("%s\n", "Wrong s value in ecdsa signature");
				break;
			}
		}
	}
	return ret;
}
