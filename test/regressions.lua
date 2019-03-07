#! /usr/bin/env lua

--[========================================================================]--
--[ Colours {{{                                                            ]--
--[========================================================================]--

local ansi = {}
setmetatable(ansi, {__index = function() return '' end})

local function usecolours()
	local e = string.char(27)
	ansi.red    = e .. '[31m' .. e .. '[1m'
	ansi.green  = e .. '[32m' .. e .. '[1m'
	ansi.yellow = e .. '[33m' .. e .. '[1m'
	ansi.blue   = e .. '[34m' .. e .. '[1m'
	ansi.stop   = e .. '[m'
end

--[========================================================================]--
--[ }}}                                                                    ]--
--[========================================================================]--

--[========================================================================]--
--[ Modules {{{                                                            ]--
--[========================================================================]--
local argparse = require('argparse')
local lfs = nil
pcall(function () lfs = require('lfs') end)

if not lfs then
	print('Warning - running without lfs.')
	print('Will fall back to shell.')
	print('Tests may be slightly slower.')
end
--[========================================================================]--
--[ }}}                                                                    ]--
--[========================================================================]--

--[========================================================================]--
--[ isdir/isfile (name) {{{                                                ]--
--[                                                                        ]--
--[ Description:                                                           ]--
--[   Does the specified dir/file exist, and is it a dir/file?             ]--
--[                                                                        ]--
--[ Params:                                                                ]--
--[   1) name - dir/file to check                                          ]--
--[                                                                        ]--
--[ Returns:                                                               ]--
--[   1) true/false                                                        ]--
--[========================================================================]--

local function lfsmode (name, mode)
	local atts = lfs.attributes(name)
	return atts and atts.mode == mode
end

local function isdir (dirname)
	if lfs then
		return lfsmode(dirname, 'directory')
	else
		return os.execute('test -d "' .. dirname .. '"') == 0
	end
end

local function isfile (filename)
	if lfs then
		return lfsmode(filename, 'file')
	else
		return os.execute('test -f "' .. filename .. '"') == 0
	end
end

--[========================================================================]--
--[ }}}                                                                    ]--
--[========================================================================]--

