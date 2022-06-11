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
		lerror(L,"uninitialised big in arg1"); } \
	if(!r->val && !r->dval) { \
		lerror(L,"uninitialised big in arg2"); } \
	if(l->doublesize && !r->doublesize) { \
		lerror(L,"incompatible sizes: arg1 is double, arg2 is not"); \
	} else if(r->doublesize && !l->doublesize) { \
		lerror(L,"incompatible sizes: arg2 is double, arg1 is not"); \
	}

int _octet_to_big(lua_State *L, big *dst, octet *src) {
	int i;
	if(src->len <= MODBYTES) { // big
		big_init(dst);
		BIG_zero(dst->val);
		// BIG *d = dst->val;
		for(i=0; i<src->len; i++) {
			BIG_fshl(dst->val,8);
			dst->val[0] += (int)(unsigned char) src->val[i];
		}
	} else if(src->len > MODBYTES && src->len <= MODBYTES<<1) {
		dbig_init(dst);
		BIG_zero(dst->dval);
		for(i=0; i<src->len; i++) {
			BIG_dshl(dst->dval,8);
			dst->dval[0] += (int)(unsigned char) src->val[i];
		}
//		dst->dval[0] += (int)(unsigned char) src->val[i];
	} else {
		lerror(L,"Cannot import BIG number");
		return(0);
	}
	// set to curve's MODLEN by d/big_init()
	// dst->len = i;
	return(i);
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
	return(c);
}

big* big_arg(lua_State *L,int n) {
	void *ud = luaL_testudata(L, n, "zenroom.big");
	luaL_argcheck(L, ud != NULL, n, "big class expected");
	if(ud) {
		big *b = (big*)ud;
		if(!b->val && !b->dval) {
			lerror(L, "invalid big number in argument: not initalized");
			return NULL; }
		return(b);
	}

	octet *o = o_arg(L,n);
	if(o) {
		big *b  = big_new(L); SAFE(b);
		_octet_to_big(L,b,o);
		lua_pop(L,1);
		return(b);
	}
	lerror(L, "invalib big number in argument");
	return NULL;
}

// allocates a new big in LUA, duplicating the one in arg
big *big_dup(lua_State *L, big *s) {
	SAFE(s);
	big *n = big_new(L);
	if(s->doublesize) {
		dbig_init(n);
		BIG_dcopy(n->dval, s->dval);
	} else {
		big_init(n);
		BIG_rcopy(n->val,s->val);
	}
	return(n);
}

int big_destroy(lua_State *L) {
	HERE();
	big *c = big_arg(L,1);
	if(c->doublesize) {
		if(c->dval) zen_memory_free(c->dval);
		if(c->val) warning(L,"found leftover buffer while freeing double big");
	} else {
		if(c->val) zen_memory_free(c->val);
		if(c->dval) warning(L,"found leftover buffer while freeing big");
	}
	SAFE(c);
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
	big *d = big_arg(L,1); SAFE(d);
	lua_pushinteger(L,_bitsize(d));
	return 1;
}
static int big_bytes(lua_State *L) {
	big *d = big_arg(L,1); SAFE(d);
	lua_pushinteger(L,ceil(_bitsize(d)/8));
	// lua_pushinteger(L,d->len);
	return 1;
}

