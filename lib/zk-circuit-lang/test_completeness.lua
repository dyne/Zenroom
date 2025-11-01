--[[
Lua Bindings Completeness Test Suite

This script systematically tests ALL C++ Logic<Field, Backend> methods
and reports which ones are available in Lua vs missing.

Date: October 15, 2025
Purpose: Automated verification of Lua binding completeness
]]

ZK = require'longfellow'

-- Verify module loaded by checking for a known global
if not create_fp256_field then
    error("lua_bindings module failed to load - create_fp256_field not found")
end

-- ANSI color codes
local RED = "\27[31m"
local GREEN = "\27[32m"
local YELLOW = "\27[33m"
local BLUE = "\27[34m"
local MAGENTA = "\27[35m"
local CYAN = "\27[36m"
local RESET = "\27[0m"
local BOLD = "\27[1m"

-- Test results tracking
local results = {
    field_arithmetic = {tested = 0, passed = 0, missing = 0},
    eltw_ops = {tested = 0, passed = 0, missing = 0},
    bitw_ops = {tested = 0, passed = 0, missing = 0},
    bitvec8_ops = {tested = 0, passed = 0, missing = 0},
    bitvec32_ops = {tested = 0, passed = 0, missing = 0},
    bitvec_other = {tested = 0, passed = 0, missing = 0},
    aggregate_ops = {tested = 0, passed = 0, missing = 0},
    array_ops = {tested = 0, passed = 0, missing = 0},
    conversion_ops = {tested = 0, passed = 0, missing = 0},
    sha_ops = {tested = 0, passed = 0, missing = 0},
}

local missing_methods = {}

-- Helper function to test method existence
local function test_method(category, cpp_signature, lua_object, lua_method_name, description)
    results[category].tested = results[category].tested + 1
    
    if lua_object and lua_object[lua_method_name] then
        results[category].passed = results[category].passed + 1
        return true
    else
        results[category].missing = results[category].missing + 1
        table.insert(missing_methods, {
            category = category,
            cpp_sig = cpp_signature,
            lua_name = lua_method_name or "N/A",
            description = description
        })
        return false
    end
end

-- Helper to try calling a method safely
local function try_call(category, cpp_signature, description, test_fn)
    results[category].tested = results[category].tested + 1
    
    local status, err = pcall(test_fn)
    if status then
        results[category].passed = results[category].passed + 1
        return true
    else
        results[category].missing = results[category].missing + 1
        table.insert(missing_methods, {
            category = category,
            cpp_sig = cpp_signature,
            lua_name = "N/A",
            description = description,
            error = tostring(err)
        })
        return false
    end
end

print(BOLD .. CYAN .. "=" .. string.rep("=", 78) .. RESET)
print(BOLD .. CYAN .. "  Longfellow-ZK Lua Bindings Completeness Test Suite" .. RESET)
print(BOLD .. CYAN .. "=" .. string.rep("=", 78) .. RESET)
print()

-- ============================================================================
-- Test Field Arithmetic (Fp256Base)
-- ============================================================================
print(BOLD .. BLUE .. "Testing Field Arithmetic (Fp256Base)..." .. RESET)

local Fp = create_fp256_field()

test_method("field_arithmetic", "Elt zero()", Fp, "zero", "Zero element")
test_method("field_arithmetic", "Elt one()", Fp, "one", "One element")
test_method("field_arithmetic", "Elt two()", Fp, "two", "Two element")
test_method("field_arithmetic", "Elt half()", Fp, "half", "Half element (1/2)")
test_method("field_arithmetic", "Elt of_scalar(uint64_t)", Fp, "of_scalar", "Create from integer")
test_method("field_arithmetic", "Elt addf(Elt, Elt)", Fp, "addf", "Field addition")
test_method("field_arithmetic", "Elt subf(Elt, Elt)", Fp, "subf", "Field subtraction")
test_method("field_arithmetic", "Elt mulf(Elt, Elt)", Fp, "mulf", "Field multiplication")
test_method("field_arithmetic", "Elt negf(Elt)", Fp, "negf", "Field negation")
test_method("field_arithmetic", "Elt invertf(Elt)", Fp, "invertf", "Field inversion")

print()

