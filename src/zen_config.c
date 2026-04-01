/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2019-2026 Dyne.org foundation
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

////////////////////////
// valid configurations:
//
// debug=1..3
// rngseed=hex:[256 bits in hex notation]
// print=sys|stb|mutt
///////////////////////

#include <strings.h>
#include <string.h>
#include <ctype.h>

// Configuration parser, based on STB's C Lexer, see: stb_c_lexer.h

#define STB_C_LEX_C_DECIMAL_INTS    Y
#define STB_C_LEX_C_HEX_INTS        N
#define STB_C_LEX_C_OCTAL_INTS      N
#define STB_C_LEX_C_DECIMAL_FLOATS  N
#define STB_C_LEX_C99_HEX_FLOATS    N
#define STB_C_LEX_C_IDENTIFIERS     Y
#define STB_C_LEX_C_DQ_STRINGS      N
#define STB_C_LEX_C_SQ_STRINGS      N
#define STB_C_LEX_C_CHARS           N
#define STB_C_LEX_C_COMMENTS        N
#define STB_C_LEX_CPP_COMMENTS      N
#define STB_C_LEX_C_COMPARISONS     N
#define STB_C_LEX_C_LOGICAL         N
#define STB_C_LEX_C_SHIFTS          N
#define STB_C_LEX_C_INCREMENTS      N
#define STB_C_LEX_C_ARROW           N
#define STB_C_LEX_EQUAL_ARROW       N
#define STB_C_LEX_C_BITWISEEQ       N
#define STB_C_LEX_C_ARITHEQ         N
#define STB_C_LEX_PARSE_SUFFIXES    N
#define STB_C_LEX_DECIMAL_SUFFIXES  ""
#define STB_C_LEX_HEX_SUFFIXES      ""
#define STB_C_LEX_OCTAL_SUFFIXES    ""
#define STB_C_LEX_FLOAT_SUFFIXES    ""
#define STB_C_LEX_0_IS_EOF             N
#define STB_C_LEX_INTEGERS_AS_DOUBLES  N
#define STB_C_LEX_MULTILINE_DSTRINGS   N
#define STB_C_LEX_MULTILINE_SSTRINGS   N
#define STB_C_LEX_USE_STDLIB           Y
#define STB_C_LEX_COLON_IDENTIFIER    Y
#define STB_C_LEX_FLOAT_NO_DECIMAL     N
#define STB_C_LEX_DEFINE_ALL_TOKEN_NAMES  N
#define STB_C_LEX_DISCARD_PREPROCESSOR    Y
#define STB_C_LEXER_DEFINITIONS
#define STB_C_LEXER_IMPLEMENTATION

#include <zen_error.h>

#include <stb_c_lexer.h>

#include <zenroom.h>

static int parse_prefixed_hex(char *dst, size_t dst_len, const char *value,
			      const char *name, const char *prefix,
			      size_t payload_len) {
	size_t prefix_len = strlen(prefix);
	size_t value_len = strlen(value);
	size_t p;

	if(strncasecmp(value, prefix, prefix_len) != 0) {
		_err("Invalid %s data prefix (must be %s)\n", name, prefix);
		return 0;
	}
	if(value_len < prefix_len) {
		_err("Invalid length of %s: 0 (must be %u)\n",
		     name, (unsigned)payload_len);
		return 0;
	}
	if(value_len != prefix_len + payload_len || payload_len + 1 > dst_len) {
		_err("Invalid length of %s: %u (must be %u)\n",
		     name, (unsigned)(value_len - prefix_len),
		     (unsigned)payload_len);
		return 0;
	}
	for(p = prefix_len; p < value_len; p++) {
		if(!isxdigit((unsigned char)value[p])) {
			_err("Invalid hex digit in %s: %c\n", name, value[p]);
			return 0;
		}
	}

	memcpy(dst, value + prefix_len, payload_len);
	dst[payload_len] = 0x0;
	return 1;
}

static int parse_prefixed_decimal(char *dst, size_t dst_len, const char *value,
				  const char *name, size_t max_digits) {
	static const char prefix[] = "dec:";
	size_t prefix_len = sizeof(prefix) - 1;
	size_t value_len = strlen(value);
	size_t digits_len;
	size_t p;

	if(strncasecmp(value, prefix, prefix_len) != 0) {
		_err("Invalid %s data prefix (must be %s)\n", name, prefix);
		return 0;
	}
	if(value_len < prefix_len) {
		_err("Invalid length of %s, must be less than %u digits",
		     name, (unsigned)max_digits);
		return 0;
	}
	digits_len = value_len - prefix_len;
	if(digits_len == 0 || digits_len > max_digits || digits_len + 1 > dst_len) {
		_err("Invalid length of %s, must be less than %u digits",
		     name, (unsigned)max_digits);
		return 0;
	}
	for(p = prefix_len; p < value_len; p++) {
		if(!isdigit((unsigned char)value[p])) {
			_err("Invalid digit in %s: %c\n", name, value[p]);
			return 0;
		}
	}

	memcpy(dst, value + prefix_len, digits_len);
	dst[digits_len] = 0x0;
	return 1;
}

