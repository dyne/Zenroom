/*  Zenroom (DECODE project)
 *
 *  (c) Copyright 2017-2018 Dyne.org foundation
 *  designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This source code is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Public License as published
 * by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 *
 * This source code is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * Please refer to the GNU Public License for more details.
 *
 * You should have received a copy of the GNU Public License along with
 * this source code; if not, write to:
 * Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <math.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <jutils.h>
#include <zen_error.h>
#include <lua_functions.h>

#include <amcl.h>

#include <zenroom.h>
#include <zen_octet.h>
#include <zen_memory.h>
#include <zen_big.h>

/// <h1>Big Number Arithmetic (BIG)</h1>
//
// Base arithmetical operations on big numbers.
//
// The values of each number can be imported using big:hex() and big:base64() methods.
//
//  @module BIG
//  @author Denis "Jaromil" Roio
//  @license GPLv3
//  @copyright Dyne.org foundation 2017-2018

extern int octet_to_hex(lua_State *L);

// to copy contents from BIG to DBIG
#define dcopy(d,s) BIG_dscopy(d,s);

#define checkalldouble(l,r) \
	if(!l->val && !l->dval) { \
		error(L,"error in %s %u",__FUNCTION__,__LINE__); \
		lerror(L,"uninitialised big in arg1"); } \
	if(!r->val && !r->dval) { \
		error(L,"error in %s %u",__FUNCTION__,__LINE__); \
		lerror(L,"uninitialised big in arg2"); } \
	if(l->doublesize && !r->doublesize) { \
		error(L,"error in %s %u",__FUNCTION__,__LINE__); \
		lerror(L,"incompatible sizes: arg1 is double, arg2 is not"); \
	} else if(r->doublesize && !l->doublesize) { \
		error(L,"error in %s %u",__FUNCTION__,__LINE__); \
		lerror(L,"incompatible sizes: arg2 is double, arg1 is not"); \
	}

big* big_new(lua_State *L) {
	big *c = (big *)lua_newuserdata(L, sizeof(big));
	if(!c) {
		lerror(L, "Error allocating new big in %s",__func__);
		return NULL; }
	luaL_getmetatable(L, "zenroom.big");
	lua_setmetatable(L, -2);
	strcpy(c->name,"big384");
	c->len = modbytes;
	c->chunksize = CHUNK;
	c->doublesize = 0;
	c->val = NULL;
	c->dval = NULL;
	func(L, "new big (%u bytes)",modbytes);
	return(c);
}


// big* big2dbig_new(lua_State *L, big *s) {
// 	big *d = big_new(L);
// 	dbig_init(d);
// 	BIG_dscopy(d->dval,s->val);
// 	return d;
// }

static int big_double(lua_State *L) {
	big *s = big_arg(L,1); SAFE(s);
	big *d = big_new(L); SAFE(d);
	dbig_init(d);
	if(s->doublesize)
		BIG_dcopy(d->dval, s->dval);
	else
		BIG_dscopy(d->dval, s->val);
	return 1;
}

big* big_arg(lua_State *L,int n) {
	void *ud = luaL_checkudata(L, n, "zenroom.big");
	luaL_argcheck(L, ud != NULL, n, "big class expected");
	big *o = (big*)ud;
	if(o->len != modbytes) {
		lerror(L, "%s: big modbytes mismatch (%u != %u)",__func__,o->len, modbytes);
		return NULL; }
	if(o->chunksize != CHUNK) {
		lerror(L, "%s: big chunk size mismatch (%u != %u)",__func__,o->chunksize, CHUNK);
		return NULL; }
	return(o);
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


static int bitsize(big *b) {
	double bits;
	if(b->doublesize)
		bits = BIG_dnbits(b->dval);
	else
		bits = BIG_nbits(b->val);
	return bits;
}
static int big_bits(lua_State *L) {
	big *d = big_arg(L,1); SAFE(d);
	lua_pushinteger(L,bitsize(d));
	return 1;
}
static int big_bytes(lua_State *L) {
	big *d = big_arg(L,1); SAFE(d);
	lua_pushinteger(L,ceil(bitsize(d)/8));
	return 1;
}

int big_init(big *n) {
	if(n->val && !n->doublesize) {
		func(NULL,"ignoring superflous initialization of big");
		return(1); }
	if(n->dval || n->doublesize) {
		error(NULL,"cannot shrink double big to big in re-initialization");
		return 0; }
	if(!n->val && !n->dval) {
		size_t size = sizeof(BIG);
		n->val = zen_memory_alloc(size);
		n->doublesize = 0;
		return(size);
	}
	error(NULL,"anomalous state of big number detected on initialization");
	return(-1);
}
int dbig_init(big *n) {
	if(n->dval && n->doublesize) {
		func(NULL,"ignoring superflous initialization of double big");
		return(1); }
	size_t size = sizeof(DBIG); // modbytes * 2, aka n->len<<1
	if(n->val && !n->doublesize) {
		n->doublesize = 1;
		n->dval = zen_memory_alloc(size);
		// extend from big to double big
		BIG_dscopy(n->dval,n->val);
		zen_memory_free(n->val);
	}
	if(!n->val || !n->dval) {
		n->doublesize = 1;
		n->dval = zen_memory_alloc(size);
		return(size);
	}
	error(NULL,"anomalous state of double big number detected on initialization");
	return(-1);
}

/***
    Create a new Big number. Set it to zero if no argument is present, else import the value from @{OCTET}.

    @param[opt] octet value of the big number
    @return a new Big number set to the given value or Zero if none
    @function BIG.new(octet)
    @see OCTET:hex
    @see OCTET:base64
*/
static int newbig(lua_State *L) {
	HERE();
	int res = lua_isnoneornil(L, 1);
	if(res) { // no argument, set to zero
		big *c = big_new(L); SAFE(c);
		big_init(c);
		BIG_zero(c->val);
		return 1; }
	// octet argument, import
	void *ud = luaL_testudata(L, 1, "zenroom.octet");
	if(ud) {
		big *c = big_new(L); SAFE(c);
		octet *o = (octet*)ud;
		if(o->len <= modbytes) { // big
			// TODO: measure byte length to detect doublebig
			big_init(c);
			BIG_fromBytesLen(c->val, o->val, o->len);
		} else if(o->len > modbytes && o->len < modbytes<<1) {
			dbig_init(c);
			BIG_dfromBytesLen(c->dval, o->val, o->len);
		} else {
			error(L, "size %u is invalid (big has modbytes %u)",o->len, modbytes);
			lua_pop(L,1);
			lerror(L,"Cannot import BIG number");
		}
		return 1; }
	// number argument, import
	int tn;
	lua_Number n = lua_tonumberx(L,1,&tn);
	if(tn) {
		big *c = big_new(L); SAFE(c);
		big_init(c);
		BIG_zero(c->val);
		BIG_inc(c->val, n);
		BIG_norm(c->val);
		return 1; }
	// BIG_384_29_dzero(DBIG_384_29 x)

	error(L,"octet or number argument expected");
	return 0;
}

