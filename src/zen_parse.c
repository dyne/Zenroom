/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2026 Dyne.org foundation
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

// auxiliary functions for parsing Zencode, used inside zencode.lua
// optimizations also happen here

// #include <stdio.h>
#include <ctype.h>
#include <strings.h>
#include <string.h>

#include <zen_error.h>

#include <lualib.h>
#include <lauxlib.h>

#include <zenroom.h>
#include <zen_octet.h>

#define MAX_DEPTH 4096

static char low[MAX_LINE]; // 1KB max for a single zencode line
// parse the first word until the first space, returns a new string
static int lua_parse_prefix(lua_State* L) { 
	const char *line;
	size_t size;
	line = luaL_checklstring(L,1,&size);
	register unsigned short int c;
	unsigned short fspace = 0;
	// skip space in front
	for(c=0; c<size && c<MAX_LINE && c<USHRT_MAX; c++) {
		if( !isspace((unsigned char)line[c]) ) break;
		fspace++; }
	for(; c<size && c<MAX_LINE && c<USHRT_MAX; c++) {
		if( isspace((unsigned char)line[c]) ) {
			low[c] = '\0'; break; }
		low[c] = (char)tolower((unsigned char)line[c]);
	}
	if(c>size || c==MAX_LINE) lua_pushnil(L);
	else lua_pushlstring(L,&low[fspace],c-fspace);
	return 1;
}

// internal use, trims the string to a provided destination which is
// pre-allocated
static size_t trimto(char *dest, const char *src, const size_t len) {
	register unsigned short int c;
	register unsigned short int d;
	for(c=0; c<len && isspace(src[c]); c++); // skip front space
	for(d=0; c<len; c++, d++) dest[d] = src[c];
	dest[d] = '\0'; // null termination
	return(d);
}

// trim whitespace in front and at end of string
static int lua_trim_spaces(lua_State* L) {
	const char* front;
	const char* end;
	size_t size;
	front = luaL_checklstring(L,1,&size);
	if (size == 0) end = front;
	else end = &front[size - 1];
	while (size && isspace((unsigned char)*front)) {
		size--;
		front++;
	}
	while (size && isspace((unsigned char)*end)) {
		size--;
		end--;
	}
	if (size == 0) lua_pushliteral(L, "");
	else lua_pushlstring(L, front, (size_t)(end - front) + 1);
	return 1;
}

// trim whitespace or single quote in front and at end of string
static int lua_trim_quotes(lua_State* L) {
	const char* front;
	const char* end;
	size_t size;
	front = luaL_checklstring(L,1,&size);
	if (size == 0) {
		lua_pushliteral(L, "");
		return 1;
	}
	end = &front[size - 1];
	while (size && (isspace((unsigned char)*front) || *front == '\'')) {
		size--;
		front++;
	}
	while (size && (isspace((unsigned char)*end) || *end == '\'')) {
		size--;
		end--;
	}
	if (size == 0) lua_pushliteral(L, "");
	else lua_pushlstring(L,front,(size_t)(end - front) + 1);
	return 1;
}

#include <ctype.h>

#define MAX_JSON_DEPTH 128

// helper: skip whitespace and literal \n \r \t sequences
#define SKIP_WS_AND_ESCAPES(ptr, end) \
    while ((ptr) < (end)) { \
        unsigned char ch__ = (unsigned char)*(ptr); \
        if (isspace(ch__)) { (ptr)++; continue; } \
        if (ch__ == '\\' && (ptr)+1 < (end)) { \
            unsigned char next__ = (unsigned char)*((ptr)+1); \
            if (next__ == 'n' || next__ == 'r' || next__ == 't') { (ptr)+=2; continue; } \
        } \
        break; \
    }

