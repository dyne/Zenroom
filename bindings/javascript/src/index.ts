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
    cache.module = await Zenroom({
      print: () => {},
      printErr: () => {},
    });
    cache.module.exec_ok = () => {};
    cache.module.exec_error = () => {};
    cache.module.onAbort = () => {};
  }
  return cache.module;
};

const DEFAULT_STDOUT_BYTES = 64 * 1024;
const DEFAULT_STDERR_BYTES = 64 * 1024;

const readCString = (heap: Uint8Array, ptr: number, maxBytes: number): string => {
  let end = ptr;
  const limit = ptr + maxBytes;
  while (end < limit && heap[end] !== 0) {
    end += 1;
  }
  return new TextDecoder().decode(heap.subarray(ptr, end));
};

const callBufferApi = async (
  name: string,
  argTypes: string[],
  args: Array<string | number | null>,
  stdoutBytes: number = DEFAULT_STDOUT_BYTES,
  stderrBytes: number = DEFAULT_STDERR_BYTES
): Promise<ZenroomResult> => {
  const Module = await getModule();
  const exec = Module.cwrap(name, "number", [
    ...argTypes,
    "number",
    "number",
    "number",
    "number",
  ]);
  const stdoutPtr = Module._malloc(stdoutBytes);
  const stderrPtr = Module._malloc(stderrBytes);
  try {
    Module.HEAPU8.fill(0, stdoutPtr, stdoutPtr + stdoutBytes);
    Module.HEAPU8.fill(0, stderrPtr, stderrPtr + stderrBytes);
    const status = exec(...args, stdoutPtr, stdoutBytes, stderrPtr, stderrBytes);
    const result = readCString(Module.HEAPU8, stdoutPtr, stdoutBytes);
    const logs = readCString(Module.HEAPU8, stderrPtr, stderrBytes);
    if (status === 0) {
      return { result, logs };
    }
    throw { result, logs };
  } finally {
    Module._free(stdoutPtr);
    Module._free(stderrPtr);
  }
};

const callPrintApi = async (
  name: string,
  argTypes: string[],
  args: Array<string | number | null>
): Promise<ZenroomResult> => {
  const Module = await getModule();
  return new Promise((resolve, reject) => {
    let result = "";
    let logs = "";
    const exec = Module.cwrap(name, "number", argTypes);
    const prevPrint = Module.print;
    const prevPrintErr = Module.printErr;
    const prevExecOk = Module.exec_ok;
    const prevExecError = Module.exec_error;
    const prevOnAbort = Module.onAbort;
    const restore = () => {
      Module.print = prevPrint;
      Module.printErr = prevPrintErr;
      Module.exec_ok = prevExecOk;
      Module.exec_error = prevExecError;
      Module.onAbort = prevOnAbort;
    };
    Module.print = (t: string) => (result += t);
    Module.printErr = (t: string) => (logs += t);
    Module.exec_ok = () => {
      restore();
      resolve({ result, logs });
    };
    Module.exec_error = () => {
      restore();
      reject({ result, logs });
    };
    Module.onAbort = () => {
      restore();
      reject({ result, logs });
    };
    exec(...args);
  });
};

const trimTrailingNewline = ({ result, logs }: ZenroomResult): ZenroomResult => ({
  result: result.replace(/\n$/, ""),
  logs,
});

const zenroomExecToBuf = async (
  lua: string,
  props?: ZenroomProps
): Promise<ZenroomResult> => {
  const { data = null, keys = null, extra = null, context = null, conf = null } = { ...props };
  return await callBufferApi(
    "zenroom_exec_tobuf",
    ["string", "string", "string", "string", "string", "string"],
    [lua, conf, keys, data, extra, context]
  );
};

const isSafeIdentifier = (value: string): boolean => /^[A-Za-z0-9_]+$/.test(value);

const isHex = (value: string): boolean =>
  value.length % 2 === 0 && /^[0-9a-fA-F]*$/.test(value);

export const bytesToHex = (bytes: Uint8Array): string =>
  Array.from(bytes, (byte) => byte.toString(16).padStart(2, "0")).join("");

export const hexToBytes = (hex: string): Uint8Array => {
  if (!isHex(hex)) {
    throw new Error("Invalid hex string");
  }
  const out = new Uint8Array(hex.length / 2);
  for (let i = 0; i < hex.length; i += 2) {
    out[i / 2] = parseInt(hex.slice(i, i + 2), 16);
  }
  return out;
};

export const utf8ToHex = (value: string): string =>
  bytesToHex(new TextEncoder().encode(value));

export const hexToUtf8 = (hex: string): string =>
  new TextDecoder().decode(hexToBytes(hex));

