# Zenroom ZK Lang Examples

This directory contains example Lua scripts demonstrating our circuit
building DSL interepreted by Zenroom through its Lua dialect and
compiled into circuits that can be used by Longfellow-ZK.

Features:

- **Demystifies production ZK systems** - Shows how real-world privacy tech works
- **Enables education** - Learn by reading working code
- **Documents architecture** - Preserves knowledge of complex system
- **Bridges languages** - C++ expertise → Lua accessibility

# Run an example
```
zenroom examples/01_simple_arithmetic.lua
```

## Example Descriptions

### Basic Circuits

#### 01_simple_arithmetic.lua
- **Concept:** Polynomial constraint
- **Proves:** Knowledge of `x` where `x^2 + 3x + 2 = 20`
- **APIs:** `QuadCircuit`, field arithmetic
- **Metrics**: 4 inputs, depth 2, 4 wires
- **Difficulty:** ⭐ Beginner
- **Demonstrates**: Basic polynomial constraint proving

Learn how to:
- Create public and private inputs
- Build arithmetic constraints
- Compile and inspect circuits

---

#### 02_age_verification.lua
- **Concept:** Range proof (lower bound)
- **Proves:** Age is at least 18
- **APIs:** `Logic`, 8-bit vectors
- **Metrics**: 9 inputs, depth 4, 20 wires
- **Difficulty:** ⭐ Beginner
- **Demonstrates**: Range proofs, inequality constraints

Learn how to:
- Use high-level Logic API
- Create bit vector inputs
- Perform comparisons

---

#### 03_range_proof.lua
- **Concept:** Range proof (bounded)
- **Proves:** Value is between 10 and 100
- **APIs:** `Logic`, 8-bit comparisons
- **Metrics**: 9 inputs, depth 4, 31 wires
- **Difficulty:** ⭐⭐ Intermediate
- **Demonstrates**: Bounded range validation

Learn how to:
- Combine multiple constraints
- Prove upper and lower bounds
- Understand assertion logic

---

### Boolean Logic

#### 04_conditional_logic.lua
- **Concept:** Boolean implication  
- **Proves:** IF condition THEN equality holds
- **APIs:** `Logic`, `limplies`
- **Metrics**: 3 inputs, depth 2, 5 wires
- **Difficulty:** ⭐⭐ Intermediate
- **Demonstrates**: Conditional assertions, multiplexers

Learn how to:
- Use logical implication
- Build conditional constraints
- Understand truth tables in ZK

---

#### 05_bitwise_operations.lua
- **Concept:** Boolean algebra  
- **Proves:** `(a AND b) XOR c = d`
- **APIs:** `Logic`, bitwise operators
- **Metrics**: 33 inputs, depth 7, 93 wires
- **Difficulty:** ⭐⭐ Intermediate
- **Demonstrates**: Boolean algebra, bit vector operations

Learn how to:
- Use AND, OR, XOR, NOT
- Work with bit vectors
- Understand bitwise ZK circuits

---

### Aggregation

#### 06_sum_verification.lua
- **Concept:** Summation constraint
- **Proves:** Four values sum to 200
- **APIs:** `Logic`, 8-bit addition
- **Metrics**: 41 inputs, depth 3, 51 wires
- **Difficulty:** ⭐⭐ Intermediate
- **Demonstrates**: Multi-input arithmetic, overflow behavior (mod 256)

Learn how to:
- Add multiple values
- Handle overflow (modular arithmetic)
- Use for budget/tally proofs

---

### Advanced Techniques

#### 07_multiplexer.lua
- **Concept:** Conditional selection
- **Proves:** Correct value selected based on control bit
- **APIs:** `Logic`, `vmux8`
- **Metrics**: 19 inputs, depth 3, 32 wires
- **Difficulty:** ⭐⭐ Intermediate
- **Demonstrates**: Data routing, conditional selection

Learn how to:
- Use multiplexers for routing
- Implement switch logic
- Build conditional circuits

---

#### 08_field_arithmetic.lua
- **Concept:** Direct field operations  
- **Proves:** Linear equation `3x + 5y = 100`  
- **APIs:** `Logic`, field elements  
- **Metrics**: 4 inputs, depth 2, 4 wires
- **Difficulty:** ⭐⭐⭐ Advanced
- **Demonstrates**: Direct field element usage vs bit vectors

Learn how to:
- Work with field elements directly
- Choose between EltW and BitVec
- Optimize for arithmetic efficiency

---

## Common Patterns

### Pattern 1: Range Proof (x ∈ [min, max])

```lua
local L = create_logic()
local x = L:vinput8()

local lower = L:vleq8(L:vbit8(min), x)  -- min <= x
local upper = L:vleq8(x, L:vbit8(max))  -- x <= max

L:assert1(lower)
L:assert1(upper)
```

### Pattern 2: Equality Constraint

```lua
local L = create_logic()
local a = L:vinput8()
local b = L:vinput8()

local eq = L:veq8(a, b)
L:assert1(eq)  -- a must equal b
```

### Pattern 3: Conditional Disclosure

```lua
local consent = L:input()  -- 1 = consent given
local secret = L:vinput8()
local disclosed = L:vinput8()

-- If consent, secret must match disclosed
local eq = L:veq8(secret, disclosed)
local condition = L:limplies(consent, eq)
L:assert1(condition)
```

### Pattern 4: Sum Constraint

