#!/usr/bin/env lua
-- Expression-based circuit example: Horner evaluation of a cubic
-- z ?= ((a*x + b)*x + c)*x + d

local zkcc = require('zkcc')

print('=== Expr Circuit: Horner cubic ===')

local L = zkcc.logic()

-- Inputs: public z, private a,b,c,d,x
local z = L:eltw_input()
L:PRIV()  -- switch to private inputs
local a = L:eltw_input()
local b = L:eltw_input()
local c = L:eltw_input()
local d = L:eltw_input()
local x = L:eltw_input()

-- Build constraint with a declarative expression using Horner's method
local lhs = L:expr(function(e)
  return ((e.a * e.x + e.b) * e.x + e.c) * e.x + e.d
end, { a = a, b = b, c = c, d = d, x = x })
L:assert_eq(lhs, z)

local artifact = L:compile(1)

-- Helper to make 32-byte OCTETs from small integers
local function oct_u64(n)
  return OCTET.from_hex(string.format('%064x', n))
end

-- Test values: a=3, b=2, c=7, d=11, x=5
-- Polynomial: 3*x^3 + 2*x^2 + 7*x + 11 at x=5 -> 3*125 + 2*25 + 35 + 11 = 375 + 50 + 35 + 11 = 471
local inputs = {
  [1] = oct_u64(471), -- public z
  [2] = oct_u64(3),   -- a
  [3] = oct_u64(2),   -- b
  [4] = oct_u64(7),   -- c
  [5] = oct_u64(11),  -- d
  [6] = oct_u64(5),   -- x
}

local seed = OCTET.from_hex(string.rep('03', 32))

local witness = zkcc.build_witness_inputs{
  circuit = artifact,
  inputs = inputs,
}

local proof = zkcc.prove_circuit{
  circuit = artifact,
  inputs = witness,
  seed = seed,
}
assert(proof, 'Proof generation failed')

local ok = zkcc.verify_circuit{
  circuit = artifact,
  proof = proof,
  public_inputs = witness,
  seed = seed,
}
assert(ok, 'Proof verification failed')

print('✓ Verified z = ((a*x + b)*x + c)*x + d with Horner evaluation')