int big_init(big *n) {
	if(n->val && !n->doublesize) {
		func(NULL,"ignoring superflous initialization of big");
		return(1); }
	if(n->dval || n->doublesize) {
		zerror(NULL, "cannot shrink double big to big in re-initialization");
		return 0; }
	if(!n->val && !n->dval) {
		size_t size = sizeof(BIG);
		n->val = (int*)zen_memory_alloc(size);
		n->doublesize = 0;
		n->len = MODBYTES;
		return(size);
	}
	zerror(NULL, "anomalous state of big number detected on initialization");
	return(-1);
}
int dbig_init(big *n) {
	if(n->dval && n->doublesize) {
		func(NULL,"ignoring superflous initialization of double big");
		return(1); }
	size_t size = sizeof(DBIG); //sizeof(DBIG); // modbytes * 2, aka n->len<<1
	if(n->val && !n->doublesize) {
		n->doublesize = 1;
		n->dval = (int*)zen_memory_alloc(size);
		// extend from big to double big
		BIG_dscopy(n->dval,n->val);
		zen_memory_free(n->val);
		n->len = MODBYTES<<1;
	}
	if(!n->val || !n->dval) {
		n->doublesize = 1;
		n->dval = (int*)zen_memory_alloc(size);
		n->len = MODBYTES<<1;
		return(size);
	}
	zerror(NULL, "anomalous state of double big number detected on initialization");
	return(-1);
}

// give information about BIG numbers internal formats
static int lua_biginfo(lua_State *L) {
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
	return 1;
}

// return the max value expressed by MODBYTES big to 0xff
// TODO: fix this to return something usable in modmul
static int lua_bigmax(lua_State *L) {
  big *b = big_new(L); SAFE(b);
  big_init(b);
  register int c;
  for(c=0 ; c < b->len ; c++) b->val[c] = 0xffffffff;
  return 1;
}

/***
    Create a new Big number. If an argument is present, import it as @{OCTET} and initialise it with its value.

    @param[opt] octet value
    @return a new Big number
    @function BIG.new(octet)
*/
static int newbig(lua_State *L) {
	HERE();
	void *ud;
	// kept for backward compat with zenroom 0.9
	ud = luaL_testudata(L, 2, "zenroom.big");
	if(ud) {
		HEREs("use of RNG deprecated");
		big *res = big_new(L); big_init(res); SAFE(res);
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
		big_init(c);
		BIG_zero(c->val);
		if((int)n>0)
			BIG_inc(c->val, (int)n);
		return 1; }

	// octet argument, import
	octet *o = o_arg(L, 1); SAFE(o);
	if(o->len > MODBYTES) {
		zerror(L, "Import of octet to BIG limit exceeded (%u > %u bytes)", o->len, MODBYTES);
		return 0; }
	big *c = big_new(L); SAFE(c);
	_octet_to_big(L, c,o);
	return 1;
}

octet *new_octet_from_big(lua_State *L, big *c) {
	int i;
	octet *o;
	if(c->doublesize && c->dval) {
		if (isdzero(c->dval)) { // zero
			o = o_new(L,c->len); SAFE(o);
			o->val[0] = 0x0;
			o->len = 1;
		} else {
			DBIG t; BIG_dcopy(t,c->dval); BIG_dnorm(t);
			o = o_new(L,c->len); SAFE(o);
			for(i=c->len-1; i>=0; i--) {
				o->val[i]=t[0]&0xff;
				BIG_dshr(t,8);
			}
			o->len = c->len;
		}
	} else if(c->val) {
		if (iszero(c->val)) { // zero
			o = o_new(L,c->len); SAFE(o);
			o->val[0] = 0x0;
			o->len = 1;
		} else {
			// fshr is destructive so use a copy
			BIG t; BIG_copy(t,c->val); BIG_norm(t);
			o = o_new(L,c->len); SAFE(o);
			for(i=c->len-1; i>=0; i--) {
				o->val[i] = t[0]&0xff;
				BIG_fshr(t,8);
			}
			o->len = c->len;
		}
	} else {
		lerror(NULL,"Invalid BIG number, cannot convert to octet");
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
        const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "string expected");
	big *num = big_new(L); SAFE(num);

	big_init(num);
	BIG_zero(num->val);
	int i = 0;
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
	return 1;
}
/*
  fixed size encoding for integer with big endian order
  @param num number that has to be coverted
  @param len bytes size
  @param big_endian use big endian order (if omitted by default is true)
*/
static int big_to_fixed_octet(lua_State *L) {
        int n_args = lua_gettop(L);
        big *num = big_arg(L,1); SAFE(num);
	octet* o = new_octet_from_big(L,num);
	int i;
	lua_Number len = lua_tointegerx(L,2,&i);
	if(!i) {
		lerror(L, "O.from_number input is not a number");
		return 0;
	}

	int big_endian = 1;
	if(n_args > 2) {
	        big_endian = lua_toboolean(L, 3);
	}
	int int_len = len;
	if(o->len < len) {
		octet* padded_oct = o_new(L, len);
		for(i=0; i<o->len; i++) {
		  padded_oct->val[int_len-(o->len)+i] = o->val[i];
		}
		for(i=0; i<len-o->len; i++) {
			padded_oct->val[i] = '\0';
		}
		padded_oct->len = len;
		o = padded_oct;
	}
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
	return 1;
}

