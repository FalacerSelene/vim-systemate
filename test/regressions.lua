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
local suites = require('suite')
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
--[ runsingletest (name, args) {{{                                         ]--
--[========================================================================]--
local function runsingletest (name, args)
	local vimbin = args.vimbin or 'vim'
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
		local cmd = string.format('diff %s %s > %s 2>/dev/null',
		                          outfilename, mstfilename, diffilename)
		passed = os.execute(cmd) == 0
	else
		passed = false
	end

	if passed then
		os.execute(string.format("rm -rf '%s' &>/dev/null", diffilename))
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
			suiteresolver = suites.parsefile(args.suitefile)
		end
		for _, test in ipairs(suiteresolver[suite]) do
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
