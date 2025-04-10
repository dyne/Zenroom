
uuids = {"550e8400-e29b-41d4-a716-446655440000",
         "f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
         "cdaed56d-8712-414d-b346-01905d0026fe",
         "urn:uuid:550e8400-e29b-41d4-a716-446655440000",
         "urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
         "urn:uuid:cdaed56d-8712-414d-b346-01905d0026fe"}

oct1 = O.from_uuid(uuids[1])
oct2 = O.from_uuid(uuids[2])
oct3 = O.from_uuid(uuids[3])
oct4 = O.from_uuid(uuids[4])
oct5 = O.from_uuid(uuids[5])
oct6 = O.from_uuid(uuids[6])

assert(oct1:uuid()==oct4:uuid() and oct1:uuid()==uuids[1] and oct4:uuid()==uuids[1])
assert(oct2:uuid()==oct5:uuid() and oct2:uuid()==uuids[2] and oct5:uuid()==uuids[2])
assert(oct3:uuid()==oct6:uuid() and oct3:uuid()==uuids[3] and oct6:uuid()==uuids[3])

print("✅ All valid input tests passed!")

success, err = pcall(OCTET.to_uuid, nil)
assert(not success, "Expected error with nil input, but succeeded")
assert(err:find("expected 16 bytes octet"), "Wrong error message for nil input")

oct = O.random(10)
success, err = pcall(OCTET.to_uuid, oct)
assert(not success, "Expected error with 8-byte octet, but succeeded")
assert(err:find("expected 16 bytes octet"), "Wrong error message for invalid length")

print("✅ All invalid input tests passed!")
