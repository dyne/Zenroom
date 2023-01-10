/*
 * This file is part of zenroom
 * 
 * Copyright (C) 2017-2021 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
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
 * 
 * Last modified by Denis Roio
 * on Monday, 9th August 2021
 */

#include <math.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <zen_error.h>
#include <lua_functions.h>

#include <amcl.h>

#include <zenroom.h>
#include <zen_octet.h>
#include <zen_memory.h>
#include <zen_big.h>
#include <zen_ecp_factory.h> // for CURVE_Order

// defined at compile time in zen_ecp.c for specific BLS
extern const chunk *ORDER;

/// <h1>Big Number Arithmetic (BIG)</h1>
//
// Base arithmetical operations on big numbers.
//
// Most operators are overloaded and can be used on BIG numbers as if they would be natural. Multiplications by @{ECP} curve points are also possible using ECP as first argument.
//
// For explanations and example usage see <a href="https://dev.zenroom.org/crypto">dev.zenroom.org/crypto</a>.
//
//  @module BIG
//  @author Denis "Jaromil" Roio
//  @license AGPLv3
//  @copyright Dyne.org foundation 2017-2018

extern int octet_to_hex(lua_State *L);

extern ecp* ecp_dup(lua_State *L, ecp* in);

// to copy contents from BIG to DBIG
#define dcopy(d,s) BIG_dscopy(d,s);
#define iszero(b) BIG_iszilch(b)
#define isdzero(d) BIG_diszilch(d)

// temporary bring all arguments to DBIG
// generates local variables _l(eft) and _r(right)
#define godbig2(l,r)	  \
	chunk *_l, *_r; \
	DBIG ll, lr; \
	if   (l->doublesize)     _l = l->dval; \
	else { dcopy(ll,l->val); _l = (chunk*)&ll; } \
	if   (r->doublesize)     _r = r->dval; \
	else { dcopy(lr,r->val); _r = (chunk*)&lr; }

// zerror(L, "error in %s %u", __FUNCTION__, __LINE__);

#define checkalldouble(l,r) \
	if(!l->val && !l->dval) { \
		failed_msg = "uninitialised big in arg1"; } \
	if(!r->val && !r->dval) { \
		failed_msg = "uninitialised big in arg2"; } \
	if(l->doublesize && !r->doublesize) { \
		failed_msg = "incompatible sizes: arg1 is double, arg2 is not"; \
	} else if(r->doublesize && !l->doublesize) { \
		failed_msg = "incompatible sizes: arg2 is double, arg1 is not"; \
	}


int _octet_to_big(lua_State *L, big *dst, octet *src) {
	int i;
	Z(L);
	if(src->len <= MODBYTES) { // big
		big_init(L,dst);
		BIG_zero(dst->val);
		// BIG *d = dst->val;
		for(i=0; i<src->len; i++) {
			BIG_fshl(dst->val,8);
			dst->val[0] += (int)(unsigned char) src->val[i];
		}
	} else if(src->len > MODBYTES && src->len <= MODBYTES<<1) {
		dbig_init(L,dst);
		BIG_dzero(dst->dval);
		for(i=0; i<src->len; i++) {
			BIG_dshl(dst->dval,8);
			dst->dval[0] += (int)(unsigned char) src->val[i];
		}
//		dst->dval[0] += (int)(unsigned char) src->val[i];
	} else {
		return(0);
	}
	// set to curve's MODLEN by d/big_init(L,)
	// dst->len = i;
	return(i);
}

void big_free(lua_State *L, big *b) {
	Z(L);
	if(b) {
		free(b);
		Z->memcount_bigs--;
	}
}

big* big_new(lua_State *L) {
	big *c = (big *)lua_newuserdata(L, sizeof(big));
	if(!c) {
		lerror(L, "Error allocating new big in %s",__func__);
		return NULL; }
	luaL_getmetatable(L, "zenroom.big");
	lua_setmetatable(L, -2);
	strcpy(c->name,"big384");
	// c->len = modbytes;
	c->chunksize = CHUNK;
	c->doublesize = 0;
	c->val = NULL;
	c->dval = NULL;
	c->zencode_positive = BIG_POSITIVE;
	return(c);
}

big* big_arg(lua_State *L,int n) {
	Z(L);
	big* result = (big*)malloc(sizeof(big));
	strcpy(result->name,"big384");
	result->chunksize = CHUNK;
	result->doublesize = 0;
	result->val = NULL;
	result->dval = NULL;
	result->zencode_positive = BIG_POSITIVE;
	void *ud = luaL_testudata(L, n, "zenroom.big");
	if(ud) {
		*result = *(big*)ud;
		if(!result->val && !result->dval) {
			zerror(L, "invalid big number in argument: not initalized");
			big_free(L,result);
			return NULL; }
		if(result) Z->memcount_bigs++;
		return(result);
	}

	octet *o = o_arg(L,n);
	if(o) {
		if(!_octet_to_big(L,result,o)) {
			big_free(L,result);
			result = NULL;
		}
		o_free(L,o);
		if(result) Z->memcount_bigs++;
		return(result);
	}
	zerror(L, "invalib big number in argument");
	big_free(L,result);
	return NULL;
}

// allocates a new big in LUA, duplicating the one in arg
big *big_dup(lua_State *L, big *s) {
	SAFE(s);
	big *n = big_new(L);
	if(s->doublesize) {
		dbig_init(L,n);
		BIG_dcopy(n->dval, s->dval);
	} else {
		big_init(L,n);
		BIG_rcopy(n->val,s->val);
	}
	n->zencode_positive = s->zencode_positive;
	return(n);
}

