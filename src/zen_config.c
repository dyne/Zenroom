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

////////////////////////
// valid configurations:
//
// debug=1..3
// rngseed=hex:[256 bits in hex notation]
// print=sys|stb|mutt
///////////////////////

#include <strings.h>
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

extern void set_debug(int lev);

#include <zenroom.h>
#include <zen_error.h>

#include <stb_c_lexer.h>

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
	// ZZ->zconf_rngseed[0] = '\0';

	// char *lexbuf = (char*)malloc(MAX_CONFIG);
	stb_c_lexer_init(&lex, configuration, configuration+len, lexbuf, MAX_CONFIG);
	while (stb_c_lexer_get_token(&lex)) {
		if (lex.token == CLEX_parse_error) {
			_err( "%s: error parsing configuration: %s\n", __func__, configuration);
			// free(lexbuf);
			return 0;
		}

		// rather simple finite state machine using zconf enum
		switch (lex.token) {
			// first token parsed, set enum for value
		case CLEX_id:
			if(strcasecmp(lex.string,"debug")  ==0) { curconf = VERBOSE; break; } // bool
			if(strcasecmp(lex.string,"verbose")==0) { curconf = VERBOSE; break; }
			if(strcasecmp(lex.string,"rngseed")==0) { curconf = RNGSEED; break; } // str
			if(strcasecmp(lex.string,"logfmt") ==0) { curconf = LOGFMT;  break; } // str
			if(strcasecmp(lex.string,"maxiter")==0) { curconf = MAXITER; break; } // str
			if(curconf==RNGSEED) {
				int len = strlen(lex.string);
				if( len-4 != RANDOM_SEED_LEN *2) { // hex doubles size
					_err( "Invalid length of random seed: %u (must be %u)\n",
					      len/2, RANDOM_SEED_LEN);
					// free(lexbuf);
					return 0;
				}
				if(strncasecmp(lex.string, "hex:", 4) != 0) { // hex: prefix needed
					_err( "Invalid rngseed data prefix (must be hex:)\n");
					// free(lexbuf);
					return 0;
				}
				for(p=4; p<RANDOM_SEED_LEN*2; p++) {
				  if(! isxdigit(lex.string[p]) ) {
					_err( "Invalid hex digit in random seed: %c\n",
						  lex.string[p]);
					return 0;
				  }
				}

				// copy string and null terminate
				memcpy(ZZ->zconf_rngseed, lex.string+4, RANDOM_SEED_LEN*2);
				ZZ->zconf_rngseed[(RANDOM_SEED_LEN*2)] = 0x0;
				break;
			}
			if(curconf==LOGFMT) {
			  int len = strlen(lex.string);
			  if( len != 4) { // must be 4 chars
				_err( "Invalid length of log format: %u (must be 4)\n",len);
				return 0;
			  }
			  if(strncasecmp(lex.string, "json", 4) == 0) ZZ->logformat = JSON;
			  else if(strncasecmp(lex.string, "text", 4) == 0) ZZ->logformat = TEXT;
			  else {
				_err( "Invalid log format string: %s\n",lex.string);
				return 0;
			  }
			  break;
			}
			if(curconf==MAXITER) {
				int len = strlen(lex.string);
				if( len-4 > STR_MAXITER_LEN || len < 5) { // hex doubles size
					_err( "Invalid length of maxiter, must be less than %u digits",
					      STR_MAXITER_LEN);
					// free(lexbuf);
					return 0;
				}
				if(strncasecmp(lex.string, "dec:", 4) != 0) { // dec: prefix needed
					_err( "Invalid rngseed data prefix (must be dec:)\n");
					// free(lexbuf);
					return 0;
				}
				for(p=4; p<len; p++) {
				  if(! isdigit(lex.string[p]) ) {
					_err( "Invalid digit in maxiter: %c\n",
						  lex.string[p]);
					return 0;
				  }
				}

				// copy string and null terminate
				memcpy(ZZ->str_maxiter, lex.string+4, len-4);
				ZZ->str_maxiter[len-4] = 0x0;
				break;
			}
			// free(lexbuf);
			_err( "Invalid configuration: %s\n", lex.string);
			curconf = NIL;
			return 0;

		case CLEX_intlit:
			if(curconf==VERBOSE) { ZZ->debuglevel = lex.int_number; break; }
			// free(lexbuf);
			_err( "Invalid integer configuration\n");
			curconf = NIL;
			return 0;

		default:
			if(lex.token == ',') { curconf = NIL; break; }
			if(lex.token == '=' && curconf == NIL) {
				_err( "Undefined config variable\n");
				break; }
			if(lex.token == '=' && curconf != NIL) break; // OK
			_err( "%s: Invalid string in configuration: %c\n", __func__, lex.token);
			// free(lexbuf);
			return 0;
		}
	}
	// free(lexbuf);
	return 1;
}
