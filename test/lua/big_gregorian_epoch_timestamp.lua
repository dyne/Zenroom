-- test from isse #1075 (https://github.com/dyne/Zenroom/issues/1075)

-- example of computing the number of seconds since 1582-10-15 (Gregorian epoch timestamp)
local fixed_actual_timestamp = BIG.new(1748958809) -- BIG.new(os.time(os.date("!*t")))
local days = BIG.new(141427) -- 1582-10-15 to 1970-01-01
local seconds_per_day = BIG.new(86400) -- 24 * 60 * 60
local gregorian_epoch_timestamp = days * seconds_per_day + fixed_actual_timestamp

local correct_result = BIG.new('13968251609')
assert(gregorian_epoch_timestamp == correct_result, "Gregorian epoch timestamp calculation is incorrect "..
    "Expected: " .. tostring(correct_result) .. ", got: " .. tostring(gregorian_epoch_timestamp))
