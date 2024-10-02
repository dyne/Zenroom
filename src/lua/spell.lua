-- Spelling Corrector.
--
-- Copyright 2014 Francisco Zamora-Martinez
-- Copyright 2024 Jaromil (Dyne.org)
-- Adaptation of Peter Norvig python Spelling Corrector:
-- http://norvig.com/spell-correct.html
-- Open source code under MIT license: http://www.opensource.org/licenses/mit-license.php

local yield, wrap = coroutine.yield, coroutine.wrap
local alphabet_str, alphabet = 'abcdefghijklmnopqrstuvwxyz', {}
for a in alphabet_str:gmatch(".") do alphabet[#alphabet + 1] = a end
spell = {}

local function list(w) return pairs { [w] =true } end

function spell:max(...)
    local arg, max, hyp = table.pack(...), 0, nil
    for w in table.unpack(arg) do
        local p = self.model[w] or 1
        if p > max or (p == max and hyp < w) then
            hyp, max = w, p
        end
    end
    return hyp
end

-- local function words(text) return text:lower():gmatch("[a-z]+") end

-- local function train(features)
--   for f in features do model[f] = (model[f] or 1) + 1 end
-- end

-- local function init(filename) train(words(io.open(filename):read("*a"))) end

local function make_yield()
    local set = {}
    return function(w)
        if not set[w] then
            set[w] = true
            yield(w)
        end
    end
end

local function edits1(word_str, yield)
    local yield = yield or make_yield()
    return wrap(function()
        local splits, word = {}, {}
        for i = 1, #word_str do
            word[i], splits[i] = word_str:sub(i, i), {word_str:sub(1, i), word_str:sub(i)}
        end
        -- sentinels
        splits[0], splits[#word_str + 1] = {"", word_str}, {word_str, ""}
        -- deletes
        for i = 1, #word_str do
            yield(splits[i - 1][1] .. splits[i + 1][2])
        end
        -- transposes
        for i = 1, #word_str - 1 do
            yield(splits[i - 1][1] .. word[i + 1] .. word[i] .. splits[i + 2][2])
        end
        -- replaces
        for i = 1, #word_str do
            for j = 1, #alphabet do
                yield(splits[i - 1][1] .. alphabet[j] .. splits[i + 1][2])
            end
        end
        -- inserts
        for i = 0, #word_str do
            for j = 1, #alphabet do
                yield(splits[i][1] .. alphabet[j] .. splits[i + 1][2])
            end
        end
    end)
end

function spell:known_edits2(w, set)
    local yield, yield2 = make_yield(), make_yield()
    return wrap(function()
        for e1 in edits1(w) do
            for e2 in edits1(e1, yield2) do
                if self.model[e2] then
                    yield(e2)
                end
            end
        end
    end)
end

function spell:known(list, aux)
    return wrap(function()
        for w in list, aux do
            if self.model[w] then
                yield(w)
            end
        end
    end)
end

function spell:correct(w)
    local w = w:lower()
    local result = self:max(self:known(list(w)))
        or self:max(self:known(edits1(w)))
        or self:max(self:known_edits2(w))
        or self:max(list(w))
    if result then
        return result
    else
        return false, "No suggestion found for word: " .. w
    end
end

return spell
