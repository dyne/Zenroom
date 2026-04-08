import fs from "fs";
import { pathToFileURL } from "url";

// Read CLI arguments
const [, , wasmPath, scriptFile, confString, keysFile, dataFile, sideloadFile] =
  process.argv;

// Dynamically import the Emscripten-generated module (with `-sEXPORT_ES6=1 -sMODULARIZE=1`)
const C = (await import(pathToFileURL(wasmPath).href)).default();

const zencodeExec = (script, conf = null, keys = null, data = null, context = null) => {
  C.then((Module) => {
    Module.exec_ok = () => 0;
    Module.exec_error = () => 0;
    Module.print = (text) => console.log(text);
    Module.printErr = (text) => console.error(text);
    Module.ccall(
      "zencode_exec",
      "number",
      ["string", "string", "string", "string", "string", "string"],
      [script, conf, keys, data, null, context],
    );
  });
};

const zencode = (
  script_file,
  conf_string = null,
  keys_file = null,
  data_file = null,
  sideload_file = null,
) => {
  const enc = { encoding: "utf8" };
  const script = fs.readFileSync(script_file, enc);
  const conf = conf_string;
  const keys = keys_file ? fs.readFileSync(keys_file, enc) : null;
  const data = data_file ? fs.readFileSync(data_file, enc) : null;
  const sideload = sideload_file ? fs.readFileSync(sideload_file, enc) : null;
  const context = sideload ? `lua\n${sideload}` : null;
  return zencodeExec(script, conf, keys, data, context);
};

zencode(scriptFile, confString, keysFile, dataFile, sideloadFile);
