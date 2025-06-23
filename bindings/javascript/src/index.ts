import Zenroom from "./zenroom.js";

type ZenroomProps = {
  data?: string | null;
  keys?: string | null;
  conf?: string | null;
  extra?: string | null;
  context?: string | null;
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
    const { data = null, keys = null, extra = null, context = null, conf = null } = { ...props };
    _exec(zencode, conf, keys, data, extra, context);
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
    const { data = null, keys = null, extra = null, context = null, conf = null } = { ...props };
    _exec(lua, conf, keys, data, extra, context);
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
  buffer: string
): Promise<ZenroomResult> => {
  const Module = await getModule();
  return new Promise((resolve, reject) => {
    let result = "";
    let logs = "";
    const _exec = Module.cwrap("zenroom_hash_update", "number", [
      "string",
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
  ab: string
): Promise<ZenroomResult> => {
  const bytesChunkSize = 1024 * 64;
  let ctx = await zenroom_hash_init(hash_type);
  let i = 0;
  for (i = 0; i < ab.length; i += bytesChunkSize) {
    const upperLimit =
      i + bytesChunkSize > ab.length ? ab.length : i + bytesChunkSize;
    const i8a = ab.slice(i, upperLimit);
    ctx = await zenroom_hash_update(ctx.result, i8a);
  }
  return await zenroom_hash_final(ctx.result);
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

export const introspect = async (zencode: string, props?: ZenroomProps) => {
  try {
    const { result } = await zencode_valid_input(zencode, props);
    return JSON.parse(result).CODEC;
  } catch (e) {
    let err: string;
    if (e.logs) {
      const heap = JSON.parse(e.logs)
        .filter((l: string) => l.startsWith("J64 HEAP:"))
        .map((l: string) => l.replace("J64 HEAP:", "").trim())[0];
      if (heap) {
        return Buffer.from(heap, "base64").toString("utf-8");
      }
      err = e.logs;
    }
    throw new Error("Failed to introspect zencode: " + (err ?? e.msg) );
  }
};

export const zencode_valid_code = async (
  zencode: string,
  conf: string | null = null,
  strict: number = 1
): Promise<ZenroomResult> => {
  const Module = await getModule();
  return new Promise((resolve, reject) => {
    let result = "";
    let logs = "";
    const _exec = Module.cwrap("zencode_valid_code", "number", [
      "string",
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
    _exec(zencode, conf, strict);
  });
}

export const safe_zencode_valid_code = async (
  zencode: string,
  conf: string | null = null
): Promise<ZenroomResult> => {
  return zencode_valid_code(zencode, conf, 0);
}

export const decode_error = (err: {result: string, logs: string}): string => {
  const errorPrefix = '[!]';
  const tracePrefix = 'J64 TRACE: ';
  try {
    const jsonError = JSON.parse(err.logs);
    const res = jsonError
      .reduce((acc: string[], l: string) => {
        if (l.startsWith(errorPrefix)) acc.push(l);
        if (l.startsWith(tracePrefix)) {
          const base64Trace = l.substring(tracePrefix.length);
          const binaryTrace = atob(base64Trace);
          const bytesTrace = new Uint8Array(binaryTrace.length);
          for (let i=0; i<binaryTrace.length; i++) {
            bytesTrace[i] = binaryTrace.charCodeAt(i);
          }
          const decoder = new TextDecoder("utf-8");
          const stringTrace = decoder.decode(bytesTrace.buffer);
          const jsonTrace = JSON.parse(stringTrace);
          acc.push(
            ...jsonTrace.
              reduce((inAcc: string[], l: string) => {
                if (l.startsWith(errorPrefix)) inAcc.push(l);
                return inAcc;
              },
              [] as string[]
            )
          )
        }
        return acc;
      },
      [] as string[]
    );
    return JSON.stringify(res);
  } catch {
    return err.logs;
  }
}

export const zencode_get_statements = async (
  scenario: string | null = null
): Promise<ZenroomResult> => {
  const Module = await getModule();
  return new Promise((resolve, reject) => {
    let result = "";
    let logs = "";
    const _exec = Module.cwrap("zencode_get_statements", "number", [
      "string"
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
    _exec(scenario);
  });
}