/*
  Slow but only for export
  Works only for positive numbers
  @param num number to be converted (zenroom.big)
  @return string which represent a decimal number (only digits 0-9)
*/
static int big_to_decimal_string(lua_State *L) {
       	big *num = big_arg(L,1); SAFE(num);
	BIG_norm(num->val);
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
	char *s = zen_memory_alloc(i+3);
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
	zen_memory_free(s);
	return 1;
}


static int luabig_to_octet(lua_State *L) {
	big *c = big_arg(L,1); SAFE(c);
	new_octet_from_big(L,c);
	return 1;
}

static int big_concat(lua_State *L) {
	big *l = big_arg(L,1); SAFE(l);
	big *r = big_arg(L,2); SAFE(r);
	
	octet *ol = new_octet_from_big(L,l);
	lua_pop(L,1);
	octet *or = new_octet_from_big(L,r);
	lua_pop(L,1);
	octet *d = o_new(L, ol->len + or->len); SAFE(d);
	OCT_copy(d,ol);
	OCT_joctet(d,or);
	return 1;
}

static int big_to_hex(lua_State *L) {
	big *a = big_arg(L,1); SAFE(a);
	octet *o = new_octet_from_big(L,a);
	lua_pop(L,1);
	push_octet_to_hex_string(L,o);
	return 1;
}

static int big_to_int(lua_State *L) {
	big *a = big_arg(L,1); SAFE(a);
	if(a->doublesize)
		lerror(L,"BIG too big for conversion to integer");
	octet *o = new_octet_from_big(L,a); SAFE(o);
	lua_pop(L,1);
	int32_t res;
	res = o->val[0];
	if(o->len > 1) res = res <<8  | (uint32_t)o->val[1];
	if(o->len > 2) res = res <<16 | (uint32_t)o->val[2];
	if(o->len > 3) res = res <<24 | (uint32_t)o->val[3];
	if(o->len > 4) warning(L,"Number conversion bigger than 32bit, BIG truncated to 4 bytes");
	lua_pushinteger(L, (lua_Integer) res);
	return(1);
}

static int _compare_bigs(lua_State *L, big *l, big *r) {
	int res;
	checkalldouble(l,r);
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
	return(res);
}
static int big_eq(lua_State *L) {
	big *l = big_arg(L,1); SAFE(l);
	big *r = big_arg(L,2); SAFE(r);
	// BIG_comp requires external normalization
	int res = _compare_bigs(L,l,r);
	// -1 if x<y, 0 if x=y, 1 if x>y
	lua_pushboolean(L, (res==0)?1:0);
	return 1;
}
static int big_lt(lua_State *L) {
	big *l = big_arg(L,1); SAFE(l);
	big *r = big_arg(L,2); SAFE(r);
	// BIG_comp requires external normalization
	int res = _compare_bigs(L,l,r);
	// -1 if x<y, 0 if x=y, 1 if x>y
	lua_pushboolean(L, (res<0)?1:0);
	return 1;
}
static int big_lte(lua_State *L) {
	big *l = big_arg(L,1); SAFE(l);
	big *r = big_arg(L,2); SAFE(r);
	// BIG_comp requires external normalization
	int res = _compare_bigs(L,l,r);
	// -1 if x<y, 0 if x=y, 1 if x>y
	lua_pushboolean(L, (res<0)?1:(res==0)?1:0);
	return 1;
}

