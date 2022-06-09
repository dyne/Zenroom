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
#include <stdio.h>
#include <stdlib.h>

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
	int len = strlen(configuration);
	if(len<3) return 0;
	stb_lexer lex;
	char lexbuf[MAX_CONFIG];
	zconf curconf = NIL;
	// ZZ->zconf_rngseed[0] = '\0';
	// ZZ->zconf_printf = LIBC;

	// char *lexbuf = (char*)malloc(MAX_CONFIG);
	stb_c_lexer_init(&lex, configuration, configuration+len, lexbuf, MAX_CONFIG);
	while (stb_c_lexer_get_token(&lex)) {
		if (lex.token == CLEX_parse_error) {
			zerror(NULL, "%s: error parsing configuration: %s", __func__, configuration);
			// free(lexbuf);
			return 0;
		}

		// rather simple finite state machine using zconf enum
		switch (lex.token) {
			// first token parsed, set enum for value
		case CLEX_id:
			if(strcasecmp(lex.string,"debug")  ==0) { curconf = VERBOSE; break; } // bool
			if(strcasecmp(lex.string,"verbose")==0) { curconf = VERBOSE; break; }
			if(strcasecmp(lex.string,"rngseed")  ==0) { curconf = RNGSEED;   break; } // str
			if(strcasecmp(lex.string,"print") ==0) { curconf = PRINTF;   break; } // str
			if(curconf==RNGSEED) {
				int len = strlen(lex.string);
				if( len-4 != RANDOM_SEED_LEN *2) { // hex doubles size
					zerror(NULL, "Invalid length of random seed: %u (must be %u)",
					      len/2, RANDOM_SEED_LEN);
					// free(lexbuf);
					return 0;
				}
				if(strncasecmp(lex.string, "hex:", 4) != 0) { // hex: prefix needed
					zerror(NULL, "Invalid rngseed data prefix (must be hex:)");
					// free(lexbuf);
					return 0;
				}
				// copy string and null terminate
				memcpy(ZZ->zconf_rngseed, lex.string+4, RANDOM_SEED_LEN*2);
				ZZ->zconf_rngseed[(RANDOM_SEED_LEN*2)] = 0x0;
				break;
			}

			if(curconf==PRINTF) {
				if(strcasecmp(lex.string,"stb") == 0) ZZ->zconf_printf = STB;
				else if(strcasecmp(lex.string,"sys") == 0) ZZ->zconf_printf = LIBC;
				else if(strcasecmp(lex.string,"mutt") == 0) ZZ->zconf_printf = MUTT;
				else {
					zerror(NULL, "Invalid print function: %s", lex.string);
					// free(lexbuf);
					return 0;
				}
				break;
			}

			// free(lexbuf);
			zerror(NULL, "Invalid configuration: %s", lex.string);
			curconf = NIL;
			return 0;

		case CLEX_intlit:
			if(curconf==VERBOSE) { ZZ->debuglevel = lex.int_number; break; }
			// free(lexbuf);
			zerror(NULL, "Invalid integer configuration");
			curconf = NIL;
			return 0;

		default:
			if(lex.token == ',') { curconf = NIL; break; }
			if(lex.token == '=' && curconf == NIL) {
				warning(NULL, "Undefined config variable");
				break; }
			if(lex.token == '=' && curconf != NIL) break; // OK
			zerror(NULL, "%s: Invalid string in configuration: %c", __func__, lex.token);
			// free(lexbuf);
			return 0;
		}
	}
	// free(lexbuf);
	return 1;
}
