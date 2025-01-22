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
  decode_error
} from "./index";
import { TextEncoder } from "util";
var enc = new TextEncoder();

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
  ctx = await zenroom_hash_update(
    ctx.result,
    enc.encode("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq")
  );
  t.is(
    ctx.result,
    "4c001000000000000000000000000000008c9bcf367e6096a3ba7ca8485ae67bb2bf894fe72f36e3cf1361d5f3af54fa5d182e6ad7f520e511f6c3e2b8c68059b6bbd41fbabd9831f79217e1319cde05b6564636264636261676665646665646369686766686766656b6a69686a6968676d6c6b6a6c6b6a696f6e6d6c6e6d6c6b71706f6e706f6e6d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000"
  );
  ctx = await zenroom_hash_final(ctx.result);
  t.is(
    ctx.result,
    "IEqPxt2oLwoM7XvrjgikFlfBbvRosiioJ5vjMacDwzWW/RXBOxsH+aodO+pXeJygMa2Fx6cd1wNU7GMSOMo0RQ=="
  );
});

test("Unknown hash type", async (t) => {
  try {
    await zenroom_hash_init("invalidhash");
  } catch (e) {
    t.true(e.logs.includes(`invalidhash`));
  }
});

test("Wrong context prefix (update)", async (t) => {
  try {
    await zenroom_hash_update(
      "z",
      enc.encode("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq")
    );
  } catch (e) {
    t.true(e.logs.endsWith("z\n"));
  }
});

test("Wrong context prefix (final)", async (t) => {
  try {
    await zenroom_hash_final("z");
  } catch (e) {
    t.true(e.logs.endsWith("z\n"));
  }
});

test("Use zenroom_hash with unknown hash function", async (t) => {
  try {
    await zenroom_hash(
      "z",
      enc.encode("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq")
    );
  } catch (e) {
    t.true(e.logs.endsWith("z\n"));
  }
});

test("Use zenroom_hash with small input", async (t) => {
  const hash = await zenroom_hash(
    "sha512",
    enc.encode("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq")
  );
  t.is(
    hash.result,
    "IEqPxt2oLwoM7XvrjgikFlfBbvRosiioJ5vjMacDwzWW/RXBOxsH+aodO+pXeJygMa2Fx6cd1wNU7GMSOMo0RQ=="
  );
});

test("Use zenroom_hash with big input", async (t) => {
  // multiple of chunk size
  const hash0 = await zenroom_hash(
    "sha512",
    enc.encode(
      "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq".repeat(
        1024 * 64
      )
    )
  );
  t.is(
    hash0.result,
    "tqyQvZM1JPW5sSokgVWXbLp3tA8NNkEWdBc8YUX+6aDhfFTNEmQmralYFnk4izrXppH7cK7fVi3cpIvJrV783g=="
  );

  // not multiple of chunk size
  const hash1 = await zenroom_hash(
    "sha512",
    enc.encode(
      "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq".repeat(
        1087 * 73
      )
    )
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
        "/zencode.lua:222: Zencode line 2 pattern not found (given): Given gibberish",
      ],
    ],
    ignored: [],
  };
  t.deepEqual(JSON.parse(result), expected);
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
        "/zencode.lua:222: Zencode line 2 pattern not found (given): Given gibberish"
      ],[
        "  When gibberish",
        4,
        "/zencode.lua:222: Zencode line 4 pattern not found (when): When gibberish"
      ],[
        "  some other stuff",
        5,
        "Invalid Zencode prefix"
      ],[
        "  Then gibberish",
        7,
        "/zencode.lua:222: Zencode line 7 pattern not found (then): Then gibberish"
      ]
    ]
  }
  t.deepEqual(JSON.parse(result), expected);
})


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

test("parse contract with muliple ingnore and invalid statements", async (t) => {
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
        '/zencode.lua:233: Zencode line 6 found invalid statement out of given or then phase: When gibberish',
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
  t.deepEqual(JSON.parse(result), expected);  
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
      Then print the 'not existing object'`,
      { data: null, keys: null }
    );
    t.fail("print of non existing object should fail");
  } catch(error) {
    const errorLines = decode_error(error);
    const jsonError = JSON.parse(errorLines);
    t.is(jsonError[0], '[!] Error at Zencode line 4');
    t.is(jsonError[1].includes('Cannot find object: not_existing_object'), true, error.logs);
    t.is(jsonError[2], '[!] Zencode runtime error');
    t.is(jsonError[3].includes("Zencode line 4: Then print the 'not existing object'"), true, error.logs);
    t.is(jsonError[4], '[!] Execution aborted with errors.');
  }
})
