/*
 * This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2024-2026 Dyne.org foundation
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License v3.0
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * Along with this program you should have received a copy of the
 * GNU Affero General Public License v3.0
 * If not, see http://www.gnu.org/licenses/agpl.txt
 */

/// <h1>Elliptic Curve Point Arithmetic for secp256k1 (SECP)</h1>
//
//  Point arithmetic over the secp256k1 curve used by Bitcoin and BIP-340
//  Schnorr.  This module is independent of the global @{ECP} class (which
//  remains BLS381).  Scalars and coordinates are exchanged as 32-byte
//  @{OCTET} values; zenroom.BIG is not accepted for SECP operations
//  because the global BIG factory is sized for BLS381.
//
//  Serialization:
//  - compressed:   33 bytes (0x02/0x03 + x)
//  - uncompressed: 65 bytes (0x04 + x + y)
//  - SECP:octet()  returns compressed (the common secp256k1 wire format)
//
//  @module SECP
//  @license AGPLv3
//  @copyright Dyne.org foundation 2024-2026

#include <zenroom.h>
#include <zen_error.h>
#include <zen_secp.h>
#include <lua_functions.h>

#include <string.h>

/* --- internal helpers --- */

static const int SECP_BYTES = MODBYTES_256_28; /* 32 */
static const int SECP_COMPRESSED   = SECP_BYTES + 1;   /* 33 */
static const int SECP_UNCOMPRESSED = SECP_BYTES * 2 + 1; /* 65 */

int secp_oct_to_big(BIG_256_28 b, const octet *o) {
	if (!o || o->len != SECP_BYTES) return 0;
	BIG_256_28_fromBytesLen(b, (char *)o->val, SECP_BYTES);
	return 1;
}

octet *secp_big_to_oct(lua_State *L, const BIG_256_28 b) {
	octet *o = o_new(L, SECP_BYTES);
	if (!o) return NULL;
	char tmp[MODBYTES_256_28];
	int i, n;
	BIG_256_28_norm((chunk *)b);
	BIG_256_28_toBytes(tmp, (chunk *)b);
	/* Left-zero-pad: toBytes may produce fewer than 32 bytes */
	memset((char *)o->val, 0, SECP_BYTES);
	/* Copy bytes to the end of the buffer (right-aligned) */
	n = MODBYTES_256_28;
	for (i = 0; i < n; i++)
		((char *)o->val)[SECP_BYTES - n + i] = tmp[i];
	o->len = SECP_BYTES;
	return o;
}

int secp_sign(BIG_256_28 y) {
	BIG_256_28 p;
	BIG_256_28_rcopy(p, Modulus_SECP256K1);
	BIG_256_28_dec(p, 1);
	BIG_256_28_norm(p);
	BIG_256_28_shr(p, 1);
	if (BIG_256_28_comp(y, p) == 1) return 1;
	return 0;
}

/* validate a point from octet, return NULL on success or error string */
static const char *_secp_from_octet(secp *e, const octet *o) {
	if (!o || o->len < 1) return "empty OCTET for SECP";
	if (o->len == 2 && o->val[0] == SCHAR_MAX && o->val[1] == SCHAR_MAX) {
		ECP_SECP256K1_inf(&e->val);
		return NULL;
	}
	if (o->len != SECP_COMPRESSED && o->len != SECP_UNCOMPRESSED)
		return "invalid SECP OCTET length (expect 33 or 65 bytes)";
	if (!ECP_SECP256K1_fromOctet(&e->val, (octet *)o))
		return "OCTET is not a valid secp256k1 point";
	return NULL;
}

/* Convert a signed 32-byte scalar to BIG_256_28, with range checking.
 * Returns 1 on success.  If order is non-NULL, checks 0 <= k < *order. */
/* Reserved for BIP-340 scalar helpers (future L2) */
/* static int _secp_scalar_check(BIG_256_28 b, const octet *o, BIG_256_28 order) ... */

/* --- lifecycle --- */

secp *secp_new(lua_State *L) {
	secp *e = (secp *)lua_newuserdata(L, sizeof(secp));
	if (HEDLEY_UNLIKELY(e == NULL)) {
		zerror(L, "Error allocating new secp in %s", __func__);
		return NULL;
	}
	e->totlen = SECP_UNCOMPRESSED;
	luaL_getmetatable(L, "zenroom.secp");
	lua_setmetatable(L, -2);
	e->ref = 1;
	return e;
}

void secp_clone_free(lua_State *L, const secp *e) {
	(void)L;
	if (HEDLEY_UNLIKELY(e == NULL)) return;
	free((void *)e);
}

