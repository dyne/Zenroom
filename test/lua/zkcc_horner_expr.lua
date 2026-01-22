--[[
--This file is part of zenroom
--
--Copyright (C) 2026 Dyne.org foundation
--designed, written and maintained by Denis Roio
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License v3.0
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--Along with this program you should have received a copy of the
--GNU Affero General Public License v3.0
--If not, see http://www.gnu.org/licenses/agpl.txt
--
--]]

local zkcc = require'crypto_zkcc'

print('=== Expr Circuit: Horner cubic ===')

local L = zkcc.named_logic()

-- Inputs: public z, private a,b,c,d,x (all field elements)
local z = L:public_input{ name = 'z', desc = 'polynomial result', type = 'field' }
local a = L:private_input{ name = 'a', desc = 'x^3 coefficient', type = 'field' }
local b = L:private_input{ name = 'b', desc = 'x^2 coefficient', type = 'field' }
local c = L:private_input{ name = 'c', desc = 'x coefficient', type = 'field' }
local d = L:private_input{ name = 'd', desc = 'constant term', type = 'field' }
local x = L:private_input{ name = 'x', desc = 'evaluation point', type = 'field' }

-- Materialize inputs (public -> private)
L:bind_inputs()

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
  z = oct_u64(471),
  a = oct_u64(3),
  b = oct_u64(2),
  c = oct_u64(7),
  d = oct_u64(11),
  x = oct_u64(5),
}

local seed = OCTET.from_hex(string.rep('03', 32))

local witness = zkcc.build_witness_inputs{
  circuit = artifact,
  inputs = inputs,
}

-- Public-only view for verifier
local public_witness = zkcc.build_witness_inputs{
  circuit = artifact,
  public_inputs = {
    z = inputs.z,
  },
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
  public_inputs = public_witness,
  seed = seed,
}
assert(ok, 'Proof verification failed')

print('✓ Verified z = ((a*x + b)*x + c)*x + d with Horner evaluation')
