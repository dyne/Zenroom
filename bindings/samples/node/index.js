import { zencode_exec } from "zenroom";

const hello = `Given nothing
Then print the string 'sai chi ti saluta?'`;

zencode_exec(hello, {}).then(console.log);
