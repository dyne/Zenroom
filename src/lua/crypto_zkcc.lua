--[[
--This file is part of zenroom
--
--Copyright (C) 2025 Dyne.org foundation
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

local native = require'zkcore'
local M = {}

-- Weak-keyed table to store artifact schemas
local artifact_schema = setmetatable({}, { __mode = "k" })

-- Export all native symbols to module
for k, v in pairs(native) do
    M[k] = v
end

-- ===========================================================================
-- Utility Functions
-- ===========================================================================

local function shallow_copy(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = v
    end
    return copy
end

local function has_string_keys(tbl)
    for k, _ in pairs(tbl) do
        if type(k) == "string" then
            return true
        end
    end
    return false
end

-- ===========================================================================
-- Schema Management (stays on Lua side)
-- ===========================================================================

local function copy_entries(entries)
    local copy = {}
    for i, entry in ipairs(entries) do
        copy[i] = {
            name = entry.name,
            kind = entry.kind,
            index = entry.index,
            desc = entry.desc,
            type = entry.type,
            decl_order = entry.decl_order,
        }
    end
    return copy
end

local function rebuild_indexes(schema)
    local by_name, by_index = {}, {}

    local function index_entry(entry)
        if entry.name then
            by_name[entry.name] = entry
        end
        by_index[entry.index] = entry
    end

    for _, entry in ipairs(schema.public) do index_entry(entry) end
    for _, entry in ipairs(schema.private) do index_entry(entry) end
    for _, entry in ipairs(schema.full) do index_entry(entry) end

    schema.by_name = by_name
    schema.by_index = by_index
end

local function snapshot_schema(state, artifact)
    local schema = {
        public = copy_entries(state.public),
        private = copy_entries(state.private),
        full = copy_entries(state.full),
        order = copy_entries(state.order),
        counts = {
            public = #state.public,
            private = #state.private,
            full = #state.full,
        },
    }

    rebuild_indexes(schema)

    -- Calculate totals from artifact if available, otherwise from state
    schema.total = (artifact and artifact.ninput and (artifact.ninput - 1)) or state.inputs
    schema.npub = (artifact and artifact.npub_input and (artifact.npub_input - 1)) or schema.counts.public

    return schema
end

local function resolve_named_inputs(schema, values, kind_filter)
    if type(values) ~= "table" then
        error("inputs must be provided as a table", 2)
    end

    local resolved = {}
    local numeric_present = {}

    -- Resolve numeric and string keys
    for key, value in pairs(values) do
        if type(key) == "number" then
            resolved[key] = value
            numeric_present[key] = true
        elseif type(key) == "string" then
            local entry = schema.by_name[key]
            if not entry then
                error("unknown input name: " .. key, 2)
            end
            if kind_filter and entry.kind ~= kind_filter then
                error(string.format("input '%s' is %s, expected %s", key, entry.kind, kind_filter), 2)
            end
            resolved[entry.index] = value
        end
    end

    -- Check for missing required inputs
    local missing = {}
    for _, entry in ipairs(schema.order) do
        local is_required = entry.name and (not kind_filter or entry.kind == kind_filter)
        if is_required and not resolved[entry.index] and not numeric_present[entry.index] then
            table.insert(missing, entry.name)
        end
    end

    if #missing > 0 then
        error("missing inputs: " .. table.concat(missing, ", "), 2)
    end

    return resolved
end

-- ===========================================================================
-- NamedArtifact: Wraps native artifact with schema-aware input resolution
-- ===========================================================================

local NamedArtifact = {}
NamedArtifact.__index = function(self, key)
    -- Direct accessors
    if key == "raw" or key == "artifact" then
        return function() return self._artifact end
    end
    if key == "schema" then
        return self._schema
    end

    -- Check for method in metatable
    local method = NamedArtifact[key]
    if method then
        return method
    end

    -- Proxy to underlying artifact
    local value = self._artifact[key]
    if type(value) == "function" then
        return function(_, ...)
            return value(self._artifact, ...)
        end
    end
    return value
end

function NamedArtifact:raw()
    return self._artifact
end

function NamedArtifact:inputs(values)
    return resolve_named_inputs(self._schema, values)
end

function NamedArtifact:public_inputs(values)
    return resolve_named_inputs(self._schema, values, "public")
end

local function is_named_artifact(obj)
    return getmetatable(obj) == NamedArtifact
end

local function wrap_artifact(artifact, schema)
    if schema then
        artifact_schema[artifact] = schema
    end
    return setmetatable({
        _artifact = artifact,
        _schema = schema or {},
    }, NamedArtifact)
end

-- ===========================================================================
-- Input Placeholder: Deferred wire binding with operator overloading
-- ===========================================================================

local placeholder_mt = {}
placeholder_mt.__index = placeholder_mt

local resolve_wire_or_value  -- forward declaration

function placeholder_mt:__tostring()
    local entry = self._entry
    local label = entry.name or "<unnamed>"
    return string.format("<%s input %s>", entry.kind, label)
end

local function try_binary_operation(operator_name, ra, rb)
    local ok, result

    ok, result = pcall(function()
        if operator_name == "add" then return ra + rb
        elseif operator_name == "sub" then return ra - rb
        elseif operator_name == "mul" then return ra * rb
        elseif operator_name == "eq" then return ra == rb
        end
    end)
    if ok then return result end

    -- Try commutative operation
    if operator_name == "add" or operator_name == "mul" then
        ok, result = pcall(function()
            if operator_name == "add" then return rb + ra
            else return rb * ra
            end
        end)
        if ok then return result end
    end

    error(operator_name .. " operation failed on inputs", 2)
end

function placeholder_mt:__add(other)
    local ra = resolve_wire_or_value(self)
    local rb = resolve_wire_or_value(other)
    if not ra or not rb then
        error("operation on unbound input: call bind_inputs()", 2)
    end
    return try_binary_operation("add", ra, rb)
end

function placeholder_mt:__sub(other)
    local ra = resolve_wire_or_value(self)
    local rb = resolve_wire_or_value(other)
    if not ra or not rb then
        error("operation on unbound input: call bind_inputs()", 2)
    end
    return try_binary_operation("sub", ra, rb)
end

function placeholder_mt:__mul(other)
    local ra = resolve_wire_or_value(self)
    local rb = resolve_wire_or_value(other)
    if not ra or not rb then
        error("operation on unbound input: call bind_inputs()", 2)
    end
    return try_binary_operation("mul", ra, rb)
end

function placeholder_mt:__eq(other)
    local ra = resolve_wire_or_value(self)
    local rb = resolve_wire_or_value(other)
    if not ra or not rb then
        error("operation on unbound input: call bind_inputs()", 2)
    end
    return try_binary_operation("eq", ra, rb)
end

local function make_placeholder(entry)
    return setmetatable({ _entry = entry }, placeholder_mt)
end

local function is_placeholder(obj)
    return getmetatable(obj) == placeholder_mt
end

local function resolve_placeholder(obj)
    if not obj._wire then
        local entry = obj._entry
        local name = entry.name or "<unnamed>"
        error("input '" .. name .. "' is not bound yet: call bind_inputs()", 3)
    end
    return obj._wire
end

resolve_wire_or_value = function(v)
    if is_placeholder(v) then
        return resolve_placeholder(v)
    end
    return v
end

local function resolve_value(val)
    if is_placeholder(val) then
        return resolve_placeholder(val)
    elseif type(val) == "table" then
        local changed = false
        local out = {}
        for k, v in pairs(val) do
            local resolved = resolve_value(v)
            if resolved ~= v then
                changed = true
            end
            out[k] = resolved
        end
        return changed and out or val
    end
    return val
end

local function resolve_args(...)
    local n = select("#", ...)
    if n == 0 then
        return ...
    end
    local args = { ... }
    for i = 1, n do
        args[i] = resolve_value(args[i])
    end
    return table.unpack(args, 1, n)
end

local function sort_entries_by_declaration_order(entries)
    table.sort(entries, function(a, b)
        if a.name and b.name then
            if a.name == b.name then
                return a.decl_order < b.decl_order
            end
            return a.name < b.name
        elseif a.name then
            return true
        elseif b.name then
            return false
        else
            return a.decl_order < b.decl_order
        end
    end)
end

-- ===========================================================================
-- NamedLogic: Circuit builder with named wire support
-- ===========================================================================

local NamedLogic = {}
NamedLogic.__index = function(self, key)
    -- Check for method in metatable
    local method = NamedLogic[key]
    if method then
        return method
    end

    -- Proxy to underlying logic with automatic input binding check and argument resolution
    local value = self._logic[key]
    if type(value) == "function" then
        return function(_, ...)
            if not self._bound then
                local pending = #self._state.public + #self._state.private + #self._state.full
                if pending > 0 then
                    error("call bind_inputs() after declaring inputs before using logic functions (" .. key .. ")", 2)
                end
            end
            return value(self._logic, resolve_args(...))
        end
    end
    return value
end

local function new_state()
    return {
        inputs = 0,
        decl_order = 0,
        public = {},
        private = {},
        full = {},
        order = {},
        by_name = {},
    }
end

local function record_input(self, kind, input_spec)
    if self._bound then
        error("cannot declare new inputs after bind_inputs()", 2)
    end

    if type(input_spec) ~= "table" then
        error("inputs must be declared with a table including name, desc, and type", 2)
    end

    if not input_spec.name or not input_spec.desc or not input_spec.type then
        error("input table must include name, desc, and type fields", 2)
    end

    local entry = {
        kind = kind,
        name = input_spec.name,
        desc = input_spec.desc,
        type = input_spec.type,
    }

    if entry.name and self._state.by_name[entry.name] then
        error("duplicate input name: " .. entry.name, 2)
    end

    self._state.decl_order = self._state.decl_order + 1
    entry.decl_order = self._state.decl_order
    entry.placeholder = make_placeholder(entry)

    table.insert(self._state[kind], entry)
    table.insert(self._state.order, entry)

    if entry.name then
        self._state.by_name[entry.name] = entry
    end

    return entry.placeholder
end

function NamedLogic:public_input(name)
    return record_input(self, "public", name)
end

function NamedLogic:private_input(name)
    return record_input(self, "private", name)
end

function NamedLogic:full(name)
    return record_input(self, "full", name)
end

function NamedLogic:bind_inputs()
    if self._bound then
        return self
    end

    local state = self._state
    sort_entries_by_declaration_order(state.public)
    sort_entries_by_declaration_order(state.private)
    sort_entries_by_declaration_order(state.full)

    local input_count = 0
    local applied_order = {}

    local function create_wire_for_type(input_type)
        local wire_creators = {
            field = function() return self._logic:eltw_input() end,
            bit = function() return self._logic:input() end,
            bitvec8 = function() return self._logic:vinput8() end,
            bitvec16 = function() return self._logic:vinput16() end,
            bitvec32 = function() return self._logic:vinput32() end,
            bitvec64 = function() return self._logic:vinput64() end,
            bitvec128 = function() return self._logic:vinput128() end,
            bitvec256 = function() return self._logic:vinput256() end,
            bitvar = function() return self._logic:vinput_var() end,
        }

        local creator = wire_creators[input_type]
        if not creator then
            error("unknown input type: " .. tostring(input_type), 2)
        end
        return creator()
    end

    local function bind_entry(entry)
        input_count = input_count + 1
        entry.index = input_count
        entry.wire = create_wire_for_type(entry.type)

        if entry.placeholder then
            entry.placeholder._wire = entry.wire
        end
        table.insert(applied_order, entry)
    end

    -- Bind public inputs first
    for _, entry in ipairs(state.public) do
        bind_entry(entry)
    end

    -- Mark private section if needed
    if #state.private > 0 or #state.full > 0 then
        self._logic:private_inputs()
    end

    -- Bind private inputs
    for _, entry in ipairs(state.private) do
        bind_entry(entry)
    end

    -- Mark full field section if needed
    if #state.full > 0 then
        self._logic:begin_full_field()
    end

    -- Bind full inputs
    for _, entry in ipairs(state.full) do
        bind_entry(entry)
    end

    state.order = applied_order
    state.inputs = input_count
    self._bound = true
    return self
end

function NamedLogic:compile(...)
    if not self._bound then
        self:bind_inputs()
    end

    local artifact = self._logic:compile(...)
    local schema = snapshot_schema(self._state, artifact)
    return wrap_artifact(artifact, schema)
end

function NamedLogic:raw()
    return self._logic
end

local function new_named_logic()
    return setmetatable({
        _logic = M.logic(),
        _state = new_state(),
        _bound = false,
    }, NamedLogic)
end

-- ===========================================================================
-- Public API
-- ===========================================================================

M.named_logic = new_named_logic

-- Unwrap named artifacts and resolve named inputs in options tables
local function unwrap_opts(opts, public_only)
    if type(opts) ~= "table" then
        return opts
    end

    local circuit = opts.circuit
    if not circuit then
        return opts
    end

    local schema
    local result = opts

    -- Extract schema from named artifact or schema table
    if is_named_artifact(circuit) then
        schema = circuit.schema
        result = shallow_copy(opts)
        result.circuit = circuit:raw()
    else
        schema = artifact_schema[circuit] or circuit.schema
    end

    if not schema then
        return result
    end

    -- Convert named inputs to indexed inputs
    local function convert_field(field_name, kind_filter)
        local field_value = result[field_name]
        if type(field_value) == "table" and has_string_keys(field_value) then
            if result == opts then
                result = shallow_copy(opts)
            end
            result[field_name] = resolve_named_inputs(schema, field_value, kind_filter)
        end
    end

    convert_field("inputs", public_only and "public" or nil)
    convert_field("public_inputs", "public")

    -- Fallback: use public_inputs as inputs if inputs not provided
    if not result.inputs and result.public_inputs then
        if result == opts then
            result = shallow_copy(opts)
        end
        result.inputs = result.public_inputs
    end

    return result
end

-- ===========================================================================
-- Wrap Native Functions with Named Artifact Support
-- ===========================================================================

if M.build_witness_inputs then
    local native_build = M.build_witness_inputs
    M.build_witness_inputs = function(opts)
        return native_build(unwrap_opts(opts))
    end
end

if M.prove_circuit then
    local native_prove = M.prove_circuit
    M.prove_circuit = function(opts)
        return native_prove(unwrap_opts(opts))
    end
end

if M.verify_circuit then
    local native_verify = M.verify_circuit
    M.verify_circuit = function(opts)
        return native_verify(unwrap_opts(opts, true))
    end
end

-- ===========================================================================
-- Helper: Generic vappend wrapper
-- ===========================================================================
-- Wraps the vappend_N_M methods with a simpler interface that auto-detects sizes
-- Usage: L:vappend(vec8_a, vec8_b) -> vec16
--        L:vappend(vec16_a, vec16_b) -> vec32
function M.Logic_vappend(logic, a, b)
    -- Get type names using Zenroom's type() which returns __name
    local type_a = type(a)
    local type_b = type(b)
    
    -- Extract size from type names (e.g., "zkcc.bitvec8" -> 8)
    local size_a = nil
    local size_b = nil
    
    if type_a == "zkcc.bitvec8" then size_a = 8
    elseif type_a == "zkcc.bitvec16" then size_a = 16
    elseif type_a == "zkcc.bitvec32" then size_a = 32
    elseif type_a == "zkcc.bitvec64" then size_a = 64
    elseif type_a == "zkcc.bitvec128" then size_a = 128
    elseif type_a == "zkcc.bitvec256" then size_a = 256
    else
        error("vappend: first argument must be a bit vector, got: " .. tostring(type_a))
    end
    
    if type_b == "zkcc.bitvec8" then size_b = 8
    elseif type_b == "zkcc.bitvec16" then size_b = 16
    elseif type_b == "zkcc.bitvec32" then size_b = 32
    elseif type_b == "zkcc.bitvec64" then size_b = 64
    elseif type_b == "zkcc.bitvec128" then size_b = 128
    elseif type_b == "zkcc.bitvec256" then size_b = 256
    else
        error("vappend: second argument must be a bit vector, got: " .. tostring(type_b))
    end
    
    -- Sizes must match
    if size_a ~= size_b then
        error(string.format("vappend: bit vector sizes must match (got %d and %d)", size_a, size_b))
    end
    
    -- Call the appropriate vappend method based on sizes
    if size_a == 8 then
        return logic:vappend_8_8(a, b)
    elseif size_a == 16 then
        return logic:vappend_16_16(a, b)
    elseif size_a == 32 then
        return logic:vappend_32_32(a, b)
    elseif size_a == 64 then
        return logic:vappend_64_64(a, b)
    elseif size_a == 128 then
        return logic:vappend_128_128(a, b)
    else
        error(string.format("vappend: unsupported size: %d", size_a))
    end
end

-- Add vappend method to Logic instances
if M.create_logic then
    local native_create = M.create_logic
    M.create_logic = function()
        local logic = native_create()
        -- Add convenience method
        logic.vappend = function(self, a, b)
            return M.Logic_vappend(self, a, b)
        end
        return logic
    end
end

return M
