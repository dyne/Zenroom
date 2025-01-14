--[[
--This file is part of zenroom
--
--Copyright (C) 2018-2025 Dyne.org foundation
--designed, written and maintained by Denis Roio <jaromil@dyne.org>
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
--Last modified by Matteo Cristino
--on Tuesday, 14th January 2025
--]]

-- TODO: check for code duplication

-- some utils functions

-- preform have and pack the result into a table
local function _packed_have(t)
    return {have(t)}
end

-- trim leading and trailing spaces and underscores
local function utrim(s)
    s = string.gsub(s, "^[%s_]+", "")
    s = string.gsub(s, "[%s_]+$", "")
    return s
end


local function _numinput(num, codec)
    local t = type(num)
    if not iszen(t) then
        if t == 'table' then
            if codec and codec.encoding == 'complex' and codec.schema == 'date_table' then
                return num
            end
            -- input table are aggragated before doing any operation on them
            local aggr = nil
            for _, v in pairs(num) do
                if aggr then
                    aggr = aggr + _numinput(v)
                else
                    aggr = _numinput(v)
                end
                return aggr
            end
            return aggr
        elseif t ~= 'number' then
            error('Invalid numeric type: ' .. t, 2)
        end
        return num
    end
    if t == 'zenroom.octet' then
        return BIG.new(num)
    elseif t == 'zenroom.big' or t == 'zenroom.float' or t == 'zenroom.time' then
        return num
    else
        return BIG.from_decimal(num:octet():string()) -- may give internal errors
    end
    error("Invalid number", 2)
    return nil
end

-- escape math function overloads for pointers
local function _add(l, r) return (l + r) end
local function _sub(l, r) return (l - r) end
local function _mul(l, r) return (l * r) end
local function _div(l, r) return (l / r) end
local function _mod(l, r) return (l % r) end
local big_ops = {
    [_add] = BIG.zenadd,
    [_sub] = BIG.zensub,
    [_mul] = BIG.zenmul,
    [_div] = BIG.zendiv,
    [_mod] = BIG.zenmod
}
local function date_ops(op)
    return function(l, r)
        local res = {}
        local lc<const> = type(l) == 'zenroom.time' and os.date("*t", tonumber(l)) or l -- type(table) checked already in math_op
        local rc<const> = type(r) == 'zenroom.time' and os.date("*t", tonumber(r)) or r
        local fields<const> = {'year', 'month', 'day', 'hour', 'min', 'sec'}
        for _, v in pairs(fields) do
            res[v] = TIME.new(op(tonumber(lc[v]) or 0, tonumber(rc[v]) or 0))
        end
        return res
    end
end
local date_ops = {
    [_add] = date_ops(_add),
    [_sub] = date_ops(_sub)
}

local function _math_op(op, la, ra, res)
    empty(res)
    local left = _numinput(la[1], la[2])
    local right = _numinput(ra[1], ra[2])
    local lz = type(left)
    local rz = type(right)
    if lz ~= rz and not ((lz == 'zenroom.time' and rz == 'table') or (rz == 'zenroom.time' and lz == 'table')) then
        error("Incompatible numeric arguments " .. lz .. " and " .. rz, 2)
    end
    local n_codec = {
        zentype = 'e'
    }
    if lz == "zenroom.big" then
        n_codec.encoding = 'integer'
        op = big_ops[op]
        if not op then
            error("Operation not supported on big integers", 2)
        end
    elseif lz == "zenroom.time" or lz == "table" then
        n_codec.encoding = 'time'
        -- TODO: when other operations on time are supported remove this checks
        if op ~= _add and op ~= _sub then
            error("Operation not supported on time", 2)
        end
        if lz == "table" or rz == "table" then
            n_codec.encoding = 'complex'
            n_codec.schema = 'date_table'
            op = date_ops[op]
        end
    else
        n_codec.encoding = 'float'
    end
    ACK[res] = op(left, right)
    new_codec(res, n_codec)
