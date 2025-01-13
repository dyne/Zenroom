local function clear_iterators()
    local info = ZEN.ITER_head
    if not info.names then return end
    for _,v in pairs(info.names) do
        ACK[v] = nil
        CODEC[v] = nil
    end
    info.names = nil
    info.pos = 0
end

local function init_iterator(name)
    local info = ZEN.ITER_head
    if info.pos == 1 or not ACK[name] then
        empty(name)
        if info.names then table.insert(info.names, name)
        else info.names = {name} end
    end
end

Foreach("'' in ''", function(name, collection)
    local info = ZEN.ITER_head
    local col = have(collection)
    local collection_codec = CODEC[collection]

    zencode_assert(collection_codec.zentype == "a", "Can only iterate over arrays")
    init_iterator(name)

    -- skip execution in the last iteration
    if info.pos == #col+1 then
        clear_iterators()
    else
        -- for each iteration read the value in the collection
        ACK[name] = col[info.pos]
        if not CODEC[name] then
            local n_codec = {encoding = collection_codec.encoding}
            if collection_codec.schema then
                n_codec.schema = collection_codec.schema
                n_codec.zentype = "e"
            end
            new_codec(name, n_codec)
        end
    end
end)

Foreach("'' in sequence from '' to '' with step ''", function(name, from_name, to_name, step_name)
    local info = ZEN.ITER_head
    local from = have(from_name)
    local to   = have(to_name)
    local step = have(step_name)

    zencode_assert(type(from) == type(to) and type(to) == type(step), "Types must be equal in foreach declaration")
    zencode_assert(type(from) == 'zenroom.big' or type(from) == 'zenroom.float', "Unknown number type")
    init_iterator(name)

    local finished
    if type(from) == 'zenroom.big' then
        -- only on first iteration: do checks and save usefull values
        if info.pos == 1 then
            zencode_assert(step ~= BIG.new(0), "zero step is not supported")
            local range_size = BIG.zensub(to, from)
            if BIG.zenpositive(step) then
                zencode_assert(BIG.zenpositive(range_size) or range_size == BIG.new(0), "end of foreach must be bigger than the start for postive step")
                info.to_plus_1 = BIG.zenadd(to, BIG.new(1))
                -- current_value >  to
                -- current_value >= to + 1
                -- (current_value - (to+1)) >= 0
                info.check_fn = function ()
                    local diff = BIG.zensub(info.cv, info.to_plus_1)
                    return BIG.zenpositive(diff) or diff == BIG.new(0)
                end
            else
                zencode_assert(not BIG.zenpositive(range_size) or range_size == BIG.new(0), "end of foreach must be smaller than the start for negative step")
                info.to_minus_1 = BIG.zensub(to, BIG.new(1))
                -- current_value < to
                -- current_value <= to - 1
                -- (current_value - (to-1)) <= 0
                info.check_fn = function()
                    local diff = BIG.zensub(info.cv, info.to_minus_1)
                    return not BIG.zenpositive(diff) or diff == BIG.new(0)
                end
            end
            info.cv = from
        else
            info.cv = BIG.zenadd(info.cv, step)
        end
        finished = info.check_fn()
    else
        -- only on first iteration: do checks and save usefull values
        if info.pos == 1 then
            zencode_assert(step ~= F.new(0), "zero step is not supported")
            if step > F.new(0) then
                zencode_assert(from <= to, "end of foreach must be bigger than the start for postive step")
                info.check_fn = function() return info.cv > to end
            else
                zencode_assert(from >= to, "end of foreach must be smaller than the start for negative step")
                info.check_fn = function() return info.cv < to end
            end
            info.cv = from
        else
            info.cv = info.cv + step
        end
        finished = info.check_fn()
    end

    if finished then
        clear_iterators()
    else
        ACK[name] = info.cv
        if not CODEC[name] then
            new_codec(name, CODEC[from])
            CODEC[name].name = name
        end
    end
end)

local function _zip_with_prefix(name, ...)
    local info = ZEN.ITER_head
    local arrays_names = {...}
    local encoding_fn = {}

    for _, n in pairs(arrays_names) do
        local v, c = have(n)
        local prefixed_name = uscore(name..n)
        -- on first iterations checks that are all arrays
        if info.pos == 1 then
            if (c.zentype ~= "a") then
                error("Can only iterate over arrays: "..n.." is "..c.zentype, 2)
            end
            init_iterator(prefixed_name)
        end
        -- terminate loop as soon as one array ends
        if not v[info.pos] then
            clear_iterators()
            return
        else
            ACK[prefixed_name] = v[info.pos]
            if not CODEC[prefixed_name] then
                local n_codec = { encoding = c.encoding }
                -- table of schemas can only contain elements
                if c.schema then
                    n_codec.schema = c.schema
                    n_codec.zentype = "e"
                end
                new_codec(prefixed_name, n_codec)
            end
        end
    end
end

Foreach("values prefix '' at same position in arrays '' and ''", _zip_with_prefix)
Foreach("values prefix '' at same position in arrays ''", function(name, arrays_names)
    local v, c = have(arrays_names)
    zencode_assert(c.zentype == "a" and c.encoding == "string",
        "Array of names must be specified in a string array")
    zencode_assert(next(v,_) ~= nil, "Array of names must not be empty")
    _zip_with_prefix(name, table.unpack(deepmap(O.to_string, v)))
end)

-- break foreach

local function break_foreach()
    if not ZEN.ITER_head then
       error("Can only exit from foreach loop", 2)
    end
    clear_iterators()
end

When("exit foreach", break_foreach)
When("break foreach", break_foreach)
