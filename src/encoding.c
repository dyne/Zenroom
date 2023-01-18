/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2019-2020 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 */

#include <inttypes.h>
#include <stddef.h>

#include <stdbool.h>
#include <string.h>

#include "bip39_english.h"
#include <amcl.h>

static const int32_t hextable[] = {
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
	-1,-1, 0,1,2,3,4,5,6,7,8,9,-1,-1,-1,-1,-1,-1,-1,10,11,12,13,14,15,-1,
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
	-1,-1,10,11,12,13,14,15,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
};

// takes zero terminated hex string, requires pre-allocation of dst,
// returns len in bytes or -1 in case of error
int hex2buf(char *dst, const char *hex) {
	register int i, j;
	for(i=0, j=0; hex[j]!=0; i++, j+=2) {
		if(hex[j+1] == '\0') {
			return -1;
		}
		dst[i] = (hextable[(short)hex[j]]<<4) + hextable[(short)hex[j+1]];
	}
	return(i);
}

// takes binary buffer and its bytes length, requires pre-allocation
// of dst string
static const char hexes[] = "0123456789abcdef";
void buf2hex(char *dst, const char *buf, const size_t len) {
	register size_t i;
	register unsigned char ch;
	for (i=0; i<len; i++) {
		ch=buf[i];
		dst[i<<1]     = hexes[ch>>4];
		dst[(i<<1)+1] = hexes[ch & 0xf];
	}
	dst[len<<1] = 0x0; // null termination
}

static const unsigned char asciitable[256] = {
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 62, 64, 63,
	52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 64, 64, 64, 64, 64, 64,
	64,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
	15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 64, 64, 64, 64, 63,
	64, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
	41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64
};

