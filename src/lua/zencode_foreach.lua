local function clear_iterators()
    if not ZEN.ITER.names then return end
    for _,v in pairs(ZEN.ITER.names) do
        ACK[v] = nil
        CODEC[v] = nil
    end
    ZEN.ITER.names = nil
end

Foreach("'' in ''", function(name, collection)
    local info = ZEN.ITER
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
    local info = ZEN.ITER
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
    local current_value
    local finished
    -- TODO(optimization): we are currently doing multiplication at each iteration
    if type(from) == 'zenroom.big' then
        zencode_assert(BIG.zenpositive(step)
            and BIG.zenpositive(BIG.zensub(to, from)),
            "only positive step is supported")
        zencode_assert(step ~= BIG.new(0), "step cannot be zero")
        local bigpos = BIG.new(info.pos-1)
        current_value = BIG.zenadd(from, BIG.zenmul(bigpos, step))
        -- current_value >  to
        -- current_value >= to + 1
        -- (current_value - (to+1)) >= 0
        finished = BIG.zenpositive(
            BIG.zensub(current_value, BIG.zenadd(to,BIG.new(1))))
    else
        zencode_assert(step > F.new(0) and from < to,
            "only positive step is supported")
        local floatpos = F.new(info.pos-1)
        current_value = from + floatpos * step
        finished = current_value > to
    end

    if finished then
        info.pos = 0
        clear_iterators()
    else
        ACK[name] = current_value
        if not CODEC[name] then
            new_codec(name, CODEC[from])
            CODEC[name].name = name
        end
    end
end)

local function break_foreach()
    zencode_assert(ZEN.ITER and ZEN.ITER.pos ~=0, "Can only exit from foreach loop")
    ZEN.ITER.pos = 0
    clear_iterators()
end

When("exit foreach", break_foreach)
When("break foreach", break_foreach)
