
all: wiki
	ldoc -X .


## select wiki pages
wiki:
	pandoc -f markdown -t html ../wiki/Functional.md > Functional.html
	pandoc -f markdown -t html ../wiki/Schema.md > Schema.html
	pandoc -f markdown -t html ../wiki/StateMachine.md > StateMachine.html
