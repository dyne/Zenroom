--[[
--This file is part of zenroom
--
--Copyright (C) 2025-2026 Dyne.org foundation
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
local TEMPLATE_DEFAULT = "bip340"
local TEMPLATE_FIELD_ID = {
    p256 = 1,
    bip340 = 10,
}

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

local function normalize_template(template)
    if template == nil then
        return TEMPLATE_DEFAULT
    end
    if type(template) ~= "string" then
        error("template must be a string", 3)
    end
    if not TEMPLATE_FIELD_ID[template] then
        error("unknown template: " .. tostring(template), 3)
    end
    return template
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
        template = state.template,
        field_id = state.field_id,
        version = state.version,
        author = state.author,
        source = state.source,
        copyright = state.copyright,
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
    deterministic_sort(entries, function(a, b)
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
        template = TEMPLATE_DEFAULT,
        field_id = TEMPLATE_FIELD_ID[TEMPLATE_DEFAULT],
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

    -- Pass 1 as default nc; the native C++ default argument is not
    -- forwarded through the Sol binding.
    local nc = select("#", ...) > 0 and ... or 1
    local artifact = self._logic:compile(nc)
    local schema = snapshot_schema(self._state, artifact)
    return wrap_artifact(artifact, schema)
end

function NamedLogic:raw()
    return self._logic
end

function NamedLogic:set_version(version)
    self._state.version = version
end

function NamedLogic:set_author(author)
    self._state.author = author
end

function NamedLogic:set_source(source)
    self._state.source = source
end

function NamedLogic:set_copyright(copyright)
    self._state.copyright = copyright
end

local function compact_input_entries(entries)
    local out = {}
    for i, entry in ipairs(entries or {}) do
        out[i] = {
            name = entry.name,
            desc = entry.desc,
            type = entry.type,
        }
    end
    return out
end

function NamedLogic:info(artifact)
    local snapshot <const> = snapshot_schema(self._state, artifact)
    local circuit_id <const> = artifact._artifact:circuit_id()
    -- A circuit's hash in longfellow-zk is made of the sha256 of a
    -- concatenation of circuid_ids, which can be more than one when
    -- linked with sumcheck. This is still TODO: multiple circuit_ids
    return {
        public_inputs = compact_input_entries(snapshot.public),
        private_inputs = compact_input_entries(snapshot.private),
        hash = HASH.sha256(circuit_id),
        version = snapshot.version,
        author = snapshot.author,
        source = snapshot.source,
        copyright = snapshot.copyright,
        -- we can add source_hash is future to link the circuit to the
        -- zkcc lua code before compilation to artifact
        -- source_hash = HMAC(this.hash, zkcc_code.lua)
    }
end

local function new_named_logic(template)
    local normalized = normalize_template(template)
    return setmetatable({
        _logic = M.logic(normalized),
        _state = {
            inputs = 0,
            decl_order = 0,
            template = normalized,
            field_id = TEMPLATE_FIELD_ID[normalized],
            public = {},
            private = {},
            full = {},
            order = {},
            by_name = {},
        },
        _bound = false,
    }, NamedLogic)
end

-- ===========================================================================
-- Public API
-- ===========================================================================

M.named_logic = new_named_logic

local function make_bip340_schema(artifact)
    -- Builds the schema for the native BIP340 verification circuit.
    -- Entries are ordered and indexed to match Bip340Verify::Witness::input()
    -- in lfzk_bindings.cc: interleaved bits_s[i], int_sx[i], int_sy[i],
    -- int_sz[i] (one iteration per i), then e·P trace (also interleaved),
    -- then py, ry, rz_inv, bits_ry.
    -- Indices are 1-based absolute positions in the dense witness array.

    local public = {}
    local private = {}
    local full = {}
    local seq = 1 -- 1-based absolute index; v_[0] is the constant-1

    local function add(list, name, kind, input_type)
        list[#list + 1] = {
            kind = kind,
            name = name,
            type = input_type,
            desc = name,
            index = seq,
            decl_order = seq,
        }
        seq = seq + 1
    end

    -- Public inputs: v_[1..3]
    add(public, "rx", "public", "field")
    add(public, "px", "public", "field")
    add(public, "e", "public", "field")

    -- Private: s·G trace (interleaved)
    for i = 1, 256 do
        add(private, string.format("bits_s_%03d", i), "private", "field")
        if i < 256 then
            add(private, string.format("int_sx_%03d", i), "private", "field")
            add(private, string.format("int_sy_%03d", i), "private", "field")
            add(private, string.format("int_sz_%03d", i), "private", "field")
        end
    end

    -- Private: e·P trace (interleaved)
    for i = 1, 256 do
        add(private, string.format("bits_e_%03d", i), "private", "field")
        if i < 256 then
            add(private, string.format("int_ex_%03d", i), "private", "field")
            add(private, string.format("int_ey_%03d", i), "private", "field")
            add(private, string.format("int_ez_%03d", i), "private", "field")
        end
    end

    add(private, "py", "private", "field")
    add(private, "ry", "private", "field")
    add(private, "rz_inv", "private", "field")

    for i = 1, 256 do
        add(private, string.format("bits_ry_%03d", i), "private", "field")
    end

    local schema = {
        public = public,
        private = private,
        full = full,
        order = {},
        template = "bip340",
        field_id = TEMPLATE_FIELD_ID.bip340,
        counts = {
            public = #public,
            private = #private,
            full = 0,
        },
    }

    for _, entry in ipairs(public) do
        schema.order[#schema.order + 1] = entry
    end
    for _, entry in ipairs(private) do
        schema.order[#schema.order + 1] = entry
    end

    rebuild_indexes(schema)
    schema.total = (artifact and artifact.ninput and (artifact.ninput - 1)) or #schema.order
    schema.npub = (artifact and artifact.npub_input and (artifact.npub_input - 1)) or #public
    return schema
end

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
        local resolved = unwrap_opts(opts)
        local schema = artifact_schema[resolved.circuit] or resolved.circuit.schema
        if schema and schema.template == "bip340" then
            return native.build_witness_inputs_bip340(resolved)
        end
        return native_build(resolved)
    end
end

if M.prove_circuit then
    local native_prove = M.prove_circuit
    M.prove_circuit = function(opts)
        local resolved = unwrap_opts(opts)
        local schema = artifact_schema[resolved.circuit] or resolved.circuit.schema
        if schema and schema.template == "bip340" then
            return native.prove_circuit_bip340(resolved)
        end
        return native_prove(resolved)
    end
end

if M.verify_circuit then
    local native_verify = M.verify_circuit
    M.verify_circuit = function(opts)
        local resolved = unwrap_opts(opts, true)
        local schema = artifact_schema[resolved.circuit] or resolved.circuit.schema
        if schema and schema.template == "bip340" then
            return native.verify_circuit_bip340(resolved)
        end
        return native_verify(resolved)
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

-- Wrap Logic instances to add convenience methods
if M.create_logic then
    local native_create_p256 = M.create_logic_p256 or M.create_logic
    local native_create_bip340 = M.create_logic_bip340
    M.create_logic = function(template)
        local normalized = normalize_template(template)
        local logic_native
        if normalized == "bip340" then
            if not native_create_bip340 then
                error("bip340 logic is not available", 2)
            end
            logic_native = native_create_bip340()
        else
            logic_native = native_create_p256()
        end
        
        -- Create a Lua table wrapper that delegates to the native usertype
        local logic_wrapper = {}
        local mt = {
            __index = function(t, k)
                -- First check if it's the vappend convenience method
                if k == "vappend" then
                    return function(self, a, b)
                        return M.Logic_vappend(logic_native, a, b)
                    end
                end
                -- Otherwise delegate to the native logic object
                local v = logic_native[k]
                -- If it's a function, wrap it to bind logic_native as self
                if type(v) == "function" then
                    return function(self, ...)
                        return v(logic_native, ...)
                    end
                end
                return v
            end,
            __newindex = function(t, k, v)
                -- Delegate writes to native object if possible
                logic_native[k] = v
            end
        }
        setmetatable(logic_wrapper, mt)
        
        return logic_wrapper
    end
end

M.logic = M.create_logic

function M.bip340_circuit()
    local artifact = native.bip340_circuit_native()
    return wrap_artifact(artifact, make_bip340_schema(artifact))
end

if M.load_circuit_artifact_bip340 then
    local native_load_bip340 = M.load_circuit_artifact_bip340
    M.load_circuit_artifact_bip340 = function(octet)
        local artifact = native_load_bip340(octet)
        return wrap_artifact(artifact, make_bip340_schema(artifact))
    end
end

if M.witness and native.bip340_compute_inputs_native then
    M.witness.bip340_compute_inputs = function(circuit, sig, pk, msg)
        local raw_circuit = is_named_artifact(circuit) and circuit:raw() or circuit
        local inputs, public_inputs =
            native.bip340_compute_inputs_native(raw_circuit, sig, pk, msg)
        return {
            inputs = inputs,
            public_inputs = public_inputs,
        }
    end
end

-- ===========================================================================
-- BIP340 Lua-Authored Circuit Helpers
-- ===========================================================================
-- These helpers allow Lua to author the BIP340 verification sequence using
-- granular gadget primitives while C++ emits the production-tested
-- constraint formulas.

--- Convert multi-return (x, y, z) from gadget calls into a point table.
-- Usage:  local sG = M.bip340_point(L:bip340_scalar_mult(...))
function M.bip340_point(x, y, z)
    return { x = x, y = y, z = z }
end

--- Declare all BIP340 witness wires on a named logic and return a
--- structured table of named wire references for use in gadget calls.
---
--- Layout matches Bip340Verify::Witness::input():
---   Public:  rx, px, e
---   Private: bits_s[256], int_s.{x,y,z}[255],
---            bits_e[256], int_e.{x,y,z}[255],
---            py, ry, rz_inv, bits_ry[256]
---
--- Returns:
--- {
---   rx = <EltW>, px = <EltW>, e = <EltW>,
---   bits_s = { [1..256] = <EltW> },
---   int_s = { x = { [1..256] }, y = { [1..256] }, z = { [1..256] } },
---   bits_e = { [1..256] = <EltW> },
---   int_e = { x = { [1..256] }, y = { [1..256] }, z = { [1..256] } },
---   py = <EltW>, ry = <EltW>, rz_inv = <EltW>,
---   bits_ry = { [1..256] = <EltW> },
--- }
function M.declare_bip340_witness(L)
    -- Public inputs
    local rx = L:public_input{ name = "rx", desc = "R.x (x-only)", type = "field" }
    local px = L:public_input{ name = "px", desc = "P.x (x-only public key)", type = "field" }
    local e  = L:public_input{ name = "e",  desc = "Fiat-Shamir challenge", type = "field" }

    -- s·G trace: bits + intermediates (interleaved)
    local bits_s = {}
    local int_sx, int_sy, int_sz = {}, {}, {}
    for i = 1, 256 do
        bits_s[i] = L:private_input{
            name = string.format("bits_s_%03d", i),
            desc = string.format("s bit %d (MSB-first)", i),
            type = "field",
        }
        if i < 256 then
            int_sx[i] = L:private_input{
                name = string.format("int_sx_%03d", i),
                desc = string.format("s·G intermediate x %d", i),
                type = "field",
            }
            int_sy[i] = L:private_input{
                name = string.format("int_sy_%03d", i),
                desc = string.format("s·G intermediate y %d", i),
                type = "field",
            }
            int_sz[i] = L:private_input{
                name = string.format("int_sz_%03d", i),
                desc = string.format("s·G intermediate z %d", i),
                type = "field",
            }
        end
    end

    -- e·P trace: bits + intermediates (interleaved)
    -- int_e arrays are padded to 256 elements for API compatibility.
    local bits_e = {}
    local int_ex, int_ey, int_ez = {}, {}, {}
    for i = 1, 256 do
        bits_e[i] = L:private_input{
            name = string.format("bits_e_%03d", i),
            desc = string.format("e bit %d (MSB-first)", i),
            type = "field",
        }
        if i < 256 then
            int_ex[i] = L:private_input{
                name = string.format("int_ex_%03d", i),
                desc = string.format("e·P intermediate x %d", i),
                type = "field",
            }
            int_ey[i] = L:private_input{
                name = string.format("int_ey_%03d", i),
                desc = string.format("e·P intermediate y %d", i),
                type = "field",
            }
            int_ez[i] = L:private_input{
                name = string.format("int_ez_%03d", i),
                desc = string.format("e·P intermediate z %d", i),
                type = "field",
            }
        else
            int_ex[i] = bits_e[i]
            int_ey[i] = bits_e[i]
            int_ez[i] = bits_e[i]
        end
    end

    -- P.y (the even square root)
    local py = L:private_input{
        name = "py", desc = "P.y (even square root)", type = "field",
    }

    -- R.y (affine, the canonical even y), rz_inv, and ry bits
    local ry = L:private_input{
        name = "ry", desc = "R.y (affine, even)", type = "field",
    }
    local rz_inv = L:private_input{
        name = "rz_inv", desc = "R.z inverse", type = "field",
    }

    local bits_ry = {}
    for i = 1, 256 do
        bits_ry[i] = L:private_input{
            name = string.format("bits_ry_%03d", i),
            desc = string.format("ry bit %d (MSB-first)", i),
            type = "field",
        }
    end

    return {
        rx = rx, px = px, e = e,
        bits_s = bits_s,
        int_s = { x = int_sx, y = int_sy, z = int_sz },
        bits_e = bits_e,
        int_e = { x = int_ex, y = int_ey, z = int_ez },
        py = py, ry = ry, rz_inv = rz_inv,
        bits_ry = bits_ry,
    }
end

--- Build a named witness inputs table from a native bip340_compute result.
--- This maps the native witness OCTET values to named keys matching
--- declare_bip340_witness output.
--- Returns { inputs = {...}, public_inputs = {...} } with string keys.
function M.bip340_witness_named(witness_result)
    local named = {
        rx = witness_result.rx,
        px = witness_result.px,
        e  = witness_result.e,
    }

    -- s·G trace (bits: 256, ints: 255)
    for i = 1, 256 do
        named[string.format("bits_s_%03d", i)] = witness_result.bits_s[i]
        if i < 256 then
            named[string.format("int_sx_%03d", i)] = witness_result.int_sx[i]
            named[string.format("int_sy_%03d", i)] = witness_result.int_sy[i]
            named[string.format("int_sz_%03d", i)] = witness_result.int_sz[i]
        end
    end

    -- e·P trace (bits: 256, ints: 255)
    for i = 1, 256 do
        named[string.format("bits_e_%03d", i)] = witness_result.bits_e[i]
        if i < 256 then
            named[string.format("int_ex_%03d", i)] = witness_result.int_ex[i]
            named[string.format("int_ey_%03d", i)] = witness_result.int_ey[i]
            named[string.format("int_ez_%03d", i)] = witness_result.int_ez[i]
        end
    end

    named.py = witness_result.py
    named.ry = witness_result.ry
    named.rz_inv = witness_result.rz_inv

    for i = 1, 256 do
        named[string.format("bits_ry_%03d", i)] = witness_result.bits_ry[i]
    end

    return named
end

--- Compile a Lua-authored BIP340 circuit, build witness inputs from a
--- valid signature, prove, and verify.
---
--- Design: Lua authors the verification sequence using granular gadget
--- primitives (bip340_addE, bip340_doubleE, bip340_scalar_mult, etc.).
--- C++ gadgets emit the production-tested constraint formulas — there is
--- exactly one C++ implementation of each EC formula, shared by the
--- native monolithic Bip340Verify and this Lua-authored path.
---
--- BIP-340 tagged SHA-256 and input parsing (r < p, s < n, pk lift)
--- are deliberately NOT proven in-circuit.  The circuit proves the
--- algebraic relation given a public challenge e; the binding between e
--- and the message/public-key is established by the verifier's own hash
--- computation outside the proof system (matching Bip340Witness).
---
--- This is the recommended entry point for the Lua-authored BIP340 flow.
--- Usage:
---   local compiled = M.bip340_lua_circuit_compile()
---   local result = M.bip340_lua_prove_verify(compiled, sig, pk, msg, seed)
function M.bip340_lua_circuit_compile()
    local L = M.named_logic("bip340")
    L:set_version("1.0.0")
    L:set_author("Lua-authored BIP340 gadget circuit")

    -- Declare witness wires
    local w = M.declare_bip340_witness(L)
    L:bind_inputs()

    -- Generator point (constant)
    local Gx = L:bip340_gx()
    local Gy = L:bip340_gy()
    local one = L:konst(L:one())
    local zero = L:konst(L:zero())

    -- 0. Verify e matches bits_e decomposition (MSB-first)
    L:bip340_assert_field_from_bits_msb(w.bits_e, w.e)

    -- 1. Verify s is a canonical secp256k1 scalar (0 <= s < n)
    L:bip340_assert_scalar_lt_order(w.bits_s)

    -- 2. Verify P is on the curve (py² = px³ + 7)
    L:bip340_assert_point_on_curve(w.px, w.py)

    -- 3. Compute s·G
    local sG_x, sG_y, sG_z = L:bip340_scalar_mult(
        Gx, Gy, one,
        w.bits_s, w.int_s.x, w.int_s.y, w.int_s.z)

    -- 4. Compute e·P
    local eP_x, eP_y, eP_z = L:bip340_scalar_mult(
        w.px, w.py, one,
        w.bits_e, w.int_e.x, w.int_e.y, w.int_e.z)

    local neg_eP_y = L:sub(zero, eP_y)
    local R_x, R_y, R_z = L:bip340_addE(
        sG_x, sG_y, sG_z,
        eP_x, neg_eP_y, eP_z)

    -- 6. Verify R is on the curve and finite
    L:bip340_assert_point_on_curve(w.rx, w.ry)
    -- Use L:mul to ensure placeholder resolution (R_z is EltW, w.rz_inv is placeholder)
    L:assert_eq(L:mul(R_z, w.rz_inv), one)

    -- 7. Check R.x == rx (projective equality)
    L:assert_eq(R_x, L:mul(w.rx, R_z))

    -- 8. Check R.y == ry (projective equality)
    L:assert_eq(R_y, L:mul(w.ry, R_z))

    -- 9. Verify ry bitness and even parity
    L:bip340_assert_field_from_bits_msb(w.bits_ry, w.ry)
    L:bip340_assert_even_from_bits_msb(w.bits_ry)

    return L:compile()
end

return M