static octet *to_octet(lua_State *L, big *c) {
	octet *o = NULL;
	int i;
	int size = 0;
	if(c->doublesize && c->dval) {
		BIG_dnorm(c->dval);
		size = BIG_dnbits(c->dval)>>3;
		o = o_new(L, size); SAFE(o);
		DBIG t;
		BIG_dcopy(t,c->dval);
		for(i=size-1; i>=0; i--) {
			o->val[i]=t[0]&0xff;
			BIG_dshr(t,8);
		}
	} else if(c->val) {
		BIG_norm(c->val);
		size = BIG_nbits(c->val)>>3;
		o = o_new(L, size); SAFE(o);
		BIG t;
		BIG_copy(t,c->val);
		for(i=size-1; i>=0; i--) {
			o->val[i]=t[0]&0xff;
			BIG_dshr(t,8);
		}
	} else
		lerror(L,"Invalid BIG number, cannot convert to octet");
	o->len = size;
	return o;
}
static int big_to_octet(lua_State *L) {
	big *c = big_arg(L,1); SAFE(c);
	octet *o = to_octet(L,c);
	(void)o;
	return 1;
}

static int big_concat(lua_State *L) {
	big *l = big_arg(L,1); SAFE(l);
	big *r = big_arg(L,2); SAFE(r);
//	BIG_norm(l->val); BIG_norm(r->val);
	int nlen = l->len + r->len;
	octet *o = o_new(L, nlen +2); SAFE(o);
	// TODO: dbig
	BIG_toBytes(o->val,l->val);
	BIG_toBytes(o->val+l->len,r->val);
	o->len = nlen;
	return 1;
}

