local io = require('io')

local function match(pattern, file)
	for line in io.lines(file) do
		local _, _, found = line:find(pattern)
		if found then
			return found
		end
	end
end

local pats = {
	{name='Readme', file='README.markdown', pattern='Version:%s*%*([^%*]*)%*'},
	{name='Plugin', file='plugin/systemate.vim', pattern='g:systemate_version%s*=%s*\'([^\']*)\''},
	{name='Addon', file='addon-info.json', pattern='"version":%s*"([^"]*)"'},
	{name='Documentation', file='doc/systemate.txt', pattern='VERSION:%s*(%S*)'},
	{name='Comment', file='plugin/systemate.vim', pattern='VERSION:%s*(%S*)'},
}

local found = {}

for _, pat in ipairs(pats) do
	found[pat.name] = match(pat.pattern, pat.file)
end
