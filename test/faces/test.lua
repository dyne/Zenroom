--[[
  This file is part of Lua-FACES (https://github.com/pakozm/lua-faces)

  Copyright 2015, Francisco Zamora-Martinez
  
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
  
  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.
  
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
  IN THE SOFTWARE.
]]

local faces = require "faces"
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
