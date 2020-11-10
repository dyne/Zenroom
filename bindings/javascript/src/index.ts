import Zenroom from "./zenroom.js";

type ZenroomProps = {
  data?: string | null;
  keys?: string | null;
  conf?: string | null;
};

type ZenroomResult = {
  result: string;
  logs: string;
};

export const zencode_exec = async (
  zencode: string,
  props?: ZenroomProps
): Promise<ZenroomResult> => {
  const Module = await Zenroom();
  return new Promise((resolve, reject) => {
    let result = "";
    let logs = "";
    const _exec = Module.cwrap("zencode_exec", "number", [
      "string",
      "string",
      "string",
      "string",
    ]);
    Module.print = (t: string) => (result += t);
    Module.printErr = (t: string) => (logs += t);
    Module.exec_ok = () => {
      resolve({ result, logs });
    };
    Module.exec_error = () => {
      reject({ result, logs });
    };
    Module.onAbort = () => {
      reject({ result, logs });
    };
    const { data = null, keys = null, conf = null } = { ...props };
    _exec(zencode, conf, keys, data);
  });
};

export const zenroom_exec = async (
  lua: string,
  props?: ZenroomProps
): Promise<ZenroomResult> => {
  const Module = await Zenroom();
  return new Promise((resolve, reject) => {
    let result = "";
    let logs = "";
    const _exec = Module.cwrap("zenroom_exec", "number", [
      "string",
      "string",
      "string",
      "string",
    ]);
    Module.print = (t: string) => (result += t);
    Module.printErr = (t: string) => (logs += t);
    Module.exec_ok = () => {
      resolve({ result, logs });
    };
    Module.exec_error = () => {
      reject({ result, logs });
    };
    Module.onAbort = () => {
      reject({ result, logs });
    };
    const { data = null, keys = null, conf = null } = { ...props };
    _exec(lua, conf, keys, data);
  });
};
