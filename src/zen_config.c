/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2019 Dyne.org foundation
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

#include <string.h>
#include <stdio.h>
#include <stdlib.h>

// Configuration parser, based on STB's C Lexer, see: stb_c_lexer.h

#define STB_C_LEX_C_DECIMAL_INTS    Y
#define STB_C_LEX_C_HEX_INTS        N
#define STB_C_LEX_C_OCTAL_INTS      N
#define STB_C_LEX_C_DECIMAL_FLOATS  N
#define STB_C_LEX_C99_HEX_FLOATS    N
#define STB_C_LEX_C_IDENTIFIERS     Y
#define STB_C_LEX_C_DQ_STRINGS      Y
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
#define STB_C_LEX_DOLLAR_IDENTIFIER    N
#define STB_C_LEX_FLOAT_NO_DECIMAL     N
#define STB_C_LEX_DEFINE_ALL_TOKEN_NAMES  N
#define STB_C_LEX_DISCARD_PREPROCESSOR    Y
#define STB_C_LEXER_DEFINITIONS
#define STB_C_LEXER_IMPLEMENTATION

extern void set_debug(int lev);
extern void set_color(int on);

#include <jutils.h>
#include <zenroom.h>
#include <zen_memory.h>

#include <stb_c_lexer.h>

typedef enum { NIL, VERBOSE, COLOR, SECCOMP,RNGSEED } zconf;
static zconf curconf = NIL;

int zconf_seccomp = 0;
char *zconf_rngseed_str = NULL;
int   zconf_rngseed_len = 0;

int zen_conf_parse(const char *configuration) {
	(void)stb__strchr;            // avoid compiler warnings
	(void)stb__clex_parse_string; // for unused functions
	if(!configuration) return 0;
	int len = strlen(configuration);
	if(len<3) return 0;
	stb_lexer lex;
	char *lexbuf = (char*)system_alloc(MAX_CONFIG);
	stb_c_lexer_init(&lex, configuration, configuration+len, lexbuf, MAX_CONFIG);
	while (stb_c_lexer_get_token(&lex)) {
		if (lex.token == CLEX_parse_error) {
			error(NULL,"%s: error parsing configuration: %s", __func__, configuration);
			system_free(lexbuf);
			return 0;
		}
		// rather simple finite state machine using zconf enum
		switch (lex.token) {
			// first token parsed, set enum for value
		case CLEX_id:
			if(strcasecmp(lex.string,"debug")  ==0) { curconf = VERBOSE; break; }
			if(strcasecmp(lex.string,"verbose")==0) { curconf = VERBOSE; break; }
			if(strcasecmp(lex.string,"color")  ==0) { curconf = COLOR;   break; }
			if(strcasecmp(lex.string,"seccomp")  ==0) { curconf = SECCOMP;   break; }
			if(strcasecmp(lex.string,"rngseed")  ==0) { curconf = RNGSEED;   break; }
			warning(NULL,"unrecognised configuration: %s",lex.string);
			curconf = NIL; break;
			// int value set based on current enum
		case CLEX_intlit:
			if(curconf==VERBOSE) { set_debug  (lex.int_number); break; }
			if(curconf==COLOR)   { set_color  (lex.int_number); break; }
			if(curconf==SECCOMP) { zconf_seccomp = lex.int_number; break; }
			system_free(lexbuf);
			error(NULL,"invalid configuration");
			return 0;
		case CLEX_dqstring:
			if(curconf==RNGSEED) {
				zconf_rngseed_len = lex.string_len;
				// quotes have been stripped, copy string and null terminate
				zconf_rngseed_str = zen_memory_alloc(lex.string_len+1);
				memcpy(zconf_rngseed_str, lex.string, lex.string_len);
				lex.string[lex.string_len] = 0x0;
				break; }
			system_free(lexbuf);
			error(NULL,"invalid configuration");
			return 0;

		default:
			if(lex.token == ',') { curconf = NIL; break; }
			if(lex.token == '=' && curconf == NIL) {
				warning(NULL,"undefined config variable");
				break; }
			if(lex.token == '=' && curconf != NIL) break; // OK
			if(lex.token == '"' && curconf != NIL) break; // OK
			error(NULL,"%s: invalid string in configuration: %c",__func__, lex.token);
			system_free(lexbuf);
			return 0;
		}
	}
	system_free(lexbuf);
	return 1;
}
