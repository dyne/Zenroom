const fs = require('fs')
const util = require('util')
// you have to copy the js.mem file in the CWD as per design or --memory-init-file 0
// but it is not recommended as stated in https://github.com/kripken/emscripten/issues/2537
// fs.writeFileSync('zenroom.js.mem', fs.readFileSync('src/zenroom.js.mem'));

const C = require(process.argv[2])() // 1st arg is path to WASM zenroom.js


const zenroomExec = function(script, conf = null, keys = null, data = null) {
  C.then(function(Module){
	Module.exec_ok = () => 0
	Module.exec_error = () => 0
	Module.print = text => console.log(text)
	Module.printErr = text => console.error(text)
    Module.ccall(
      'zenroom_exec',
      'number',
      ['string', 'string', 'string', 'string', 'number'],
      [script, conf, keys, data]
    )
  })
}
const zenroom = function(script_file, conf_string=null, keys_file=null, data_file=null) {
  const enc = { encoding: 'utf8' }
  const script = fs.readFileSync(script_file, enc)
  const conf = conf_string
  const keys = (keys_file) ? fs.readFileSync(keys_file, enc) : null
  const data = (data_file) ? fs.readFileSync(data_file, enc) : null
  return zenroomExec(script, conf, keys, data)
}

console.log("[JS] zenroom %s %s %s %s",
            process.argv[3], // script file
            process.argv[4], // conf string
            process.argv[5], // keys file
            process.argv[6], // data file
		   )

console.time(process.argv[3])
zenroom(process.argv[3],process.argv[4],process.argv[5],process.argv[6])
console.timeEnd(process.argv[3])
console.log("@", "=".repeat(40), "@\n")
