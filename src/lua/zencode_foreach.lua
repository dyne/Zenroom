local function clear_iterators()
    local info = ZEN.ITER_head
    if not info.names then return end
    for _,v in pairs(info.names) do
        ACK[v] = nil
        CODEC[v] = nil
    end
    info.names = nil
end

Foreach("'' in ''", function(name, collection)
    local info = ZEN.ITER_head
    local col = have(collection)
    local collection_codec = CODEC[collection]
    zencode_assert(collection_codec.zentype == "a", "Can only iterate over arrays")
    -- in the first itaration decale the index variable
    if info.pos == 1 or not ACK[name] then
        empty(name)
        if info.names then table.insert(info.names, name)
        else info.names = {name} end
    end

    -- skip execution in the last iteration
    if info.pos == #col+1 then
        info.pos = 0
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

    if info.pos == 1 or not ACK[name] then
        empty(name)
        if info.names then table.insert(info.names, name)
        else info.names = {name} end
    end

    zencode_assert(type(from) == type(to) and type(to) == type(step), "Types must be equal in foreach declaration")
    zencode_assert(type(from) == 'zenroom.big' or type(from) == 'zenroom.float', "Unknown number type")
    local finished
    if type(from) == 'zenroom.big' then
        -- only on first iteration: do checks and save usefull values
        if info.pos == 1 then
            zencode_assert(BIG.zenpositive(step) and step ~= BIG.new(0), "only positive step is supported")
            zencode_assert(BIG.zenpositive(BIG.zensub(to, from)), "end of foreach must be bigger than the start")
            info.to_plus_1 = BIG.zenadd(to, BIG.new(1)) -- store to avoid repeating at each step
            info.cv = from
        else
            info.cv = BIG.zenadd(info.cv, step)
        end
        -- current_value >  to
        -- current_value >= to + 1
        -- (current_value - (to+1)) >= 0
        local diff = BIG.zensub(info.cv, info.to_plus_1)
        finished = BIG.zenpositive(diff) or diff == BIG.new(0)
    else
        -- only on first iteration: do checks and save usefull values
        if info.pos == 1 then
            zencode_assert(step > F.new(0) and from < to,
                "only positive step is supported")
            info.cv = from
        else
            info.cv = info.cv + step
        end
        finished = info.cv > to
    end

    if finished then
        info.pos = 0
        clear_iterators()
    else
        ACK[name] = info.cv
        if not CODEC[name] then
            new_codec(name, CODEC[from])
            CODEC[name].name = name
        end
    end
end)

local function break_foreach()
    if not ZEN.ITER_head then
       error("Can only exit from foreach loop", 2)
    end
    ZEN.ITER_head.pos = 0
    clear_iterators()
end

When("exit foreach", break_foreach)
When("break foreach", break_foreach)
