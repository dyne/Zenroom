import test from "ava";

import { zencode_exec, zenroom_exec } from "./index";

test("does exists", (t) => {
  t.is(typeof zenroom_exec, "function");
  const p = zenroom_exec("print()").catch(() => {});
  t.true(p instanceof Promise);
});

test("does run hello world", async (t) => {
  const { result } = await zenroom_exec(`print('hello world!')`);
  t.is(result, "hello world!");
});

test("does parse data", async (t) => {
  const { result } = await zenroom_exec(`print(DATA)`, { data: "DATA INSIDE" });
  t.is(result, "DATA INSIDE");
});

test("does broke gracefully", async (t) => {
  try {
    await zenroom_exec(`broken sapokdao`);
  } catch (e) {
    t.true(
      e.logs.includes(
        `[!] [string "broken sapokdao"]:1: syntax error near 'sapokdao'`
      )
    );
  }
});

test("does handle empty zencode", async (t) => {
  try {
    await zencode_exec(null);
  } catch (e) {
    t.true(e.logs.includes("[!] NULL string as script for zencode_exec()"));
  }
  try {
    await zencode_exec(``);
  } catch (e) {
    t.true(e.logs.includes("[!] Empty string as script for zencode_exec()"));
  }
});

test("does handle empty lua", async (t) => {
  try {
    await zenroom_exec(null);
  } catch (e) {
    t.true(e.logs.includes("[!] NULL string as script for zenroom_exec()"));
  }
  try {
    await zenroom_exec(``);
  } catch (e) {
    t.true(e.logs.includes("[!] Empty string as script for zenroom_exec()"));
  }
});

test("does run zencode", async (t) => {
  const { result } = await zencode_exec(`scenario simple:
  given nothing
  Then print all data`);
  t.is(result, "[]");
});

test("handle broken zencode", async (t) => {
  try {
    await zencode_exec(`sapodksapodk`);
  } catch (e) {
    t.true(
      e.logs.includes(
        `[!] [string "ZEN:begin()..."]:2: Invalid Zencode line: sapodksapodk`
      )
    );
  }
});

test("Executes a zencode correctly", async (t) => {
  const random_name = Math.random().toString(36).substring(7);
  const {
    result,
  } = await zencode_exec(`Scenario 'credential': credential keygen 
    Given that I am known as '${random_name}' 
    When I create the credential key
    and I create the issuer key
    Then print my 'keys'`);
  t.is(typeof result, "string");
  const r = JSON.parse(result);
  t.is(typeof r[random_name], "object");
  t.is(typeof r[random_name]["keys"]["credential"], "string");
  t.is(typeof r[random_name]["keys"]["issuer"]["x"], "string");
  t.is(typeof r[random_name]["keys"]["issuer"]["y"], "string");
});
