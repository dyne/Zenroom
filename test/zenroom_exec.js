import fs from "fs";
import { pathToFileURL } from "url";

// Read CLI arguments
const [, , wasmPath, scriptFile, confString, keysFile, dataFile, sideloadFile] =
  process.argv;

// Dynamically import the Emscripten-generated module (built with `-sMODULARIZE=1 -sEXPORT_ES6=1`)
const C = (await import(pathToFileURL(wasmPath).href)).default();

const zenroomExec = (script, conf = null, keys = null, data = null) => {
  C.then((Module) => {
    Module.exec_ok = () => 0;
    Module.exec_error = () => 0;
    Module.print = (text) => console.log(text);
    Module.printErr = (text) => console.error(text);
    Module.ccall(
      "zenroom_exec",
      "number",
      ["string", "string", "string", "string", "number"],
      [script, conf, keys, data],
    );
  });
};

const zenroom = (
  script_file,
  conf_string = null,
  keys_file = null,
  data_file = null,
  sideload_file = null,
) => {
  const enc = { encoding: "utf8" };
  let script = fs.readFileSync(script_file, enc);
  if (sideload_file) {
    const sideload = fs.readFileSync(sideload_file, enc);
    script = `${sideload}\n${script}`;
  }
  const conf = conf_string;
  const keys = keys_file ? fs.readFileSync(keys_file, enc) : null;
  const data = data_file ? fs.readFileSync(data_file, enc) : null;
  return zenroomExec(script, conf, keys, data);
};

console.log(
  "[JS] zenroom %s %s %s %s %s",
  scriptFile,
  confString,
  keysFile,
  dataFile,
  sideloadFile,
);

console.time(scriptFile);
zenroom(scriptFile, confString, keysFile, dataFile, sideloadFile);
console.timeEnd(scriptFile);
console.log("@", "=".repeat(40), "@\n");