export const zencode_exec = async (
  zencode: string,
  props?: ZenroomProps
): Promise<ZenroomResult> => {
  const { data = null, keys = null, extra = null, context = null, conf = null } = { ...props };
  return await callPrintApi(
    "zencode_exec",
    ["string", "string", "string", "string", "string", "string"],
    [zencode, conf, keys, data, extra, context]
  );
};

export const zenroom_exec = async (
  lua: string,
  props?: ZenroomProps
): Promise<ZenroomResult> => {
  const { data = null, keys = null, extra = null, context = null, conf = null } = { ...props };
  return await callPrintApi(
    "zenroom_exec",
    ["string", "string", "string", "string", "string", "string"],
    [lua, conf, keys, data, extra, context]
  );
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

export const hashHex = async (
  hashType: string,
  msgHex: string
): Promise<ZenroomResult> => {
  if (!isHex(msgHex)) {
    throw new Error("Invalid hex string");
  }
  return trimTrailingNewline(
    await callBufferApi("zenroom_hash_hex_tobuf", ["string", "string"], [hashType, msgHex])
  );
};

export const pbkdf2Hex = async (
  hashType: string,
  passwordHex: string,
  saltHex: string,
  iterations: number,
  keylen: number
): Promise<ZenroomResult> => {
  if (!isHex(passwordHex) || !isHex(saltHex)) {
    throw new Error("Invalid hex string");
  }
  return trimTrailingNewline(
    await callBufferApi(
      "zenroom_pbkdf2_hex_tobuf",
      ["string", "string", "string", "number", "number"],
      [hashType, passwordHex, saltHex, iterations, keylen]
    )
  );
};

export const signKeygenHex = async (
  algo: string,
  rngseed: string | null = null
): Promise<ZenroomResult> =>
  trimTrailingNewline(
    await callBufferApi("zenroom_sign_keygen_tobuf", ["string", "string"], [algo, rngseed])
  );

export const signPubgenHex = async (
  algo: string,
  keyHex: string
): Promise<ZenroomResult> => {
  if (!isHex(keyHex)) {
    throw new Error("Invalid hex string");
  }
  return trimTrailingNewline(
    await callBufferApi("zenroom_sign_pubgen_tobuf", ["string", "string"], [algo, keyHex])
  );
};

export const signCreateHex = async (
  algo: string,
  keyHex: string,
  msgHex: string
): Promise<ZenroomResult> => {
  if (!isHex(keyHex) || !isHex(msgHex)) {
    throw new Error("Invalid hex string");
  }
  return trimTrailingNewline(
    await callBufferApi("zenroom_sign_create_tobuf", ["string", "string", "string"], [algo, keyHex, msgHex])
  );
};

export const signVerifyHex = async (
  algo: string,
  pubkeyHex: string,
  msgHex: string,
  sigHex: string
): Promise<ZenroomResult> => {
  if (!isHex(pubkeyHex) || !isHex(msgHex) || !isHex(sigHex)) {
    throw new Error("Invalid hex string");
  }
  return trimTrailingNewline(
    await callBufferApi(
      "zenroom_sign_verify_tobuf",
      ["string", "string", "string", "string"],
      [algo, pubkeyHex, msgHex, sigHex]
    )
  );
};

export const merkleRootHex = async (
  leavesHex: string[],
  hashType: string = "sha256"
): Promise<ZenroomResult> => {
  if (!isSafeIdentifier(hashType)) {
    throw new Error("Invalid hash type");
  }
  if (!Array.isArray(leavesHex) || leavesHex.length === 0) {
    throw new Error("Expected at least one leaf");
  }
  if (leavesHex.some((leaf) => !isHex(leaf))) {
    throw new Error("Invalid hex string");
  }
  const leavesLua = leavesHex.map((leaf) => `O.from_hex('${leaf}')`).join(", ");
  const script = `local MT = require'crypto_merkle'
local leaves = {${leavesLua}}
print(MT.create_merkle_root(leaves, '${hashType}'):hex())`;
  return trimTrailingNewline(await zenroomExecToBuf(script));
};

export const merkleProofVerifyHex = async (
  proofHex: string[],
  position: number,
  rootHex: string,
  leafCount: number,
  hashType: string = "sha256"
): Promise<ZenroomResult> => {
  if (!isSafeIdentifier(hashType)) {
    throw new Error("Invalid hash type");
  }
  if (!isHex(rootHex) || proofHex.some((leaf) => !isHex(leaf))) {
    throw new Error("Invalid hex string");
  }
  const proofLua = proofHex.map((leaf) => `O.from_hex('${leaf}')`).join(", ");
  const script = `local MT = require'crypto_merkle'
local proof = {${proofLua}}
local ok = MT.verify_proof(proof, ${position}, O.from_hex('${rootHex}'), ${leafCount}, '${hashType}')
print(ok and '1' or '0')`;
  return trimTrailingNewline(await zenroomExecToBuf(script));
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
