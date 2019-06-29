DATA = [[
{
  "squadName": "Super hero squad",
  "homeTown": "Metro City",
  "formed": 2016,
  "secretBase": "Super tower",
  "active": true,
  "members": [
    {
      "name": "Molecule Man",
      "age": 29,
      "secretIdentity": "Dan Jukes",
      "powers": [
        "Radiation resistance",
        "Turning tiny",
        "Radiation blast"
      ]
    },
    {
      "name": "Madame Uppercut",
      "age": 39,
      "secretIdentity": "Jane Wilson",
      "powers": [
        "Million tonne punch",
        "Damage resistance",
        "Superhuman reflexes"
      ]
    },
    {
      "name": "Eternal Flame",
      "age": 1000000,
      "secretIdentity": "Unknown",
      "powers": [
        "Immortality",
        "Heat Immunity",
        "Inferno",
        "Teleportation",
        "Interdimensional travel"
      ]
    }
  ]
}
]]

print 'import'
-- i = {}
t,i = JSON.decode(DATA)
-- i = t
print("t:"..type(t).." i:"..type(i))

print 'table clone'
-- i = t -- table.deepcopy(t)
print("t:"..type(t).." i:"..type(i))


print 'inspect i'
I.print(i)
print("t:"..type(t).." i:"..type(i))

print 'inspect t'
I.print(t)
print("t:"..type(t).." i:"..type(i))

print 'map i'
m = map(i,base64)
I.print(m)
print("t:"..type(t).." i:"..type(i).." m:"..type(m))

-- test known values
m2 = { homeTown = "b64:TWV0cm8gQ2l0eQ==",
	   secretBase = "b64:U3VwZXIgdG93ZXI=",
	   squadName = "b64:U3VwZXIgaGVybyBzcXVhZA==" }
assert(m.homeTown   == m2.homeTown)
assert(m.secretBase == m2.secretBase)
assert(m.squadName  == m2.squadName)