const secp *secp_arg(lua_State *L, int n) {
	const char *failed_msg = NULL;
	secp *res;
	void *ud = luaL_testudata(L, n, "zenroom.secp");
	if (ud) {
		res = malloc(sizeof(secp));
		if (res == NULL) {
			zerror(L, "Error allocating secp clone in %s", __func__);
			return NULL;
		}
		*res = *(secp *)ud;
		return res;
	}
	/* try OCTET coercion */
	const octet *o = o_arg(L, n);
	if (o) {
		res = malloc(sizeof(secp));
		if (res == NULL) {
			zerror(L, "Error allocating secp clone in %s", __func__);
			o_free(L, o);
			return NULL;
		}
		res->totlen = SECP_UNCOMPRESSED;
		failed_msg = _secp_from_octet(res, o);
		res->ref = 1;
		o_free(L, o);
		if (failed_msg) {
			free(res);
			zerror(L, "invalid SECP in argument: %s", failed_msg);
			return NULL;
		}
		return res;
	}
	zerror(L, "invalid SECP in argument");
	return NULL;
}

secp *secp_dup(lua_State *L, const secp *in) {
	secp *e = secp_new(L);
	if (e == NULL) {
		zerror(L, "Error duplicating SECP in %s", __func__);
		return NULL;
	}
	ECP_SECP256K1_copy(&e->val, (ECP_SECP256K1 *)&in->val);
	return e;
}

/* --- constructors --- */

