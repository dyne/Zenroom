import test from "ava";

import {
  zencode_exec,
  zenroom_exec,
  zenroom_hash_init,
  zenroom_hash_update,
  zenroom_hash_final,
  zenroom_hash,
  introspect,
  zencode_valid_code,
  safe_zencode_valid_code,
  decode_error,
  zencode_get_statements,
} from "./index";
//import { TextEncoder } from "util";
//var enc = new TextEncoder();

const sanitizeZencodeParse = (result: string) => {
  const parsedResult = JSON.parse(result);
  parsedResult.invalid = parsedResult.invalid.map(([line, number, message]) => {
    if (typeof message === 'string') {
      message = message.replace(/\/zencode\.lua:\d+:/, '/zencode.lua:NNN:');
    }
    return [line, number, message];
  });
  return parsedResult;
}

//

test("does exists", (t) => {
  t.is(typeof zenroom_exec, "function");
  const p = zenroom_exec("print()").catch(() => {});
  t.true(p instanceof Promise);
});

test("does run hello world", async (t) => {
  const { result } = await zenroom_exec(`print('hello world!')`);
  t.is(result, "hello world!\n");
});

test("does parse data", async (t) => {
  const { result } = await zenroom_exec(`print(DATA)`, { data: "DATA INSIDE" });
  t.is(result, "DATA INSIDE\n");
});

test("does break gracefully", async (t) => {
  try {
    await zenroom_exec(`broken sapokdao`);
  } catch (e) {
    const lines = JSON.parse(e.logs);
    t.true(
      lines.includes(
        `[!] [source 'broken sapokdao']:1: syntax error near 'sapokdao'`
      )
    );
  }
});

test("does handle empty zencode", async (t) => {
  try {
    await zencode_exec(null);
    t.fail("NULL zencode script does not fail");
  } catch (e) {
    const lines = JSON.parse(e.logs);
    t.true(lines.includes("[!] NULL string as script argument"), e.logs);
  }
  try {
    await zencode_exec(``);
    t.fail("empty zencode script does not fail");
  } catch(e) {
    const lines = JSON.parse(e.logs);
    t.true(lines.includes("[!] Empty string as script argument"), e.logs);
  }
});

test("does handle empty lua", async (t) => {
  try {
    await zenroom_exec(null);
    t.fail("NULL lua script does not fail");
  } catch (e) {
    const lines = JSON.parse(e.logs);
    t.true(lines.includes("[!] NULL string as script argument"), e.logs);
  }
  try {
    await zenroom_exec(``);
    t.fail("empty lua script does not fail");
  } catch (e) {
    const lines = JSON.parse(e.logs);
    t.true(lines.includes("[!] Empty string as script argument"), e.logs);
  }
});

// cannot reproduce since timezone changes from CI to local
// github reports 3600 and local GMT+2 reports 0
// test("does access os.time()", async (t) => {
//   const {result} = await zenroom_exec(`print(os.time({year=1970, month=1, day=1, hour=1}))`);
//   t.is(result, "0\n");
// });

test("does run zencode", async (t) => {
  const { result } = await zencode_exec(`scenario simple:
  given nothing
  Then print all data`);
  t.is(result, "[]\n");
});

test("error format contains newlines", async (t) => {
  try {
    await zencode_exec(`a`);
  } catch (e) {
    const lines = JSON.parse(e.logs);
    t.true(lines.includes("[!] Zencode parser error"));
  }
});

test("handle broken zencode", async (t) => {
  try {
    await zencode_exec(`sapodksapodk`);
  } catch (e) {
    t.true(e.logs.includes(`Invalid Zencode prefix 1: 'sapodksapodk'`));
  }
});

test("Executes a zencode correctly", async (t) => {
  const random_name = Math.random().toString(36).substring(7);
  const { result } =
    await zencode_exec(`Scenario 'credential': credential keygen 
    Given that I am known as '${random_name}' 
    When I create the credential key
    and I create the issuer key
    Then print my 'keyring'`);
  t.is(typeof result, "string");
  const r = JSON.parse(result);
  t.is(typeof r[random_name], "object");
  t.is(typeof r[random_name]["keyring"]["credential"], "string");
  t.is(typeof r[random_name]["keyring"]["issuer"]["x"], "string");
  t.is(typeof r[random_name]["keyring"]["issuer"]["y"], "string");
});

