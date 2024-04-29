-- intrspection.txt  --> contains all the statements present in src/lua/zencode_*.lua
--                       divided by scenario and there is a empty line between the scenarios
-- documented.txt    --> contains all the statements present in docs/_media/examples/zencode_cookbook/**/*.zen

local function all_statements(file_name)
    io.input(file_name)
    local d = {}
    local scenarios = {}
    local scenario, line
    while true do
        line = io.read()
        if not line then break end
        if line == "" then
            -- reading the scenario
            scenario = io.read()
            d[scenario] = {}
            table.insert(scenarios, scenario) -- used to create a sorted output file
        else
            d[scenario][line:lower()] = true -- saving the statement
        end
    end
    io.input():close()
    table.sort(scenarios)
    return scenarios, d
end

local function documented(file_name)
    local gsub = string.gsub
    local to, _, previous_to
    local d = {}
    for line in io.lines(file_name) do
        -- CLEAN THE STATEMENT (adapted from src/lua/zencode.lua)
        line = gsub(line, "'(.-)'", "''")
        line = gsub(line, ' I ', ' ', 1) -- eliminate first person
        line = line:lower()
        to, _ = line:match("(%w+)(.+)") -- select the frist word of the string
        -- previous_to to handle "and __" statements
        if (to == 'then') or (to == 'and' and previous_to == 'then') then
            previous_to = 'then'
            line = gsub(line, ' the ', ' ', 1)
        elseif (to == 'given') or (to == 'and' and previous_to == 'given') then
            previous_to = 'given'
            line = gsub(line, ' the ', ' ', 1)
            line = gsub(line, ' a ', ' ', 1)
            line = gsub(line, ' an ', ' ', 1)
            line = gsub(line, ' have ', ' ', 1)
            line = gsub(line, ' known as ', ' ', 1)
            line = gsub(line, ' valid ', ' ', 1)
        else
            previous_to = nil
        end
        -- prefixes found at beginning of statement
        line = gsub(line, '^when ', '', 1)
        line = gsub(line, '^then ', '', 1)
        line = gsub(line, '^given ', '', 1)
        line = gsub(line, '^if ', '', 1)
        line = gsub(line, '^foreach ', '', 1)
        line = gsub(line, '^and ', '', 1)
        -- generic particles
        line = gsub(line, '^that ', ' ', 1)
        line = gsub(line, ' the ', ' ')
        line = gsub(line, '^an ', 'a ', 1)
        line = gsub(line, ' valid ', ' ', 1)
        line = gsub(line, ' all ', ' ', 1)
        line = gsub(line, ' inside ', ' in ', 1)
        line = gsub(line, ' +', ' ') -- eliminate multiple internal spaces
        line = gsub(line, '^ +', '') -- remove initial spaces
        line = gsub(line, ' +$', '') -- remove final spaces


        if d[line] == nil then
        d[line] = true
        end
    end
    return d
end


local scenarios, zencode = all_statements(arg[1])
local zencode_doc = documented(arg[2])
local _, zencode_no_doc = all_statements(arg[3])

io.output("to_be_documented.txt")

for _, scenario in pairs(scenarios) do
    io.write(scenario, "\n")
    for statement, _ in pairs(zencode[scenario]) do
        if (not zencode_doc[statement])
        and (not zencode_no_doc[scenario]
        or not zencode_no_doc[scenario][statement]) then
        io.write("\t", statement, "\n")
        end
    end
end

io.output():close()
