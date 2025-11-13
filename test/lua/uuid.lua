
local valid_uuids = {
    "550e8400-e29b-41d4-a716-446655440000",
    "f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
    "cdaed56d-8712-414d-b346-01905d0026fe",
    "urn:uuid:550e8400-e29b-41d4-a716-446655440000",
    "urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
    "urn:uuid:cdaed56d-8712-414d-b346-01905d0026fe"
}

local oct1 = O.from_uuid(valid_uuids[1])
local oct2 = O.from_uuid(valid_uuids[2])
local oct3 = O.from_uuid(valid_uuids[3])
local oct4 = O.from_uuid(valid_uuids[4])
local oct5 = O.from_uuid(valid_uuids[5])
local oct6 = O.from_uuid(valid_uuids[6])

assert(oct1:uuid()==oct4:uuid() and oct1:uuid()==valid_uuids[1] and oct4:uuid()==valid_uuids[1])
assert(oct2:uuid()==oct5:uuid() and oct2:uuid()==valid_uuids[2] and oct5:uuid()==valid_uuids[2])
assert(oct3:uuid()==oct6:uuid() and oct3:uuid()==valid_uuids[3] and oct6:uuid()==valid_uuids[3])

print("✅ All valid input tests passed!")

local invalid_uuids = {
    "xy0e8400-e29b-41d4-a716-446655440000",
    "definetly-not-a-uuid",
    "bau:miao:550e8400-e29b-41d4-a716-446655440000",
}

local success, err = pcall(OCTET.from_uuid, invalid_uuids[1])
assert(not success, "Expected error with nil input, but succeeded")
assert(err:find("Invalid hex sequence in uuid"), "Wrong error message for invalid hex input")

local success, err = pcall(OCTET.from_uuid, invalid_uuids[2])
assert(not success, "Expected error with nil input, but succeeded")
assert(err:find("Invalid uuid argument length"), "Wrong error message for invalid length")

local success, err = pcall(OCTET.from_uuid, invalid_uuids[3])
assert(not success, "Expected error with nil input, but succeeded")
assert(err:find("Invalid uuid argument length"), "Wrong error message for invalid length with wrong prefix")

local success, err = pcall(OCTET.to_uuid, nil)
assert(not success, "Expected error with 8-byte octet, but succeeded")
assert(err:find("Invalid argument, 16 bytes octet expected"), "Wrong error message for invalid length")

local oct = O.random(10)
local success, err = pcall(OCTET.to_uuid, oct)
assert(not success, "Expected error with 8-byte octet, but succeeded")
assert(err:find("Invalid argument, 16 bytes octet expected"), "Wrong error message for invalid length")

print("✅ All invalid input tests passed!")