test("Unknown variable error shown in logs", async (t) => {
  const random_name = Math.random().toString(36).substring(7);
  try {
    await zencode_exec(`Rule unknown ignore
      Given nothing
      Then print my '${random_name}'`);
    t.truthy(false);
  } catch (e) {
    const lines = JSON.parse(e.logs);
    let found = null;
    for (let log of lines) {
      if (log.startsWith("J64 TRACE")) {
        const encoded = log.substring("J64 TRACE: ".length);
        found = Buffer.from(encoded, "base64").toString("utf-8");
      }
    }
    t.truthy(
      found &&
        JSON.parse(found).some(
          (s: string) =>
            s.startsWith("[!]") && s.includes("No identity specified in WHO")
        )
    );
    t.truthy(
      lines.some(
        (s: string) =>
          s.startsWith("[!]") &&
          s.includes(`Zencode line 3: Then print my '${random_name}'`)
      )
    );
  }
});

test("Run hash api", async (t) => {
  let ctx = await zenroom_hash_init("sha512");
  t.is(
    ctx.result,
    "40000000000000000000000000000000008c9bcf367e6096a3ba7ca8485ae67bb2bf894fe72f36e3cf1361d5f3af54fa5d182e6ad7f520e511f6c3e2b8c68059b6bbd41fbabd9831f79217e1319cde05b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000"
  );
  // update with a string
  ctx = await zenroom_hash_update(
    ctx.result,
    "518985977ee21d2bf622a20567124fcbf11c72df805365835ab3c041f4a9cd8a0ad63c9dee1018aa21a9fa3720f47dc48006"
  );
  t.is(
    ctx.result,
    "49001000000000000000000000000000008c9bcf367e6096a3ba7ca8485ae67bb2bf894fe72f36e3cf1361d5f3af54fa5d182e6ad7f520e511f6c3e2b8c68059b6bbd41fbabd9831f79217e1319cde05b2b1de27e97858951cb4f126705a222f683655380df721cf18acda9f441c0b35aaa1810ee9d3cd60ac47df42037faa921068000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000"
  );
  // update with a string
  ctx = await zenroom_hash_update(
    ctx.result,
    "f1aa3dba544950f87e627f369bc2793ede21223274492cceb77be7eea50e5a509059929a16d33a9f54796cde5770c74bd3ecc25318503f1a41976407aff2"
  );
  t.is(
    ctx.result,
    "48003000000000000000000000000000008c9bcf367e6096a3ba7ca8485ae67bb2bf894fe72f36e3cf1361d5f3af54fa5d182e6ad7f520e511f6c3e2b8c68059b6bbd41fbabd9831f79217e1319cde05b2b1de27e97858951cb4f126705a222f683655380df721cf18acda9f441c0b35aaa1810ee9d3cd60ac47df42037faa9214954ba3daaf10680c29b367f627ef8504974322221de3e790ea5eee77bb7ce2cd3169a925990505a7057de6c79549f3a501853c2ecd34bc7f2af076497411a3f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000"
  );
  ctx = await zenroom_hash_final(ctx.result);
  t.is(
    ctx.result,
    "wAkmo3TN5VuPvXf1DaE2PaGXRNP0ZOB84xeUxaYbb5yFaJ+hz+E2VTUn/Ydr6RZzwsrC3RV7Le/qNghRttks9A=="
  );
});

test("Unknown hash type", async (t) => {
  try {
    await zenroom_hash_init("invalidhash");
  } catch (e) {
    t.is(e.logs, "zenroom_hash_init :: invalid hash type: invalidhash\n", e.logs);
  }
});

