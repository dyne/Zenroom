
all: wiki
	@mkdir -p ../pub/api
	ldoc -X .


## select wiki pages
wiki:
	pandoc -f markdown -t html ../wiki/Syntax.md > Syntax
	pandoc -f markdown -t html ../wiki/Functional.md > Functional
	pandoc -f markdown -t html ../wiki/Schema.md > Schema
	pandoc -f markdown -t html ../wiki/StateMachine.md > StateMachine
