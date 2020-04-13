project='Zenroom'
title='Zenroom LUA'
description='Documentation of Lua scripting in Zenroom'
full_description=[[

Zenroom is a portable language interpreter inspired by
language-theoretical security and designed to be small,
attack-resistant and very portable. Its main use case is distributed
computing of untrusted code, for instance it can be used for delicate
cryptographic operations.  Here is the documentation of the
cryptographic primitive functions that are made available by the Lua
direct-syntax parser in Zenroom.

For more information see the homepage of this project: <a
href="https://zenroom.org">Zenroom.org</a>.

<img src="https://www.dyne.org/wp-content/uploads/2015/12/software_by_dyne.png" alt="Software by Dyne.org">

]]
format='markdown'
merge=true
-- use same dir as config.ld
style=false
template=false
backtick_references=true
file={
	'../../../src/zen_octet.c',
	'../../../src/zen_hash.c',
	'../../../src/zen_aes.c',
	'../../../src/zen_ecdh.c',
	'../../../src/zen_ecp.c',
	'string.lua',
	'table.lua',
	'../../../src/lua/inspect.lua',
	'../../../src/lua/zencode.lua',
	'../../../src/zen_big.c',
}
dir='o'
kind_names={topic='Tutorials',script='Programs'}
examples = {
    '../../../examples/keygen.lua',
	'../../../examples/crypt-to-multi.lua',
}