int big_destroy(lua_State *L) {
	big *c = (big*)luaL_testudata(L, 1, "zenroom.big");
	if(c) {
		if(c->doublesize) {
			if(c->dval) free(c->dval);
			if(c->val) warning(L,"found leftover buffer while freeing double big");
		} else {
			if(c->val) free(c->val);
			if(c->dval) warning(L,"found leftover buffer while freeing big");
		}
	}
	return 0;
}

int _bitsize(big *b) {
	double bits;
	if(b->doublesize)
		bits = BIG_dnbits(b->dval);
	else
		bits = BIG_nbits(b->val);
	return bits;
}

static int big_bits(lua_State *L) {
	BEGIN();
	big *d = big_arg(L,1);
	if(d) {
		lua_pushinteger(L,_bitsize(d));
		big_free(L, d);
	} else {
		THROW("Could not read big argument");
	}
	END(1);
}
static int big_bytes(lua_State *L) {
	BEGIN();
	big *d = big_arg(L,1);
	if(d) {
		lua_pushinteger(L,ceil(_bitsize(d)/8));
		big_free(L, d);
	} else {
		THROW("Could not read big argument");
	}
	// lua_pushinteger(L,d->len);
	END(1);
}

int big_init(lua_State *L,big *n) {
	if(n->val && !n->doublesize) {
		func(L,"ignoring superflous initialization of big");
		return(1); }
	if(n->dval || n->doublesize) {
		zerror(L, "cannot shrink double big to big in re-initialization");
		return 0; }
	if(!n->val && !n->dval) {
		size_t size = sizeof(BIG);
		n->val = (int*)malloc(size);
		n->doublesize = 0;
		n->len = MODBYTES;
		return(size);
	}
	zerror(L, "anomalous state of big number detected on initialization");
	return(-1);
}

int dbig_init(lua_State *L,big *n) {
	if(n->dval && n->doublesize) {
		func(L,"ignoring superflous initialization of double big");
		return(1); }
	size_t size = sizeof(DBIG); //sizeof(DBIG); // modbytes * 2, aka n->len<<1
	if(n->val && !n->doublesize) {
		n->doublesize = 1;
		n->dval = (int*)malloc(size);
		// extend from big to double big
		BIG_dscopy(n->dval,n->val);
		free(n->val);
		n->len = MODBYTES<<1;
	}
	if(!n->val || !n->dval) {
		n->doublesize = 1;
		n->dval = (int*)malloc(size);
		n->len = MODBYTES<<1;
		return(size);
	}
	zerror(L, "anomalous state of double big number detected on initialization");
	return(-1);
}

// give information about BIG numbers internal formats
static int lua_biginfo(lua_State *L) {
	BEGIN();
	lua_newtable(L);
	lua_pushinteger(L,BIGLEN);
	lua_setfield(L,1,"biglen");
	lua_pushinteger(L,DBIGLEN);
	lua_setfield(L,1,"dbiglen");
	lua_pushinteger(L,MODBYTES);
	lua_setfield(L,1,"modbytes");
	lua_pushinteger(L,(unsigned int)sizeof(BIG));
	lua_setfield(L,1,"sizeof_BIG");
	lua_pushinteger(L,(unsigned int)sizeof(DBIG));
	lua_setfield(L,1,"sizeof_DBIG");
	END(1);
}

// return the max value expressed by MODBYTES big to 0xff
// TODO: fix this to return something usable in modmul
static int lua_bigmax(lua_State *L) {
	BEGIN();
	big *b = big_new(L); SAFE(b);
	big_init(L, b);
	register int c;
	for(c=0 ; c < b->len ; c++) b->val[c] = 0xffffffff;
	END(1);
}

/***
    Create a new Big number. If an argument is present, import it as @{OCTET} and initialise it with its value.

    @param[opt] octet value
    @return a new Big number
    @function BIG.new(octet)
*/
static int newbig(lua_State *L) {
	BEGIN();
	void *ud;
	// kept for backward compat with zenroom 0.9
	ud = luaL_testudata(L, 2, "zenroom.big");
	if(ud) {
		warning(L, "use of RNG deprecated");
		big *res = big_new(L); big_init(L,res); SAFE(res);
		// random with modulus
		big *modulus = (big*)ud; SAFE(modulus);
		Z(L);
		BIG_randomnum(res->val,modulus->val,Z->random_generator);
		return 1;
	}

	// number argument, import
	int tn;
	lua_Number n = lua_tointegerx(L,1,&tn);
	if(tn) {
		if(n > 0xffff)
			warning(L, "Import of number to BIG limit exceeded (>16bit)");
		big *c = big_new(L); SAFE(c);
		big_init(L,c);
		BIG_zero(c->val);
		if((int)n>0)
			BIG_inc(c->val, (int)n);
		return 1; }

	// octet argument, import
	octet *o = o_arg(L, 1);
	if(!o) {
		zerror(L, "Could not allocate octet");
		return 0;
	}
	if(o->len > MODBYTES) {
		zerror(L, "Import of octet to BIG limit exceeded (%u > %u bytes)", o->len, MODBYTES);
		return 0; }
	big *c = big_new(L);
	if(!c) {
		zerror(L, "Could not allocate big");
		return 0;
	}
	_octet_to_big(L, c,o);
	o_free(L,o);
	END(1);
}

