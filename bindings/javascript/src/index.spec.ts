import test from "ava";

import { zencode_exec, zenroom_exec } from "./index";

test("does exists", (t) => {
  t.is(typeof zenroom_exec, "function");
  const p = zenroom_exec("print()").catch(() => {});
  t.true(p instanceof Promise);
});

test("does run hello world", async (t) => {
  const r = await zenroom_exec(`print('hello world!')`);
  t.is(r, "hello world!");
});

test("does parse data", async (t) => {
  const r = await zenroom_exec(`print(DATA)`, { data: "DATA INSIDE" });
  t.is(r, "DATA INSIDE");
});

test("does broke gracefully", async (t) => {
  try {
    await zenroom_exec(`broken sapokdao`);
  } catch (e) {
    t.true(
      e.includes(
        `[!] [string "broken sapokdao"]:1: syntax error near 'sapokdao'`
      )
    );
  }
});

test("does handle empty zencode", async (t) => {
  try {
    await zencode_exec(null);
  } catch (e) {
    t.true(e.includes("[!] NULL string as script for zencode_exec()"));
  }
  try {
    await zencode_exec(``);
  } catch (e) {
    t.true(e.includes("[!] Empty string as script for zencode_exec()"));
  }
});

test("does handle empty lua", async (t) => {
  try {
    await zenroom_exec(null);
  } catch (e) {
    t.true(e.includes("[!] NULL string as script for zenroom_exec()"));
  }
  try {
    await zenroom_exec(``);
  } catch (e) {
    t.true(e.includes("[!] Empty string as script for zenroom_exec()"));
  }
});

test("does run zencode", async (t) => {
  const r = await zencode_exec(`scenario simple:
  given nothing
  Then print all data`);
  t.is(r, "[]");
});

test("handle broken zencode", async (t) => {
  try {
    await zencode_exec(`sapodksapodk`);
  } catch (e) {
    t.true(
      e.includes(
        `[!] [string "ZEN:begin()..."]:2: Invalid Zencode line: sapodksapodk`
      )
    );
  }
});
