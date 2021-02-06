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
// color=1,0
// seccomp=0,1
// rngseed=hex:[256 bytes in hex notation]
// memmanager=sys|lw|je
// memwipe=0,1
// print=sys|stb
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
extern void set_color(int on);

#include <jutils.h>
#include <zenroom.h>
#include <zen_memory.h>
#include <zen_config.h>

#include <stb_c_lexer.h>

typedef enum { NIL, VERBOSE, COLOR, SECCOMP, RNGSEED, MEMMGR, MEMWIPE, PRINTF } zconf;
static zconf curconf;

int zconf_seccomp = 0;
char zconf_rngseed[(RANDOM_SEED_LEN*2)+4]; // 0x and terminating \0
mmtype zconf_memmg = SYS;
int  zconf_memwipe = 0;
printftype zconf_printf = SYS;

int zen_conf_parse(const char *configuration) {
	(void)stb__strchr;            // avoid compiler warnings
	(void)stb__clex_parse_string; // for unused functions
	if(!configuration) return 0;
	int len = strlen(configuration);
	if(len<3) return 0;
	stb_lexer lex;
	char lexbuf[MAX_CONFIG];
	// char *lexbuf = (char*)malloc(MAX_CONFIG);
	stb_c_lexer_init(&lex, configuration, configuration+len, lexbuf, MAX_CONFIG);
	zconf_rngseed[0] = '\0'; // set zero rngseed as config flag
	curconf = NIL;
	while (stb_c_lexer_get_token(&lex)) {
		if (lex.token == CLEX_parse_error) {
			error(NULL,"%s: error parsing configuration: %s", __func__, configuration);
			// free(lexbuf);
			return 0;
		}

		// rather simple finite state machine using zconf enum
		switch (lex.token) {
			// first token parsed, set enum for value
		case CLEX_id:
			if(strcasecmp(lex.string,"debug")  ==0) { curconf = VERBOSE; break; } // bool
			if(strcasecmp(lex.string,"verbose")==0) { curconf = VERBOSE; break; }
			if(strcasecmp(lex.string,"color")  ==0) { curconf = COLOR;   break; } // bool
			if(strcasecmp(lex.string,"seccomp")  ==0) { // bool
#if (defined(ARCH_WIN) || defined(DISABLE_FORK)) || defined(ARCH_CORTEX) || defined(ARCH_BSD)
				warning(NULL, "protected mode (seccomp isolation) only available on Linux");
#else
				curconf = SECCOMP;
#endif
				break;
			}
			if(strcasecmp(lex.string,"rngseed")  ==0) { curconf = RNGSEED;   break; } // str
			if(strcasecmp(lex.string,"memmanager") ==0) { curconf = MEMMGR;   break; } // str
			if(strcasecmp(lex.string,"memwipe") ==0) { curconf = MEMWIPE;   break; } // bool
			if(strcasecmp(lex.string,"print") ==0) { curconf = PRINTF;   break; } // str

			if(curconf==MEMMGR) {
				if(strcasecmp(lex.string,"sys") == 0) zconf_memmg = SYS;
				else if(strcasecmp(lex.string,"lw") == 0) zconf_memmg = LW;
				else if(strcasecmp(lex.string,"je") == 0) zconf_memmg = JE;
				else {
					error(NULL,"Invalid memory manager: %s",lex.string);
					// free(lexbuf);
					return 0;
				}
				break;
			}

			if(curconf==RNGSEED) {
				int len = strlen(lex.string);
				if( len-4 != RANDOM_SEED_LEN *2) { // hex doubles size
					error(NULL,"Invalid length of random seed: %u (must be %u)",
					      len/2, RANDOM_SEED_LEN);
					// free(lexbuf);
					return 0;
				}
				if(strncasecmp(lex.string, "hex:", 4) != 0) { // hex: prefix needed
					error(NULL,"Invalid rngseed data prefix (must be hex:)");
					// free(lexbuf);
					return 0;
				}
				// copy string and null terminate
				memcpy(zconf_rngseed, lex.string+4, RANDOM_SEED_LEN*2);
				zconf_rngseed[(RANDOM_SEED_LEN*2)] = 0x0;
				break;
			}

			if(curconf==PRINTF) {
				if(strcasecmp(lex.string,"stb") == 0) zconf_printf = STB_PRINTF;
				else if(strcasecmp(lex.string,"sys") == 0) zconf_printf = LIBC_PRINTF;
				else if(strcasecmp(lex.string,"mutt") == 0) zconf_printf = MUTT_PRINTF;
				else {
					error(NULL,"Invalid print function: %s",lex.string);
					// free(lexbuf);
					return 0;
				}
				break;
			}

			// free(lexbuf);
			error(NULL,"Invalid configuration: %s", lex.string);
			curconf = NIL;
			return 0;

		case CLEX_intlit:
			if(curconf==VERBOSE) { set_debug  ( lex.int_number ); break; }
			if(curconf==COLOR)   { set_color  ( lex.int_number ); break; }
			if(curconf==SECCOMP) { zconf_seccomp = lex.int_number; break; }
			if(curconf==MEMWIPE) { zconf_memwipe = lex.int_number; break; }

			// free(lexbuf);
			error(NULL,"Invalid integer configuration");
			curconf = NIL;
			return 0;

		default:
			if(lex.token == ',') { curconf = NIL; break; }
			if(lex.token == '=' && curconf == NIL) {
				warning(NULL,"Undefined config variable");
				break; }
			if(lex.token == '=' && curconf != NIL) break; // OK
			error(NULL,"%s: Invalid string in configuration: %c",__func__, lex.token);
			// free(lexbuf);
			return 0;
		}
	}
	// free(lexbuf);
	return 1;
}