octet *new_octet_from_big(lua_State *L, big *c) {
	int i;
	octet *o;
	if(c->doublesize && c->dval) {
		if (isdzero(c->dval)) { // zero
			o = o_alloc(L, 1);
			o->val[0] = 0x0;
			o->len = 1;
		} else {
			DBIG t; BIG_dcopy(t,c->dval); BIG_dnorm(t);
			o = o_alloc(L, c->len);
			for(i=c->len-1; i>=0; i--) {
				o->val[i]=t[0]&0xff;
				BIG_dshr(t,8);
			}
			o->len = c->len;
		}
	} else if(c->val) {
		if (iszero(c->val)) { // zero
			o = o_alloc(L, 1);
			o->val[0] = 0x0;
			o->len = 1;
		} else {
			// fshr is destructive so use a copy
			BIG t; BIG_copy(t,c->val); BIG_norm(t);
			o = o_alloc(L, c->len);
			for(i=c->len-1; i>=0; i--) {
				o->val[i] = t[0]&0xff;
				BIG_fshr(t,8);
			}
			o->len = c->len;
		}
	} else {
		zerror(NULL,"Invalid BIG number, cannot convert to octet");
		return NULL;
	}
	// remove leading zeroes from octet
	if(o->val[0]==0x0 && o->len != 1) {
		int p;
		for(p = 0; p < o->len && o->val[p] == 0x0; p++);
		for(i=0; i < o->len-p; i++) o->val[i] = o->val[i+p];
		o->len = o->len-p;
	}
	return(o);
}

