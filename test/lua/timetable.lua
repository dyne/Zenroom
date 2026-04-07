local TIMETABLE = require('timetable')

local tt = TIMETABLE.from_seconds(60)
assert(TIMETABLE.to_string(tt) == '1970-01-01T00:01:00Z')
assert(TIMETABLE.to_rfc3339(tt) == '1970-01-01T00:01:00.000Z')

local parsed, tz = TIMETABLE.from_string('1970-01-01T00:01:00Z')
assert(parsed ~= nil and tz == 0)
assert(TIMETABLE.to_seconds(parsed) == 60)
