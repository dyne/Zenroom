--[[
--This file is part of zenroom
--
--Copyright (C) 2018-2026 Dyne.org foundation
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

-- trim leading and trailing spaces and underscores
local function utrim(s)
    s = string.gsub(s, "^[%s_]+", "")
    s = string.gsub(s, "[%s_]+$", "")
    return s
end

-- datetable operations
local function date_ops(op)
    return function(l, r)
        local res = {}
        local lc <const> = type(l) == 'zenroom.time' and os.date("*t", tonumber(l)) or l -- type(table) checked already in math_op
        local rc <const> = type(r) == 'zenroom.time' and os.date("*t", tonumber(r)) or r
        local fields <const> = { 'year', 'month', 'day', 'hour', 'min', 'sec' }
        for _, v in pairs(fields) do
            res[v] = TIME.new(op(tonumber(lc[v]) or 0, tonumber(rc[v]) or 0))
        end
        return res
    end
end

-- biynary operations
local ops2 <const> = {
    ['zenroom.big'] = {
        ['+'] = BIG.zenadd,
        ['-'] = BIG.zensub,
        ['*'] = BIG.zenmul,
        ['/'] = BIG.zendiv,
        ['%'] = BIG.zenmod
    },
    ['zenroom.float'] = {
        ['+'] = F.add,
        ['-'] = F.sub,
        ['*'] = F.mul,
        ['/'] = F.div,
        ['%'] = F.mod
    },
    ['zenroom.time'] = {
        ['+'] = TIME.add,
        ['-'] = TIME.sub
    },
    ['table'] = {
        ['+'] = date_ops(function(a,b) return a+b end),
        ['-'] = date_ops(function(a,b) return a-b end)
    }
}
local function apply_op2(op, a, b)
    local a_type <const> = type(a)
    local b_type <const> = type(b)
    -- manage time + table
    if a_type == 'table' and b_type == 'zenroom.time' then
        return ops2[a_type][op](a, b)
    elseif b_type == 'table' and a_type == 'zenroom.time' then
        return ops2[b_type][op](a, b)
    end

    if a_type ~= b_type then
        error("Different types to do arithmetics on: " .. a_type .. " and " .. type(b), 2)
    end
    if ops2[a_type] and ops2[a_type][op] then
        return ops2[a_type][op](a, b)
    else
        error("Unknown type to do arithmetics on: " .. type(a), 2)
    end
end

-- unitary operations
local ops1 <const> = {
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
    local a_type <const> = type(a)
    if ops1[a_type] and ops1[a_type][op] then
        return ops1[a_type][op](a)
    else
        error("Unknown type to do arithmetics on: " .. type(a), 2)
    end
end

-- operator priorities
local priorities <const> = {
    ['+'] = 0,
    ['-'] = 0,
    ['*'] = 1,
    ['/'] = 1,
    ['%'] = 1,
    ['~'] = 2 -- unary minus
}

-- eval rpn expressions
local function _rpn_eval(rpn)
    -- cache
    local remove <const> = table.remove
    local insert <const> = table.insert
    -- evaluate the rpn expression
    local values = {}
    for _, v in pairs(rpn) do
        local res
        if v == '~' then
            local op = remove(values)
            if not op then
                error("Invalid arithmetical expression", 2)
            end
            res = apply_op1(v, op)
        elseif priorities[v] then
            local op1 = remove(values)
            local op2 = remove(values)
            if not op1 or not op2 then
                error("Invalid arithmetical expression", 2)
            end
            res = apply_op2(v, op2, op1)
        else
            local t <const> = type(v)
            -- is the current number a integer?
            if BIG.is_integer(v) then
                res = BIG.new(v)
            elseif F.is_float(v) then
                res = F.new(v)
            elseif t == 'zenroom.big' or t == 'zenroom.time' or t == 'zenroom.float' or t == 'table' then
                res = v
            else
                -- handle path divided by conf separator in value name
                res = pick_from_path(v, true)
            end
        end
        insert(values, res)
    end

    if #values ~= 1 then
        error("Invalid arithmetical expression", 2)
    end
    ACK.result = values[1]
    local t <const> = type(ACK.result)
    local n_codec = {
        zentype = 'e'
    }
    if t == 'zenroom.big' then
        n_codec.encoding = 'integer'
    elseif t == 'zenroom.float' then
        n_codec.encoding = 'float'
    elseif t == 'zenroom.time' then
        n_codec.encoding = 'time'
    elseif t == 'table' then
        n_codec.encoding = 'complex'
        n_codec.schema = 'date_table'
    end
    new_codec('result', n_codec)
end

local function _check_not_table(name, inside)
    local s, c = have(fif(inside, {inside, name}, name))
    if type(s) ~= 'table' then return s end
    if c and c.encoding == 'complex' and c.schema == 'date_table' then return s end
    warn("Table needs to be aggregated before doing math operation with it: " .. name)
    error("Found table as input to math operation: " .. name, 2)
end

When("create result of '' inverted sign", function(left)
    local l = _check_not_table(left)
    _rpn_eval({l, '~'})
end)

When("create result of '' + ''", function(left, right)
    local l = _check_not_table(left)
    local r = _check_not_table(right)
    _rpn_eval({l, r, '+'})
end)

When("create result of '' in '' + ''", function(left, ldict, right)
    local l = _check_not_table(left, ldict)
    local r = _check_not_table(right)
    _rpn_eval({l, r, '+'})
end)

When("create result of '' in '' + '' in ''", function(left, ldict, right, rdict)
    local l = _check_not_table(left, ldict)
    local r = _check_not_table(right, rdict)
    _rpn_eval({l, r, '+'})
end)

When("create result of '' - ''", function(left, right)
    local l = _check_not_table(left)
    local r = _check_not_table(right)
    _rpn_eval({l, r, '-'})
end)

When("create result of '' in '' - ''", function(left, ldict, right)
    local l = _check_not_table(left, ldict)
    local r = _check_not_table(right)
    _rpn_eval({l, r, '-'})
end)

When("create result of '' in '' - '' in ''", function(left, ldict, right, rdict)
    local l = _check_not_table(left, ldict)
    local r = _check_not_table(right, rdict)
    _rpn_eval({l, r, '-'})
end)

When("create result of '' * ''", function(left, right)
    local l = _check_not_table(left)
    local r = _check_not_table(right)
    _rpn_eval({l, r, '*'})
end)

When("create result of '' in '' * ''", function(left, ldict, right)
    local l = _check_not_table(left, ldict)
    local r = _check_not_table(right)
    _rpn_eval({l, r, '*'})
end)

When("create result of '' * '' in ''", function(left, right, rdict)
    local l = _check_not_table(left)
    local r = _check_not_table(right, rdict)
    _rpn_eval({l, r, '*'})
end)

When("create result of '' in '' * '' in ''", function(left, ldict, right, rdict)
    local l = _check_not_table(left, ldict)
    local r = _check_not_table(right, rdict)
    _rpn_eval({l, r, '*'})
end)

When("create result of '' / ''", function(left, right)
    local l = _check_not_table(left)
    local r = _check_not_table(right)
    _rpn_eval({l, r, '/'})
end)

When("create result of '' in '' / ''", function(left, ldict, right)
    local l = _check_not_table(left, ldict)
    local r = _check_not_table(right)
    _rpn_eval({l, r, '/'})
end)

When("create result of '' / '' in ''", function(left, right, rdict)
    local l = _check_not_table(left)
    local r = _check_not_table(right, rdict)
    _rpn_eval({l, r, '/'})
end)

When("create result of '' in '' / '' in ''", function(left, ldict, right, rdict)
    local l = _check_not_table(left, ldict)
    local r = _check_not_table(right, rdict)
    _rpn_eval({l, r, '/'})
end)

When("create result of '' % ''", function(left, right)
    local l = _check_not_table(left)
    local r = _check_not_table(right)
    _rpn_eval({l, r, '%'})
end)

When("create result of '' in '' % ''", function(left, ldict, right)
    local l = _check_not_table(left, ldict)
    local r = _check_not_table(right)
    _rpn_eval({l, r, '%'})
end)

When("create result of '' in '' % '' in ''", function(left, ldict, right, rdict)
    local l = _check_not_table(left, ldict)
    local r = _check_not_table(right, rdict)
    _rpn_eval({l, r, '%'})
end)

-- generic polynomial evaluation
When("create result of ''", function(expr)
    -- cache
    local insert <const> = table.insert
    local remove <const> = table.remove

    empty 'result'
    -- tokenizations
    local re <const> = '[()*%-%/+]'
    local tokens = {}
    local function extract_and_add_token(range_start, range_end)
        local val <const> = utrim(expr:sub(range_start, range_end))
        if val ~= "" then insert(tokens, val) end
    end
    local start_pos = 1
    while true do
        local match_pos <const> = expr:find(re, start_pos)
        if not match_pos then
            -- if no match found add remaining token to tokens
            extract_and_add_token(start_pos, #expr)
            break
        elseif start_pos < match_pos then
            -- add tokens find between one special symbol and the other
            extract_and_add_token(start_pos, match_pos - 1)
        end
        -- add matched special symbol char to tokens
        extract_and_add_token(match_pos, match_pos)
        start_pos = match_pos + 1
    end

    -- infix to RPN
    local rpn = {}
    local operators = {}
    local expected_unary = true
    for _, v in pairs(tokens) do
        if v == '-' and expected_unary then
            insert(operators, '~') -- unary minus (change sign)
        elseif priorities[v] then
            while next(operators) and operators[#operators] ~= '(' and priorities[operators[#operators]] >= priorities[v] do
                insert(rpn, remove(operators))
            end
            insert(operators, v)
        elseif v == '(' then
            insert(operators, v)
        elseif v == ')' then
            -- put every operator in rpn until I don't see the open parens
            while next(operators) and operators[#operators] ~= '(' do
                insert(rpn, remove(operators))
            end
            zencode_assert(next(operators), "Paranthesis not balanced", 2)
            remove(operators) -- remove open parens
        else
            insert(rpn, v)
        end
        expected_unary = v == '('
    end

    -- all remaining operators have to be applied
    while(next(operators)) do
        local op <const> = remove(operators)
        zencode_assert(op ~= ')', "Paranthesis not balanced", 2)
        insert(rpn, op)
    end

    -- evaluate rpn expression
    _rpn_eval(rpn)
end)
