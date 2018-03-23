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

The base direct-syntax parser we use is a subset of LUA.

Below is a list of tutorials that also apply to Zenroom's implementation of the LUA direct syntax parser:
<ul>
<li><a href="http://lua-users.org/wiki/LuaTypesTutorial">Lua Types</a></li>
<li><a href="http://lua-users.org/wiki/AssignmentTutorial">Assigmnents</a></li>
<li><a href="http://lua-users.org/wiki/NumbersTutorial">Numbers</a></li>
<li><a href="http://lua-users.org/wiki/OperatorsTutorial">Operators</a></li>
<li><a href="http://bitop.luajit.org/api.html">Bitwise Operations</a></li>
<li><a href="http://lua-users.org/wiki/ControlStructureTutorial">Control Structures</a></li>
<li><a href="http://lua-users.org/wiki/StringLibraryTutorial">Strings</a></li>
<li><a href="http://lua-users.org/wiki/TablesTutorial">Tables</a> (useful for cjson() conversions)</li>
<li><a href="http://lua-users.org/wiki/FunctionsTutorial">Functions</a></li>
<li><a href="http://lua-users.org/wiki/ScopeTutorial">Scoping</a></li>
</ul>
]]
format='discount'
merge=true
-- use same dir as config.ld
style=true
template=true
backtick_references=false
file={
	'crypto.lua',
	'../../src/lua/functional.lua',
	'math.lua',
	'string.lua',
	'table.lua',
}
dir='../pub/api'
-- readme='../../README.md'
topics={
	'Functional.html',
	'Schema.html',
	'StateMachine.html',
}
	
style='!pale'
-- kind_names={topic='Manual',script='Programs'}
examples = {
    '../../examples/hello.lua',
    '../../examples/json-tables.lua',
    '../../examples/wave.lua',
    '../../examples/keygen.lua',
	'../../examples/crypt-to-multi.lua',
}
