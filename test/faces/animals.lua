local faces = require "faces"
local kb = faces()

-- Taken from: http://web.missouri.edu/jonassend/courses/mindtool/expert/MAM.KB
-- A simple knowledge base to guide you in the identification of animals
-- Prof A M Starfield
-- University of the Witwatersrand
-- South Africa

local BODY_COVERING = "BodyCovering"
local HAVE_FINS = "HaveFins"
local FISH_HAVE = "FishHave"

local ANIMAL_IS = "AnimalIs"
local HAIR = "Hair"
local SCALES = "Scales"
local FEATHERS = "Feathers"
local OTHER = "Other"
local YES = "YES"
local NO = "NO"
local FIN_RAYS = 'Fin rays'
local GILL_SLITS = 'Gill slits'

local d1 = { ANIMAL_IS, "MAMMAL" }
local d2 = { ANIMAL_IS, "BIRD" }
local d3 = { ANIMAL_IS, "FISH" }
local d4 = { ANIMAL_IS, "REPTILE" }
local d5 = { ANIMAL_IS, "AMPHIBIAN" }
local d6 = { ANIMAL_IS, "BONY FISH" }
local d7 = { ANIMAL_IS, "CARTILAGENOUS FISH" }

-------------- USER INTERACTION SECTION -----------------

local function ask(msg, tbl, screen)
  screen = screen or {}
  print(msg)
  for i=1,#tbl do print(string.format("%d. %s", i, screen[i] or tbl[i])) end
  local n
  repeat io.write("Input: ") n = tonumber(io.read("*l")) until n and tbl[n]
  return tbl[n]
end

local function question1()
  -- Reptiles & Fish are scaly, birds feathery, mammals hairy
  local ans = ask("Is the main body covering:",
                  { HAIR, SCALES, FEATHERS, OTHER })
  kb:fassert{ BODY_COVERING, ans }
end

local function question2()
  -- It might be a fish and have fins
  local ans = ask("Does the animal have fins?:", { YES, NO })
  kb:fassert{ HAVE_FINS, ans }
end

local function question3()
  -- Bony fishes have fin rays, others have gill slits
  local ans = ask("Does the fish have", { FIN_RAYS, GILL_SLITS },
                  { 'Fin rays (bones in fins) and gill covers',
                    'External gill slits' })
  kb:fassert{ FISH_HAVE, ans }
end

---------------------------------------------------------

-- Error fact
kb:fassert{ "ERROR" }

-- Error rule
kb:defrule("Error"):
  salience(-100):
  pattern{ "ERROR" }:
  ENTAILS("=>"):
  u(function()
      print("Unable to classify the animal")
  end)

-- Retracts error rule in case any classification is asserted
kb:defrule("RetractError"):
  salience(100):
  var("?f1"):pattern{ "ERROR" }:
  pattern{ ANIMAL_IS, ".*" }:
  ENTAILS("=>"):
  retract(u("f1"))

-- Initial rule, asks the first question
kb:defrule("initial"):
  pattern{ "initial fact" }:
  ENTAILS("=>"):
  u(question1)

-- Control rule, asks question 2 in case it is necessary
kb:defrule("Control"):
  pattern{ BODY_COVERING, SCALES }:
  ENTAILS("=>"):
  u(question2)

-- If it has hair it is a mammal
kb:defrule("Rule1"):
  pattern{ BODY_COVERING, HAIR }:
  ENTAILS("=>"):
  fassert(d1)

-- If it has feathers then it is a bird
kb:defrule("Rule2"):
  pattern{ BODY_COVERING, FEATHERS }:
  ENTAILS("=>"):
  fassert(d2)

-- If it has smooth hairless sacleless skin it is amphibian
kb:defrule("Rule3"):
  pattern{ BODY_COVERING, OTHER }:
  ENTAILS("=>"):
  fassert(d5)

-- If it has scales & fins it is a fish, and asks question 3
kb:defrule("Rule4"):
  pattern{ BODY_COVERING, SCALES }:
  pattern{ HAVE_FINS, YES }:
  ENTAILS("=>"):
  fassert(d3):
  u(question3)

-- If it has scales but no fins it is a reptile
kb:defrule("Rule5"):
  pattern{ BODY_COVERING, SCALES }:
  pattern{ HAVE_FINS, NO }:
  ENTAILS("=>"):
  fassert(d4)

--
kb:defrule("Rule6"):
  pattern(d3):
  pattern{ FISH_HAVE, FIN_RAYS }:
  ENTAILS("=>"):
  fassert(d6)

--
kb:defrule("Rule7"):
  pattern(d3):
  pattern{ FISH_HAVE, GILL_SLITS }:
  ENTAILS("=>"):
  fassert(d7)

-- show rule
kb:defrule("Show"):
  salience(-10):
  pattern{ ANIMAL_IS, "?x" }:
  ENTAILS("=>"):
  u(function(vars)
      print("The animal is a: " .. vars.x)
  end)

----------------------------------------------------------------------

kb:run()
