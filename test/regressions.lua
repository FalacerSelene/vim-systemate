#! /usr/bin/env lua

--[========================================================================]--
--[ Colours {{{                                                            ]--
--[                                                                        ]--
--[ ANSI terminal colours for pretty output.                               ]--
--[========================================================================]--

local escape = string.char(27)
local ansi_red   = escape .. '[31m' .. escape .. '[1m'
local ansi_green = escape .. '[32m' .. escape .. '[1m'
local ansi_blue  = escape .. '[34m' .. escape .. '[1m'
local ansi_end   = escape .. '[m'

local function remove_colours ()
	ansi_red = ''
	ansi_green = ''
	ansi_blue = ''
	ansi_end = ''
end

--[========================================================================]--
--[ }}}                                                                    ]--
--[========================================================================]--

--[========================================================================]--
--[ Modules {{{                                                            ]--
--[                                                                        ]--
--[ I use LFS later on to check that tests and directories exist before    ]--
--[ trying to run/open them. However, I can still shell out instead, so    ]--
--[ LFS isn't mandatory.                                                   ]--
--[========================================================================]--
local function req (modname)
	local mod = nil
	pcall(function () mod = require(modname) end)
	return mod
end

local lfs = req('lfs')

if not lfs then
	print('Warning - running without lfs.')
	print('Will fall back to shell.')
	print('Tests may be slightly slower.')
end
--[========================================================================]--
--[ }}}                                                                    ]--
--[========================================================================]--

--[========================================================================]--
--[ isdir (dirname) {{{                                                    ]--
--[                                                                        ]--
--[ Description:                                                           ]--
--[   Does the specified directory exist, and is it a directory?           ]--
--[                                                                        ]--
--[ Params:                                                                ]--
--[   1) dirname - dir to check                                            ]--
--[                                                                        ]--
--[ Returns:                                                               ]--
--[   1) true/false                                                        ]--
--[========================================================================]--

local function isdir (dirname)
	local isdir = false
	local diratts

	if lfs then
		diratts = lfs.attributes(dirname)
		isdir = diratts and diratts.mode == 'directory'
	elseif os.execute('[ -d "' .. dirname .. '" ]') then
		isdir = true
	end

	return isdir
end

--[========================================================================]--
--[ }}}                                                                    ]--
--[========================================================================]--

--[========================================================================]--
--[ isfile (filename) {{{                                                  ]--
--[                                                                        ]--
--[ Description:                                                           ]--
--[   Does the specified file exist, and is it a normal file?              ]--
--[                                                                        ]--
--[ Params:                                                                ]--
--[   1) filename - file to check                                          ]--
--[                                                                        ]--
--[ Returns:                                                               ]--
--[   1) true/false                                                        ]--
--[========================================================================]--

local function isfile (filename)
	local isfile = false
	local fileatts

	if lfs then
		fileatts = lfs.attributes(filename)
		isfile = fileatts and fileatts.mode == 'file'
	elseif os.execute('[ -f "' .. filename .. '" ]') then
		isfile = true
	end

	return isfile
end

--[========================================================================]--
--[ }}}                                                                    ]--
--[========================================================================]--

