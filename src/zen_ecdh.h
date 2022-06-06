/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2019 Dyne.org foundation
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

#ifndef __ZEN_ECDH_H__
#define __ZEN_ECDH_H__

#include <zen_octet.h>
#include <pbc_support.h>

typedef struct {
	// function pointers
	int (*ECP__KEY_PAIR_GENERATE)(csprng *R, octet *s, octet *W);
	int (*ECP__PUBLIC_KEY_VALIDATE)(octet *W);
	int (*ECP__SVDP_DH)(octet *s, octet *W, octet *K);
	void (*ECP__ECIES_ENCRYPT)(int h, octet *P1, octet *P2,
	                           csprng *R, octet *W, octet *M, int len,
	                           octet *V, octet *C, octet *T);
	int (*ECP__ECIES_DECRYPT)(int h, octet *P1, octet *P2,
	                          octet *V, octet *C, octet *T,
	                          octet *U, octet *M);
	int (*ECP__SP_DSA)(int h, csprng *R, octet *k, octet *s,
			   octet *M, octet *c, octet *d);
	int (*ECP__VP_DSA)(int h, octet *W, octet *M, octet *c, octet *d);
	int (*ECP__SP_DSA_NOHASH)(int h, csprng *R, octet *k,
				  octet *s, octet *M,
				  octet *c, octet *d, int *parity);
	int (*ECP__VP_DSA_NOHASH)(int h, octet *W, octet *M,
				  octet *c, octet *d);
	int (*ECP__PUBLIC_KEY_RECOVERY)(octet *X, int y_parity, octet *H,
					octet *C, octet *D, octet *PK);
	int fieldsize;
	int hash; // hash type is also bytes length of hash
	char curve[16]; // just short names
	char type[16];
        char *order;
	char *prime;
        int mod_size;
	int cofactor;
} ecdh;

#endif