-- ============================================================================
-- Test Logic Class Setup
-- ============================================================================
print(BOLD .. BLUE .. "Testing Logic Class Creation..." .. RESET)

local logic_created = pcall(function()
    logic = create_logic()
end)

if not logic_created then
    print(RED .. "✗ Failed to create Logic object - cannot continue tests" .. RESET)
    os.exit(1)
end

print(GREEN .. "✓ Logic object created successfully" .. RESET)
print()

-- ============================================================================
-- Test EltW Operations
-- ============================================================================
print(BOLD .. BLUE .. "Testing EltW (Field Element Wire) Operations..." .. RESET)

test_method("eltw_ops", "EltW eltw_input()", logic, "eltw_input", "Create input wire")
test_method("eltw_ops", "EltW add(EltW*, EltW&)", logic, "add", "Wire addition")
test_method("eltw_ops", "EltW sub(EltW*, EltW&)", logic, "sub", "Wire subtraction")
test_method("eltw_ops", "EltW mul(EltW*, EltW&)", logic, "mul", "Wire multiplication")
test_method("eltw_ops", "EltW mul(Elt, EltW&)", logic, "mul_scalar", "Scalar multiplication")
test_method("eltw_ops", "EltW konst(Elt)", logic, "konst", "Constant wire from Elt")
test_method("eltw_ops", "EltW konst(uint64_t)", logic, "konst", "Constant wire from int (overloaded)")
test_method("eltw_ops", "EltW assert0(EltW&)", logic, "assert0", "Assert wire is zero (overloaded)")
test_method("eltw_ops", "EltW assert_eq(EltW*, EltW&)", logic, "assert_eq", "Assert wires equal (overloaded)")

-- Missing EltW methods
test_method("eltw_ops", "EltW mul(Elt, EltW*, EltW&)", logic, "mul_3arg", "3-arg multiplication k*a*b")
test_method("eltw_ops", "EltW ax(Elt, EltW&)", logic, "ax", "Linear: a*x")
test_method("eltw_ops", "EltW axy(Elt, EltW*, EltW&)", logic, "axy", "Linear: a*x*y")
test_method("eltw_ops", "EltW axpy(EltW*, Elt, EltW&)", logic, "axpy", "Linear: y + a*x")
test_method("eltw_ops", "EltW apy(EltW&, Elt)", logic, "apy", "Linear: y + a")
test_method("eltw_ops", "EltW eval(BitW&)", logic, "eval", "Convert BitW to EltW")
test_method("eltw_ops", "EltW mux(BitW*, EltW*, EltW&)", logic, "mux_elt", "EltW multiplexer")

print()

-- ============================================================================
-- Test BitW Operations
-- ============================================================================
print(BOLD .. BLUE .. "Testing BitW (Boolean Wire) Operations..." .. RESET)

test_method("bitw_ops", "BitW input()", logic, "input", "Create bit input")
test_method("bitw_ops", "BitW bit(size_t)", logic, "bit", "Create constant bit")
test_method("bitw_ops", "BitW lnot(BitW&)", logic, "lnot", "Logical NOT")
test_method("bitw_ops", "BitW land(BitW*, BitW&)", logic, "land", "Logical AND")
test_method("bitw_ops", "BitW lor(BitW*, BitW&)", logic, "lor", "Logical OR")
test_method("bitw_ops", "BitW lxor(BitW*, BitW&)", logic, "lxor", "Logical XOR")
test_method("bitw_ops", "BitW limplies(BitW*, BitW&)", logic, "limplies", "Logical IMPLIES")
test_method("bitw_ops", "BitW mux(BitW*, BitW*, BitW&)", logic, "mux", "BitW multiplexer")
test_method("bitw_ops", "EltW assert0(BitW&)", logic, "assert0", "Assert bit is 0 (overloaded)")
test_method("bitw_ops", "EltW assert1(BitW&)", logic, "assert1", "Assert bit is 1")
test_method("bitw_ops", "EltW assert_eq(BitW*, BitW&)", logic, "assert_eq", "Assert bits equal (overloaded)")
test_method("bitw_ops", "EltW assert_is_bit(BitW&)", logic, "assert_is_bit", "Assert value is bit")
test_method("bitw_ops", "void output(BitW&, size_t)", logic, "output", "Output bit wire")

