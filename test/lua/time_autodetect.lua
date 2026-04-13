require('zencode_data')

local function assert_type(value, expected)
    assert(type(value) == expected, "expected " .. expected .. ", got " .. type(value))
end

local raw_time = 2524608000
local near_time = 2524608256

local time_encoder = input_encoding('time').fun
local string_encoder = input_encoding('string').fun

local explicit_time = time_encoder(raw_time)
assert_type(explicit_time, 'zenroom.time')
assert(tostring(explicit_time) == '2524608000')

CONF.input.number_strict = false
local autodetected_time = string_encoder(raw_time)
assert_type(autodetected_time, 'zenroom.time')
assert(tostring(autodetected_time) == '2524608000')

local second_explicit_time = time_encoder(near_time)
assert_type(second_explicit_time, 'zenroom.time')
assert(tostring(second_explicit_time) == '2524608256')

local second_autodetected_time = string_encoder(near_time)
assert_type(second_autodetected_time, 'zenroom.time')
assert(tostring(second_autodetected_time) == '2524608256')

CONF.input.number_strict = true
local strict_number = string_encoder(raw_time)
assert_type(strict_number, 'zenroom.float')

print('time autodetect regressions OK')
