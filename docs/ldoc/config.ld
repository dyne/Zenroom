project='Zenroom'
title='Zenroom API documentation'
description='Application Protocol Interface'
format='discount'
merge=true
-- use same dir as config.ld
style=true
template=true
backtick_references=false
file={
	'zenroom-api.lua',
	'../../src/lua/moses.lua',
	'../../src/lua/statemachine.lua'
}
dir='../pub/api'
readme='../../README.md'
style='!pale'
kind_names={topic='Manual',script='Programs'}
examples = {
    '../../examples/hello.lua',
    '../../examples/wave.lua',
    '../../examples/keygen.lua',
	'../../examples/crypt-to-multi.lua',
}
