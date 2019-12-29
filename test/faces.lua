-- factorial

local faces = require "faces"
local kb = faces()

kb:defrule"factorial":
  pattern{ "Factorial", "?x", "?y" }:
  pattern{ "Limit", "?z" }:
  u"x < z":
  ENTAILS"=>":
  fassert{ "Factorial", u"x+1", u"y*(x+1)" }

kb:fassert{ "Factorial", 1, 1 }

kb:fassert{ "Limit", 10 }

kb:agenda()
kb:run()
kb:facts()

-- test

local kb = faces()
local pack = table.pack

print( kb:fassert{ "duck" } )
print( kb:fassert{ "duck" } )
print( kb:fassert{ "quack" } )
print( kb:fassert({"a"}, {"b"}, {"c"}) )
print( kb:fassert{ "hunter game", "Brian", "duck" } )
print( kb:fassert{ "duck", nil, n=2 } )
print( kb:fassert( pack("duck2", nil) ) )
print( kb:fassert{ "x", 0.5 } )
print( kb:fassert{ "y", -1 } )

kb:facts()

kb:retract(9)
print( pcall( kb.retract, kb, 9 ) )
kb:retract(4,5,6)

print( kb:fassert{ "animal is", "duck" } )
kb:facts()

kb:fassert{ "my father is", "duck" }

kb:defrule("duck"):
  salience(10):
  pattern{ ".*", "duck" }:
  ENTAILS("=>"):
  fassert{ "sound is", "quack" }

kb:fassert{ "duck sound", { "quack", 2 } }
kb:fassert{ "duck sound", "poww" }

kb:defrule("duck2"):
  salience(100):
  var("?f1"):pattern{ "duck sound", { "?name1", "?name2" } }:
  match("?name1", "q.*"):
  ENTAILS("=>"):
  fassert{ "sound is", { "?name1", "?name2" } }:
  u(function(vars)
      print("DEBUG", kb:consult(vars.f1), vars.name1, vars.name2)
  end)

kb:defrule("init"):
  salience(1000):
  pattern{ "initial fact" }:
  ENTAILS("=>"):
  fassert{ "initialized" }

kb:rules()
kb:agenda()

kb:run(2)
kb:agenda()
kb:facts()

kb:run()
kb:agenda()
kb:facts()

kb:retract("*")
kb:facts()

local id = kb:fassert{ "duck sound", { "quack", 2 } }
kb:agenda()
kb:run()
kb:facts()
kb:retract(id)
kb:fassert{ "duck sound", { "quack", 2 } }
kb:agenda()
kb:run()
kb:facts()

kb:defrule("MultiValuated"):
  pattern{ "duck sound", "$?p" }:
  ENTAILS("=>"):
u(function(vars) print(vars.p) end)

kb:agenda()

kb:run()

-- test 2

kb:retract('*')
kb:fassert{ "duck", 4 }
kb:fassert{ 16 }
kb:fassert{ "AnimalIs", "duck" }

kb:defrule("user"):
   pattern{ "?x", "?y" }:
   pattern{ "?z" }:
   pattern{ "AnimalIs", "?x" }:
   numeric("?y"):
   numeric("?z"):
   u("(z == y*4) and (y%2)==0"):
   ENTAILS("=>"):
   fassert{ "EvenAnimal", "?x", "?y", "?z" }

kb:rules()
kb:agenda()
kb:run()
kb:facts()