end

When("create result of '' inverted sign", function(left)
    local l, lc = have(left)
    local zero = 0;
    if type(l) == "zenroom.big" then
        zero = INT.new(0)
    elseif type(l) == "zenroom.float" then
        zero = F.new(0)
    end
    _math_op(_sub, {zero}, {l, lc}, 'result')
end)

When("create result of '' + ''", function(left, right)
    _math_op(_add, _packed_have(left), _packed_have(right), 'result')
end)

When("create result of '' in '' + ''", function(left, dict, right)
    _math_op(_add, _packed_have({dict, left}), _packed_have(right), 'result')
end)

When("create result of '' in '' + '' in ''", function(left, ldict, right, rdict)
    _math_op(_add, _packed_have({ldict, left}), _packed_have({rdict, right}), 'result')
end)

When("create result of '' - ''", function(left, right)
    _math_op(_sub, _packed_have(left), _packed_have(right), 'result')
end)

When("create result of '' in '' - ''", function(left, dict, right)
    _math_op(_sub, _packed_have({dict, left}), _packed_have(right), 'result')
end)

When("create result of '' in '' - '' in ''", function(left, ldict, right, rdict)
    _math_op(_sub, _packed_have({ldict, left}), _packed_have({rdict, right}), 'result')
end)

When("create result of '' * ''", function(left, right)
    _math_op(_mul, _packed_have(left), _packed_have(right), 'result')
end)

When("create result of '' in '' * ''", function(left, dict, right)
    _math_op(_mul, _packed_have({dict, left}), _packed_have(right), 'result')
end)

When("create result of '' * '' in ''", function(left, right, dict)
    _math_op(_mul, _packed_have(left), _packed_have({dict, right}), 'result')
end)

When("create result of '' in '' * '' in ''", function(left, ldict, right, rdict)
    _math_op(_mul, _packed_have({ldict, left}), _packed_have({rdict, right}), 'result')
end)

When("create result of '' / ''", function(left, right)
    _math_op(_div, _packed_have(left), _packed_have(right), 'result')
end)

When("create result of '' in '' / ''", function(left, dict, right)
    _math_op(_div, _packed_have({dict, left}), _packed_have(right), 'result')
end)

When("create result of '' / '' in ''", function(left, right, dict)
    _math_op(_div, _packed_have(left), _packed_have({dict, right}), 'result')
end)

When("create result of '' in '' / '' in ''", function(left, ldict, right, rdict)
    _math_op(_div, _packed_have({ldict, left}), _packed_have({rdict, right}), 'result')
end)

When("create result of '' % ''", function(left, right)
    _math_op(_mod, _packed_have(left), _packed_have(right), 'result')
end)

When("create result of '' in '' % ''", function(left, dict, right)
    _math_op(_mod, _packed_have({dict, left}), _packed_have(right), 'result')
end)

When("create result of '' in '' % '' in ''", function(left, ldict, right, rdict)
    _math_op(_mod, _packed_have({ldict, left}), _packed_have({rdict, right}), 'result')
end)

-- generic polynomial evaluation

local ops2 = {
    ['zenroom.big'] = {
        ['+'] = BIG.zenadd,
        ['-'] = BIG.zensub,
        ['*'] = BIG.zenmul,
        ['/'] = BIG.zendiv
    },
    ['zenroom.float'] = {
        ['+'] = F.add,
        ['-'] = F.sub,
        ['*'] = F.mul,
        ['/'] = F.div
    },
    ['zenroom.time'] = {
        ['+'] = TIME.add,
        ['-'] = TIME.sub
    }
}

local function apply_op2(op, a, b)
    local a_type = type(a)
    if a_type ~= type(b) then
        error("Different types to do arithmetics on: " .. type(a) .. " and " .. type(b), 2)
    end
    if ops2[a_type] and ops2[a_type][op] then
        return ops2[a_type][op](a, b)
    else
        error("Unknown type to do arithmetics on: " .. type(a), 2)
    end
