/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2024-2026 Dyne.org foundation
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
 */

#ifndef __ZEN_SECP_H__
#define __ZEN_SECP_H__

#include <zen_octet.h>
#include <hedley.h>

#include <ecp_SECP256K1.h>

/*
 * secp256k1 userdata: mirrors the ECP pattern but uses Milagro
 * SECP256K1 types directly.  Zenroom's global BIG and ECP macros
 * remain mapped to BLS381; this module is independent of those
 * factories so that BLS381 callers are not affected.
 *
 * Field / coordinate size: 32 bytes (MODBYTES_256_28)
 * Compressed public key:   33 bytes (0x02/0x03 + 32-byte x)
 * Uncompressed public key: 65 bytes (0x04 + 32-byte x + 32-byte y)
 */

typedef struct {
	int    totlen;   /* serialized octet length (uncompressed) */
	ECP_SECP256K1 val; /* Milagro projective point */
	int    ref;
} secp;

/* --- lifecycle (cf. ecp_new / ecp_arg) --- */

HEDLEY_NON_NULL(1)
void secp_clone_free(lua_State *L, HEDLEY_NO_ESCAPE const secp *e);

HEDLEY_NON_NULL(1)
HEDLEY_WARN_UNUSED_RESULT
secp *secp_new(lua_State *L);

HEDLEY_NON_NULL(1)
HEDLEY_WARN_UNUSED_RESULT
const secp *secp_arg(lua_State *L, int n);

HEDLEY_NON_NULL(1)
HEDLEY_WARN_UNUSED_RESULT
secp *secp_dup(lua_State *L, const secp *in);

/* --- internal helpers --- */

/* Convert 32-byte big-endian OCTET to BIG_256_28.
 * Returns 1 on success, 0 on failure (e.g. wrong length). */
int secp_oct_to_big(BIG_256_28 b, const octet *o);

/* Convert BIG_256_28 to a fresh big-endian 32-byte OCTET on the Lua stack. */
octet *secp_big_to_oct(lua_State *L, const BIG_256_28 b);

/* Signed-even-y helper (0 if even, 1 if odd). */
int secp_sign(BIG_256_28 y);

#endif