static int lua_unserialize_json(lua_State* L) {
    size_t size;
    const char *in = luaL_checklstring(L, 1, &size);
    const char *p = in;
    const char *end = in + size;

    int level = 0;
    char brackets[MAX_JSON_DEPTH];
    int in_literal_str = 0;

    // strip UTF‑8 BOM if present
    if ((size_t)(end - p) >= 3 &&
        (unsigned char)p[0] == 0xEF &&
        (unsigned char)p[1] == 0xBB &&
        (unsigned char)p[2] == 0xBF) {
        p += 3;
    }

    // skip leading whitespace and literal escapes
    SKIP_WS_AND_ESCAPES(p, end);
    if (p >= end) { lua_pushnil(L); return 1; }

    // must start with { or [
    if (*p != '{' && *p != '[') {
        // Return nil silently if no valid JSON start found
        // This allows the caller to gracefully handle trailing non-JSON content
        lua_pushnil(L);
        return 1;
    }

    if (level < MAX_JSON_DEPTH)
        brackets[level] = (*p == '{') ? '}' : ']';
    level++;
    p++;

    // tolerate escapes/whitespace immediately after first brace
    SKIP_WS_AND_ESCAPES(p, end);

    const char *json_end = NULL;

    for (; p < end; p++) {
        unsigned char ch = (unsigned char)*p;

        if (in_literal_str) {
            if (ch == '"') {
                // count preceding backslashes
                const char *q = p - 1;
                int backslashes = 0;
                while (q >= in && *q == '\\') { backslashes++; q--; }
                if ((backslashes % 2) == 0) {
                    in_literal_str = 0;
                }
            }
            continue;
        }

        // tolerate whitespace and literal escapes outside strings
        if (isspace(ch)) continue;
        if (ch == '\\' && p+1 < end) {
            unsigned char next = (unsigned char)*(p+1);
            if (next == 'n' || next == 'r' || next == 't') { p++; continue; }
        }

        switch (ch) {
        case '"':
            in_literal_str = 1;
            break;
        case '{': case '[':
            if (level < MAX_JSON_DEPTH)
                brackets[level] = (ch == '{') ? '}' : ']';
            level++;
            break;
        case '}': case ']':
            level--;
            if (level < 0) {
                lerror(L, "JSON format error: unexpected closing %c at pos %ld", ch, (long)(p - in + 1));
                lua_pushnil(L);
                return 1;
            }
            if (level < MAX_JSON_DEPTH && brackets[level] != ch) {
                lerror(L, "JSON format error: expected %c, found %c at pos %ld",
                       brackets[level], ch, (long)(p - in + 1));
                lua_pushnil(L);
                return 1;
            }
            if (level == 0) {
                json_end = p + 1;
            }
            break;
        default:
            break;
        }

        if (json_end) break;
    }

    if (!json_end) {
        lerror(L, "JSON appears truncated or malformed (size=%lu, level=%d)",
               (unsigned long)(end - in), level);
        lua_pushnil(L);
        return 1;
    }

    // push the JSON substring
    lua_pushlstring(L, in, (size_t)(json_end - in));

    // skip trailing whitespace and literal escapes
    const char *q = json_end;
    SKIP_WS_AND_ESCAPES(q, end);

    lua_pushlstring(L, q, (size_t)(end - q));
    return 2;
}

static int replace_first(char *s, const char *pat, const char *rep) {
	char *p = strstr(s, pat);
	size_t patlen;
	size_t replen;
	size_t tail;
	if (!p) return 0;
	patlen = strlen(pat);
	replen = strlen(rep);
	tail = strlen(p + patlen);
	if (patlen != replen) {
		memmove(p + replen, p + patlen, tail + 1);
	}
	memcpy(p, rep, replen);
	return 1;
}

static void replace_all(char *s, const char *pat, const char *rep) {
	size_t patlen = strlen(pat);
	size_t replen = strlen(rep);
	char *p;
	int rep_contains_pat;

	/* avoid undefined behavior / infinite loop on empty pattern */
	if (patlen == 0) {
		return;
	}

	/* detect self-amplifying replacements that can cause unbounded growth */
	rep_contains_pat = (replen >= patlen && strstr(rep, pat) != NULL);

	p = strstr(s, pat);
	while (p) {
		size_t tail = strlen(p + patlen);
		if (patlen != replen) {
			memmove(p + replen, p + patlen, tail + 1);
		}
		memcpy(p, rep, replen);

		/* 
		 * If the replacement is longer and contains the pattern,
		 * repeated replacements could grow without bound in a fixed buffer.
		 * In that case, perform only a single replacement to avoid overflow.
		 */
		if (rep_contains_pat && replen > patlen) {
			break;
		}
		p = strstr(p + replen, pat);
	}
}

static void strip_prefix_once(char *s, const char *prefix) {
	size_t plen = strlen(prefix);
	size_t len = strlen(s);
	if (len >= plen && strncmp(s, prefix, plen) == 0) {
		memmove(s, s + plen, len - plen + 1);
	}
}

static void collapse_and_trim_spaces(char *s) {
	char *r = s;
	char *w = s;
	int prev_space = 0;
	while (*r && isspace((unsigned char)*r)) r++;
	while (*r) {
		unsigned char c = (unsigned char)*r++;
		if (isspace(c)) {
			if (!prev_space) {
				*w++ = ' ';
				prev_space = 1;
			}
		} else {
			*w++ = (char)c;
			prev_space = 0;
		}
	}
	if (w > s && *(w - 1) == ' ') w--;
	*w = '\0';
}

