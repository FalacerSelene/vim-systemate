#! /usr/bin/env lua

local M = {}

function M.parser ()
	local self = {tokens = {}}

	local T = {name = 0, ref = 1, value = 2}

	-- Lex a single line (everything is line based)
	function self.feed (self, line)
		if line:match('^ *#.*$') or line:match('^ *$') then
			-- Comment line
			return
		else
			local found
			local function m (pat)
				found = line:match(pat)
				return found
			end

			if m('^%[([a-zA-Z0-9_]*)%].*$') then
				self.tokens[#self.tokens+1] = { t = T.name, v = found }
			elseif m('^%.%[([a-zA-Z0-9_]*)%].*$') then
				self.tokens[#self.tokens+1] = { t = T.ref, v = found }
			elseif m('^[ \t]*([a-zA-Z0-9_]*)[ \t]*$') then
				self.tokens[#self.tokens+1] = { t = T.value, v = found }
			else
				error('Unlexable suitefile line:\n\t' .. line)
			end
		end

	end

	-- Now we've got all the tokens, parse it.
	function self.parse (self)
		local raw = {}
		local refs = {}
		local names = {}
		local cur = nil

		-- assign refs and names to suites
		for i, t in ipairs(self.tokens) do
			if i == 1 and t.t ~= T.name then
				error('Definition outside of suite: ' .. t.v)
			end

			if t.t == T.name then
				cur = t.v
				names[#names+1] = t.v
				if raw[cur] then
					error('Multiple definition of suite: ' .. cur)
				else
					raw[cur] = {}
				end
			elseif t.t == T.ref then
				local l = #raw[cur]
				raw[cur][l+1] = t
				refs[#refs+1] = t.v
			elseif t.t == T.value then
				local l = #raw[cur]
				raw[cur][l+1] = t
			end
		end

		-- check all refs exist
		for _, r in ipairs(refs) do
			if not raw[r] then
				error('Undefined suiteref in use: ' .. r)
			end
		end

		-- resolve refs
		local ret = {}

		local function fromraw (name)
			local r = raw[name]
			local s = {}
			for _, v in ipairs(r) do
				if v.t == T.value then
					s[#s+1] = v.v
				else
					-- recursive
					for _, v2 in ipairs(fromraw(v.v)) do
						s[#s+1] = v2
					end
				end
			end

			return s
		end

		for _, n in ipairs(names) do
			ret[n] = fromraw(n)
		end

		return ret
	end

	return self
end

function M.parse (lines)
	local p = M.parser()
	for _, l in ipairs(lines) do
		p:feed(l)
	end
	return p:parse()
end

function M.parsefile (filename)
	local p = M.parser()
	for l in io.lines(filename) do
		p:feed(l)
	end
	return p:parse()
end

return M