/***
    Create a new SECP point from an OCTET containing compressed (33-byte) or
    uncompressed (65-byte) serialized point coordinates.

    @function SECP.new
    @param OCTET 33-byte compressed or 65-byte uncompressed point
    @return a new SECP point on secp256k1
    @see SECP:octet
*/
static int lua_new_secp(lua_State *L) {
	BEGIN();
	const char *failed_msg = NULL;
	const octet *o = o_arg(L, 1); SAFE_GOTO(o, ALLOCATE_OCT_ERR);
	secp *e = secp_new(L); SAFE_GOTO(e, CREATE_ECP_ERR);
	if (o->len == 2 && o->val[0] == SCHAR_MAX && o->val[1] == SCHAR_MAX) {
		ECP_SECP256K1_inf(&e->val);
		goto end;
	}
	if (o->len != SECP_COMPRESSED && o->len != SECP_UNCOMPRESSED) {
		lua_pop(L, 1);
		failed_msg = "SECP.new: octet length must be 33 or 65 bytes";
		goto end;
	}
	failed_msg = _secp_from_octet(e, o);
	if (failed_msg) {
		lua_pop(L, 1);
	}
end:
	o_free(L, o);
	if (failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Create a SECP point from affine x and y coordinates (32-byte OCTET each).

    @function SECP.from_xy
    @param x 32-byte OCTET x coordinate
    @param y 32-byte OCTET y coordinate
    @return a new SECP point, or nil if coordinates are not on the curve
*/
static int lua_from_xy(lua_State *L) {
	BEGIN();
	const char *failed_msg = NULL;
	BIG_256_28 x, y;
	const octet *ox = o_arg(L, 1); SAFE_GOTO(ox, ALLOCATE_OCT_ERR);
	const octet *oy = o_arg(L, 2); SAFE_GOTO(oy, ALLOCATE_OCT_ERR);
	SAFE_GOTO(ox->len == SECP_BYTES, "x coordinate must be 32 bytes");
	SAFE_GOTO(oy->len == SECP_BYTES, "y coordinate must be 32 bytes");
	secp *e = secp_new(L); SAFE_GOTO(e, CREATE_ECP_ERR);
	BIG_256_28_fromBytesLen(x, (char *)ox->val, SECP_BYTES);
	BIG_256_28_fromBytesLen(y, (char *)oy->val, SECP_BYTES);
	if (!ECP_SECP256K1_set(&e->val, x, y)) {
		lua_pop(L, 1);
		failed_msg = "SECP.from_xy: point not on curve";
		goto end;
	}
end:
	o_free(L, ox);
	o_free(L, oy);
	if (failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Return the generator of the secp256k1 curve.

    @function SECP.generator
    @return the generator point G
*/
static int secp_generator(lua_State *L) {
	BEGIN();
	secp *e = secp_new(L); SAFE(e, CREATE_ECP_ERR);
	ECP_SECP256K1_generator(&e->val);
	END(1);
}

/***
    Return the point at infinity.

    @function SECP.infinity
    @return SECP point at infinity
*/
static int secp_get_infinity(lua_State *L) {
	BEGIN();
	secp *e = secp_new(L); SAFE(e, CREATE_ECP_ERR);
	ECP_SECP256K1_inf(&e->val);
	END(1);
}

/***
    Give the order of the secp256k1 curve as a 32-byte OCTET.

    @function SECP.order
    @return 32-byte OCTET containing the curve order
*/
static int secp_order(lua_State *L) {
	BEGIN();
	BIG_256_28 order;
	/* ROM constant is read-only; copy so BIG_toBytes works */
	BIG_256_28_copy(order, (chunk *)CURVE_Order_SECP256K1);
	octet *o = secp_big_to_oct(L, order);
	if (!o) {
		THROW("Could not create order OCTET");
	}
	END(1);
}

/***
    Give the field prime p of secp256k1 as a 32-byte OCTET.

    @function SECP.prime
    @return 32-byte OCTET containing the field prime
*/
static int secp_prime(lua_State *L) {
	BEGIN();
	BIG_256_28 p;
	BIG_256_28_rcopy(p, Modulus_SECP256K1);
	octet *o = secp_big_to_oct(L, p);
	if (!o) {
		THROW("Could not create prime OCTET");
	}
	END(1);
}

/***
    Compute the right-hand side y^2 of the curve equation for a given x.

    @function SECP.rhs
    @param x 32-byte OCTET x coordinate
    @return 32-byte OCTET containing rhs = x^3 + 7 (mod p)
*/
static int secp_rhs(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *ox = o_arg(L, 1); SAFE_GOTO(ox, ALLOCATE_OCT_ERR);
	SAFE_GOTO(ox->len == SECP_BYTES, "x must be 32 bytes");
	BIG_256_28 xb;
	FP_SECP256K1 X, Y;
	BIG_256_28_fromBytesLen(xb, (char *)ox->val, SECP_BYTES);
	FP_SECP256K1_nres(&X, xb);
	ECP_SECP256K1_rhs(&Y, &X);
	BIG_256_28 rb;
	FP_SECP256K1_redc(rb, &Y);
	secp_big_to_oct(L, rb);
end:
	o_free(L, ox);
	if (failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Validate an OCTET as a secp256k1 point.

    @function SECP.validate
    @param OCTET point bytes (33 or 65 bytes)
    @return true if valid, false otherwise
*/
static int secp_validate(lua_State *L) {
	BEGIN();
	const octet *o = o_arg(L, 1); SAFE(o, ALLOCATE_OCT_ERR);
	/* ECP_SECP256K1 has no PUBLIC_KEY_VALIDATE,
	 * try fromOctet which returns 1 on success */
	ECP_SECP256K1 tmp;
	int res = ECP_SECP256K1_fromOctet(&tmp, (octet *)o);
	lua_pushboolean(L, res == 1);
	o_free(L, o);
	END(1);
}

/* --- point methods --- */

/***
    Make an existing SECP point affine.

    @function affine
    @return a new affine SECP point
*/
static int secp_affine(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const secp *in = secp_arg(L, 1); SAFE_GOTO(in, ALLOCATE_ECP_ERR);
	secp *out = secp_dup(L, in); SAFE_GOTO(out, DUPLICATE_ECP_ERR);
	ECP_SECP256K1_affine(&out->val);
end:
	secp_clone_free(L, in);
	if (failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Check if a point is the point at infinity.

    @function isinf
    @return true if infinity, false otherwise
*/
static int secp_isinf(lua_State *L) {
	BEGIN();
	const secp *e = secp_arg(L, 1); SAFE(e, ALLOCATE_ECP_ERR);
	lua_pushboolean(L, ECP_SECP256K1_isinf((ECP_SECP256K1 *)&e->val));
	secp_clone_free(L, e);
	END(1);
}

/***
    Add two SECP points.

    @function add
    @param other another SECP point
    @return sum P + Q
*/
static int secp_add(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const secp *e = secp_arg(L, 1);
	const secp *q = secp_arg(L, 2);
	SAFE_GOTO(e && q, ALLOCATE_ECP_ERR);
	secp *p = secp_dup(L, e); SAFE_GOTO(p, DUPLICATE_ECP_ERR);
	ECP_SECP256K1_add(&p->val, (ECP_SECP256K1 *)&q->val);
end:
	secp_clone_free(L, q);
	secp_clone_free(L, e);
	if (failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Subtract one SECP point from another.

    @function sub
    @param other SECP point to subtract
    @return difference P - Q
*/
static int secp_sub(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const secp *e = secp_arg(L, 1);
	const secp *q = secp_arg(L, 2);
	SAFE_GOTO(e && q, ALLOCATE_ECP_ERR);
	secp *p = secp_dup(L, e); SAFE_GOTO(p, DUPLICATE_ECP_ERR);
	ECP_SECP256K1_sub(&p->val, (ECP_SECP256K1 *)&q->val);
end:
	secp_clone_free(L, q);
	secp_clone_free(L, e);
	if (failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Return the negation of a SECP point.

    @function negative
    @return -P
*/
static int secp_negative(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const secp *in = secp_arg(L, 1); SAFE_GOTO(in, ALLOCATE_ECP_ERR);
	secp *out = secp_dup(L, in); SAFE_GOTO(out, DUPLICATE_ECP_ERR);
	ECP_SECP256K1_neg(&out->val);
end:
	secp_clone_free(L, in);
	if (failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Double a SECP point.

    @function double
    @return 2*P
*/
static int secp_double(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const secp *in = secp_arg(L, 1); SAFE_GOTO(in, ALLOCATE_ECP_ERR);
	secp *out = secp_dup(L, in); SAFE_GOTO(out, DUPLICATE_ECP_ERR);
	ECP_SECP256K1_dbl(&out->val);
end:
	secp_clone_free(L, in);
	if (failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Multiply a SECP point by a scalar (32-byte OCTET).

    @function mul
    @param scalar 32-byte OCTET scalar (0 <= k < order)
    @return k * P
*/
static int secp_mul(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const secp *e = NULL;
	const octet *scalar = NULL;
	int sepos = 0, octpos = 0;
	/* argument order: SECP * scalar or scalar * SECP */
	sepos = luaL_testudata(L, 1, "zenroom.secp") ? 1 : 0;
	if (!sepos) sepos = luaL_testudata(L, 2, "zenroom.secp") ? 2 : 0;
	SAFE_GOTO(sepos, "SECP not found among multiplication arguments");
	octpos = lua_type(L, 1) == LUA_TUSERDATA ? 2 : 1;
	e = secp_arg(L, sepos); SAFE_GOTO(e, ALLOCATE_ECP_ERR);
	scalar = o_arg(L, octpos); SAFE_GOTO(scalar, ALLOCATE_OCT_ERR);
	SAFE_GOTO(scalar->len == SECP_BYTES, "scalar must be 32 bytes");
	secp *out = secp_dup(L, e); SAFE_GOTO(out, DUPLICATE_ECP_ERR);
	BIG_256_28 k;
	BIG_256_28_fromBytesLen(k, (char *)scalar->val, SECP_BYTES);
	ECP_SECP256K1_mul(&out->val, k);
end:
	secp_clone_free(L, e);
	o_free(L, scalar);
	if (failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Compare two SECP points for equality.

    @function eq
    @param other another SECP point
    @return true if equal, false otherwise
*/
static int secp_eq(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const secp *p = secp_arg(L, 1);
	const secp *q = secp_arg(L, 2);
	SAFE_GOTO(p && q, ALLOCATE_ECP_ERR);
	ECP_SECP256K1_affine((ECP_SECP256K1 *)&p->val);
	ECP_SECP256K1_affine((ECP_SECP256K1 *)&q->val);
	lua_pushboolean(L, ECP_SECP256K1_equals(
	                (ECP_SECP256K1 *)&p->val, (ECP_SECP256K1 *)&q->val));
end:
	secp_clone_free(L, p);
	secp_clone_free(L, q);
	if (failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/* convert a point to compressed (33-byte) octet */
static int _secp_to_octet_compressed(octet *o, const secp *e) {
	if (ECP_SECP256K1_isinf((ECP_SECP256K1 *)&e->val)) {
		o->val[0] = SCHAR_MAX; o->val[1] = SCHAR_MAX;
		o->val[2] = 0x0; o->len = 2;
		return 1;
	}
	ECP_SECP256K1_toOctet(o, (ECP_SECP256K1 *)&e->val, true);
	return 1;
}

/***
    Return the compressed (33-byte) serialization of the SECP point.

    @function octet
    @return 33-byte compressed OCTET (0x02 for even y, 0x03 for odd y)
    This is the default serialization (alias for compressed).
*/
static int secp_octet(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const secp *e = secp_arg(L, 1); SAFE_GOTO(e, ALLOCATE_ECP_ERR);
	octet *o = o_new(L, SECP_COMPRESSED + 1); SAFE_GOTO(o, CREATE_OCT_ERR);
	_secp_to_octet_compressed(o, e);
end:
	secp_clone_free(L, e);
	if (failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Return the compressed (33-byte) serialization.

    @function compressed
    @return 33-byte compressed OCTET
*/
static int secp_compressed(lua_State *L) {
	return secp_octet(L);
}

/***
    Return the uncompressed (65-byte) serialization (0x04 + x + y).

    @function uncompressed
    @return 65-byte uncompressed OCTET
*/
static int secp_uncompressed(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const secp *e = secp_arg(L, 1); SAFE_GOTO(e, ALLOCATE_ECP_ERR);
	octet *o = o_new(L, SECP_UNCOMPRESSED + 1); SAFE_GOTO(o, CREATE_OCT_ERR);
	if (ECP_SECP256K1_isinf((ECP_SECP256K1 *)&e->val)) {
		o->val[0] = SCHAR_MAX; o->val[1] = SCHAR_MAX;
		o->val[2] = 0x0; o->len = 2;
		goto end;
	}
	ECP_SECP256K1_toOctet(o, (ECP_SECP256K1 *)&e->val, false);
end:
	secp_clone_free(L, e);
	if (failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Return the x-only (32-byte) serialization of the point.

    @function xonly
    @return 32-byte OCTET containing the x coordinate
*/
static int secp_xonly(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const secp *e = secp_arg(L, 1); SAFE_GOTO(e, ALLOCATE_ECP_ERR);
	ECP_SECP256K1_affine((ECP_SECP256K1 *)&e->val);
	BIG_256_28 x, y;
	ECP_SECP256K1_get(x, y, (ECP_SECP256K1 *)&e->val);
	secp_big_to_oct(L, x);
end:
	secp_clone_free(L, e);
	if (failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Return the x coordinate as a 32-byte OCTET.

    @function x
    @return 32-byte OCTET containing the x coordinate
*/
static int secp_get_x(lua_State *L) {
	return secp_xonly(L);
}

/***
    Return the y coordinate as a 32-byte OCTET.

    @function y
    @return 32-byte OCTET containing the y coordinate
*/
static int secp_get_y(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const secp *e = secp_arg(L, 1); SAFE_GOTO(e, ALLOCATE_ECP_ERR);
	ECP_SECP256K1_affine((ECP_SECP256K1 *)&e->val);
	BIG_256_28 x, y;
	ECP_SECP256K1_get(x, y, (ECP_SECP256K1 *)&e->val);
	secp_big_to_oct(L, y);
end:
	secp_clone_free(L, e);
	if (failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    String representation: hex-encoded compressed point.

    @function __tostring
    @return hex string of compressed serialization
*/
static int secp_output(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const secp *e = secp_arg(L, 1); SAFE_GOTO(e, ALLOCATE_ECP_ERR);
	if (ECP_SECP256K1_isinf((ECP_SECP256K1 *)&e->val)) {
		octet *o = o_new(L, 3); SAFE_GOTO(o, CREATE_OCT_ERR);
		o->val[0] = SCHAR_MAX; o->val[1] = SCHAR_MAX;
		o->val[2] = 0x0; o->len = 2;
		goto end;
	}
	octet *o = o_new(L, SECP_COMPRESSED + 1); SAFE_GOTO(o, CREATE_OCT_ERR);
	_secp_to_octet_compressed(o, e);
	push_octet_to_hex_string(L, o);
end:
	secp_clone_free(L, e);
	if (failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int secp_destroy(lua_State *L) {
	(void)L;
	return 0;
}

/* --- BIP-340 Schnorr helpers --- */

int secp_bip340_seckey_valid(const octet *o) {
	if (!o || o->len != SECP_BYTES) return 0;
	BIG_256_28 d, order, zero;
	BIG_256_28_fromBytesLen(d, (char *)o->val, SECP_BYTES);
	BIG_256_28_copy(order, (chunk *)CURVE_Order_SECP256K1);
	BIG_256_28_zero(zero);
	if (BIG_256_28_comp(d, zero) == 0) return 0;
	if (BIG_256_28_comp(d, order) >= 0) return 0;
	return 1;
}

void secp_bip340_scalar_negate(BIG_256_28 k) {
	BIG_256_28 n;
	BIG_256_28_copy(n, (chunk *)CURVE_Order_SECP256K1);
	BIG_256_28_sub(k, n, k);
	BIG_256_28_norm(k);
}

void secp_bip340_sign_response(BIG_256_28 s, const BIG_256_28 k,
                               const BIG_256_28 e, const BIG_256_28 d) {
	BIG_256_28 ed, n;
	BIG_256_28_copy(n, (chunk *)CURVE_Order_SECP256K1);
	/* s = (k + e*d) mod n */
	/* compute ed = e * d (with double-precision intermediate) */
	DBIG_256_28 ded;
	BIG_256_28_mul(ded, (chunk *)e, (chunk *)d);  /* cast away const for Milagro API */
	BIG_256_28_dmod(ed, ded, n);
	BIG_256_28_add(s, k, ed);
	BIG_256_28_norm(s);
	if (BIG_256_28_comp(s, n) >= 0) {
		BIG_256_28_sub(s, s, n);
		BIG_256_28_norm(s);
	}
}

void secp_bip340_challenge(BIG_256_28 e, const octet *hash32) {
	BIG_256_28 n;
	BIG_256_28_fromBytesLen(e, (char *)hash32->val, SECP_BYTES);
	BIG_256_28_copy(n, (chunk *)CURVE_Order_SECP256K1);
	BIG_256_28_mod(e, n);
}

octet *secp_bip340_tagged_hash(lua_State *L, const char *tag, const octet *data) {
	/* tagged_hash(tag, data) = sha256(sha256(tag) || sha256(tag) || data) */
	hash256 H;
	char taghash[32], result[32];
	size_t i;

	/* sha256(tag) */
	HASH256_init(&H);
	for (i = 0; tag[i]; i++) HASH256_process(&H, (unsigned char)tag[i]);
	HASH256_hash(&H, taghash);

	/* sha256(sha256(tag) || sha256(tag) || data) */
	HASH256_init(&H);
	for (i = 0; i < 32; i++) HASH256_process(&H, (unsigned char)taghash[i]);
	for (i = 0; i < 32; i++) HASH256_process(&H, (unsigned char)taghash[i]);
	for (i = 0; i < data->len; i++) HASH256_process(&H, data->val[i]);
	HASH256_hash(&H, result);

	octet *o = o_new(L, SECP_BYTES);
	if (!o) return NULL;
	memcpy((char *)o->val, result, SECP_BYTES);
	o->len = SECP_BYTES;
	return o;
}

int secp_bip340_lift_x(ECP_SECP256K1 *P, const octet *xo) {
	if (!xo || xo->len != SECP_BYTES) return 0;
	BIG_256_28 x;
	BIG_256_28_fromBytesLen(x, (char *)xo->val, SECP_BYTES);
	/* check x < p */
	BIG_256_28 p;
	BIG_256_28_rcopy(p, Modulus_SECP256K1);
	if (BIG_256_28_comp(x, p) >= 0) return 0;
	/* setx with s=0 gives y with parity matching s */
	if (!ECP_SECP256K1_setx(P, x, 0)) return 0;
	/* Check if y is even (LSB = 0).  setx(s, 0) selects y where
	 * the LSB matches s. If LSB != 0, we need to negate. */
	BIG_256_28 bx, by;
	ECP_SECP256K1_affine(P);
	ECP_SECP256K1_get(bx, by, P);
	/* Check LSB of y: BIG_256_28 is stored in base 2^28, check byte 31 LSB */
	char ybytes[MODBYTES_256_28];
	BIG_256_28_toBytes(ybytes, by);
	int y_lsb = ybytes[MODBYTES_256_28 - 1] & 1;
	if (y_lsb) {
		ECP_SECP256K1_neg(P);
	}
	return 1;
}

/* --- Lua-callable BIP-340 helpers --- */

/***
    Validate a BIP-340 secret key: exactly 32 bytes, 1 <= d < n.

    @function bip340_seckey_valid
    @param sk 32-byte OCTET secret key
    @return true if valid, false otherwise
*/
static int lua_bip340_seckey_valid(lua_State *L) {
	BEGIN();
	const octet *o = o_arg(L, 1); SAFE(o, ALLOCATE_OCT_ERR);
	lua_pushboolean(L, secp_bip340_seckey_valid(o));
	o_free(L, o);
	END(1);
}

/***
    Compute BIP-0340 tagged hash: sha256(sha256(tag) || sha256(tag) || data).

    @function bip340_tagged_hash
    @param tag a string (e.g. "BIP0340/challenge")
    @param data an OCTET to hash
    @return 32-byte OCTET hash digest
*/
static int lua_bip340_tagged_hash(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	size_t taglen;
	const char *tag = lua_tolstring(L, 1, &taglen);
	const octet *data = o_arg(L, 2);
	SAFE_GOTO(tag && data, "bip340_tagged_hash: tag and data required");
	octet *o = secp_bip340_tagged_hash(L, tag, data);
	SAFE_GOTO(o, "bip340_tagged_hash: allocation failed");
end:
	o_free(L, data);
	if (failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Lift an x-only (32-byte) octet to a SECP point with even y.

    @function bip340_lift_x
    @param x 32-byte OCTET x coordinate
    @return SECP point with even y, or nil if x is not on the curve
*/
static int lua_bip340_lift_x(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *xo = o_arg(L, 1); SAFE_GOTO(xo, ALLOCATE_OCT_ERR);
	SAFE_GOTO(xo->len == SECP_BYTES, "lift_x: x must be 32 bytes");
	secp *e = secp_new(L); SAFE_GOTO(e, CREATE_ECP_ERR);
	if (!secp_bip340_lift_x(&e->val, xo)) {
		lua_pop(L, 1);
		failed_msg = "lift_x: no point on curve for this x";
		goto end;
	}
end:
	o_free(L, xo);
	if (failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}


/***
    Add two 32-byte scalars modulo n. Returns 32-byte OCTET.

    @function bip340_scalar_add
    @param a 32-byte OCTET
    @param b 32-byte OCTET
    @return 32-byte OCTET (a + b) mod n
*/
static int lua_bip340_scalar_add(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *oa = o_arg(L, 1); SAFE_GOTO(oa, ALLOCATE_OCT_ERR);
	const octet *ob = o_arg(L, 2); SAFE_GOTO(ob, ALLOCATE_OCT_ERR);
	SAFE_GOTO(oa->len == SECP_BYTES && ob->len == SECP_BYTES, "scalars must be 32 bytes");
	BIG_256_28 a, b, n, s;
	BIG_256_28_fromBytesLen(a, (char *)oa->val, SECP_BYTES);
	BIG_256_28_fromBytesLen(b, (char *)ob->val, SECP_BYTES);
	BIG_256_28_copy(n, (chunk *)CURVE_Order_SECP256K1);
	BIG_256_28_add(s, a, b);
	BIG_256_28_norm(s);
	if (BIG_256_28_comp(s, n) >= 0) {
		BIG_256_28_sub(s, s, n);
		BIG_256_28_norm(s);
	}
	secp_big_to_oct(L, s);
end:
	o_free(L, oa);
	o_free(L, ob);
	if (failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Multiply two 32-byte scalars modulo n. Returns 32-byte OCTET.

    @function bip340_scalar_mul
    @param a 32-byte OCTET
    @param b 32-byte OCTET
    @return 32-byte OCTET (a * b) mod n
*/
static int lua_bip340_scalar_mul(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *oa = o_arg(L, 1); SAFE_GOTO(oa, ALLOCATE_OCT_ERR);
	const octet *ob = o_arg(L, 2); SAFE_GOTO(ob, ALLOCATE_OCT_ERR);
	SAFE_GOTO(oa->len == SECP_BYTES && ob->len == SECP_BYTES, "scalars must be 32 bytes");
	BIG_256_28 a, b, n, p;
	DBIG_256_28 dp;
	BIG_256_28_fromBytesLen(a, (char *)oa->val, SECP_BYTES);
	BIG_256_28_fromBytesLen(b, (char *)ob->val, SECP_BYTES);
	BIG_256_28_copy(n, (chunk *)CURVE_Order_SECP256K1);
	BIG_256_28_mul(dp, a, b);
	BIG_256_28_dmod(p, dp, n);
	secp_big_to_oct(L, p);
end:
	o_free(L, oa);
	o_free(L, ob);
	if (failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Divide two 32-byte scalars modulo n. Returns 32-byte OCTET.

    @function bip340_scalar_div
    @param a 32-byte OCTET
    @param b 32-byte non-zero OCTET
    @return 32-byte OCTET (a / b) mod n
*/
static int lua_bip340_scalar_div(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *oa = NULL;
	const octet *ob = NULL;
	oa = o_arg(L, 1); SAFE_GOTO(oa, ALLOCATE_OCT_ERR);
	ob = o_arg(L, 2); SAFE_GOTO(ob, ALLOCATE_OCT_ERR);
	SAFE_GOTO(oa->len == SECP_BYTES && ob->len == SECP_BYTES, "scalars must be 32 bytes");
	BIG_256_28 a, b, n, zero, q;
	BIG_256_28_fromBytesLen(a, (char *)oa->val, SECP_BYTES);
	BIG_256_28_fromBytesLen(b, (char *)ob->val, SECP_BYTES);
	BIG_256_28_copy(n, (chunk *)CURVE_Order_SECP256K1);
	BIG_256_28_zero(zero);
	BIG_256_28_mod(a, n);
	BIG_256_28_mod(b, n);
	SAFE_GOTO(BIG_256_28_comp(b, zero) != 0, "scalar divisor must be non-zero");
	BIG_256_28_moddiv(q, a, b, n);
	BIG_256_28_norm(q);
	secp_big_to_oct(L, q);
end:
	o_free(L, oa);
	o_free(L, ob);
	if (failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Negate a 32-byte scalar modulo n. Returns 32-byte OCTET.

    @function bip340_scalar_negate
    @param x 32-byte OCTET
    @return 32-byte OCTET n - x mod n
*/
static int lua_bip340_scalar_negate(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *ox = o_arg(L, 1); SAFE_GOTO(ox, ALLOCATE_OCT_ERR);
	SAFE_GOTO(ox->len == SECP_BYTES, "scalar must be 32 bytes");
	BIG_256_28 x;
	BIG_256_28_fromBytesLen(x, (char *)ox->val, SECP_BYTES);
	secp_bip340_scalar_negate(x);
	secp_big_to_oct(L, x);
end:
	o_free(L, ox);
	if (failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Reduce a 32-byte hash value modulo the curve order.

    @function bip340_challenge_reduce
    @param hash32 32-byte OCTET (SHA-256 output)
    @return 32-byte OCTET hash32 mod n
*/
static int lua_bip340_challenge_reduce(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *oh = o_arg(L, 1); SAFE_GOTO(oh, ALLOCATE_OCT_ERR);
	SAFE_GOTO(oh->len == SECP_BYTES, "hash must be 32 bytes");
	BIG_256_28 e;
	secp_bip340_challenge(e, oh);
	secp_big_to_oct(L, e);
end:
	o_free(L, oh);
	if (failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
    Map an OCTET of exactly 64 bytes to a point on the secp256k1 curve.
    Uses Milagro's hash-to-point mapping.

    @function mapit
    @param OCTET 64-byte hash output
    @return SECP point on secp256k1
*/
static int secp_mapit(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *o = o_arg(L, 1); SAFE_GOTO(o, ALLOCATE_OCT_ERR);
	SAFE_GOTO(o->len == 64, "Invalid argument, octet must be 64 bytes");
	secp *e = secp_new(L); SAFE_GOTO(e, CREATE_ECP_ERR);
	func(L, "mapit on o->len %u", o->len);
	ECP_SECP256K1_mapit(&e->val, (octet *)o);
end:
	o_free(L, o);
	if (failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/* --- module registration --- */

int luaopen_secp(lua_State *L) {
	(void)L;
	const struct luaL_Reg secp_class[] = {
		{"new", lua_new_secp},
		{"from_xy", lua_from_xy},
		{"inf", secp_get_infinity},
		{"infinity", secp_get_infinity},
		{"isinf", secp_isinf},
		{"order", secp_order},
		{"prime", secp_prime},
		{"rhs", secp_rhs},
		{"validate", secp_validate},
		{"mapit", secp_mapit},
		{"generator", secp_generator},
		{"G", secp_generator},
		{"bip340_seckey_valid", lua_bip340_seckey_valid},
		{"bip340_tagged_hash", lua_bip340_tagged_hash},
		{"bip340_lift_x", lua_bip340_lift_x},
		{"bip340_scalar_add", lua_bip340_scalar_add},
		{"bip340_scalar_mul", lua_bip340_scalar_mul},
		{"bip340_scalar_div", lua_bip340_scalar_div},
		{"bip340_scalar_negate", lua_bip340_scalar_negate},
		{"bip340_challenge_reduce", lua_bip340_challenge_reduce},
		{NULL, NULL}};
	const struct luaL_Reg secp_methods[] = {
		{"affine", secp_affine},
		{"negative", secp_negative},
		{"double", secp_double},
		{"isinf", secp_isinf},
		{"isinfinity", secp_isinf},
		{"octet", secp_octet},
		{"compressed", secp_compressed},
		{"uncompressed", secp_uncompressed},
		{"xonly", secp_xonly},
		{"add", secp_add},
		{"sub", secp_sub},
		{"mul", secp_mul},
		{"x", secp_get_x},
		{"y", secp_get_y},
		{"__add", secp_add},
		{"__sub", secp_sub},
		{"__mul", secp_mul},
		{"eq", secp_eq},
		{"__eq", secp_eq},
		{"__gc", secp_destroy},
		{"__tostring", secp_output},
		{NULL, NULL}};
	zen_add_class(L, "secp", secp_class, secp_methods);

	act(L, "SECP curve is secp256k1");
	return 1;
}
