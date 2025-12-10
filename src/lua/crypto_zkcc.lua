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

-- Export native symbols
for k, v in pairs(native) do
    M[k] = v
end

-- Utility helpers
local function shallow_copy(tbl)
    local out = {}
    for k, v in pairs(tbl) do
        out[k] = v
    end
    return out
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
-- Named Artifact Wrapper (schema stays on the Lua side)
-- ===========================================================================
local function copy_entries(entries)
    local out = {}
    for i, e in ipairs(entries) do
        out[i] = { name = e.name, kind = e.kind, index = e.index }
    end
    return out
end

local function rebuild_indexes(schema)
    local by_name = {}
    local by_index = {}
    local function add(entry)
        if entry.name then
            by_name[entry.name] = entry
        end
        by_index[entry.index] = entry
    end
    for _, e in ipairs(schema.public) do add(e) end
    for _, e in ipairs(schema.private) do add(e) end
    for _, e in ipairs(schema.full) do add(e) end
    schema.by_name = by_name
    schema.by_index = by_index
end

local function snapshot_schema(state, artifact)
    local schema = {
        public = copy_entries(state.public),
        private = copy_entries(state.private),
        full = copy_entries(state.full),
        order = copy_entries(state.order),
        counts = {},
    }
    rebuild_indexes(schema)
    schema.counts.public = #schema.public
    schema.counts.private = #schema.private
    schema.counts.full = #schema.full
    schema.total = (artifact and artifact.ninput) and (artifact.ninput - 1) or state.inputs
    schema.npub = (artifact and artifact.npub_input) and (artifact.npub_input - 1) or schema.counts.public
    return schema
end

local function resolve_named_inputs(schema, values, kind_filter)
    if type(values) ~= "table" then
        error("inputs must be provided as a table", 2)
    end
    local resolved = {}
    local numeric_present = {}
    for k, v in pairs(values) do
        if type(k) == "number" then
            resolved[k] = v
            numeric_present[k] = true
        elseif type(k) == "string" then
            local entry = schema.by_name[k]
            if not entry then
                error("unknown input name: " .. k, 2)
            end
            if kind_filter and entry.kind ~= kind_filter then
                error(string.format("input '%s' is %s, expected %s", k, entry.kind, kind_filter), 2)
            end
            resolved[entry.index] = v
        end
    end

    local missing = {}
    for _, entry in ipairs(schema.order) do
        if entry.name and (not kind_filter or entry.kind == kind_filter) then
            if resolved[entry.index] == nil and not numeric_present[entry.index] then
                table.insert(missing, entry.name)
            end
        end
    end
    if #missing > 0 then
        error("missing inputs: " .. table.concat(missing, ", "), 2)
    end
    return resolved
end

local NamedArtifact = {}
NamedArtifact.__index = function(self, key)
    if key == "raw" or key == "artifact" then
        return self._artifact
    end
    if key == "schema" then
        return self._schema
    end
    local method = NamedArtifact[key]
    if method then
        return method
    end
    local v = self._artifact[key]
    if type(v) == "function" then
        return function(_, ...)
            return v(self._artifact, ...)
        end
    end
    return v
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
    return setmetatable({
        _artifact = artifact,
        _schema = schema or {},
    }, NamedArtifact)
end

-- ===========================================================================
-- Named Logic Wrapper (records schema alongside native logic)
-- ===========================================================================
local NamedLogic = {}
NamedLogic.__index = function(self, key)
    local method = NamedLogic[key]
    if method then
        return method
    end
    local v = self._logic[key]
    if type(v) == "function" then
        return function(_, ...)
            return v(self._logic, ...)
        end
    end
    return v
end

local function new_state()
    return {
        inputs = 0,
        public = {},
        private = {},
        full = {},
        order = {},
        by_name = {},
    }
end

local function record_input(self, kind, name)
    self._state.inputs = self._state.inputs + 1
    local entry = { name = name, kind = kind, index = self._state.inputs }
    if name then
        if self._state.by_name[name] then
            error("duplicate input name: " .. name, 3)
        end
        self._state.by_name[name] = entry
        table.insert(self._state[kind], entry)
        table.insert(self._state.order, entry)
    end
    return self._logic:eltw_input()
end

function NamedLogic:pub(name)
    if self._private_started or self._full_started then
        error("public inputs must be declared before private/full inputs", 2)
    end
    return record_input(self, "public", name)
end

function NamedLogic:priv(name)
    if not self._private_started then
        self._logic:private_inputs()
        self._private_started = true
    end
    if self._full_started then
        error("private inputs must come before full-field inputs", 2)
    end
    return record_input(self, "private", name)
end

function NamedLogic:full(name)
    if not self._private_started then
        self._logic:private_inputs()
        self._private_started = true
    end
    if not self._full_started then
        self._logic:begin_full_field()
        self._full_started = true
    end
    return record_input(self, "full", name)
end

function NamedLogic:compile(...)
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
        _private_started = false,
        _full_started = false,
    }, NamedLogic)
end

-- ===========================================================================
-- Public helpers and wrappers
-- ===========================================================================
M.named_logic = new_named_logic

local function unwrap_opts(opts, public_only)
    if type(opts) ~= "table" then
        return opts
    end
    local circuit = opts.circuit
    if not circuit then
        return opts
    end
    local schema
    local out = opts
    if is_named_artifact(circuit) then
        schema = circuit.schema
        out = shallow_copy(opts)
        out.circuit = circuit:raw()
    elseif circuit.schema then
        schema = circuit.schema
    end
    if schema then
        local function convert(field, filter)
            local val = out[field]
            if type(val) == "table" and has_string_keys(val) then
                if out == opts then
                    out = shallow_copy(out)
                end
                out[field] = resolve_named_inputs(schema, val, filter)
            end
        end
        convert("inputs", nil)
        convert("public_inputs", public_only and "public" or nil)
    end
    return out
end

-- Wrap selected entrypoints to understand named artifacts
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

-- Also set global functions for backward compatibility
for k, v in pairs(M) do
    if type(v) == "function" then
        _G[k] = v
    end
end

-- Set the module version
M._VERSION = native.LONGFELLOW_ZK_VERSION or "0.1.0"

return M
