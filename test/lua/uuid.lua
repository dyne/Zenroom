
uuids = {"550e8400-e29b-41d4-a716-446655440000",
         "f81d4fae-7dec-11d0-a765-00a0c91e6bf6"}
for _,v in ipairs(uuids) do
    I.print(v.." "..#v)
    I.print(O.from_uuid(v))
    I.print(v.." "..#v)
    I.print(O.from_uuid(v):base64())
end
