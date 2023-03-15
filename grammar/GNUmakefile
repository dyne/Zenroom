CC := gcc

all: zencode-parser

bison.tab.c bison.tab.h: bison.y
	bison -t -v -d bison.y

flex.yy.c: flex.l bison.tab.h
	flex --bison-bridge flex.l

zencode-parser: flex.yy.c bison.tab.c bison.tab.h
	${CC} -I ../src bison.tab.c lex.yy.c -o zencode-parser

clean:
	rm -f *.tab.c *.tab.h
	rm -f *.yy.c
	rm -f zencode-parser
