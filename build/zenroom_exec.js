#!/usr/bin/env node
// try this script from nodejs with a script as argument:
if ( process.argv[2] === undefined ) {
	console.log("usage: zenroom_exec.js script_file.lua")
	console.log("for example: zenroom_exec.js example/hello.lua")
	console.log("for a complete wrapper see: https://github.com/decodeproject/zenroomjs")
    return(1)
}

const zenroom_module = require('./zenroom.js')

// use in case the .mem file is not in the same directory as the .js
// const fs = require('fs')
// fs.writeFileSync('zenroom.js.mem', fs.readFileSync('./nodejs/zenroom.js.mem'));

zenroom_module.exec_ok    = () => 0
zenroom_module.exec_error = () => 0
zenroom_module.print = text => console.log(text)

const zenroom = (script_file=process.argv[2],
				 conf=null,
				 keys_file=process.argv[3], data_file=process.argv[4],
				 verbosity=1) => {
	const enc = { encoding: 'utf8' }
	const script = fs.readFileSync(script_file, enc)
	const config = null
	const keys = (keys_file) ? fs.readFileSync(keys_file, enc) : null
	const data = (data_file) ? fs.readFileSync(data_file, enc) : null

	return zenroom_module.ccall('zenroom_exec', 'number',
								['string', 'string', 'string', 'string',
								 'number'],
								[script, config, keys, data, verbosity])
}
zenroom()