static int big_add(lua_State *L) {
	big *l = big_arg(L,1); SAFE(l);
	big *r = big_arg(L,2); SAFE(r);
	big *d = big_new(L); SAFE(d);
	if(l->doublesize || r->doublesize) {
		func(L,"ADD doublesize");
		godbig2(l,r);
		dbig_init(d);
		BIG_dadd(d->dval, _l, _r);
		BIG_dnorm(d->dval);
	} else {
		big_init(d);
		BIG_add(d->val, l->val, r->val);
		BIG_norm(d->val);
	}
	return 1;
}

static int big_sub(lua_State *L) {
	big *l = big_arg(L,1); SAFE(l);
	big *r = big_arg(L,2); SAFE(r);
	big *d = big_new(L); SAFE(d);
	if(l->doublesize || r->doublesize) {
		godbig2(l, r);
		dbig_init(d);
		if(BIG_dcomp(_l,_r)<0) {
			lerror(L,"Subtraction error: arg1 smaller than arg2 (consider use of :modsub)");
			return 0; }
		BIG_dsub(d->dval, _l, _r);
		BIG_dnorm(d->dval);
	} else {
		// if(BIG_comp(l->val,r->val)<0) {
		// 	lerror(L,"Subtraction error: arg1 smaller than arg2");
		// 	return 0; }
		big_init(d);
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
	return 1;
}

static int big_modsub(lua_State *L) {
	big *l = big_arg(L,1); SAFE(l);
	big *r = big_arg(L,2); SAFE(r);
	big *m = big_arg(L,3); SAFE(m);
	big *d = big_new(L); SAFE(d);
	big_init(d);
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
	return 1;
}



/***
    Generate a random Big number whose ceiling is defined by the modulo to another number.

    @param modulo another BIG number, usually @{ECP.order} 
    @return a new Big number
    @function BIG.modrand(modulo)
*/

static int big_modrand(lua_State *L) {
	big *modulus = big_arg(L,1); SAFE(modulus);	
	big *res = big_new(L); big_init(res); SAFE(res);
	Z(L);
	BIG_randomnum(res->val,modulus->val,Z->random_generator);
	return(1);
}

/***
    Generate a random Big number whose ceiling is the order of the curve.

    @return a new Big number
    @function BIG.random()
*/

static int big_random(lua_State *L) {
	big *res = big_new(L); big_init(res); SAFE(res);
	Z(L);
	BIG_randomnum(res->val,(chunk*)CURVE_Order,Z->random_generator);
	return(1);
}

static int big_mul(lua_State *L) {
	big *l = big_arg(L,1); SAFE(l);
	void *ud = luaL_testudata(L, 2, "zenroom.ecp");
	if(ud) {
		ecp *e = (ecp*)ud; SAFE(e);
		if(l->doublesize) {
			lerror(L,"cannot multiply double BIG numbers with ECP point, need modulo");
			return 0; }
		ecp *out = ecp_dup(L,e); SAFE(out);
		PAIR_G1mul(&out->val,l->val);
		// TODO: use unaccellerated multiplication for non-pairing curves
		// ECP_mul(&out->val,l->val);
		return 1; }
	big *r = big_arg(L,2); SAFE(r);
	if(l->doublesize || r->doublesize) {
		lerror(L,"cannot multiply double BIG numbers");
		return 0; }
	// BIG_norm(l->val); BIG_norm(r->val);
	big *d = big_new(L); SAFE(d);
	big_init(d);
	// dbig_init(d); // assume it always returns a double big
	// BIG_dzero(d->dval);
	BIG_modmul(d->val, l->val, r->val, (chunk*)CURVE_Order);
	BIG_norm(d->val);
	return 1;
}

// Square and multiply, not secure against side channel attacks
static int big_modpower(lua_State *L) {
	big *x = big_arg(L,1); SAFE(x);
	big *n = big_arg(L,2); SAFE(n);
	big *m = big_arg(L,3); SAFE(m);

	BIG safen;
	BIG_copy(safen, n->val);

	big *res = big_new(L); SAFE(res);
	big_init(res);
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

	return 1;
}

static int big_sqr(lua_State *L) {
	big *l = big_arg(L,1); SAFE(l);
	if(l->doublesize) {
		lerror(L,"cannot make square root of a double big number");
		return 0; }
	// BIG_norm(l->val); BIG_norm(r->val);
	// BIG_norm(l->val);
	big *d = big_new(L); SAFE(d);
	dbig_init(d); // assume it always returns a double big
	BIG_sqr(d->dval,l->val);
	return 1;
}

static int big_monty(lua_State *L) {
	big *s = big_arg(L,1); SAFE(s);
	if(!s->doublesize) {
		lerror(L,"no need for montgomery reduction: not a double big number");
		return 0; }
	big *m = big_arg(L, 2); SAFE(m);
	if(m->doublesize) {
		lerror(L, "double big modulus in montgomery reduction");
		return 0; }
	big *d = big_new(L); big_init(d); SAFE(d);
	BIG_monty(d->val, m->val, Montgomery, s->dval);
	return 1;
}

static int big_mod(lua_State *L) {
	big *l = big_arg(L, 1); SAFE(l);
	big *r = big_arg(L, 2); SAFE(r);
	if(r->doublesize) {
		lerror(L, "modulus cannot be a double big (dmod)");
		return 0; }
	if(l->doublesize) {
		big *d = big_new(L); big_init(d); SAFE(d);
		DBIG t; BIG_dcopy(t, l->dval); // dmod destroys 2nd arg
		BIG_dmod(d->val, t, r->val);
	} else {
		big *d = big_dup(L, l); SAFE(d);
		BIG_mod(d->val, r->val);
	}
	return 1;
}

static int big_div(lua_State *L) {
	big *l = big_arg(L, 1); SAFE(l);
	big *r = big_arg(L, 2); SAFE(r);
	if(r->doublesize) {
		lerror(L, "division not supported with double big modulus");
		return 0; }
	big *d = big_dup(L, l); SAFE(d);
	if(l->doublesize) { // use ddiv on double big
		DBIG t; BIG_dcopy(t, l->dval); 	// in ddiv the 2nd arg is destroyed
		BIG_ddiv(d->val, t, r->val);
	} else { // use sdiv for normal bigs
		BIG_sdiv(d->val, r->val);
	}
	return 1;
}


/***
    Multiply a BIG number by another BIG while ceiling the operation to a modulo to avoid excessive results. This operation is to be preferred to the simple overladed operator '*' in most cases where such a multiplication takes place. It may replace '*' in the future as a simplification.

    @param coefficient another BIG number
    @param modulo usually @{ECP.order} 
    @return a new Big number
    @function BIG.modmul(coefficient, modulo)
*/
static int big_modmul(lua_State *L) {
	big *y = big_arg(L, 1); SAFE(y);
	big *z = big_arg(L, 2); SAFE(z);
	big *n = luaL_testudata(L, 3, "zenroom.big");
	if(n) {
		if(y->doublesize || z->doublesize || n->doublesize) {
			lerror(L, "modmul not supported on double big numbers");
			return 0; }
		BIG t1, t2;
		BIG_copy(t1, y->val);
		BIG_copy(t2, z->val);
		big *x = big_new(L); SAFE(x);
		big_init(x);
		BIG_modmul(x->val, t1, t2, n->val);
		BIG_norm(x->val);
		return 1;
	} else {
		// modulo default ORDER from ECP
		BIG t1, t2;
		BIG_copy(t1, y->val);
		BIG_copy(t2, z->val);
		big *x = big_new(L); SAFE(x);
		big_init(x);
		BIG_modmul(x->val, t1, t2, (chunk*)CURVE_Order);
		BIG_norm(x->val);
		return 1;
	}
}

static int big_moddiv(lua_State *L) {
	big *y = big_arg(L, 1); SAFE(y);
	big *div = big_arg(L, 2); SAFE(div);
	big *mod = big_arg(L, 3); SAFE(mod);
	if(y->doublesize || div->doublesize || mod->doublesize) {
		lerror(L, "moddiv not supported on double big numbers");
		return 0; }
	BIG t;
	BIG_copy(t, y->val);
	big *x = big_new(L); SAFE(x);
	big_init(x);
	BIG_moddiv(x->val, t, div->val, mod->val);
	BIG_norm(x->val);
	return 1;
}

static int big_modsqr(lua_State *L) {
	big *y = big_arg(L, 1); SAFE(y);
	big *n = big_arg(L, 2); SAFE(n);
	if(y->doublesize || n->doublesize) {
		lerror(L, "modsqr not supported on double big numbers");
		return 0; }
	BIG t;
	BIG_copy(t, y->val);
	big *x = big_new(L); SAFE(x);
	big_init(x);
	BIG_modsqr(x->val, t, n->val);
	BIG_norm(x->val);
	return 1;
}

static int big_modneg(lua_State *L) {
	big *y = big_arg(L, 1); SAFE(y);
	big *n = big_arg(L, 2); SAFE(n);
	if(y->doublesize || n->doublesize) {
		lerror(L, "modneg not supported on double big numbers");
		return 0; }
	BIG t;
	BIG_copy(t, y->val);
	big *x = big_new(L); SAFE(x);
	big_init(x);
	BIG_modneg(x->val, t, n->val);
	BIG_norm(x->val);
	return 1;
}
static int big_jacobi(lua_State *L) {
	big *x = big_arg(L, 1); SAFE(x);
	big *y = big_arg(L, 2); SAFE(y);
	if(x->doublesize || y->doublesize) {
		lerror(L, "jacobi not supported on double big numbers");
		return 0; }
	lua_pushinteger(L, BIG_jacobi(x->val, y->val));
	return 1;
}

static int big_modinv(lua_State *L) {
	big *y = big_arg(L, 1); SAFE(y);
	big *m = big_arg(L, 2); SAFE(m);
	big *x = big_new(L); SAFE(x);
	big_init(x);
	BIG_invmodp(x->val, y->val, m->val);
	return 1;
}

static int big_parity(lua_State *L) {
	big *c = big_arg(L, 1); SAFE(c);
	lua_pushboolean(L, BIG_parity(c->val)==1); // big % 2
	return 1;
}

static int big_shiftr(lua_State *L) {
        big *c = big_arg(L, 1); SAFE(c);
	int i;
	lua_Number n = lua_tointegerx(L, 2, &i);
	if(!i) {
		lerror(L, "the number of bits to shift has to be a number");
		return 0;
	}
	int int_n = n;
  
	big *r = big_dup(L, c); SAFE(r);
	if(c->doublesize) {
		BIG_dnorm(r->val);
		BIG_dshr(r->val, int_n);
	} else {
		BIG_norm(r->val);
		BIG_shr(r->val, int_n);
	}
	return 1;
}


int luaopen_big(lua_State *L) {
	(void)L;
	const struct luaL_Reg big_class[] = {
		{"new", newbig},
		{"to_octet", luabig_to_octet},
		{"from_decimal", big_from_decimal_string},
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
		{"__tostring", big_to_hex},
		{"fixed", big_to_fixed_octet},
		{"__shr", big_shiftr},
		{NULL, NULL}
	};
	zen_add_class(L, "big", big_class, big_methods);
	return 1;
}
