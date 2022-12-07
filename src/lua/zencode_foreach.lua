Foreach("'' in ''", function(name, collection)
    local info = ZEN.ITER
    local col = have(collection)
    ZEN.assert(ZEN.CODEC[collection].zentype == "array", "Can only iterate over arrays")
    -- in the first itaration decale the index variable
    if info.pos == 1 or not ACK[name] then
        empty(name)
    end

    -- skip execution in the last iteration
    if info.pos == #col+1 then
        info.pos = 0
    else
        -- for each iteration read the value in the collection
        ACK[name] = col[info.pos]
        if not ZEN.CODEC[name] then
            new_codec(name, {encoding = ZEN.CODEC[collection].encoding})
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
    end

    ZEN.assert(type(from) == type(to) and type(to) == type(step), "Types must be equal in foreach declaration")
    ZEN.assert(type(from) == 'zenroom.big' or type(from) == 'zenroom.float', "Unknown number type")
    local current_value
    local finished
    -- TODO(optimization): we are currently doing multiplication at each iteration
    if type(from) == 'zenroom.big' then
        ZEN.assert(BIG.zenpositive(step)
            and BIG.zenpositive(BIG.zensub(to, from)),
            "only positive step is supported")
        ZEN.assert(step ~= BIG.new(0), "step cannot be zero")
        local bigpos = BIG.new(info.pos-1)
        current_value = BIG.zenadd(from, BIG.zenmul(bigpos, step))
        -- current_value >  to
        -- current_value >= to + 1
        -- (current_value - (to+1)) >= 0
        finished = BIG.zenpositive(
            BIG.zensub(current_value, BIG.zenadd(to,BIG.new(1))))
    else
        ZEN.assert(step > F.new(0) and from < to,
            "only positive step is supported")
        local floatpos = F.new(info.pos-1)
        current_value = from + floatpos * step
        finished = current_value > to
    end

    if finished then
        info.pos = 0
    else
        ACK[name] = current_value
        if not ZEN.CODEC[name] then
            new_codec(name, ZEN.CODEC[from])
            ZEN.CODEC[name].name = name
        end
    end
end)
