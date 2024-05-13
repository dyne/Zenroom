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

const cache = {
  module: null,
};

const getModule = async () => {
  if (cache.module === null) {
    cache.module = await Zenroom();
  }
  return cache.module;
};

export const zencode_exec = async (
  zencode: string,
  props?: ZenroomProps
): Promise<ZenroomResult> => {
  const Module = await getModule();
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
  const Module = await getModule();
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

export const zenroom_hash_init = async (
  hash_type: string
): Promise<ZenroomResult> => {
  const Module = await getModule();
  return new Promise((resolve, reject) => {
    let result = "";
    let logs = "";
    const _exec = Module.cwrap("zenroom_hash_init", "number", ["string"]);
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
    _exec(hash_type);
  });
};

export const zenroom_hash_update = async (
  hash_ctx: string,
  buffer: Uint8Array
): Promise<ZenroomResult> => {
  const Module = await getModule();
  return new Promise((resolve, reject) => {
    let result = "";
    let logs = "";
    const _exec = Module.cwrap("zenroom_hash_update", "number", [
      "string",
      "array",
      "number",
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
    _exec(hash_ctx, buffer, buffer.length);
  });
};

export const zenroom_hash_final = async (
  hash_ctx: string
): Promise<ZenroomResult> => {
  const Module = await getModule();
  return new Promise((resolve, reject) => {
    let result = "";
    let logs = "";
    const _exec = Module.cwrap("zenroom_hash_final", "number", ["string"]);
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
    _exec(hash_ctx);
  });
};

export const zenroom_hash = async (
  hash_type: string,
  ab: ArrayBuffer
): Promise<ZenroomResult> => {
  const bytesChunkSize = 1024 * 64;
  let ctx = await zenroom_hash_init(hash_type);
  let i = 0;
  for (i = 0; i < ab.byteLength; i += bytesChunkSize) {
    const upperLimit =
      i + bytesChunkSize > ab.byteLength ? ab.byteLength : i + bytesChunkSize;
    const i8a = new Uint8Array(ab.slice(i, upperLimit));
    ctx = await zenroom_hash_update(ctx.result, i8a);
  }
  return zenroom_hash_final(ctx.result);
};

export const zencode_valid_input = async (
  zencode: string,
  props?: ZenroomProps
): Promise<ZenroomResult> => {
  const Module = await getModule();
  return new Promise((resolve, reject) => {
    let result = "";
    let logs = "";
    const _exec = Module.cwrap("zencode_valid_input", "number", [
      "string",
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
    _exec(zencode, null, props?.keys, props?.data, null);
  });
};

export const introspect = async (zencode, props?: ZenroomProps) => {
  try {
    const { result } = await zencode_valid_input(zencode, props);
    return JSON.parse(result).CODEC;
  } catch ({ logs }) {
    const heap = JSON.parse(logs)
      .filter((l) => l.startsWith("J64 HEAP:"))
      .map((l) => l.replace("J64 HEAP:", "").trim())[0];

    return JSON.parse(Buffer.from(heap, "base64").toString("utf-8"));
  }
};

export const zencode_valid_code = async (
  zencode: string,
  strict: number = 1
): Promise<ZenroomResult> => {
  const Module = await getModule();
  return new Promise((resolve, reject) => {
    let result = "";
    let logs = "";
    const _exec = Module.cwrap("zencode_valid_code", "number", [
      "string",
      "number",
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
    _exec(zencode, strict);
  });
}

export const safe_zencode_valid_code = async (
  zencode: string
): Promise<ZenroomResult> => {
  return zencode_valid_code(zencode, 0);
}