static const char alpha_U64[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
// static const char alpha_B64[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

int B64encoded_len(int len) { return ((((len + 2) / 3) <<2) + 1); }

int B64decoded_len(int len) { return ((len + 3) >> 2) * 3; }

// assumes null terminated string
// no padding equals check (no modulo 4)
// returns 0 if not base else length of base encoded string
int is_url64(const char *in) {
	if(!in) { return 0; }
	register int c;
	// check u64: header
	unsigned char *bufin;
	bufin = (unsigned char *)in;
	for(c=0; bufin[c] != '\0'; c++)
		if(asciitable[*(bufin+c)] > 63)
			return 0;
	return(c);
}

int U64decode(char *dest, const char *src) {
	register const unsigned char *bufin;
	register unsigned char *bufout;
	register int nprbytes;
	const unsigned char *_buf = (const unsigned char *) src;
	bufin = _buf;
	while (asciitable[*(bufin++)] <= 63);
	nprbytes = bufin - _buf - 1;

	bufout = (unsigned char *) dest;
	bufin = _buf;

	while (nprbytes > 4) {
		*(bufout++) = (unsigned char) (asciitable[*bufin] << 2 | asciitable[bufin[1]] >> 4);
		*(bufout++) = (unsigned char) (asciitable[bufin[1]] << 4 | asciitable[bufin[2]] >> 2);
		*(bufout++) = (unsigned char) (asciitable[bufin[2]] << 6 | asciitable[bufin[3]]);
		bufin += 4;
		nprbytes -= 4;
	}

	if (nprbytes > 1)
		*(bufout++) = (unsigned char) (asciitable[*bufin] << 2 | asciitable[bufin[1]] >> 4);
	if (nprbytes > 2)
		*(bufout++) = (unsigned char) (asciitable[bufin[1]] << 4 | asciitable[bufin[2]] >> 2);
	if (nprbytes > 3)
		*(bufout++) = (unsigned char) (asciitable[bufin[2]] << 6 | asciitable[bufin[3]]);

	*(bufout++) = '\0';
	// return the length of decoded
	return(bufout-(unsigned char*)dest-1);
}

void U64encode(char *dest, const char *src, int len) {
	int i;
	char *p = dest;

	for (i = 0; i < len - 2; i += 3) {
		*p++ = alpha_U64[(src[i] >> 2) & 0x3F];
		*p++ = alpha_U64[((src[i] & 0x3) << 4) | ((int) (src[i + 1] & 0xF0) >> 4)];
		*p++ = alpha_U64[((src[i + 1] & 0xF) << 2) | ((int) (src[i + 2] & 0xC0) >> 6)];
		*p++ = alpha_U64[src[i + 2] & 0x3F];
	}

	if (i < len) {
		*p++ = alpha_U64[(src[i] >> 2) & 0x3F];
		if (i == (len - 1)) {
			*p++ = alpha_U64[((src[i] & 0x3) << 4)];
		} else {
			*p++ = alpha_U64[((src[i] & 0x3) << 4) | ((int) (src[i + 1] & 0xF0) >> 4)];
			*p++ = alpha_U64[((src[i + 1] & 0xF) << 2)];
		}
	}

	*p++ = '\0';
}


static const char alpha_b45[] = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:";


static const char b45table[256] = {
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	36, 64, 64, 64, 37, 38, 64, 64, 64, 64, 39, 40, 64, 41, 42, 43,
	 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 44, 64, 64, 64, 64, 64,
	64, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
	25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
};


// returns the length of the string encoded
// if dest == NULL it doesn't create the output string
// (it only returns the length)
int b45encode(char *dest, const char *src, int len) {
	int i, j;
	// A pair of bytes becomes a triplet of chars,
	// if the length is odd the last byte is encoded as
	// two chars (there is also the final char '\0')
	int dest_len = len / 2 * 3 + (len % 2) * 2 + 1;

	if(dest) {
		j=0;
		for(i=0; i+1<len; i+= 2) {
			uint16_t word = (((uint16_t)src[i]) << 8) | src[i+1];
			dest[j++] = alpha_b45[word % 45]; word = word / 45;
			dest[j++] = alpha_b45[word % 45]; word = word / 45;
			dest[j++] = alpha_b45[word];
		}
		// i is even
		if(len == i + 1) {
		        // len is odd
			uint16_t word = (uint16_t)src[len-1];
			dest[j++] = alpha_b45[word % 45]; word = word / 45;
			dest[j++] = alpha_b45[word];
		}
		dest[j++] = '\0';
	}
	return dest_len;
}

// returns the length of the bytes decoded
// Even when there is an error, the decoding goes on until
// the end
int b45decode(char *dest, const char *src) {
	int i, j;

	int error = 0;
	// chars cannot be indices
	// (otherwise they rise a warning, they could be negative)
	const uint8_t *bytes = (uint8_t*)src;

	i = 0;
	j = 0;
	// start decoding the triplets
	while(bytes[i] && bytes[i+1] && bytes[i+2]) {
	        uint16_t c = b45table[bytes[i]];
	        uint16_t d = b45table[bytes[i+1]];
	        uint16_t e = b45table[bytes[i+2]];

		uint32_t decoded = c + 45 * d + 2025*e;
		if(decoded >= (1<<16)) {
		        error = 1;
		}
		dest[j++] = decoded / 256;
		dest[j++] = decoded % 256;
		i+=3;
	}
	// there could be one last byte (when the length is odd)
	if (bytes[i]) {
	        if(!bytes[i+1]) {
		        error = 1;
		} else {
		        // in this case s[i+2] == '\0'
		        uint16_t c = b45table[bytes[i]];
		        uint16_t d = b45table[bytes[i+1]];

			if (c > 63 || d > 63 || c + 45 * d > 255) {
			        error = 1;
			}
			c = c + 45 * d;
			dest[j++] = c % 256;
		}
	}

	return error ? -1 : j;
}

// read the string until the end even if there is an error
// it returns a negative value if there is an error
int is_base45(const char* src) {
        int i = 0;
	int error = 0;
	uint8_t *bytes = (uint8_t*)src;
	while(bytes[i] != '\0') {
	        if(b45table[bytes[i]] > 63) {
		        error = 1;
		}
	        i++;
	}
	if(i % 3 == 1) {
	        error = 1;
	}
	i = i / 3 * 2 + (i % 3) / 2; // length of decoded string

	return error ? -1 : i;
}

/**
 * Imported from https://github.com/trezor/trezor-crypto/blob/master/bip39.c
 * Changes of Alberto Lerda on 29th Sept 2021
 * - Removed cache (maybe we add it in future)
 * - Started using SHA of Milagro
 * - Removed global static string because zenroom could be used on a multi-thread
 *   app and it wouldn't work
 * - `mnemonic_check` verifies the checksum and return the byte array
 *   it has become ` mnemonic_check_and_bits`
 */

void sha256_raw(const char *data, int len, char *result) {
  hash256 hash;
  HASH256_init(&hash);
  register int i;
  for(i=0;i<len;i++) HASH256_process(&hash,data[i]);
  HASH256_hash(&hash, (char*)result);
}

// Return value: 0 bad input data, 1 bip39 string generated correctly
// mnemo size has to be 24*10
int mnemonic_from_data(char *mnemo, const char *data, int len) {
  if (len % 4 || len < 16 || len > 32) {
    return 0;
  }

  char bits[32 + 1];

  sha256_raw(data, len, bits);
  // checksum
  bits[len] = bits[0];
  // data
  memcpy(bits, data, len);

  int mlen = len * 3 / 4;

  int i, j, idx;
  char *p = mnemo;
  for (i = 0; i < mlen; i++) {
    idx = 0;
    for (j = 0; j < 11; j++) {
      idx <<= 1;
      idx += (bits[(i * 11 + j) / 8] & (1 << (7 - ((i * 11 + j) % 8)))) > 0;
    }
    strcpy(p, wordlist[idx]);
    p += strlen(wordlist[idx]);
    *p = (i < mlen - 1) ? ' ' : 0;
    p++;
  }
  memset(bits, 0, sizeof(bits));
  return 1;
}

int mnemonic_to_bits(const char *mnemonic, char *bits) {
  if (!mnemonic) {
    return 0;
  }

  uint32_t i = 0, n = 0;

  while (mnemonic[i]) {
    if (mnemonic[i] == ' ') {
      n++;
    }
    i++;
  }
  n++;

  // check number of words
  if (n != 12 && n != 18 && n != 24) {
    return 0;
  }

  char current_word[10] = {0};
  uint32_t j = 0, k = 0, ki = 0, bi = 0;
  char result[32 + 1] = {0};

  memset(result, 0, sizeof(result));
  i = 0;
  while (mnemonic[i]) {
    j = 0;
    while (mnemonic[i] != ' ' && mnemonic[i] != 0) {
      if (j >= sizeof(current_word) - 1) {
        return 0;
      }
      current_word[j] = mnemonic[i];
      i++;
      j++;
    }
    current_word[j] = 0;
    if (mnemonic[i] != 0) {
      i++;
    }
    k = 0;
    for (;;) {
      if (!wordlist[k]) {  // word not found
        return 0;
      }
      if (strcmp(current_word, wordlist[k]) == 0) {  // word found on index k
        for (ki = 0; ki < 11; ki++) {
          if (k & (1 << (10 - ki))) {
            result[bi / 8] |= 1 << (7 - (bi % 8));
          }
          bi++;
        }
        break;
      }
      k++;
    }
  }
  if (bi != n * 11) {
    return 0;
  }
  memcpy(bits, result, sizeof(result));
  memset(result, 0, sizeof(result));

  // returns amount of entropy + checksum BITS
  return n * 11;
}

// bits must be 33 bytes long
int mnemonic_check_and_bits(const char *mnemonic, int *len, char *result) {
  char bits[32+1] = { 0 };
  int mnemonic_bits_len = mnemonic_to_bits(mnemonic, bits);
  if (mnemonic_bits_len != (12 * 11) && mnemonic_bits_len != (18 * 11) &&
      mnemonic_bits_len != (24 * 11)) {
    return 0;
  }
  int words = mnemonic_bits_len / 11;
  *len = words * 4 / 3; // remove checksum;
  memcpy(result, bits, *len);
  
  char checksum = bits[words * 4 / 3];
  sha256_raw(bits, words * 4 / 3, bits);
  if (words == 12) {
    return (bits[0] & 0xF0) == (checksum & 0xF0);  // compare first 4 bits
  } else if (words == 18) {
    return (bits[0] & 0xFC) == (checksum & 0xFC);  // compare first 6 bits
  } else if (words == 24) {
    return bits[0] == checksum;  // compare 8 bits
  }
  return 0;
}


const char *const *mnemonic_wordlist(void) { return wordlist; }
