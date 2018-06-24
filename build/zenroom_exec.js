// try this script from nodejs with a script as argument:
// nodejs zenroom_exec.js ../../examples/keygen.lua

const fs = require('fs')

const zenroom_module = require('./nodejs/zenroom.js')
fs.writeFileSync('zenroom.js.mem', fs.readFileSync('./nodejs/zenroom.js.mem'));

zenroom_module.exec_ok    = () => 0
zenroom_module.exec_error = () => 0

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