test("Wrong context prefix (update)", async (t) => {
  try {
    await zenroom_hash_update(
      "z",
      "518985977ee21d2bf622a20567124fcbf11c72df805365835ab3c041f4a9cd8a0ad63c9dee1018aa21a9fa3720f47dc48006"
    );
  } catch (e) {
    t.is(e.logs, "zenroom_hash_update :: invalid hash context prefix\n", e.logs);
  }
});

test("Wrong context prefix (final)", async (t) => {
  try {
    const res = await zenroom_hash_final("z");
    t.fail("zenroom_hash_final should fail"+JSON.stringify(res));
  } catch (e) {
    t.is(e.logs, "zenroom_hash_final :: invalid hash context prefix\n", e.logs);
  }
});

test("Use zenroom_hash with unknown hash function", async (t) => {
  try {
    const res = await zenroom_hash(
      "z",
      "518985977ee21d2bf622a20567124fcbf11c72df805365835ab3c041f4a9cd8a0ad63c9dee1018aa21a9fa3720f47dc48006"
    );
    console.log(res)
  } catch (e) {
    t.is(e.logs, "zenroom_hash_init :: invalid hash type: z\n", e.logs);
  }
});

test("Use zenroom_hash with small input", async (t) => {
  const hash = await zenroom_hash(
    "sha512",
    "518985977ee21d2bf622a20567124fcbf11c72df805365835ab3c041f4a9cd8a0ad63c9dee1018aa21a9fa3720f47dc48006f1aa3dba544950f87e627f369bc2793ede21223274492cceb77be7eea50e5a509059929a16d33a9f54796cde5770c74bd3ecc25318503f1a41976407aff2"
  );
  t.is(
    hash.result,
    "wAkmo3TN5VuPvXf1DaE2PaGXRNP0ZOB84xeUxaYbb5yFaJ+hz+E2VTUn/Ydr6RZzwsrC3RV7Le/qNghRttks9A=="
  );
});

test("Use zenroom_hash with big input", async (t) => {
  // multiple of chunk size
  const hash0 = await zenroom_hash(
    "sha512",
    "6162636462636465636465666465666765666768666768696768696A68696A6B696A6B6C6A6B6C6D6B6C6D6E6C6D6E6F6D6E6F706E6F7071".repeat(1024 * 64)
  );
  t.is(
    hash0.result,
    "tqyQvZM1JPW5sSokgVWXbLp3tA8NNkEWdBc8YUX+6aDhfFTNEmQmralYFnk4izrXppH7cK7fVi3cpIvJrV783g=="
  );

  // not multiple of chunk size
  const hash1 = await zenroom_hash(
    "sha512",
    "6162636462636465636465666465666765666768666768696768696A68696A6B696A6B6C6A6B6C6D6B6C6D6E6C6D6E6F6D6E6F706E6F7071".repeat(1087 * 73)
  );
  t.is(
    hash1.result,
    "HM5Pm1A/V/FqShY8sm6x4AU5O5B44Gs9+uXjDn6PhjSg9cSzlPa2MHXriPSZS4wuRYn0UgN2g9L3A+P7rOJRdA=="
  );
});

test("Check the introspection", async (t) => {
  const r = await introspect(
    `Scenario ethereum
Given I have a 'ethereum address'
and I have an 'ethereum address' named 'missing address'
and I have a 'keyring'
Then print codec`
  );
  t.deepEqual(r, {
    ethereum_address: {
      encoding: "complex",
      missing: true,
      name: "ethereum_address",
      schema: "ethereum_address",
      zentype: "e",
    },
    keyring: {
      encoding: "complex",
      missing: true,
      name: "keyring",
      schema: "keyring",
      zentype: "e",
    },
    missing_address: {
      encoding: "complex",
      missing: true,
      name: "missing_address",
      schema: "ethereum_address",
      zentype: "e",
    },
  });
});

