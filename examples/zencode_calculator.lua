-- Zencode test

Calculator = { numbers = {} }

function Calculator:Reset ()
   self.numbers = {}
end

function Calculator:Enter (number)
   table.insert(self.numbers, tonumber(number))
end

function Calculator:Add ()
   self.result = 0
   for i = 1, #self.numbers do
      self.result = self.result + self.numbers[i]
   end
end

-- steps

Before(function()
	  Calculator:Reset()
end)

Given("I have entered '(%w+)' [^and]", function (number)
         Calculator:Enter(number)
end)

Given("I have entered '(%w+)' and '(%w+)'", function (num1, num2)
         Calculator:Enter(num1)
         Calculator:Enter(num2)
end)

When("I press add", function ()
		Calculator:Add()
end)

Then("result should be '(%w+)'", function (number)
		assert(Calculator.result == tonumber(number),
			   "Result was expected to be " .. number .. ", but was " .. Calculator.result)
		print("Result is ".. Calculator.result)
end)


-- execution
print "=== Zencode begin"
ZEN:begin()


addition = [[
Feature: Addition
  In order to avoid silly mistakes
  As a math idiot
  I want to be told the sum of two numbers

  Scenario Outline: Add two numbers
    Given I have entered '1' into the calculator
    And I have entered '2' into the calculator
    And I have entered '3' and '4'
    When I press add
    Then the result should be '10' on the screen
]]


ZEN:parse(addition)
-- content(ZEN.matches[3])
ZEN:run()