end

local ops1 = {
    ['zenroom.big'] = {
        ['~'] = BIG.zenopposite
    },
    ['zenroom.float'] = {
        ['~'] = F.opposite
    },
    ['zenroom.time'] = {
        ['~'] = TIME.opposite
    }
}

local function apply_op1(op, a)
    local a_type = type(a)
    if ops1[a_type] and ops1[a_type][op] then
        return ops1[a_type][op](a)
    else
        error("Unknown type to do arithmetics on: " .. type(a), 2)
    end
end

-- ~ is unary minus
local priorities = {
    ['+'] = 0,
    ['-'] = 0,
    ['*'] = 1,
    ['/'] = 1,
    ['~'] = 2
}
When("create result of ''", function(expr)
    local specials = {'(', ')'}
    local i, j
    empty 'result'
    for k, v in pairs(priorities) do
        table.insert(specials, k)
    end
    -- tokenizations
    local re = '[()*%-%/+]'
    local tokens = {}
    i = 1
    repeat
        j = expr:find(re, i)
        if j then
            if i < j then
                local val = utrim(expr:sub(i, j - 1))
                if val ~= "" then
                    table.insert(tokens, val)
                end
            end
            table.insert(tokens, expr:sub(j, j))
            i = j + 1
        end
    until not j
    if i <= #expr then
        local val = utrim(expr:sub(i))
        if val ~= "" then
            table.insert(tokens, val)
        end
    end

    -- infix to RPN
    local rpn = {}
    local operators = {}
    local last_token
    for k, v in pairs(tokens) do
        if v == '-' and (#rpn == 0 or last_token == '(') then
            table.insert(operators, '~') -- unary minus (change sign)
        elseif priorities[v] then
            while #operators > 0 and operators[#operators] ~= '(' and priorities[operators[#operators]] >= priorities[v] do
                table.insert(rpn, operators[#operators])
                operators[#operators] = nil
            end
            table.insert(operators, v)
        elseif v == '(' then
            table.insert(operators, v)
        elseif v == ')' then
            -- put every operator in rpn until I don't see the open parens
            while #operators > 0 and operators[#operators] ~= '(' do
                table.insert(rpn, operators[#operators])
                operators[#operators] = nil
            end
            zencode_assert(#operators > 0, "Paranthesis not balanced", 2)
            operators[#operators] = nil -- remove open parens
        else
            table.insert(rpn, v)
        end
        last_token = v
    end

    -- all remaining operators have to be applied
    for i = #operators, 1, -1 do
        if operators[i] == '(' then
            zencode_assert(false, "Paranthesis not balanced", 2)
        end
        table.insert(rpn, operators[i])
    end

    local values = {}
    -- evaluate the expression
    for k, v in pairs(rpn) do
        if v == '~' then
            local op = values[#values];
            values[#values] = nil
            table.insert(values, apply_op1(v, op))
        elseif priorities[v] then
            zencode_assert(#values >= 2)
            local op1 = values[#values];
            values[#values] = nil
            local op2 = values[#values];
            values[#values] = nil
            local res = apply_op2(v, op2, op1)
            table.insert(values, res)
        else
            local val
            -- is the current number a integer?
            if BIG.is_integer(v) then
                val = BIG.from_decimal(v)
            elseif F.is_float(v) then
                val = F.new(v)
            else
                val = have(v)
            end
            table.insert(values, val)
        end
    end

    zencode_assert(#values == 1, "Invalid arithmetical expression", 2)
    ACK.result = values[1]
    local n_codec = {
        zentype = 'e'
    }
    if type(values[1]) == 'zenroom.big' then
        n_codec.encoding = 'integer'
    elseif type(values[1]) == 'zenroom.float' then
        n_codec.encoding = 'float'
    elseif type(values[1]) == 'zenroom.time' then
        n_codec.encoding = 'time'
    end
    new_codec('result', n_codec)
end)