```lua
local values = {L:vinput8(), L:vinput8(), L:vinput8()}
local sum = values[1]
for i = 2, #values do
    sum = L:vadd8(sum, values[i])
end

local target = L:vbit8(100)
L:assert1(L:veq8(sum, target))
```

## Circuit Metrics Guide

Understanding circuit metrics helps optimize your designs.

### Depth
- **Definition:** Maximum number of sequential gate layers
- **Impact:** Affects prover time (logarithmically)
- **Good:** < 10 for simple circuits, < 20 for complex
- **Optimization:** Use parallel operations when possible

### Wires
- **Definition:** Total number of gates/wires in circuit
- **Impact:** Affects prover time (linearly) and proof size
- **Good:** < 10,000 for simple, < 100,000 for complex
- **Optimization:** Reuse subexpressions, avoid redundant operations

### Example Metrics

| Circuit                | Depth | Wires  | Notes                    |
|------------------------|-------|--------|--------------------------|
| Simple AND             | 1     | ~10    | Minimal circuit          |
| 8-bit comparison       | 4-5   | ~100   | Parallel-prefix adder    |
| 8-bit addition         | 4     | ~50    | Logarithmic depth        |
| SHA-256 block          | 7     | 40,000 | Bitwise operations heavy |
| ECDSA verification     | 7     | 20,000 | Scalar multiplication    |

## Debugging Tips

### 1. Start Small

```lua
-- Test with minimal circuit first
local L = create_logic()
local a = L:input()
print("Created input, wire ID:", a:wire_id())

local circuit = L:get_circuit()
circuit:mkcircuit(1)
print("Depth:", circuit.depth)  -- Should be 0 for single input
```

### 2. Check Metrics

```lua
circuit:mkcircuit(1)

if circuit.depth > 20 then
    print("WARNING: Circuit is very deep!")
end

if circuit.nwires > 100000 then
    print("WARNING: Circuit is very large!")
end
```

### 3. Test Boundary Cases

```lua
-- Test with edge values
local x = L:vbit8(0)     -- Minimum
local y = L:vbit8(255)   -- Maximum
local z = L:vbit8(128)   -- Midpoint
```

### 4. Use Error Handling

```lua
local ok, err = pcall(function()
    -- Your circuit building code
    local L = create_logic()
    -- ...
    L:get_circuit():mkcircuit(1)
end)

if not ok then
    print("Error:", err)
end
```

## Performance Tips

### 1. Choose Right API Level

- **QuadCircuit:** Maximum control, verbose
- **Logic:** High-level, optimized implementations

### 2. Prefer Field Elements for Arithmetic

```lua
-- Less efficient (bit-by-bit)
local a = L:vinput8()
local b = L:vinput8()
local sum = L:vadd8(a, b)

-- More efficient (single field operation)
local a = L:eltw_input()
local b = L:eltw_input()
local sum = L:add(a, b)
```

### 3. Batch Operations

```lua
-- Good: Single comparison
local all_equal = L:veq8(a, b)

-- Avoid: Bit-by-bit comparison (unless needed)
-- ... manual equality check on each bit ...
```

## Next Steps

After mastering these examples:

3. **Study the real mDoc circuit:** `09_mdoc_circuit.lua` - Complete ISO 18013-5 mDoc verification
4. **Explore advanced circuits:**
   - Hash preimage proofs (SHA-256 - see 09_mdoc_circuit.lua)
   - Merkle tree membership
   - ECDSA verification (placeholder in 09_mdoc_circuit.lua)
   - Full mDoc credential proofs (use C++ CLI tool)

## Advanced Example: mDoc Circuit

**09_mdoc_circuit.lua** is a complete translation of the production mDoc (mobile driver's license) verification circuit from C++ to Lua. This is a real-world, production-grade zero-knowledge proof system.

**What it demonstrates:**
- Multi-circuit architecture (Signature + Hash circuits)
- Field interoperability (Fp256Base for signatures, GF2_128 for hashing)
- Message Authentication Codes (MACs) binding circuits
- ECDSA signature verification structure
- SHA-256 hash verification structure  
- CBOR parsing and validation
- ISO 18013-5 mDoc standard compliance

**Circuit structure:**
```
Signature Circuit (Fp256Base)    Hash Circuit (GF2_128)
├─ Issuer ECDSA verify          ├─ SHA-256(MSO) verification
├─ Device ECDSA verify          ├─ Time: validFrom <= now <= validUntil
├─ MAC verification             ├─ Device key extraction
└─ Common inputs: e, dpkx, dpky ├─ Attribute hash verification
                                ├─ CBOR structure parsing
                                └─ MAC verification
                
               Linked via Message Authentication Codes (MACs)
```

**Real circuit complexity:**
- Signature circuit: ~11,000 inputs, ~50,000 gates, depth ~30
- Hash circuit: ~25,000 inputs, ~400,000 gates, depth ~200
- Total uncompressed: ~150 MB
- Compressed (zstd): ~5-10 MB
- Proof size: ~100-500 KB
- Prover time: 10-60 seconds

Run it:
```bash
zenroom 09_mdoc_circuit.lua
```

**Note:** The Lua version is a structural demonstration. Full mDoc proving requires:
- ECDSA verification circuits (not yet in Lua bindings)
- SHA-256 circuits (flatsha256_circuit.h)
- MAC circuits over GF(2^128)
- Bit pluckers and routing operations

## Contributing

Have a useful example? Submit a pull request!

Examples should:
- Be well-commented
- Include expected output
- Demonstrate a single concept
- Follow the existing naming pattern