-- Missing BitW methods
test_method("bitw_ops", "BitW rebase(Elt, Elt, BitW&)", logic, "rebase", "Change bit basis")
test_method("bitw_ops", "EltW lmul(BitW*, EltW&)", logic, "lmul", "Multiply bit * EltW")
test_method("bitw_ops", "BitW lor_exclusive(BitW*, BitW&)", logic, "lor_exclusive", "Exclusive OR (XOR)")

print()

-- ============================================================================
-- Test SHA-256 Specific Operations
-- ============================================================================
print(BOLD .. BLUE .. "Testing SHA-256 Specific Operations..." .. RESET)

test_method("sha_ops", "BitW lCh(BitW*, BitW*, BitW&)", logic, "lCh", "SHA Choose function")
test_method("sha_ops", "BitW lMaj(BitW*, BitW*, BitW&)", logic, "lMaj", "SHA Majority function")
test_method("sha_ops", "BitW lxor3(BitW*, BitW*, BitW&)", logic, "lxor3", "3-way XOR")

print()

-- ============================================================================
-- Test BitVec<8> Operations
-- ============================================================================
print(BOLD .. BLUE .. "Testing BitVec<8> Operations..." .. RESET)

test_method("bitvec8_ops", "bitvec<8> vinput()", logic, "vinput8", "8-bit input")
test_method("bitvec8_ops", "bitvec<8> vbit(uint64_t)", logic, "vbit8", "8-bit constant")
test_method("bitvec8_ops", "bitvec<8> vnot(bitvec<8>&)", logic, "vnot8", "8-bit NOT")
test_method("bitvec8_ops", "bitvec<8> vand(bitvec<8>*, bitvec<8>&)", logic, "vand8", "8-bit AND")
test_method("bitvec8_ops", "bitvec<8> vor(bitvec<8>*, bitvec<8>&)", logic, "vor8", "8-bit OR")
test_method("bitvec8_ops", "bitvec<8> vxor(bitvec<8>*, bitvec<8>&)", logic, "vxor8", "8-bit XOR")
test_method("bitvec8_ops", "bitvec<8> vadd(bitvec<8>&, bitvec<8>&)", logic, "vadd8", "8-bit addition")
test_method("bitvec8_ops", "BitW veq(bitvec<8>&, bitvec<8>&)", logic, "veq8", "8-bit equality")
test_method("bitvec8_ops", "BitW vlt(bitvec<8>*, bitvec<8>&)", logic, "vlt8", "8-bit less-than")
test_method("bitvec8_ops", "BitW vleq(bitvec<8>*, bitvec<8>&)", logic, "vleq8", "8-bit less-equal")

-- Available BitVec<8> methods (previously marked as missing)
test_method("bitvec8_ops", "bitvec<8> vCh(bitvec<8>*, bitvec<8>*, bitvec<8>&)", logic, "vCh8", "8-bit SHA Choose")
test_method("bitvec8_ops", "bitvec<8> vMaj(bitvec<8>*, bitvec<8>*, bitvec<8>&)", logic, "vMaj8", "8-bit SHA Majority")
test_method("bitvec8_ops", "bitvec<8> vxor3(bitvec<8>*, bitvec<8>*, bitvec<8>&)", logic, "vxor3_8", "8-bit 3-way XOR")
test_method("bitvec8_ops", "bitvec<8> vshr(bitvec<8>&, size_t, size_t)", logic, "vshr8", "8-bit shift right")
test_method("bitvec8_ops", "bitvec<8> vshl(bitvec<8>&, size_t, size_t)", logic, "vshl8", "8-bit shift left")
test_method("bitvec8_ops", "bitvec<8> vrotr(bitvec<8>&, size_t)", logic, "vrotr8", "8-bit rotate right")
test_method("bitvec8_ops", "bitvec<8> vrotl(bitvec<8>&, size_t)", logic, "vrotl8", "8-bit rotate left")
test_method("bitvec8_ops", "bitvec<8> vadd(bitvec<8>&, uint64_t)", logic, "vadd8_const", "8-bit add constant")
test_method("bitvec8_ops", "BitW veq(bitvec<8>&, uint64_t)", logic, "veq8_const", "8-bit eq constant")
test_method("bitvec8_ops", "BitW vlt(bitvec<8>&, uint64_t)", logic, "vlt8_const", "8-bit lt constant")