// useful to double-check big_to_octet():hex()
// this function is known to return good results
// static int big_to_hex(lua_State *L) {
// 	BIG b;
// 	int i,len;
// 	char str[MAX_STRING]; // TODO:
// 	int modby2 = modbytes<<1;
// 	big *a = big_arg(L,1); SAFE(a);
// 	len = BIG_nbits(a->val);
// 	int lendiv4 = len>>2;
// 	if (len%4==0) len=lendiv4;
// 	else {
// 		len=lendiv4;
// 		len++;
// 	}
// 	if (len<modby2) len=modby2;
// 	int c = 0;
// 	// TODO: double
// 	for (i=len-1; i>=0; i--) {
// 		BIG_copy(b,a->val);
// 		BIG_shr(b,i<<2);
// 		sprintf(str+c,"%01x",(unsigned int) b[0]&15);
// 		c++;
// 	}
// 	lua_pushstring(L,str);
// 	return 1;
// }

static int big_to_hex(lua_State *L) {
	big *a = big_arg(L,1); SAFE(a);
	octet *o = to_octet(L,a);
	lua_pop(L,1);
	push_octet_to_hex_string(o);
	return 1;
}

static int big_eq(lua_State *L) {
	big *l = big_arg(L,1); SAFE(l);
	big *r = big_arg(L,2); SAFE(r);
	// BIG_comp requires external normalization
	int res;
	checkalldouble(l,r);
	if(l->doublesize && r->doublesize) {
		BIG_dnorm(l->dval);
		BIG_dnorm(r->dval);
		res = BIG_dcomp(l->dval,r->dval);
	} else {
		BIG_norm(l->val);
		BIG_norm(r->val);
		res = BIG_comp(l->val,r->val);
	}
	lua_pushboolean(L, (res==0)?1:0);
	return 1;
}