// Works only for positive numbers
static int big_from_decimal_string(lua_State *L) {
	BEGIN();
	const char *s = lua_tostring(L, 1);
	if(!s) {
		return 0;
	}
	big *num = big_new(L); SAFE(num);

	big_init(L,num);
	BIG_zero(num->val);
	int i = 0;
	if(s[i] == '-') {
		num->zencode_positive = BIG_NEGATIVE;
		i++;
	} else {
		num->zencode_positive = BIG_POSITIVE;
	}
	while(s[i] != '\0') {
		BIG res;
		BIG_copy(res, num->val);
		BIG_pmul(num->val, res, 10);

		//if (!isdigit(s[i])) {
		if (s[i] < '0' || s[i] > '9') {
			zerror(L, "%s: string is not a number %s", __func__, s);
			lerror(L, "operation aborted");
			return 0;
		}
		BIG_inc(num->val, (int)(s[i] - '0'));
		i++;
	}
	BIG_norm(num->val);
	END(1);
}
/*
  fixed size encoding for integer with big endian order
  @param num number that has to be coverted
  @param len bytes size
  @param big_endian use big endian order (if omitted by default is true)
*/
static int big_to_fixed_octet(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	int n_args = lua_gettop(L);
	octet *o = NULL;
	big *num = big_arg(L,1);
	if(!num) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	o = new_octet_from_big(L,num);
	if(!o) {
		failed_msg = "Could not create octet from BIG";
		goto end;
	}
	int i;
	lua_Number len = lua_tointegerx(L,2,&i);
	if(!i) {
		failed_msg = "O.from_number input is not a number";
		o_free(L, o);
		goto end;
	}

	int big_endian = 1;
	if(n_args > 2) {
		big_endian = lua_toboolean(L, 3);
	}
	int int_len = len;
	octet* padded_oct;
	if(o->len < len) {
		padded_oct = o_new(L, len);
		if(!padded_oct) {
			failed_msg = "Could not create octet";
			o_free(L, o);
			goto end;
		}
		for(i=0; i<o->len; i++) {
		  padded_oct->val[int_len-(o->len)+i] = o->val[i];
		}
		for(i=0; i<len-o->len; i++) {
			padded_oct->val[i] = '\0';
		}
		padded_oct->len = len;
	} else {
		padded_oct = o_dup(L, o);
	}
	o_free(L,o);
	o = padded_oct;
	if(!big_endian) {
		register int i=0, j=o->len-1;
		register char t;
		while(i < j) {
			t = o->val[j];
			o->val[j] = o->val[i];
			o->val[i] = t;
			i++; j--;
		}

	}
end:
	big_free(L,num);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/*
  Slow but only for export
  Works only for positive numbers
  @param num number to be converted (zenroom.big)
  @return string which represent a decimal number (only digits 0-9)
*/
// TODO: always show negative sign or put a flag?
static int big_to_decimal_string(lua_State *L) {
	BEGIN();
	big *num = big_arg(L,1);
	if (!num) {
		THROW("Could not read input number");
	} else if(num->doublesize || num->dval) {
		big_free(L, num);
		THROW("Integer too big to be exported");
	}
	BIG_norm(num->val);

	// I can modify safenum without loosing num
	BIG safenum;
	BIG_copy(safenum, num->val);
	BIG ten_power;
	BIG ten;

	BIG_zero(ten_power);
	BIG_inc(ten_power, 1);

	BIG_zero(ten);
	BIG_inc(ten, 10);
	int i = 0;
	int j;
	// Order of magnitude
	while (BIG_comp(ten_power,num->val)<=0) {
		BIG res;
		BIG_copy(res, ten_power);
		BIG_pmul(ten_power, res, 10);
		i++;
		BIG_norm(ten_power);
	}
	char *s = malloc(i+4);
	if (i == 0) {
		s[0] = '0';
		i++;
	} else {
		i = 0;
		while(!BIG_iszilch(safenum)) {
			// Read less significant digit
			BIG tmp;
			BIG_copy(tmp, safenum);
			BIG_mod(tmp, ten);
			s[i] = tmp[0]+'0';

			// Divide by 10 (remove the digit I have just read)
			DBIG dividend;
			BIG_dzero(dividend);
			BIG_dscopy(dividend, safenum);
			BIG_ddiv(safenum, dividend, ten);
			i++;
		}
		// In the end I will reverse and the last minus
		// will be at the beginning
		if(num->zencode_positive == BIG_NEGATIVE) {
			s[i] = '-'; i++;
		}
	}
	s[i]='\0';

	// Digits in the opposite order
	j = 0;
	i--;
	while(j < i) {
		char t;
		t = s[i];
		s[i] = s[j];
		s[j] = t;
		i--;
		j++;
	}
	lua_pushstring(L,s);
	free(s);
	big_free(L, num);
	END(1);
}


static int luabig_to_octet(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *c_oct = NULL;
	big *c = big_arg(L,1);
	if(!c) {
		failed_msg = "Could not read big";
		goto end;
	}
	c_oct = new_octet_from_big(L,c);
	if(!c_oct) {
		failed_msg = "Could not create octet from big";
		goto end;
	}
	o_dup(L, c_oct);
end:
	big_free(L,c);
	o_free(L,c_oct);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int big_concat(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *ol = NULL, *or = NULL;
	big *l = big_arg(L,1);
	big *r = big_arg(L,2);
	if(!r || !l) {
		failed_msg = "Could not read big";
		goto end;
	}
	ol = new_octet_from_big(L,l);
	lua_pop(L,1);
	or = new_octet_from_big(L,r);
	lua_pop(L,1);
	octet *d = o_new(L, ol->len + or->len);
	if(!d) {
		failed_msg = "Could not create big";
		goto end;
	}
	OCT_copy(d,ol);
	OCT_joctet(d,or);
end:
	o_free(L, or);
	o_free(L, ol);
	big_free(L,r);
	big_free(L,l);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int big_to_hex(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *o = NULL;
	big *a = big_arg(L,1);
	if(!a) {
		failed_msg = "Could not read big";
		goto end;
	}
	o = new_octet_from_big(L,a);
	if(!o) {
		failed_msg = "Could not create octet from big";
		goto end;
	}
	push_octet_to_hex_string(L,o);
end:
	o_free(L, o);
	big_free(L,a);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int big_to_int(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *o = NULL;
	big *a = big_arg(L,1);
	if(!a) {
		failed_msg = "Could not read big";
		goto end;
	}
	if(a->doublesize) {
		failed_msg = "BIG too big for conversion to integer";
		goto end;
	}
	o = new_octet_from_big(L,a);
	if(!o) {
		failed_msg = "Could not create octet from big";
	}
	int32_t res;
	res = o->val[0];
	if(o->len > 1) res = res <<8  | (uint32_t)o->val[1];
	if(o->len > 2) res = res <<16 | (uint32_t)o->val[2];
	if(o->len > 3) res = res <<24 | (uint32_t)o->val[3];
	if(o->len > 4) warning(L,"Number conversion bigger than 32bit, BIG truncated to 4 bytes");
	lua_pushinteger(L, (lua_Integer) res);
end:
	o_free(L, o);
	big_free(L,a);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int _compare_bigs(big *l, big *r, char *failed_msg) {
	int res = 0;
	checkalldouble(l,r);
	if(!failed_msg) {
		if(l->doublesize || r->doublesize) {
			godbig2(l,r);
			BIG_dnorm(_l);
			BIG_dnorm(_r);
			res = BIG_dcomp(_l,_r);
		} else {
			BIG_norm(l->val);
			BIG_norm(r->val);
			res = BIG_comp(l->val,r->val);
		}
	}
	return(res);
}

static int big_eq(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	big *l = big_arg(L,1);
	big *r = big_arg(L,2);
	if(!l || !r) {
		failed_msg = "Could not read big";
		goto end;
	}
	// BIG_comp requires external normalization
	int res = _compare_bigs(l,r,failed_msg);
	if(!failed_msg) {
		// -1 if x<y, 0 if x=y, 1 if x>y
		lua_pushboolean(L, (res==0)?1:0);
	}
end:
	big_free(L,r);
	big_free(L,l);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}
static int big_lt(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	big *l = big_arg(L,1);
	big *r = big_arg(L,2);
	if(!r || !l) {
		failed_msg = "Could not read big";
		goto end;
	}
	// BIG_comp requires external normalization
	int res = _compare_bigs(l,r,failed_msg);
	if(!failed_msg) {
		// -1 if x<y, 0 if x=y, 1 if x>y
		lua_pushboolean(L, (res<0)?1:0);
	}
end:
	big_free(L,l);
	big_free(L,r);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}
static int big_lte(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	big *l = big_arg(L,1);
	big *r = big_arg(L,2);
	if(!r || !l) {
		failed_msg = "Could not read big";
		goto end;
	}
	// BIG_comp requires external normalization
	int res = _compare_bigs(l,r,failed_msg);
	if(!failed_msg) {
		// -1 if x<y, 0 if x=y, 1 if x>y
		lua_pushboolean(L, (res<0)?1:(res==0)?1:0);
	}
end:
	big_free(L,r);
	big_free(L,l);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int big_add(lua_State *L) {
	BEGIN();
	big *l = big_arg(L,1);
	big *r = big_arg(L,2);
	big *d = big_new(L);
	if(l && r && d) {
		if(l->doublesize || r->doublesize) {
			func(L,"ADD doublesize");
			godbig2(l,r);
			dbig_init(L,d);
			BIG_dadd(d->dval, _l, _r);
			BIG_dnorm(d->dval);
		} else {
			big_init(L,d);
			BIG_add(d->val, l->val, r->val);
			BIG_norm(d->val);
		}
	}
	big_free(L,r);
	big_free(L,l);
	if(!l || !r || !d) {
		THROW("Could not create bigs");
	}
	END(1);
}

static int big_sub(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	big *l = big_arg(L,1);
	big *r = big_arg(L,2);
	big *d = big_new(L);
	if(!l || !r || !d) {
		failed_msg = "Could not create BIGs";
		goto end;
	}
	if(l->doublesize || r->doublesize) {
		godbig2(l, r);
		dbig_init(L,d);
		if(BIG_dcomp(_l,_r)<0) {
			failed_msg = "Subtraction error: arg1 smaller than arg2 (consider use of :modsub)";
			goto end;
		}
		BIG_dsub(d->dval, _l, _r);
		BIG_dnorm(d->dval);
	} else {
		// if(BIG_comp(l->val,r->val)<0) {
		// 	lerror(L,"Subtraction error: arg1 smaller than arg2");
		// 	return 0; }
		big_init(L,d);
		if(BIG_comp(l->val,r->val)<0) {
			BIG t;
			BIG_sub(t, r->val, l->val);
			BIG_sub(d->val, (chunk*)CURVE_Order, t);
		} else {
			BIG_sub(d->val, l->val, r->val);
			BIG_mod(d->val, (chunk*)CURVE_Order);
		}
		BIG_norm(d->val);
	}
end:
	big_free(L,r);
	big_free(L,l);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int big_modsub(lua_State *L) {
	BEGIN();
	big *l = big_arg(L,1);
	big *r = big_arg(L,2);
	big *m = big_arg(L,3);
	big *d = big_new(L);
	if(l && r && m && d) {
		big_init(L,d);
		if(l->doublesize || r->doublesize) {
			// temporary bring all to DBIG
			godbig2(l,r);
			if(BIG_dcomp(_l,_r)<0) { // if l < r
				// res = m - (r-l % m)
				DBIG t; BIG tm;
				BIG_dsub (t,  _r, _l);
				BIG_dmod (tm, t,   m->val);
				BIG_sub  (d->val,  m->val, tm);
			} else { // if l > r
				DBIG t;
				BIG_dsub(t  , _l, _r);
				BIG_dmod(d->val,t,m->val);
			}
		} else { // no DBIG involved
			if(BIG_comp(l->val,r->val)<0) {
				BIG t;
				BIG_sub(t, r->val, l->val);
				BIG_mod(t, m->val);
				BIG_sub(d->val, m->val, t);
			} else {
				BIG_sub(d->val, l->val, r->val);
				BIG_mod(d->val, m->val);
			}
		}
	}
	big_free(L,l);
	big_free(L,r);
	big_free(L,m);
	if(!l || !r || !m || !d) {
		THROW("Could not create BIGs");
	}
	END(1);
}



/***
    Generate a random Big number whose ceiling is defined by the modulo to another number.

    @param modulo another BIG number, usually @{ECP.order}
    @return a new Big number
    @function BIG.modrand(modulo)
*/

static int big_modrand(lua_State *L) {
	BEGIN();
	Z(L);
	big *modulus = big_arg(L,1);
	big *res = big_new(L);
	if(modulus && res) {
		big_init(L,res);
		BIG_randomnum(res->val,modulus->val,Z->random_generator);
	}
	big_free(L,modulus);
	if(!modulus || !res) {
		THROW("Could not create BIGs");
	}
	END(1);
}

/***
    Generate a random Big number whose ceiling is the order of the curve.

    @return a new Big number
    @function BIG.random()
*/

static int big_random(lua_State *L) {
	BEGIN();
	big *res = big_new(L); big_init(L,res); SAFE(res);
	Z(L);
	BIG_randomnum(res->val,(chunk*)CURVE_Order,Z->random_generator);
	END(1);
}

static int big_mul(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	big *l = big_arg(L,1);
	if(!l) {
		failed_msg = "Could not read big";
		goto end;
	}
	void *ud = luaL_testudata(L, 2, "zenroom.ecp");
	if(ud) {
		ecp *e = (ecp*)ud;
		if(l->doublesize) {
			failed_msg = "cannot multiply double BIG numbers with ECP point, need modulo";
			goto end;
		}

		// push result on stack
		ecp *out = ecp_dup(L,e);
		if(!out) {
			failed_msg = "Could not create ECP";
			goto end;
		}
		PAIR_G1mul(&out->val,l->val);
		// TODO: use unaccellerated multiplication for non-pairing curves
		// ECP_mul(&out->val,l->val);
	}
	else {
		big *r = big_arg(L,2);
		if(!r) {
			failed_msg = "Could not create BIG";
			goto end_big;
		}
		if(l->doublesize || r->doublesize) {
			failed_msg = "cannot multiply double BIG numbers";
			goto end_big;
		}
		// BIG_norm(l->val); BIG_norm(r->val);
		big *d = big_new(L);
		if(!d) {
			failed_msg = "Could not create BIG";
			goto end_big;
		}
		big_init(L,d);
		// dbig_init(L,d); // assume it always returns a double big
		// BIG_dzero(d->dval);
		BIG_modmul(d->val, l->val, r->val, (chunk*)CURVE_Order);
		BIG_norm(d->val);
end_big:
		big_free(L,r);
	}

end:
	big_free(L,l);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

// Square and multiply, not secure against side channel attacks
static int big_modpower(lua_State *L) {
	BEGIN();
	big *x = big_arg(L,1);
	big *n = big_arg(L,2);
	big *m = big_arg(L,3);
	big *res = big_new(L);
	if(x && n && m && res) {
		BIG safen;
		BIG_copy(safen, n->val);

		big_init(L,res);
		BIG_zero(res->val);
		BIG_inc(res->val, 1);

		BIG powerx;
		BIG_copy(powerx, x->val);

		BIG zero;
		BIG_zero(zero);

		while(BIG_comp(safen, zero) > 0) {
			if((safen[0] & 1) == 1) {
				// n odd
				BIG_modmul(res->val, res->val, powerx, m->val);
				BIG_dec(safen, 1);
			} else {
				// n even
				BIG tmp;
				BIG_modmul(tmp, powerx, powerx, m->val);
				BIG_copy(powerx, tmp);
				BIG_norm(safen);
				BIG_shr(safen, 1);
			}
		}
	}
	big_free(L,m);
	big_free(L,n);
	big_free(L,x);
	if(!x || !n || !m || !res) {
		THROW("Could not create BIGs");
	}
	END(1);
}

static int big_sqr(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	big *d = NULL;
	big *l = big_arg(L,1);
	if(!l) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	if(l->doublesize) {
		failed_msg = "cannot make square root of a double big number";
		goto end;
	}
	// BIG_norm(l->val); BIG_norm(r->val);
	// BIG_norm(l->val);
	d = big_new(L);
	if(!d) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	dbig_init(L,d); // assume it always returns a double big
	BIG_sqr(d->dval,l->val);
end:
	big_free(L,l);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int big_monty(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	big *m = NULL;
	big *s = big_arg(L,1);
	if(!s) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	if(!s->doublesize) {
		failed_msg = "no need for montgomery reduction: not a double big number";
		goto end;
	}
	m = big_arg(L,2);
	if(!m) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	if(m->doublesize) {
		failed_msg = "double big modulus in montgomery reduction";
		goto end;
	}
	big *d = big_new(L);
	if(!d) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	big_init(L,d);
	BIG_monty(d->val, m->val, Montgomery, s->dval);
end:
	big_free(L,m);
	big_free(L,s);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int big_mod(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	big *l = big_arg(L,1);
	big *r = big_arg(L,2);
	if(!l || !r) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	if(r->doublesize) {
		failed_msg = "modulus cannot be a double big (dmod)";
		goto end;
	}
	if(l->doublesize) {
		big *d = big_new(L);
		if(d) {
			big_init(L,d);
			DBIG t; BIG_dcopy(t, l->dval); // dmod destroys 2nd arg
			BIG_dmod(d->val, t, r->val);
		} else {
			failed_msg = "Could not create BIG";
			goto end;
		}
	} else {
		big *d = big_dup(L,l);
		if(d) {
			BIG_mod(d->val,r->val);
		} else {
			failed_msg = "Could not create BIG";
			goto end;
		}
	}
end:
	big_free(L,r);
	big_free(L,l);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int big_div(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	big *l = big_arg(L, 1);
	big *r = big_arg(L, 2);
	big *d = NULL;
	if(!l || !r) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	if(r->doublesize) {
		failed_msg = "division not supported with double big modulus";
		goto end;
	}
	d = big_dup(L, l);
	if(!d) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	if(l->doublesize) { // use ddiv on double big
		DBIG t; BIG_dcopy(t, l->dval); 	// in ddiv the 2nd arg is destroyed
		BIG_ddiv(d->val, t, r->val);
	} else { // use sdiv for normal bigs
		BIG_sdiv(d->val, r->val);
	}
end:
	big_free(L,r);
	big_free(L,l);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}


/***
    Multiply a BIG number by another BIG while ceiling the operation to a modulo to avoid excessive results. This operation is to be preferred to the simple overladed operator '*' in most cases where such a multiplication takes place. It may replace '*' in the future as a simplification.

    @param coefficient another BIG number
    @param modulo usually @{ECP.order}
    @return a new Big number
    @function BIG.modmul(coefficient, modulo)
*/
static int big_modmul(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	big *y = big_arg(L, 1);
	big *z = big_arg(L, 2);
	if(!y || !z) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	big *n = luaL_testudata(L, 3, "zenroom.big");
	big *x = big_new(L);
	if(!x) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	if(n) {
		if(y->doublesize || z->doublesize || n->doublesize) {
			failed_msg = "modmul not supported on double big numbers";
			goto end;
		}
		BIG t1, t2;
		BIG_copy(t1, y->val);
		BIG_copy(t2, z->val);
		big_init(L,x);
		BIG_modmul(x->val, t1, t2, n->val);
		BIG_norm(x->val);
	} else {
		// modulo default ORDER from ECP
		BIG t1, t2;
		BIG_copy(t1, y->val);
		BIG_copy(t2, z->val);
		big_init(L,x);
		BIG_modmul(x->val, t1, t2, (chunk*)CURVE_Order);
		BIG_norm(x->val);
	}
end:
	big_free(L,z);
	big_free(L,y);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int big_moddiv(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	big *y = big_arg(L, 1);
	big *div = big_arg(L, 2);
	big *mod = big_arg(L, 3);
	if(!y || !div || !mod) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	if(y->doublesize || div->doublesize || mod->doublesize) {
		failed_msg = "moddiv not supported on double big numbers";
		goto end;
	}
	BIG t;
	BIG_copy(t, y->val);
	big *x = big_new(L);
	if(!x) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	big_init(L,x);
	BIG_moddiv(x->val, t, div->val, mod->val);
	BIG_norm(x->val);
end:
	big_free(L,y);
	big_free(L,div);
	big_free(L,mod);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int big_modsqr(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	big *y = big_arg(L, 1);
	big *n = big_arg(L, 2);
	if(!y || !n) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	if(y->doublesize || n->doublesize) {
		failed_msg = "modsqr not supported on double big numbers";
		goto end;
	}
	BIG t;
	BIG_copy(t, y->val);
	big *x = big_new(L);
	if(!x) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	big_init(L,x);
	BIG_modsqr(x->val, t, n->val);
	BIG_norm(x->val);
end:
	big_free(L,n);
	big_free(L,y);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int big_modneg(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	big *y = big_arg(L, 1);
	big *n = big_arg(L, 2);
	if(!y || !n) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	if(y->doublesize || n->doublesize) {
		failed_msg = "modneg not supported on double big numbers";
		goto end;
	}
	BIG t;
	BIG_copy(t, y->val);
	big *x = big_new(L);
	if(!x) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	big_init(L,x);
	BIG_modneg(x->val, t, n->val);
	BIG_norm(x->val);
end:
	big_free(L,y);
	big_free(L,n);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}
static int big_jacobi(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	big *x = big_arg(L, 1);
	big *y = big_arg(L, 2);
	if(!x || !y) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	if(x->doublesize || y->doublesize) {
		failed_msg = "jacobi not supported on double big numbers";
		goto end;
	}
	lua_pushinteger(L, BIG_jacobi(x->val, y->val));
end:
	big_free(L,x);
	big_free(L,y);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int big_modinv(lua_State *L) {
	BEGIN();
	big *y = big_arg(L, 1);
	big *m = big_arg(L, 2);
	big *x = big_new(L);
	if(y && m && x) {
		big_init(L,x);
		BIG_invmodp(x->val, y->val, m->val);
	}
	big_free(L,y);
	big_free(L,m);
	if(!y || !m || !x) {
		THROW("Could not create BIG");
	}
	END(1);
}

// algebraic sum (add and sub) taking under account zencode sign
static void _algebraic_sum(big *c, big *a, big *b, char *failed_msg) {
	if (a->zencode_positive == b->zencode_positive) {
		BIG_add(c->val, a->val, b->val);
		c->zencode_positive = a->zencode_positive;
	} else {
		int res = _compare_bigs(a,b,failed_msg);
		// a and b have opposite sign, so I do the bigger minus the
		// smaller and take the sign of the bigger
		if(res > 0) {
			BIG_sub(c->val, a->val, b->val);
			c->zencode_positive = a->zencode_positive;
		} else {
			BIG_sub(c->val, b->val, a->val);
			c->zencode_positive = b->zencode_positive;
		}
	}
}

static int big_zenadd(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	big *a = big_arg(L, 1);
	big *b = big_arg(L, 2);
	big *c = big_new(L);
	if(!a || !b || !c) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	big_init(L,c);
	_algebraic_sum(c, a, b, failed_msg);
end:
	big_free(L,b);
	big_free(L,a);
	if(failed_msg) {
		THROW("Could not create BIG");
	}
	END(1);
}

static int big_zensub(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	big *a = big_arg(L, 1);
	big *b = big_arg(L, 2);
	big *c = big_new(L);
	if(!a || !b || !c) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	big_init(L,c);
	b->zencode_positive = BIG_OPPOSITE(b->zencode_positive);
	_algebraic_sum(c, a, b, failed_msg);
	b->zencode_positive = BIG_OPPOSITE(b->zencode_positive);
end:
	big_free(L,b);
	big_free(L,a);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

// the result is expected to be inside a BIG
static int big_zenmul(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	big *a = big_arg(L, 1);
	big *b = big_arg(L, 2);
	if(!a || !b) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	if(a->doublesize || b->doublesize) {
		failed_msg = "cannot multiply double BIG numbers";
		goto end;
	}
	//BIG_norm(a->val); BIG_norm(b->val);
	DBIG result;
	BIG top;
	big *bottom = big_new(L);
	if(!bottom) {
		failed_msg = "could not create BIG";
		goto end;
	}
	big_init(L,bottom);
	BIG_mul(result, a->val, b->val);
	BIG_sdcopy(bottom->val, result);
	BIG_sducopy(top, result);
	// check that the result is a big (not a dbig)
	if(!iszero(top)) {
		failed_msg = "the result is too big";
		goto end;
	}
	bottom->zencode_positive = BIG_MULSIGN(a->zencode_positive, b->zencode_positive);
end:
	big_free(L,b);
	big_free(L,a);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int big_zendiv(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	big *a = big_arg(L, 1);
	big *b = big_arg(L, 2);
	if(!a || !b) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	if(a->doublesize || b->doublesize) {
		failed_msg = "cannot multiply double BIG numbers";
		goto end;
	}
	DBIG dividend;
	BIG_dzero(dividend);
	dcopy(dividend, a->val);
	big *result = big_new(L);
	if(!result) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	big_init(L,result);
	BIG_ddiv(result->val, dividend, b->val);
	result->zencode_positive = BIG_MULSIGN(a->zencode_positive, b->zencode_positive);
end:
	big_free(L,b);
	big_free(L,a);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int big_zenpositive(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	big *a = big_arg(L, 1);
	if(!a) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	lua_pushboolean(L, a->zencode_positive == BIG_POSITIVE);
end:
	big_free(L,a);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}
static int big_zenmod(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	big *a = big_arg(L, 1);
	big *b = big_arg(L, 2);
	if(!a || !b) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	if(a->doublesize || b->doublesize) {
		failed_msg = "cannot multiply double BIG numbers";
		goto end;
	}
	if(a->zencode_positive == BIG_NEGATIVE || b->zencode_positive == BIG_NEGATIVE) {
		failed_msg = "modulo operation only available with positive numbers";
		goto end;
	}
	big *result = big_new(L);
	if(!result) {
		failed_msg = "could not create BIG";
		goto end;
	}
	big_init(L,result);
	BIG_copy(result->val, a->val);
	BIG_mod(result->val, b->val);
	result->zencode_positive = BIG_POSITIVE;
end:
	big_free(L,b);
	big_free(L,a);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int big_zenopposite(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	big *a = big_arg(L, 1);
	if(!a) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	big *result = big_dup(L, a);
	if(!result) {
		failed_msg = "Could not copy BIG";
		goto end;
	}
	result->zencode_positive = BIG_OPPOSITE(result->zencode_positive);
end:
	big_free(L,a);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

static int big_isinteger(lua_State *L) {
	BEGIN();
	int result = 0;
	if(lua_isinteger(L, 1)) {
		result = 1;
	} else if(lua_isstring(L, 1)) {
		int i = 0;
		const char *arg = lua_tostring(L, 1);
		if(arg[i] == '-') {
			i++;
		}
		result = 1;
		while(result == 1 && arg[i] != '\0') {
			if(arg[i] < '0' || arg[i] > '9') {
				result = 0;
			}
			i++;
		}
	}
	lua_pushboolean(L, result);
	END(1);
}

static int big_parity(lua_State *L) {
	BEGIN();
	big *c = big_arg(L, 1);
	if(c) {
		lua_pushboolean(L, BIG_parity(c->val)==1); // big % 2
		big_free(L, c);
	} else {
		THROW("Could not create BIG");
	}
	END(1);
}

static int big_shiftr(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	big *c = big_arg(L, 1);
	if(!c) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	int i;
	lua_Number n = lua_tointegerx(L, 2, &i);
	if(!i) {
		failed_msg = "the number of bits to shift has to be a number";
		goto end;
	}
	int int_n = n;
	big *r = big_dup(L, c);
	if(!r) {
		failed_msg = "Could not create BIG";
		goto end;
	}
	if(c->doublesize) {
		BIG_dnorm(r->val);
		BIG_dshr(r->val, int_n);
	} else {
		BIG_norm(r->val);
		BIG_shr(r->val, int_n);
	}
end:
	big_free(L,c);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}


int luaopen_big(lua_State *L) {
	(void)L;
	const struct luaL_Reg big_class[] = {
		{"new", newbig},
		{"to_octet", luabig_to_octet},
		{"from_decimal", big_from_decimal_string},
		{"to_decimal", big_to_decimal_string},
		{"eq", big_eq},
		{"add", big_add},
		{"sub", big_sub},
		{"mul", big_mul},
		{"mod", big_mod},
		{"div", big_div},
		{"sqr", big_sqr},
		{"bits", big_bits},
		{"bytes", big_bytes},
		{"modmul", big_modmul},
		{"moddiv", big_moddiv},
		{"modsqr", big_modsqr},
		{"modneg", big_modneg},
		{"modsub", big_modsub},
		{"modrand", big_modrand},
		{"random", big_random},
		{"modinv", big_modinv},
		{"jacobi", big_jacobi},
		{"monty", big_monty},
		{"parity", big_parity},
		{"info", lua_biginfo},
		{"max", lua_bigmax},
		{"shr", big_shiftr},
		{"is_integer", big_isinteger},
		{"zenadd", big_zenadd},
		{"zenmod", big_zenmod},
		{"zenopposite", big_zenopposite},
		{"zensub", big_zensub},
		{"zenmul", big_zenmul},
		{"zendiv", big_zendiv},
		{"zenpositive", big_zenpositive},
		{NULL, NULL}
	};
	const struct luaL_Reg big_methods[] = {
		// idiomatic operators
		{"octet", luabig_to_octet},
		{"hex", big_to_hex},
		{"decimal", big_to_decimal_string},
		{"__add", big_add},
		{"__sub", big_sub},
		{"__mul", big_mul},
		{"__mod", big_mod},
		{"__div", big_div},
		{"__eq", big_eq},
		{"__lt", big_lt},
		{"__lte", big_lte},
		{"__concat", big_concat},
		{"bits", big_bits},
		{"bytes", big_bytes},
		{"int", big_to_int},
		{"integer", big_to_int},
		{"__len", big_bytes},
		{"sqr", big_sqr},
		{"modmul", big_modmul},
		{"moddiv", big_moddiv},
		{"modsqr", big_modsqr},
		{"modneg", big_modneg},
		{"modsub", big_modsub},
		{"modinv", big_modinv},
		{"modpower", big_modpower},
		{"jacobi", big_jacobi},
		{"monty", big_monty},
		{"parity", big_parity},
		{"__gc", big_destroy},
		{"__tostring", big_to_decimal_string},
		{"fixed", big_to_fixed_octet},
		{"__shr", big_shiftr},
		{NULL, NULL}
	};
	zen_add_class(L, "big", big_class, big_methods);
	return 1;
}