test("Check the introspection with data", async (t) => {
  const data = `{
  "myFirstObject":{
     "myNumber":11223344,
     "myString":"Hello World!",
     "myStringArray":[
        "String1",
        "String2",
        "String3",
        "String4"
     ]
  },
   "Alice":{
     "keyring":{
      "ecdh":"AxLMXkey00i2BD675vpMQ8WhP/CwEfmdRr+BtpuJ2rM="
     }
    }
}`;
  const r = await introspect(
    `Given I am 'Alice'
    and I have my 'hex' named 'missing public key'
    Given I have a 'string array' named 'myStringArray' in 'myFirstObject'
    And I have a 'string dictionary' named 'does not exists' in 'myFirstObject'
    When I create the random 'random'
    Then print codec`,
    { keys: null, data: data }
  );

  t.deepEqual(r, {
    does_not_exists: {
      encoding: "string",
      missing: true,
      name: "does_not_exists",
      root: "myFirstObject",
      zentype: "d",
    },
    missing_public_key: {
      encoding: "hex",
      missing: true,
      name: "missing_public_key",
      root: "Alice",
      zentype: "e",
    },
    myStringArray: {
      encoding: "string",
      name: "myStringArray",
      root: "myFirstObject",
      zentype: "a",
    },
  });
});

test("parse simple contract", async (t) => {
  const { result } = await safe_zencode_valid_code(`Scenario ecdh
  Given nothing
  Then print all data`);
  t.deepEqual(JSON.parse(result), {invalid: [], ignored: []});
})

test("parse contract with an invalid statement", async (t) => {
  const { result } = await safe_zencode_valid_code(`Scenario ecdh
  Given gibberish
  Given nothing
  Then print all data`);
  const expected = {
    invalid: [
      [
        "  Given gibberish",
        2,
        "/zencode.lua:NNN: Zencode line 2 pattern not found (given): Given gibberish",
      ],
    ],
    ignored: [],
  };
  const parsedResult = sanitizeZencodeParse(result);
  t.deepEqual(parsedResult, expected);
})

test("parse contract with more than one invalid statement", async (t) => {
  const { result } = await safe_zencode_valid_code(`Scenario ecdh
  Given gibberish
  Given nothing
  When gibberish
  some other stuff
  Then print all data
  Then gibberish`);
  const expected = {
    "ignored":[],
    "invalid":[
      [
        "  Given gibberish",
        2,
        "/zencode.lua:NNN: Zencode line 2 pattern not found (given): Given gibberish"
      ],[
        "  When gibberish",
        4,
        "/zencode.lua:NNN: Zencode line 4 pattern not found (when): When gibberish"
      ],[
        "  some other stuff",
        5,
        "Invalid Zencode prefix"
      ],[
        "  Then gibberish",
        7,
        "/zencode.lua:NNN: Zencode line 7 pattern not found (then): Then gibberish"
      ]
    ]
  }
  const parsedResult = sanitizeZencodeParse(result);
  t.deepEqual(parsedResult, expected);
});


test("parse contract with ingnore statements", async (t) => {
  const { result } = await safe_zencode_valid_code(`Rule unknown ignore
  Scenario ecdh
  Given gibberish
  and more gibberish
  Given nothing
  When done
  Then print all data
  Then gibberish`);
  const expected = {
    "ignored": [
      [
        '  Given gibberish',
        3,
      ],[
        '  and more gibberish',
        4,
      ],[
        '  Then gibberish',
        8,
      ],
    ],
    "invalid":[]
  }
  t.deepEqual(JSON.parse(result), expected);  
})

test("parse contract with multiple ignore and invalid statements", async (t) => {
  const { result } = await safe_zencode_valid_code(`Rule unknown ignore
  Scenario ecdh
  Given gibberish
  and more gibberish
  Given nothing
  When gibberish
  Not a real statement
  When done
  Something more
  Then print all data
  Is it clear?
  Then gibberish`);
  const expected = {
    "ignored": [
      [
        '  Given gibberish',
        3,
      ],[
        '  and more gibberish',
        4,
      ],[
        '  Is it clear?',
        11,
      ],[
        '  Then gibberish',
        12,
      ],
    ],
    "invalid":[
      [
        '  When gibberish',
        6,
        '/zencode.lua:NNN: Zencode line 6 found invalid statement out of given or then phase: When gibberish',
      ],[
        '  Not a real statement',
        7,
        'Invalid Zencode line',
      ],[
        '  Something more',
        9,
        'Invalid Zencode line',
      ]
    ]
  }
  const parsedResult = sanitizeZencodeParse(result);
  t.deepEqual(parsedResult, expected);
})