-- Missing BitVec<8> methods
test_method("bitvec8_ops", "bitvec<8> vor_exclusive(bitvec<8>*, bitvec<8>&)", logic, "vor_exclusive8", "8-bit exclusive OR")
test_method("bitvec8_ops", "void voutput(bitvec<8>&, size_t)", logic, "voutput8", "8-bit output")
test_method("bitvec8_ops", "void vassert0(bitvec<8>&)", logic, "vassert0_8", "Assert 8-bit zero")
test_method("bitvec8_ops", "void vassert_eq(bitvec<8>*, bitvec<8>&)", logic, "vassert_eq8", "Assert 8-bit equal")

print()

-- ============================================================================
-- Test BitVec<32> Operations
-- ============================================================================
print(BOLD .. BLUE .. "Testing BitVec<32> Operations..." .. RESET)

test_method("bitvec32_ops", "bitvec<32> vinput()", logic, "vinput32", "32-bit input")
test_method("bitvec32_ops", "bitvec<32> vbit(uint64_t)", logic, "vbit32", "32-bit constant")
test_method("bitvec32_ops", "bitvec<32> vadd(bitvec<32>&, bitvec<32>&)", logic, "vadd32", "32-bit addition")
test_method("bitvec32_ops", "BitW veq(bitvec<32>&, bitvec<32>&)", logic, "veq32", "32-bit equality")

-- Available BitVec<32> methods (previously marked as missing)
test_method("bitvec32_ops", "bitvec<32> vnot(bitvec<32>&)", logic, "vnot32", "32-bit NOT")
test_method("bitvec32_ops", "bitvec<32> vand(bitvec<32>*, bitvec<32>&)", logic, "vand32", "32-bit AND")
test_method("bitvec32_ops", "bitvec<32> vor(bitvec<32>*, bitvec<32>&)", logic, "vor32", "32-bit OR")
test_method("bitvec32_ops", "bitvec<32> vxor(bitvec<32>*, bitvec<32>&)", logic, "vxor32", "32-bit XOR")
test_method("bitvec32_ops", "BitW vlt(bitvec<32>*, bitvec<32>&)", logic, "vlt32", "32-bit less-than")
test_method("bitvec32_ops", "BitW vleq(bitvec<32>*, bitvec<32>&)", logic, "vleq32", "32-bit less-equal")
test_method("bitvec32_ops", "bitvec<32> vCh(bitvec<32>*, bitvec<32>*, bitvec<32>&)", logic, "vCh32", "32-bit SHA Choose")
test_method("bitvec32_ops", "bitvec<32> vMaj(bitvec<32>*, bitvec<32>*, bitvec<32>&)", logic, "vMaj32", "32-bit SHA Majority")
test_method("bitvec32_ops", "bitvec<32> vxor3(bitvec<32>*, bitvec<32>*, bitvec<32>&)", logic, "vxor3_32", "32-bit 3-way XOR")
test_method("bitvec32_ops", "bitvec<32> vshr(bitvec<32>&, size_t, size_t)", logic, "vshr32", "32-bit shift right")
test_method("bitvec32_ops", "bitvec<32> vshl(bitvec<32>&, size_t, size_t)", logic, "vshl32", "32-bit shift left")
test_method("bitvec32_ops", "bitvec<32> vrotr(bitvec<32>&, size_t)", logic, "vrotr32", "32-bit rotate right")
test_method("bitvec32_ops", "bitvec<32> vrotl(bitvec<32>&, size_t)", logic, "vrotl32", "32-bit rotate left")

print()

-- ============================================================================
-- Test Other BitVec Sizes
-- ============================================================================
print(BOLD .. BLUE .. "Testing Other BitVec Sizes (16, 64, 128, 256)..." .. RESET)

test_method("bitvec_other", "bitvec<16> vinput()", logic, "vinput16", "16-bit input")
test_method("bitvec_other", "bitvec<64> vinput()", logic, "vinput64", "64-bit input")
test_method("bitvec_other", "bitvec<128> vinput()", logic, "vinput128", "128-bit input")
test_method("bitvec_other", "bitvec<256> vinput()", logic, "vinput256", "256-bit input")

