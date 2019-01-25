project='Zenroom'
title='Zenroom API documentation'
description='Zenroom - Application Protocol Interface documentation'
full_description=[[
Zenroom is a portable language interpreter inspired by
language-theoretical security and designed to be small,
attack-resistant and very portable. Its main use case is
distributed computing of untrusted code, for instance it can be
used for delicate cryptographic operations.  Here is the
"application protocol interface" documentation of the cryptographic
primitive functions that are made available by zenroom in its
computations.

For more information see the homepage of this project: <a
href="https://zenroom.dyne.org">zenroom.dyne.org</a>.

<img src="https://www.dyne.org/wp-content/uploads/2015/12/software_by_dyne.png" alt="Software by Dyne.org">

]]
format='discount'
merge=true
-- use same dir as config.ld
style=true
template=true
backtick_references=false
file={
	'../../src/zen_octet.c',
	'../../src/zen_random.c',
	'../../src/zen_hash.c',
	'../../src/zen_ecdh.c',
	'../../src/zen_ecp.c',
	'../../src/zen_ecp2.c',
	'../../src/zen_big.c',
	'../../src/lua/functional.lua',
	'math.lua',
	'string.lua',
	'table.lua',
}
dir='../pub/api'
-- readme='../../README.md'
topics={
	'Syntax',
	'Functional',
	'Schema',
	'StateMachine',
	'Embed',
}
	
style='css'
kind_names={topic='Tutorials',script='Programs'}
examples = {
    '../../examples/hello.lua',
    '../../examples/json-tables.lua',
    '../../examples/keygen.lua',
	'../../examples/crypt-to-multi.lua',
}
