local faces = require "faces"
local kb = faces()

kb:defrule"factorial":
  pattern{ "Factorial", "?x", "?y" }:
  pattern{ "Limit", "?z" }:
  u"x < z":
  ENTAILS"=>":
  fassert{ "Factorial", u"x+1", u"y*(x+1)" }

kb:fassert{ "Factorial", 1, 1 }

kb:fassert{ "Limit", 100 }

kb:agenda()
kb:run()
kb:facts()