int zen_conf_parse(zenroom_t *ZZ, const char *configuration) {
	(void)stb__strchr;            // avoid compiler warnings
	(void)stb__clex_parse_string; // for unused functions
	if(!configuration) return 0;
	register int p, len;
	len = strnlen(configuration, MAX_CONFIG);
	if(len<3) return 0;
	for(p=0; p<len; p++) {
	  if(isalnum(configuration[p])) continue;
	  if(isspace(configuration[p])) continue;
	  if(configuration[p]==',') continue;
	  if(configuration[p]==':') continue;
	  if(configuration[p]=='=') continue;
	  // illegal character
	  return 0;
	}
	stb_lexer lex;
	char lexbuf[MAX_CONFIG];
	zconf curconf = NIL;

	stb_c_lexer_init(&lex, configuration, configuration+len, lexbuf, MAX_CONFIG);
	while (stb_c_lexer_get_token(&lex)) {
		if (lex.token == CLEX_parse_error) {
			_err( "%s: error parsing configuration: %s\n", __func__, configuration);
			return 0;
		}

		// rather simple finite state machine using zconf enum
		switch (lex.token) {
			// first token parsed, set enum for value
		case CLEX_id:
			if(strcasecmp(lex.string,"debug")==0)   { curconf = VERBOSE; break; } // int
			if(strcasecmp(lex.string,"verbose")==0) { curconf = VERBOSE; break; } // int
			if(strcasecmp(lex.string,"scope")==0)   { curconf = SCOPE;   break; } // str
			if(strcasecmp(lex.string,"rngseed")==0) { curconf = RNGSEED; break; } // str
			if(strcasecmp(lex.string,"logfmt") ==0) { curconf = LOGFMT;  break; } // str
			if(strcasecmp(lex.string,"maxiter")==0) { curconf = MAXITER; break; } // str
			if(strcasecmp(lex.string,"maxmem")==0)  { curconf = MAXMEM;  break; } // str
			if(strcasecmp(lex.string,"memblocknum")==0)  { curconf = MEMBLOCKNUM;  break; } // int
			if(strcasecmp(lex.string,"memblocksize")==0)  { curconf = MEMBLOCKSIZE;  break; } // int
			if(curconf==RNGSEED) {
				if(!parse_prefixed_hex(ZZ->zconf_rngseed,
						       sizeof(ZZ->zconf_rngseed),
						       lex.string, "rngseed", "hex:",
						       RANDOM_SEED_LEN * 2)) {
					return 0;
				}
				break;
			}
			if(curconf==LOGFMT) {
			  int len = strlen(lex.string);
			  if( len != 4) { // must be 4 chars
				_err( "Invalid length of log format: %u (must be 4)\n",len);
				return 0;
			  }
			  if(strncasecmp(lex.string, "json", 4) == 0) ZZ->logformat = LOG_JSON;
			  else if(strncasecmp(lex.string, "text", 4) == 0) ZZ->logformat = LOG_TEXT;
			  else {
				_err( "Invalid log format string: %s\n",lex.string);
				return 0;
			  }
			  break;
			}
			if(curconf==SCOPE) {
			  int len = strlen(lex.string);
			  if( len != 4 && len != 5) {
				// must be 4 or 5 chars (full or given)
				_err( "Invalid scope config string: %u bytes\n",len);
				return 0;
			  }
			  if(strncasecmp(lex.string, "full", 4) == 0) ZZ->scope = SCOPE_FULL;
			  else if(strncasecmp(lex.string, "given", 5) == 0) ZZ->scope = SCOPE_GIVEN;
			  else {
				_err( "Invalid scope config string: %s\n",lex.string);
				return 0;
			  }
			  break;
			}
			if(curconf==MAXITER) {
				if(!parse_prefixed_decimal(ZZ->str_maxiter,
							   sizeof(ZZ->str_maxiter),
							   lex.string, "maxiter",
							   STR_MAXITER_LEN)) {
					return 0;
				}
				break;
			}
			if(curconf==MAXMEM) {
				if(!parse_prefixed_decimal(ZZ->str_maxmem,
							   sizeof(ZZ->str_maxmem),
							   lex.string, "maxmem",
							   STR_MAXMEM_LEN)) {
					return 0;
				}
				break;
			}
			_err( "Invalid configuration: %s\n", lex.string);
			curconf = NIL;
			return 0;

		case CLEX_intlit:
			if(curconf==VERBOSE) { ZZ->debuglevel = lex.int_number; break; }
			if(curconf==MEMBLOCKNUM) { ZZ->sfpool_blocknum = lex.int_number; break; }
			if(curconf==MEMBLOCKSIZE) { ZZ->sfpool_blocksize = lex.int_number; break; }
			_err( "Invalid integer configuration\n");
			curconf = NIL;
			return 0;

		default:
			if(lex.token == ',') { curconf = NIL; break; }
				if(lex.token == '=' && curconf == NIL) {
					_err( "Undefined config variable\n");
					break; }
				if(lex.token == '=' && curconf != NIL) break; // OK
				_err( "%s: Invalid string in configuration: %lu\n", __func__, lex.token);
				return 0;
			}
		}
		return 1;
	}