static int big_add(lua_State *L) {
	big *l = big_arg(L,1); SAFE(l);
	big *r = big_arg(L,2); SAFE(r);
	big *d = big_new(L); SAFE(d);
	checkalldouble(l,r);
	if(l->doublesize && r->doublesize) {
		dbig_init(d);
		BIG_dadd(d->dval, l->dval, r->dval);
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
	checkalldouble(l,r);
	if(l->doublesize && r->doublesize) {
		big *d = big_new(L); SAFE(d);
		dbig_init(d);
		if(BIG_dcomp(l->dval,r->dval)<0) {
			lerror(L,"Subtraction error: arg1 smaller than arg2");
			return 0; }
		BIG_dsub(d->dval, l->dval, r->dval);
		BIG_dnorm(d->dval);
	} else {
		// if(BIG_comp(l->val,r->val)<0) {
		// 	lerror(L,"Subtraction error: arg1 smaller than arg2");
		// 	return 0; }
		big *d = big_new(L); SAFE(d);
		big_init(d);
		BIG_sub(d->val, l->val, r->val);
		BIG_norm(d->val);
	}
	return 1;
}

static int big_modsub(lua_State *L) {
	big *l = big_arg(L,1); SAFE(l);
	big *r = big_arg(L,2); SAFE(r);
	big *m = big_arg(L,3); SAFE(m);
	checkalldouble(l,r);
	big *d = big_new(L); SAFE(d);
	big_init(d);
	if(l->doublesize || r->doublesize) {
		// temporary bring all to DBIG
		chunk *llv, *lrv;
		DBIG ll, lr;
		if   (l->doublesize)     llv = l->dval;
		else { dcopy(ll,l->val); llv = (chunk*)&ll; }
		if   (r->doublesize)     lrv = r->dval;
		else { dcopy(lr,r->val); lrv = (chunk*)&lr; }
		if(BIG_dcomp(l->dval,r->dval)<0) { // if l < r
			// res = m - (r-l % m)
			DBIG t; BIG tm;
			BIG_dsub (t,  lrv, llv);
			BIG_dmod (tm, t,   m->val);
			BIG_sub  (d->val,  m->val, tm);
		} else { // if l > r
			DBIG t;
			BIG_dsub(t  , llv, lrv);
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

static int big_mul(lua_State *L) {
	big *l = big_arg(L,1); SAFE(l);
	big *r = big_arg(L,2); SAFE(r);
	checkalldouble(l,r);
	if(l->doublesize || r->doublesize) {
		lerror(L,"cannot multiply double big numbers");
		return 0; }
	// BIG_norm(l->val); BIG_norm(r->val);
	big *d = big_new(L); SAFE(d);
	dbig_init(d); // assume it always returns a double big
	// BIG_dzero(d->dval);
	BIG_mul(d->dval,l->val,r->val);
	BIG_dnorm(d->dval);
	return 1;
}

static int big_sqr(lua_State *L) {
	big *l = big_arg(L,1); SAFE(l);
	if(l->doublesize) {
		lerror(L,"cannot make square root of a double big number");
		return 0; }
	// BIG_norm(l->val); BIG_norm(r->val);
	big *d = big_new(L); SAFE(d);
	dbig_init(d); // assume it always returns a double big
	// BIG_dzero(d->dval);
	BIG_sqr(d->dval,l->val);
	BIG_dnorm(d->dval);
	return 1;
}

static int big_mod(lua_State *L) {
	big *l = big_arg(L,1); SAFE(l);
	big *r = big_arg(L,2); SAFE(r);
	if(r->doublesize) {
		lerror(L,"modulus cannot be a double big (dmod)");
		return 0; }
	if(l->doublesize) {
		big *d = big_new(L); SAFE(d);
		dbig_init(d);
		BIG_dmod(d->dval,l->dval,r->val);
	} else {
		big *d = big_dup(L,l); SAFE(d);
		BIG_mod(d->val,r->val);
	}
	return 1;
}

static int big_div(lua_State *L) {
	big *l = big_arg(L,1); SAFE(l);
	big *r = big_arg(L,2); SAFE(r);
	checkalldouble(l,r);
	if(l->doublesize || r->doublesize)
		lerror(L,"division not supported on double big numbers (ddiv)");
	big *d = big_dup(L,l); SAFE(d);
	BIG_div(d->val,r->val);
	BIG_norm(d->val);
	return 1;
}

static int big_modmul(lua_State *L) {
	big *y = big_arg(L, 1); SAFE(y);
	big *z = big_arg(L, 2); SAFE(z);
	big *n = big_arg(L, 3); SAFE(n);
	checkalldouble(y,z);
	if(y->doublesize || z->doublesize || n->doublesize) {
		lerror(L,"modmul not supported on double big numbers");
		return 0; }
	BIG t1, t2;
	BIG_copy(t1,y->val);
	BIG_copy(t2,z->val);
	big *x = big_new(L); SAFE(x);
	big_init(x);
	BIG_modmul(x->val, t1, t2, n->val);
	BIG_norm(x->val);
	return 1;
}

static int big_moddiv(lua_State *L) {
	big *y = big_arg(L, 1); SAFE(y);
	big *div = big_arg(L, 2); SAFE(div);
	big *mod = big_arg(L, 3); SAFE(mod);
	checkalldouble(y,div);
	if(y->doublesize || div->doublesize || mod->doublesize) {
		lerror(L,"moddiv not supported on double big numbers");
		return 0; }
	BIG t;
	BIG_copy(t,y->val);
	big *x = big_new(L); SAFE(x);
	big_init(x);
	BIG_moddiv(x->val, t, div->val, mod->val);
	BIG_norm(x->val);
	return 1;
}

static int big_modsqr(lua_State *L) {
	big *y = big_arg(L, 1); SAFE(y);
	big *n = big_arg(L, 2); SAFE(n);
	checkalldouble(y,n);
	if(y->doublesize || n->doublesize) {
		lerror(L,"modsqr not supported on double big numbers");
		return 0; }
	BIG t;
	BIG_copy(t,y->val);
	big *x = big_new(L); SAFE(x);
	big_init(x);
	BIG_modsqr(x->val, t, n->val);
	BIG_norm(x->val);
	return 1;
}

static int big_modneg(lua_State *L) {
	big *y = big_arg(L, 1); SAFE(y);
	big *n = big_arg(L, 2); SAFE(n);
	checkalldouble(y,n);
	if(y->doublesize || n->doublesize) {
		lerror(L,"modneg not supported on double big numbers");
		return 0; }
	BIG t;
	BIG_copy(t,y->val);
	big *x = big_new(L); SAFE(x);
	big_init(x);
	BIG_modneg(x->val, t, n->val);
	BIG_norm(x->val);
	return 1;
}
static int big_jacobi(lua_State *L) {
	big *x = big_arg(L, 1); SAFE(x);
	big *y = big_arg(L, 2); SAFE(y);
	checkalldouble(x,y);
	if(x->doublesize || y->doublesize) {
		lerror(L,"jacobi not supported on double big numbers");
		return 0; }
	lua_pushinteger(L, BIG_jacobi(x->val, y->val));
	return 1;
}

int luaopen_big(lua_State *L) {
	const struct luaL_Reg big_class[] = {
		{"new",newbig},
		{"eq",big_eq},
		{"add",big_add},
		{"sub",big_sub},
		{"mul",big_mul},
		{"mod",big_mod},
		{"div",big_div},
		{"sqr",big_sqr},
		{"bits",big_bits},
		{"bytes",big_bytes},
		{"modmul",big_modmul},
		{"moddiv",big_moddiv},
		{"modsqr",big_modsqr},
		{"modneg",big_modneg},
		{"modsub",big_modsub},
		{"jacobi",big_jacobi},
		{NULL,NULL}
	};
	const struct luaL_Reg big_methods[] = {
		// idiomatic operators
		{"octet",big_to_octet},
		{"hex",big_to_hex},
		{"add",  big_add},
		{"__add",big_add},
		{"sub",  big_sub},
		{"__sub",big_sub},
		{"mul",  big_mul},
		{"__mul",big_mul},
		{"mod",  big_mod},
		{"__mod",big_mod},
		{"div",  big_div},
		{"__div",big_div},
		{"sqr",big_sqr},
		{"eq",  big_eq},
		{"__eq",big_eq},
		{"__concat",big_concat},
		{"bits",big_bits},
		{"bytes",big_bytes},
		{"__len",big_bytes},
		{"double",big_double},
		{"modmul",big_modmul},
		{"moddiv",big_moddiv},
		{"modsqr",big_modsqr},
		{"modneg",big_modneg},
		{"modsub",big_modsub},
		{"jacobi",big_jacobi},
		{"__gc", big_destroy},
		{"__tostring",big_to_hex},
		{NULL,NULL}
	};
	zen_add_class(L, "big", big_class, big_methods);
	return 1;
}