static int lua_normalize_statement(lua_State* L) {
	size_t src_len;
	size_t to_len;
	const char *src = luaL_checklstring(L, 1, &src_len);
	const char *to = luaL_checklstring(L, 2, &to_len);
	size_t start = 0;
	size_t end = src_len;
	char buf[MAX_LINE];
	char *out;
	size_t i = 0, j = 0;
	int is_given;
	int is_then;
	if (src_len >= MAX_LINE) {
		return luaL_error(
			L,
			"Zencode line too long for normalization: %zu bytes (max %d)",
			src_len,
			MAX_LINE - 1
		);
	}
	while (start < end && isspace((unsigned char)src[start])) start++;
	while (end > start && isspace((unsigned char)src[end - 1])) end--;
	/* Replace quoted chunks with '' similarly to Lua gsub("'(.-)'","''"). */
	i = start;
	while (i < end) {
		if (src[i] == '\'') {
			size_t k = i + 1;
			while (k < end && src[k] != '\'') k++;
			if (k < end) {
				/* Ensure there is room for two apostrophes and the final '\0'. */
				if (j + 2 >= MAX_LINE) {
					j = MAX_LINE - 1;
					break;
				}
				buf[j++] = '\'';
				buf[j++] = '\'';
				i = k + 1;
				continue;
			}
		}
		/* Ensure there is room for one character and the final '\0'. */
		if (j + 1 >= MAX_LINE) {
			j = MAX_LINE - 1;
			break;
		}
		buf[j++] = src[i++];
	}
	buf[j] = '\0';

	replace_first(buf, " I ", " ");
	for (out = buf; *out; out++) {
		*out = (char)tolower((unsigned char)*out);
	}

	is_then = (to_len == 4 && strncmp(to, "then", 4) == 0) ||
		(to_len == 6 && strncmp(to, "thenif", 6) == 0);
	is_given = (to_len == 5 && strncmp(to, "given", 5) == 0);

	if (is_then) {
		replace_first(buf, " the ", " ");
	}
	if (is_given) {
		replace_first(buf, " the ", " ");
		replace_first(buf, " a ", " ");
		replace_first(buf, " an ", " ");
		replace_first(buf, " have ", " ");
		replace_first(buf, " known as ", " ");
		replace_first(buf, " valid ", " ");
	}

	strip_prefix_once(buf, "when ");
	strip_prefix_once(buf, "then ");
	strip_prefix_once(buf, "given ");
	strip_prefix_once(buf, "if ");
	strip_prefix_once(buf, "foreach ");
	strip_prefix_once(buf, "and ");

	strip_prefix_once(buf, "that ");
	replace_all(buf, " the ", " ");
	if (strncmp(buf, "an ", 3) == 0) {
		memmove(buf + 1, buf + 2, strlen(buf + 2) + 1); /* "an " -> "a " */
	}
	replace_first(buf, " valid ", " ");
	replace_first(buf, " all ", " ");
	replace_first(buf, " inside ", " in ");
	collapse_and_trim_spaces(buf);

	lua_pushstring(L, buf);
	return 1;
}


// removed because of unexplained segfault when used inside pcall to
// parse zencode: set_rule and set_scenario will explode, also seems
// to perform worse than pure Lua (see PR #709)

#if 0
char* strtok_single(char* str, char const* delims)
{
    static char* src = NULL;
    char *p, *ret = NULL;

    if (str != NULL)
        src = str;

    if (src == NULL)
        return NULL;

    if ((p = strpbrk(src, delims)) != NULL) {
        *p = 0;
        ret = src;
        src = ++p;
    } else {
        ret = src;
        src = NULL;
    }

    return ret;
}

static int lua_strtok(lua_State* L) {
	const char DEFAULT_SEP[] = " ";

	char copy[MAX_FILE];
	const char *sep = DEFAULT_SEP;

	const char *in;
	size_t size;
	register int i = 1;
	register char *token;

	in = luaL_checklstring(L, 1, &size);
	if(!in) {
		lua_pushnil(L);
		return 1;
	}
	if (lua_gettop(L) > 1) {
		sep = luaL_checklstring(L, 2, NULL);
	}

	lua_newtable(L);

	memcpy(copy, in, size+1);

	token = strtok_single(copy, sep);
	while(token != NULL) {
		lua_pushlstring(L, token, strlen(token));

		lua_rawseti(L, -2, i);

		token = strtok_single(NULL, sep);
		i = i + 1;
	}
	return 1;
}
#endif

// list scenarios embedded at build time in lualibs_detected.c
extern const char* const zen_scenarios[];
static int lua_list_scenarios(lua_State* L) {
	lua_newtable(L);
	register int i;
	for (i = 0; zen_scenarios[i] != NULL; i++) {
		lua_pushnumber(L, i + 1);  // Lua arrays are 1-indexed
		lua_pushstring(L, zen_scenarios[i]);
		lua_settable(L, -3);
	}
	return 1;
}

void zen_add_parse(lua_State *L) {
	// override print() and io.write()
	static const struct luaL_Reg custom_parser [] =
		{ {"parse_prefix", lua_parse_prefix},
		  {"trim", lua_trim_spaces},
		  {"trimq", lua_trim_quotes},
		  {"normalize_stmt", lua_normalize_statement},
		  {"jsontok", lua_unserialize_json},
		  {"zencode_scenarios", lua_list_scenarios},
		  {NULL, NULL} };
	lua_getglobal(L, "_G");
	luaL_setfuncs(L, custom_parser, 0);  // for Lua versions 5.2 or greater
	lua_pop(L, 1);
}
