local fs = require("@lune/fs")
local process = require("@lune/process")

local filter = require("./filter")
local log = require("./log")

local function print_usage()
	print("Usage: lune run .lune/test.luau [OPTIONS]")
	print("")
	print("Options:")
	print("  --filter <expr>  Run tests matching filter expression")
	print("                     Supports: term, not, and, or, parentheses")
	print("                     Examples:")
	print("                       --filter user")
	print("                       --filter 'auth and login'")
	print("                       --filter 'auth and not slow'")
	print("                       --filter '(auth or admin) and not slow'")
	print("  --focus          Run only test.focus definitions")
	print("  --help           Show this help message")
end

local function parse_args(): { filter: string?, focus: boolean, help: boolean }
	local args = {
		filter = nil,
		focus = false,
		help = false,
	}

	local argv = process.args
	local i = 1
	while i <= #argv do
		local arg = argv[i]
		if arg == "--help" or arg == "-h" then
			args.help = true
			i += 1
		elseif arg == "--focus" then
			args.focus = true
			i += 1
		elseif arg == "--filter" or arg == "-k" then
			local next_arg = argv[i + 1]
			if next_arg == nil or string.sub(next_arg, 1, 1) == "-" then
				log.fatal("--filter requires an argument")
			end
			args.filter = next_arg
			i += 2
		else
			i += 1
		end
	end

	return args
end

local function discover_tests(tests_dir: string): { string }
	local files = {}

	if not fs.isDir(tests_dir) then
		return files
	end

	local entries = fs.readDir(tests_dir)
	for _, entry in ipairs(entries) do
		if string.find(entry, "%.luau$") then
			local full_path = `{tests_dir}/{entry}`
			if fs.isFile(full_path) then
				table.insert(files, entry)
			end
		end
	end

	table.sort(files)
	return files
end

local function load_tests(tests_dir: string)
	local test_files = discover_tests(tests_dir)

	for _, filename in ipairs(test_files) do
		local module_path = `../tests/{string.gsub(filename, "%.luau$", "")}`

		local success, err = pcall(function()
			require(module_path)()
		end)

		if not success then
			log.fatal(`Failed to load test file '{filename}': {err}`)
		end
	end
end

local function apply_filter(filter_expr: filter.FilterExpr)
	local frktest = require("@devpkgs/frktest")
	local test = frktest.test

	local function should_run_test(test_name: string, suite_name: string): boolean
		return filter.matches(filter_expr, test_name, suite_name)
	end

	test.on_exec_begin(function(_)
		local state = _G._modulestate and _G._modulestate.test
		if state == nil then
			return
		end

		for _, t in ipairs(state.global_suite) do
			if not should_run_test(t.name, "") then
				t.skip = true
			end
		end

		for _, suite in ipairs(state.suites) do
			for _, t in ipairs(suite.tests) do
				if not should_run_test(t.name, suite.name) then
					t.skip = true
				end
			end
		end
	end)
end

local function run_tests(focus: boolean)
	local frktest = require("@devpkgs/frktest")
	local reporter = frktest._reporters.lune_console_reporter

	reporter.init()
	return frktest.run()
end

local function main()
	local args = parse_args()

	if args.help then
		print_usage()
		return
	end

	local tests_dir = process.env.PWD .. "/tests"

	load_tests(tests_dir)

	if args.filter ~= nil then
		local filter_expr = filter.parse(args.filter)
		apply_filter(filter_expr)
	end

	local passed = run_tests(args.focus)

	if not passed then
		process.exit(1)
	end
end

main()
