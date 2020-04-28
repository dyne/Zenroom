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
// returns len in bytes
int hex2buf(char *dst, const char *hex) {
	register int i, j;
	for(i=0, j=0; hex[j]!=0; i++, j+=2)
		dst[i] = (hextable[(short)hex[j]]<<4) + hextable[(short)hex[j+1]];
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
static const char alpha_B64[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
