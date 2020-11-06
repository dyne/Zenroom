import Zenroom from "./zenroom.js";

type ZenroomProps = {
  data?: string | null;
  keys?: string | null;
  conf?: string | null;
};

export const zencode_exec = async (zencode: string, props?: ZenroomProps) => {
  const Module = await Zenroom();
  return new Promise((resolve, reject) => {
    let out = "";
    let error = "";
    const _exec = Module.cwrap("zencode_exec", "number", [
      "string",
      "string",
      "string",
      "string",
    ]);
    Module.print = (t: string) => (out += t);
    Module.printErr = (t: string) => (error += t);
    Module.exec_ok = () => {
      resolve(out);
    };
    Module.exec_error = () => {
      reject(error);
    };
    Module.onAbort = () => {
      reject(error);
    };
    const { data = null, keys = null, conf = null } = { ...props };
    _exec(zencode, conf, keys, data);
  });
};

export const zenroom_exec = async (lua: string, props?: ZenroomProps) => {
  const Module = await Zenroom();
  return new Promise((resolve, reject) => {
    let out = "";
    let error = "";
    const _exec = Module.cwrap("zenroom_exec", "number", [
      "string",
      "string",
      "string",
      "string",
    ]);
    Module.print = (t: string) => (out += t);
    Module.printErr = (t: string) => (error += t);
    Module.exec_ok = () => {
      resolve(out);
    };
    Module.exec_error = () => {
      reject(error);
    };
    Module.onAbort = () => {
      reject(error);
    };
    const { data = null, keys = null, conf = null } = { ...props };
    _exec(lua, conf, keys, data);
  });
};
