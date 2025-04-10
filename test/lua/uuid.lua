
uuids = {"550e8400-e29b-41d4-a716-446655440000",
         "f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
         "cdaed56d-8712-414d-b346-01905d0026fe"}

for _,v in ipairs(uuids) do
    oct = O.from_uuid(v)
    assert(oct:uuid()==v)
end
print("✅ All valid input tests passed!")

success, err = pcall(OCTET.to_uuid, nil)
assert(not success, "Expected error with nil input, but succeeded")
assert(err:find("expected 16 bytes octet"), "Wrong error message for nil input")

oct = O.random(10)
success, err = pcall(OCTET.to_uuid, oct)
assert(not success, "Expected error with 8-byte octet, but succeeded")
assert(err:find("expected 16 bytes octet"), "Wrong error message for invalid length")

print("✅ All invalid input tests passed!")
