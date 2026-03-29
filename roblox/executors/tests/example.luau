local frktest = require("@devpkgs/frktest")
local test = frktest.test

return function()
	test.suite("a group of tests", function()
		print("this is a suite")
		test.case("a test within a suite", function()
			print("and a test under a group!")
		end)
	end)
end
