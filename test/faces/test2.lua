local faces = require "faces"
local kb = faces()

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
