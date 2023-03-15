%{
#include "bison.tab.h"
%}

%%

"given"   { return GIVEN; }
"when"    { return WHEN; }
"then"    { return THEN; }
[ \t\n]+  ;  // skip whitespace and newlines
.         { yylval->string = strdup(yytext); return STRING; }

%%

int yywrap() {
    return 1;
}
