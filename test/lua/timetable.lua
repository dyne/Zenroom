local TIMETABLE = require('timetable')

local tt = TIMETABLE.from_seconds(60)
assert(TIMETABLE.to_string(tt) == '1970-01-01T00:01:00Z')
assert(TIMETABLE.to_rfc3339(tt) == '1970-01-01T00:01:00.000Z')

local parsed, tz = TIMETABLE.from_string('1970-01-01T00:01:00Z')
assert(parsed ~= nil and tz == 0)
assert(TIMETABLE.to_seconds(parsed) == '60')

local future = TIMETABLE.from_seconds('2524608000')
assert(TIMETABLE.to_string(future) == '2050-01-01T00:00:00Z')
assert(TIMETABLE.to_seconds(future) == '2524608000')
