CC ?= gcc
LEXER ?= flex
PARSER ?= bison

all: parser.c lexer.c
	${CC} -ggdb -o zencode-parser lexer.c parser.c main.c

%.c: %.yy
	${PARSER} --output=$*.c --defines=$*.h -v $*.yy

%.c: %.lex
	${LEXER}  --outfile=$*.c --header-file=$*.h $*.lex

clean:
	rm -f parser.h lexer.h parser.c lexer.c
	rm -f *.output
	rm -f zencode-parser
