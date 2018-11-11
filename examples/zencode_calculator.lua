-- Zencode test

verbosity = 1
numbers = {}

function enter (number)
   table.insert(numbers, tonumber(number))
end

function add ()
   result = 0
   for i = 1, #numbers do
      result = result + numbers[i]
   end
end

-- steps

Given("I have entered '' [^and]", function (number)
         enter(number)
end)

Given("I have entered '' and ''", function (num1, num2)
         enter(num1)
         enter(num2)
end)

When("I press add", function ()
		add()
end)

Then("result should be ''", function (number)
		assert(result == tonumber(number),
			   "Result was expected to be " .. number .. ", but was " .. result)
		print("Result is ".. result)
end)


-- execution
ZEN:begin(verbosity)


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