--[========================================================================]--
--[ parseargs (args) {{{                                                   ]--
--[========================================================================]--
local function parseargs (args)
	local parsed = {}

	local function addarg (name, elem, uniq)
		if parsed[name] == nil then
			if uniq then
				parsed[name] = elem
			else
				parsed[name] = {elem}
			end
		else
			if uniq then
				error("Multiple instances of unique argument --" .. name)
			else
				local l = parsed[name]
				l[#l+1] = elem
			end
		end
	end

	local STATE_NORM    = 0
	local STATE_SUITE   = 1
	local STATE_TESTDIR = 2
	local STATE_VIMRC   = 3
	local STATE_SUITES  = 4
	local STATE_VIMBIN  = 5
	local state         = STATE_NORM

	local lastarg = nil

	for _, arg in ipairs(args) do
		lastarg = arg
		if     state == STATE_NORM    then
			if     arg == '-s' or arg == '--suite'     then
				state = STATE_SUITE
			elseif arg == '-d' or arg == '--testdir'   then
				state = STATE_TESTDIR
			elseif arg == '-v' or arg == '--vimrc'     then
				state = STATE_VIMRC
			elseif arg == '-f' or arg == '--suitefile' then
				state = STATE_SUITES
			elseif arg == '-b' or arg == '--vimbinary' then
				state = STATE_VIMBIN
			elseif arg == '-c' or arg == '--colours'   then
				addarg('use_colours', true, true)
			else
				addarg('tests', arg)
			end
		elseif state == STATE_SUITE   then
			addarg('suites', arg)
			state = STATE_NORM
		elseif state == STATE_TESTDIR then
			addarg('testdir', arg, true)
			state = STATE_NORM
		elseif state == STATE_VIMRC   then
			addarg('vimrc', arg, true)
			state = STATE_NORM
		elseif state == STATE_SUITES  then
			addarg('suitefile', arg, true)
			state = STATE_NORM
		elseif state == STATE_VIMBIN  then
			addarg('vimbin', arg, true)
			state = STATE_NORM
		else
			error("Programming error in parseargs()")
		end
	end

	if state ~= STATE_NORM then
		error("Missing mandatory argument to arg: " .. lastarg)
	elseif not parsed.testdir then
		error("Missing mandatory arg --testdir")
	elseif parsed.suites and not parsed.suitefile then
		error("Option --suites requires a --suitefile")
	end

	if not parsed.suites then
		parsed.suites = {}
	end

	if not parsed.tests then
		parsed.tests = {}
	end

	return parsed
end
--[========================================================================]--
--[ }}}                                                                    ]--
--[========================================================================]--

--[========================================================================]--
--[ assertfilesexist (args) {{{                                            ]--
--[                                                                        ]--
--[ Description:                                                           ]--
--[   Assert that the files given by command line argements exist.         ]--
--[                                                                        ]--
--[ Params:                                                                ]--
--[   1) args - The command line arguments.                                ]--
--[                                                                        ]--
--[ Returns:                                                               ]--
--[   1) The same arguments as passed in. Errors if any of the required    ]--
--[      files do not exist.                                               ]--
--[========================================================================]--
local function assertfilesexist (args)
	if not isdir(args.testdir) then
		error("Could not find directory: " .. args.testdir)
	elseif args.vimrc and
	       not isfile(args.vimrc) then
		error("Could not find file: " .. args.vimrc)
	elseif args.suitefile and
	       not isfile(args.suitefile) then
		error("Could not find file: " .. args.suitefile)
	end
	return(args)
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
	local args = assertfilesexist(parseargs(args))

	if not args.use_colours then
		remove_colours()
	end

	local successcount = 0
	local failurecount = 0
	local failures = {}
	local notfoundcount = 0
	local notfound = {}
	local _, test
	for _, test in ipairs(testlistfromargs(args)) do
		if not isfile(args.testdir .. "/scripts/" .. test .. ".vim") then
			print(test .. "... " .. ansi_red .. "NOTFOUND" .. ansi_end)
			notfoundcount = notfoundcount + 1
			notfound[#notfound+1] = test
		else
			local passed = runsingletest(test, args)
			if passed then
				print(test .. "... " .. ansi_green .. "PASSED" .. ansi_end)
				successcount = successcount + 1
			else
				print(test .. "... " .. ansi_red .. "FAILED" .. ansi_end)
				failurecount = failurecount + 1
				failures[#failures+1] = test
			end
		end
	end

	print(ansi_blue .. "TOTAL" .. ansi_end .. ":\t" .. (successcount + failurecount))
	print(ansi_blue .. "SUCCESSES" .. ansi_end .. ":\t" .. successcount)

	if failurecount == 0 then
		print(ansi_green .. "FAILURES:" .. ansi_end .. "\t" .. failurecount)
	else
		print(ansi_red .. "FAILURES:" .. ansi_end .. "\t" .. failurecount)
	end

	if notfoundcount > 0 then
		print(ansi_red .. "NOTFOUND" .. ansi_end .. ":\t" .. notfoundcount)
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