test("strict parse of contract", async (t) => {
  try {
    await zencode_valid_code(`Rule unknown ignore
    Scenario ecdh
    Given gibberish
    and more gibberish
    Given nothing
    When gibberish
    Not a real statement
    When done
    Something more
    Then print all data
    Is it clear?
    Then gibberish`);
  } catch(error) {
    t.true(error.logs.includes('Zencode line 6 found invalid statement out of given or then phase: When gibberish'));
  }
})

test("correctly fails on huge input", async (t) => {
  // 6MiB base64 -> 4718592 bytes in octets
  const data = `{"keyring":{"ecdh":"AxLMXkey00i2BD675vpMQ8WhP/CwEfmdRr+BtpuJ2rM="}, "bytes": "${"a".repeat(6*1024*1024)}"}`;
  try {
    await zencode_exec(`Scenario ecdh
      Given I have a 'keyring'
      Given I have a 'base64' named 'bytes'
      When I create the ecdh signature of 'bytes'
      Then print the 'ecdh signature'`, { data: data, keys: null });
    t.fail("input of size bigger than 4MiB should not pass");
  } catch(error) {
    const lines = JSON.parse(error.logs);
    t.is(lines.includes('[!] Cannot create octet, size too big: 4718592'), true, error.logs);
  } 
})

test("decode zencode error", async (t) => {
  try {
    await zencode_exec(`Scenario ecdh
      Given nothing
      When I create the ecdh key
      Then print the 'not existing object 👺'`,
      { data: null, keys: null }
    );
    t.fail("print of non existing object should fail");
  } catch(error) {
    const errorLines = decode_error(error);
    const jsonError = JSON.parse(errorLines);
    t.is(jsonError[0], '[!] Error at Zencode line 4', errorLines);
    t.is(jsonError[1].includes('Cannot find object: not_existing_object_👺'), true, errorLines);
    t.is(jsonError[2], '[!] Zencode runtime error', errorLines);
    t.is(jsonError[3].includes("Zencode line 4: Then print the 'not existing object 👺'"), true, errorLines);
    t.is(jsonError[4], '[!] Execution aborted with errors.', errorLines);
  }
})

test("get all the statements", async (t) => {
  const res = await zencode_get_statements();
  const jsonResult = JSON.parse(res.result);
  t.truthy(jsonResult.Foreach);
  t.truthy(jsonResult.If);
  t.truthy(jsonResult.Given);
  t.truthy(jsonResult.When);
  t.truthy(jsonResult.Then);
})

test("get all the statements from the then scenario", async (t) => {
  const res = await zencode_get_statements("then");
  const jsonResult = JSON.parse(res.result);
  t.deepEqual(jsonResult.Foreach, []);
  t.deepEqual(jsonResult.If, []);
  t.deepEqual(jsonResult.Given, []);
  t.deepEqual(jsonResult.When, []);
  t.is(jsonResult.Then && jsonResult.Then.length !== 0, true);
})

test("does run zencode with extra and context", async (t) => {
  const { result } = await zencode_exec(`
  given I have a 'string' named 'data'
  and I have a 'string' named 'keys'
  and I have a 'string' named 'extra'
  Then print all data`, { data: '{"data": "data"}', keys: '{"keys": "keys"}', extra: '{"extra": "extra"}' });
  t.is(result, '{"data":"data","extra":"extra","keys":"keys"}\n');
});

test("does run zenroom_exec with extra and context", async (t) => {
  const { result } = await zenroom_exec(`print(DATA..KEYS..EXTRA..CONTEXT)`, { data: "USING ", keys: "ALL ", extra: "ZENROOM ", context: "INPUTS" });
  t.is(result, "USING ALL ZENROOM INPUTS\n");
});
