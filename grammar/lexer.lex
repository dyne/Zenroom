
%{

#include <string.h>
#include "parser.h"
// You can put additional header files here.

%}

%option reentrant
%option noyywrap
%option never-interactive

int_const -?[0-9][0-9]*

whitespace   ([ \t\n]*)

%{
// Initial declarations
%}

name	[a-zA-Z_][a-zA-Z0-9_]*


string_const ("\""[^\n\"]*"\"")

Operator     ([\%\/\<\>\;\!\?\*\-\+\,\.\:\[\]\(\)\{\}\=\|\&\^\$])


comment      ("//"[^\n]*)

%%

{whitespace}   { /* skip */ }

{comment}      { /* skip */ }


{int_const}    { 
		//Rule to identify an integer constant. 
		//The return value indicates the type of token;
		//in this case T_int as defined in parser.yy.
		//The actual value of the constant is returned
		//in the intconst field of yylval (defined in the union
		//type in parser.yy).
			yylval->intconst = atoi(yytext);
			return T_int;
		}

%{
// The rest of your lexical rules go here. 
// rules have the form 
// pattern action
%}


{string_const}  {

			char*  tmp = strdup(yytext);
			// *tmp = tmp->substr(1, tmp->size() -2);
			yylval->strconst = tmp;
			return T_string;
		}



"None" 		{ return T_none; }
"true" 		{ return T_true; }
"false"		{ return T_false; }
"push_ref"     { return T_push_ref; }
"load_ref"     { return T_load_ref; }
"store_ref"    { return T_store_ref; }

{Operator} {  return yytext[0]; }

{name} 		{ 
			yylval->strconst = strdup(yytext);
			return T_ident;
		}

%%

