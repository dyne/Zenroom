# Zencode grammar parser

Experimental code to parse Zencode using Flex/Bison

## Grammar definition

```
<scenario> ::= <step> <scenario>
             | <step>

<step> ::= <given> <have> <named> <inside>
         | <when> <text>
         | <then> <text>

<given> ::= "given"

<when> ::= "when"

<then> ::= "then"

<text> ::= <string>
<have> ::= <string>
<named> ::= <string>
<inside> ::= <string>
```

The above is incomplete and omits finite-state-machine dependencies.

# Usage

Install flex and bison

Type `make`

```
cat << EOF | zencode-parser
given "I am known as Alice"
when "I I create my eddsa key""
then "print my 'keyring'
EOF
```
