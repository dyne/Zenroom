%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "zenroom.h"

/* declarations to fix warnings from sloppy
   yacc/byacc/bison code generation. */
extern int yylex(void);
extern int yyparse();
extern FILE* yyin;
extern void yyerror(const char *s);

%}

%token GIVEN
%token WHEN
%token THEN
%token STRING

%union {
  int integer;
  char *string;
}

%%

statement:
  GIVEN STRING { printf("Given: %s\n", $<string>$); }
  | WHEN STRING { printf("When: %s\n", $<string>$); }
  | THEN STRING { printf("Then: %s\n", $<string>$); }
  ;

%%

int main(int argc, char** argv) {
	yyin = stdin;
	do {
		yyparse();
	} while(!feof(yyin));
    return 0;
}

void yyerror(const char* s) {
    fprintf(stderr, "Bison parse error: %s\n", s);
	exit(1);
}