print()

-- ============================================================================
-- Test Conversion Operations
-- ============================================================================
print(BOLD .. BLUE .. "Testing Conversion Operations..." .. RESET)

test_method("conversion_ops", "EltW eval(BitW&)", logic, "eval", "Convert BitW to EltW")
test_method("conversion_ops", "EltW as_scalar(bitvec<8>&)", logic, "as_scalar8", "Convert 8-bit to scalar")
test_method("conversion_ops", "EltW as_scalar(bitvec<32>&)", logic, "as_scalar32", "Convert 32-bit to scalar")
test_method("conversion_ops", "EltW as_scalar(bitvec<64>&)", logic, "as_scalar64", "Convert 64-bit to scalar")

print()

-- ============================================================================
-- Test Aggregate Operations
-- ============================================================================
print(BOLD .. BLUE .. "Testing Aggregate Operations (functional style)..." .. RESET)

test_method("aggregate_ops", "EltW add(size_t, size_t, function)", logic, "add_range", "Sum over range")
test_method("aggregate_ops", "EltW mul(size_t, size_t, function)", logic, "mul_range", "Product over range")
test_method("aggregate_ops", "BitW land(size_t, size_t, function)", logic, "land_range", "AND over range")
test_method("aggregate_ops", "BitW lor(size_t, size_t, function)", logic, "lor_range", "OR over range")

print()

-- ============================================================================
-- Test Array Operations
-- ============================================================================
print(BOLD .. BLUE .. "Testing Array Operations..." .. RESET)

test_method("array_ops", "BitW eq0(size_t, BitW[])", logic, "eq0", "All-zero check")
test_method("array_ops", "BitW eq(size_t, BitW[], BitW[])", logic, "eq_array", "Array equality")
test_method("array_ops", "BitW lt(size_t, BitW[], BitW[])", logic, "lt_array", "Array less-than")
test_method("array_ops", "BitW leq(size_t, BitW[], BitW[])", logic, "leq_array", "Array less-equal")
test_method("array_ops", "void scan_and(BitW[], size_t, size_t, bool)", logic, "scan_and", "Cumulative AND")
test_method("array_ops", "void scan_or(BitW[], size_t, size_t, bool)", logic, "scan_or", "Cumulative OR")
test_method("array_ops", "void scan_xor(BitW[], size_t, size_t, bool)", logic, "scan_xor", "Cumulative XOR")

print()

-- ============================================================================
-- Print Summary
-- ============================================================================
print(BOLD .. CYAN .. "=" .. string.rep("=", 78) .. RESET)
print(BOLD .. CYAN .. "  Test Results Summary" .. RESET)
print(BOLD .. CYAN .. "=" .. string.rep("=", 78) .. RESET)
print()

local total_tested = 0
local total_passed = 0
local total_missing = 0

local function print_category_results(name, category)
    local tested = results[category].tested
    local passed = results[category].passed
    local missing = results[category].missing
    
    total_tested = total_tested + tested
    total_passed = total_passed + passed
    total_missing = total_missing + missing
    
    local pct = tested > 0 and math.floor((passed / tested) * 100) or 0
    local color = pct >= 90 and GREEN or (pct >= 50 and YELLOW or RED)
    local status = pct >= 90 and "✓" or (pct >= 50 and "⚠" or "✗")
    
    print(string.format("%s%-30s %s %3d/%3d  %s%3d%%%s  (%d missing)",
        color, name .. ":", status, passed, tested, BOLD, pct, RESET, missing))
end

print_category_results("Field Arithmetic", "field_arithmetic")
print_category_results("EltW Operations", "eltw_ops")
print_category_results("BitW Operations", "bitw_ops")
print_category_results("SHA-256 Operations", "sha_ops")
print_category_results("BitVec<8> Operations", "bitvec8_ops")
print_category_results("BitVec<32> Operations", "bitvec32_ops")
print_category_results("Other BitVec Sizes", "bitvec_other")
print_category_results("Conversion Operations", "conversion_ops")
print_category_results("Aggregate Operations", "aggregate_ops")
print_category_results("Array Operations", "array_ops")

