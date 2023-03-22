
#include "parser.h"
#include "lexer.h"

int main(int argc, char** argv)
{
  fprintf(stderr,"Using parser\n");
  void* scanner;
  yylex_init(&scanner);
  yyset_in(stdin, scanner);

  int rvalue = yyparse(scanner);
  if(rvalue == 1){
	fprintf(stderr,"Parsing failed\n");
	return 1;
  }

  return 0;
}