--[========================================================================]--
--[ parseargs (args) {{{                                                   ]--
--[========================================================================]--
local function parseargs (args)
	local parser = argparse('regressions.lua', 'Regression test runner')

	parser:flag('-c --colours', 'Should colours be used on output?'):action(usecolours)
	parser:option('-s --suite', 'Whole suites to run'):count('*'):target('suites')
	parser:option('-d --testdir', 'Test base directory')
	parser:option('-v --vimrc', 'Vimrc file to use')
	parser:option('-f --suitefile', 'Suite definition file')
	parser:option('-b --vimbinary', 'Binary to use for testing'):target('vimbin')
	parser:argument('tests', 'Individual tests to run'):args('*')

	local parsed = parser:parse(args)

	-- And now do some validity checking.
	if not parsed.testdir then
		error("Missing mandatory arg --testdir")
	elseif (#parsed.suites ~= 0) and not parsed.suitefile then
		error("Option --suites requires a --suitefile")
	elseif not isdir(parsed.testdir) then
		error("Could not find directory: " .. parsed.testdir)
	elseif parsed.vimrc and not isfile(parsed.vimrc) then
		error("Could not find file: " .. parsed.vimrc)
	elseif parsed.suitefile and not isfile(parsed.suitefile) then
		error("Could not find file: " .. parsed.suitefile)
	end

	return parsed
end
--[========================================================================]--
--[ }}}                                                                    ]--
--[========================================================================]--

--[========================================================================]--
--[ getsuiteresolver (filename) {{{                                        ]--
--[========================================================================]--
local function getsuiteresolver (filename)
	local TYPE_TEST = 0
	local TYPE_SUITE = 1

	-- extendtable (first, second) {{{
	-- Utility function to extend a table
	local function extendtable (first, second)
		local e
		for _,e in ipairs(second) do
			first[#first+1] = e
		end
	end -- }}}

	-- resolvesuites (unresolved) -- {{{
	local function resolvesuites (unresolved)
		resolved = {}
		local resolving, entries
		for resolving, entries in pairs(unresolved) do

			-- Recursively reduce a suite down to a list of tests.
			local function resolvesinglesuite(suitename)
				if suitename == resolving then
					error("Circular reference to suite: " .. suitename)
				elseif resolved[suitename] then
					return resolved[suitename]
				elseif not unresolved[suitename] then
					error("Reference to undefined suite: " .. suitename)
				end

				local single = {}
				local _, entry
				for _, entry in ipairs(unresolved[suitename]) do
					if entry.type == TYPE_TEST then
						single[#single+1] = entry.name
					elseif entry.type == TYPE_SUITE then
						extendtable(single, resolvesinglesuite(entry.name))
					end
				end
				return single
			end

			resolved[resolving] = {}
			local t = resolved[resolving]
			local _, entry
			for _,entry in ipairs(entries) do
				if entry.type == TYPE_TEST then
					t[#t+1] = entry.name
				elseif entry.type == TYPE_SUITE then
					extendtable(t, resolvesinglesuite(entry.name))
				end
			end
		end
		return resolved
	end -- }}}

	-- readlines (filename) {{{
	local function readlines(filename)
		local read = {}
		local current, line
		for line in io.lines(filename) do
			if not string.match(line, "^[ \t]*#") and
		      not string.match(line, "^[ \t]*$") then
				local newsuite = line:match('^%[([a-zA-Z0-9_]*)%].*$')
				local suiteref = line:match('^%.%[([a-zA-Z0-9_]*)%].*$')
				local testname = line:match('^[ \t]*([a-zA-Z0-9_]*)[ \t]*$')
				if not (newsuite or suiteref or testname) then
					error("Invalid line in file " .. filename .. ":\n" ..
				         "  " .. line)
				elseif not (newsuite or current) then
					error("Definition outside of suite in line:\n" ..
				         "  " .. line)
				elseif newsuite then
					if read[newsuite] then
						error("Multiple definitions of suite " .. newsuite)
					else
						read[newsuite] = {}
						current = newsuite
					end
				elseif suiteref then
					local s = read[current]
					s[#s+1] = {
						["type"] = TYPE_SUITE,
						["name"] = suiteref,
					}
				elseif testname then
					local s = read[current]
					s[#s+1] = {
						["type"] = TYPE_TEST,
						["name"] = testname,
					}
				else
					error("Unreadable line at line:\n" ..
				         "  " .. line)
				end
			end
		end
		return read
	end -- }}}

	-- produceaccessor (filetable) {{{
	local function produceaccessor (filetable)
		return function (suitename)
			return filetable[suitename] or error("No such suite: " .. suitename)
		end
	end -- }}}

	return produceaccessor(resolvesuites(readlines(filename)))
end
--[========================================================================]--
--[ }}}                                                                    ]--
--[========================================================================]--

--[========================================================================]--
--[ runsingletest (name, args) {{{                                         ]--
--[========================================================================]--
local function runsingletest (name, args)
	local vimbin
	if args.vimbin then
		vimbin = args.vimbin
	else
		vimbin = "vim"
	end

	local vimcmd = vimbin .. " -E -n -N"
	if args.vimrc then
		local curdir = os.getenv("PWD")
		vimcmd = vimcmd .. " -u '" .. curdir .. '/' .. args.vimrc .. "'"
	end

	vimcmd = vimcmd .. ' -c "silent source scripts/' .. name .. '.vim"'

	os.execute("( cd " .. args.testdir .. " && " .. vimcmd .. " )")

	local mstfilename = args.testdir .. "/output/" .. name .. ".mst"
	local outfilename = args.testdir .. "/output/" .. name .. ".out"
	local diffilename = args.testdir .. "/output/" .. name .. ".diff"

	local passed
	if isfile(mstfilename) and isfile(outfilename) then
		passed = os.execute("diff " .. outfilename .. " " .. mstfilename ..
		                    " >" .. diffilename .. " 2>/dev/null")
	else
		passed = false
	end

	if passed == true or passed == 0 then
		passed = true
	else
		passed = false
	end

	if passed then
		os.execute("rm -rf '" .. diffilename .. "' &>/dev/null")
	end

	return passed
end
--[========================================================================]--
--[ }}}                                                                    ]--
--[========================================================================]--

--[========================================================================]--
--[ testlistfromargs (args) {{{                                            ]--
--[                                                                        ]--
--[ Description:                                                           ]--
--[   Create a list of tests to run from the command line arguments passed ]--
--[   in. This involves parsing the suite file and resolving any families  ]--
--[   given recursively.                                                   ]--
--[                                                                        ]--
--[ Params:                                                                ]--
--[   1) args - command line args.                                         ]--
--[                                                                        ]--
--[ Returns:                                                               ]--
--[   1) A list of test file names.                                        ]--
--[========================================================================]--
local function testlistfromargs (args)
	local testlist = {}
	local testset = {}
	local _, test, suite, suiteresolver
	for _, test in ipairs(args.tests) do
		if not testset[test] then
			testset[test] = true
			testlist[#testlist+1] = test
		end
	end
	for _, suite in ipairs(args.suites) do
		if not suiteresolver then
			suiteresolver = getsuiteresolver(args.suitefile)
		end
		for _, test in ipairs(suiteresolver(suite)) do
			if not testset[test] then
				testset[test] = true
				testlist[#testlist+1] = test
			end
		end
	end
	return testlist
end
--[========================================================================]--
--[ }}}                                                                    ]--
--[========================================================================]--

--[========================================================================]--
--[ main (args) {{{                                                        ]--
--[========================================================================]--
local function main (args)
	local args = parseargs(args)

	print(ansi.yellow .. '===== START OF TESTS =====' .. ansi.stop)

	local successcount = 0
	local failurecount = 0
	local failures = {}
	local notfoundcount = 0
	local notfound = {}
	local _, test
	for _, test in ipairs(testlistfromargs(args)) do
		if not isfile(args.testdir .. "/scripts/" .. test .. ".vim") then
			print(test .. "... " .. ansi.red .. "NOTFOUND" .. ansi.stop)
			notfoundcount = notfoundcount + 1
			notfound[#notfound+1] = test
		else
			local passed = runsingletest(test, args)
			if passed then
				print(test .. "... " .. ansi.green .. "PASSED" .. ansi.stop)
				successcount = successcount + 1
			else
				print(test .. "... " .. ansi.red .. "FAILED" .. ansi.stop)
				failurecount = failurecount + 1
				failures[#failures+1] = test
			end
		end
	end

	print(ansi.yellow .. '===== END OF TESTS =====' .. ansi.stop)

	print(ansi.blue .. "TOTAL" .. ansi.stop .. ":\t" .. (successcount + failurecount))
	print(ansi.blue .. "SUCCESSES" .. ansi.stop .. ":\t" .. successcount)

	if failurecount == 0 then
		print(ansi.green .. "FAILURES" .. ansi.stop .. ":\t" .. failurecount)
	else
		print(ansi.red .. "FAILURES" .. ansi.stop .. ":\t" .. failurecount)
	end

	if notfoundcount > 0 then
		print(ansi.red .. "NOTFOUND" .. ansi.stop .. ":\t" .. notfoundcount)
	end

	if failurecount == 0 and notfoundcount == 0 then
		return 0
	else
		return 1
	end
end
--[========================================================================]--
--[ }}}                                                                    ]--
--[========================================================================]--

local success, rc = pcall(main, arg)
if success then
	os.exit(rc)
else
	print(rc)
	os.exit(1)
end