print()
print(BOLD .. string.rep("-", 78) .. RESET)

local total_pct = total_tested > 0 and math.floor((total_passed / total_tested) * 100) or 0
local total_color = total_pct >= 90 and GREEN or (total_pct >= 50 and YELLOW or RED)

print(string.format("%sTOTAL:%s                         %3d/%3d  %s%s%3d%%%s  (%d missing)",
    BOLD, RESET, total_passed, total_tested, BOLD, total_color, total_pct, RESET, total_missing))

print()

-- ============================================================================
-- Print Missing Methods Details
-- ============================================================================
if total_missing > 0 then
    print(BOLD .. CYAN .. "=" .. string.rep("=", 78) .. RESET)
    print(BOLD .. CYAN .. "  Missing Methods Details" .. RESET)
    print(BOLD .. CYAN .. "=" .. string.rep("=", 78) .. RESET)
    print()
    
    local current_category = nil
    for _, method in ipairs(missing_methods) do
        if current_category ~= method.category then
            current_category = method.category
            print(BOLD .. YELLOW .. "\n" .. current_category .. ":" .. RESET)
        end
        print(string.format("  %s%-50s%s  %s",
            RED, method.cpp_sig, RESET, method.description))
    end
    print()
end

-- ============================================================================
-- Priority Recommendations
-- ============================================================================
print(BOLD .. CYAN .. "=" .. string.rep("=", 78) .. RESET)
print(BOLD .. CYAN .. "  Priority Recommendations" .. RESET)
print(BOLD .. CYAN .. "=" .. string.rep("=", 78) .. RESET)
print()

if results.aggregate_ops.missing > 0 then
    print(BOLD .. RED .. "🔥 HIGH PRIORITY:" .. RESET .. " Aggregate operations missing (" .. 
          results.aggregate_ops.missing .. " methods)")
    print("   These are essential for functional-style circuit building")
    print()
end

if results.array_ops.missing > 0 then
    print(BOLD .. RED .. "🔥 HIGH PRIORITY:" .. RESET .. " Array operations missing (" .. 
          results.array_ops.missing .. " methods)")
    print("   Needed for efficient bulk operations on arrays of wires")
    print()
end

if results.bitvec8_ops.missing > 0 then
    print(BOLD .. YELLOW .. "⚠️  MEDIUM PRIORITY:" .. RESET .. " BitVec<8> operations missing (" .. 
          results.bitvec8_ops.missing .. " methods)")
    print("   Output and assertion methods for 8-bit vectors")
    print()
end

if results.eltw_ops.missing > 0 then
    print(BOLD .. YELLOW .. "⚠️  MEDIUM PRIORITY:" .. RESET .. " EltW operations missing (" .. 
          results.eltw_ops.missing .. " methods)")
    print("   Linear algebra operations (ax, axpy, etc.) improve circuit efficiency")
    print()
end

if results.bitw_ops.missing > 0 then
    print(BOLD .. BLUE .. "📘 LOW PRIORITY:" .. RESET .. " BitW operations missing (" .. 
          results.bitw_ops.missing .. " methods)")
    print("   Advanced bit operations (rebase, lmul, lor_exclusive)")
    print()
end

-- ============================================================================
-- Final Status
-- ============================================================================
print(BOLD .. CYAN .. "=" .. string.rep("=", 78) .. RESET)
print()

if total_pct >= 90 then
    print(BOLD .. GREEN .. "✓ EXCELLENT: Lua bindings are nearly complete!" .. RESET)
elseif total_pct >= 50 then
    print(BOLD .. YELLOW .. "⚠ WARNING: Lua bindings are only " .. total_pct .. "% complete" .. RESET)
    print(BOLD .. YELLOW .. "  Significant gaps remain for production use" .. RESET)
else
    print(BOLD .. RED .. "✗ CRITICAL: Lua bindings are only " .. total_pct .. "% complete" .. RESET)
    print(BOLD .. RED .. "  Major implementation work needed" .. RESET)
end

-- print()
-- print("Full audit document: src/dsl/COMPLETENESS_AUDIT.md")
-- print()
