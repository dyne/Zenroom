%code requires{

#include <string.h>
#define YY_DECL int yylex (YYSTYPE* yylval, YYLTYPE * yylloc, yyscan_t yyscanner)
#ifndef FLEX_SCANNER 
#include "lexer.h"
#endif 

	//The macro below is used by bison for error reporting
	//it comes from stacck overflow
	//http://stackoverflow.com/questions/656703/how-does-flex-support-bison-location-exactly
#define YY_USER_ACTION							\
    yylloc->first_line = yylloc->last_line;		\
    yylloc->first_column = yylloc->last_column; \
    for(int i = 0; yytext[i] != '\0'; i++) {	\
        if(yytext[i] == '\n') {					\
            yylloc->last_line++;				\
            yylloc->last_column = 0;			\
        }										\
        else {									\
            yylloc->last_column++;				\
        }										\
    }


#include <inttypes.h>

#include <assert.h>

	int32_t safe_cast(int64_t value);
	uint32_t safe_unsigned_cast(int64_t value);

 }


%define api.pure full
%parse-param {yyscan_t yyscanner}
// {Function*& out}
%lex-param {yyscan_t yyscanner}
%locations 
%define parse.error verbose

%code provides{
	YY_DECL;
//	int yyerror(YYLTYPE * yylloc, yyscan_t yyscanner, Function*& out, const char* message);
	int yyerror(YYLTYPE * yylloc, yyscan_t yyscanner, const char* message);

}


%union {
	int64_t intconst;
	char* strconst;
}

//Below is where you define your tokens and their types. 
//for example, we have defined for you a T_int token, with type intconst
//the type is the name of a field from the union above


%token T_none
%token T_false
%token T_true
%token<intconst> T_int
%token<strconst> T_string
%token<strconst> T_ident

%token T_push_ref
%token T_load_ref
%token T_store_ref

// Grammar
%%

statement:
				T_string { fprintf(stdout, "%s\n",$<strconst>$); }
				;
%%

// Error reporting function. You should not have to modify this.
// int yyerror(YYLTYPE * yylloc, void* p, Function*& out, const char*  msg)
int yyerror(YYLTYPE * yylloc, void* p, const char*  msg)
{
	fprintf(stderr,"Error in line %u, col %u: %s\n", yylloc->last_line, yylloc->last_column, msg);
	return 0;
}

int32_t safe_cast(int64_t value)
{	
	int32_t new_value = (int32_t) value;

	assert(new_value == value);

	return new_value;
}


uint32_t safe_unsigned_cast(int64_t value)
{	
	int32_t new_value = (uint32_t) value;

	assert(new_value == value);

	assert (0 <= new_value);

	return new_value;
}
