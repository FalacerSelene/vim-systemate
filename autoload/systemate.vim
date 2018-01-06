"|===========================================================================|
"|                                                                           |
"|         FILE:  autoload/systemate.vim                                     |
"|                                                                           |
"|  DESCRIPTION:  Primary autoload functions for plugin.                     |
"|                See plugin/systemate.vim for more details.                 |
"|                                                                           |
"|===========================================================================|

"|===========================================================================|
"|                            SCRIPT CONSTANTS                               |
"|===========================================================================|
let s:ft_saved = {}

"|===========================================================================|
"|                            PUBLIC FUNCTIONS                               |
"|===========================================================================|

"|===========================================================================|
"| systemate#SystemateCommand(style) {{{                                     |
"|===========================================================================|
function! systemate#SystemateCommand(style) abort
	if a:style != ''
		call systemate#Toggle(&l:filetype, a:style)
	elseif get(b:, 'systemate_style', {}) != {}
		call systemate#Toggle(&l:filetype, 'DEFAULT')
	else
		call systemate#Toggle(&l:filetype, <SID>GetDefaultStyle())
	endif
endfunction
"|===========================================================================|
"| }}}                                                                       |
"|===========================================================================|

"|===========================================================================|
"| systemate#Toggle(filetype, style) {{{                                     |
"|===========================================================================|
function! systemate#Toggle(filetype, style) abort
	let l:new_style = systemate#ApplyForFiletype(a:filetype, a:style)
	if l:new_style ==# ''
		echo 'Systemate Unset'
	else
		echo 'Systemate Set:' l:new_style
	endif
endfunction
"|===========================================================================|
"| }}}                                                                       |
"|===========================================================================|

"|===========================================================================|
"| systemate#ApplyForFiletype(filetype, style) {{{                           |
"|                                                                           |
"| RETURNS:                                                                  |
"|   '' when systemate is now off, the name of the style when it's just been |
"|   set.                                                                    |
"|===========================================================================|
function! systemate#ApplyForFiletype(filetype, style) abort
	let l:default = a:style ==# 'DEFAULT'
	let l:cur_style = get(b:, 'systemate_style', {})
	let l:cur_style_name = get(l:cur_style, "name", '')
	let l:cur_on = l:cur_style != {}

	if l:default && !l:cur_on
		"|------------------------------------------------
		"| Already DEFAULT, set to DEFAULT. NOOP.
		"|------------------------------------------------
		return ''
	elseif !l:default && l:cur_on && l:cur_style_name ==# a:style
		"|------------------------------------------------
		"| Already set, set to same thing. NOOP.
		"|------------------------------------------------
		return a:style
	elseif l:default
		"|------------------------------------------------
		"| Already set, return to DEFAULT
		"|------------------------------------------------
		unlet b:systemate_style

		for [l:item, l:value] in items(l:cur_style["revert"])
			call <SID>SetValue(l:item, l:value)
		endfor

		return ''
	elseif !l:cur_on
		"|------------------------------------------------
		"| Already DEFAULT, set to something else
		"|------------------------------------------------
		let l:toapply = <SID>SettingsForFiletype(a:filetype, a:style)
		let l:current = {}

		for l:item in keys(l:toapply)
			let l:current[l:item] = <SID>GetValue(l:item)
		endfor

		let b:systemate_style = {"name": a:style, "revert": l:current}

		for [l:item, l:value] in items(l:toapply)
			call <SID>SetValue(l:item, l:value)
		endfor

		return a:style
	else
		"|------------------------------------------------
		"| Already set, set to something alse
		"|------------------------------------------------

		throw "Systemate:NOTYETIMPLEMENTED"
	endif
endfunction
"|===========================================================================|
"| }}}                                                                       |
"|===========================================================================|

"|===========================================================================|
"|                            PRIVATE FUNCTIONS                              |
"|===========================================================================|

"|===========================================================================|
"| s:SettingsForFiletype(filetype, style) {{{                                |
"|                                                                           |
"| Returns a dict of current settings for all values which would be affected |
"| by activating a style on this filetype.                                   |
"|                                                                           |
"| PARAMS:                                                                   |
"|   1) The filetype to check.                                               |
"|   2) The style to apply.                                                  |
"|===========================================================================|
function! s:SettingsForFiletype(filetype, style) abort
	if !has_key(g:, 'systemate')
		return {}
	elseif !has_key(g:systemate, a:style)
		throw printf('Systemate:NOSUCHSTYLE:%s', a:style)
	endif

	let l:settingset = {}
	for [l:k, l:v] in items(get(g:systemate[a:style], 'settings', {}))
		let l:settingset[l:k] = l:v
	endfor

	if has_key(g:systemate[a:style], 'per_filetype')
		for [l:k, l:v] in items(get(g:systemate[a:style]['per_filetype'],
		  \                         a:filetype,
		  \                         {}))
			let l:settingset[l:k] = l:v
		endfor
	endif

	return l:settingset
endfunction
"|===========================================================================|
"| }}}                                                                       |
"|===========================================================================|


"|===========================================================================|
"| s:GetDefaultStyle() {{{                                                   |
"|===========================================================================|
function! s:GetDefaultStyle() abort
	let l:styles = keys(get(g:, 'systemate', {}))
	if has_key(g:, 'systemate_default')
		return g:sytemate_default
	elseif len(l:styles) == 1
		return l:styles[0]
	else
		throw 'Systemate:BADCONFIG:0 or >1 style(s) present and g:systemate_default not set!'
	endif
endfunction
"|===========================================================================|
"| }}}                                                                       |
"|===========================================================================|

function! s:SetValue(name, value) abort
	if a:value ==# '%NULL%'
		if strpart(a:name, 0, 1) == '&'
			if strpart(a:name, 0, 3) == '&l:'
				execute printf('set %s<', strpart(a:name, 3))
			else
				execute printf('set %s&', strpart(a:name, 1))
			endif
		else
			execute 'unlet!' a:name
		endif
	elseif strpart(a:name, 0, 1) == '&'
		if type(a:value) == type(".")
			let l:q = printf("'%s'", a:value)
			execute 'let' a:name '=' l:q
		else
			execute 'let' a:name '=' a:value
		endif
	else
		let {a:name} = a:value
	endif
endfunction

function! s:GetValue(name) abort
	if strpart(a:name, 0, 1) == '&'
		let l:val = eval(a:name)
		if l:val == '' && strpart(a:name, 0, 3) ==# '&l:'
			let l:val = eval(printf("&%s", strpart(a:name, 3)))
		endif
		return l:val
	else
		try
			return eval(a:name)
		catch /E121/
			return '%NULL%'
		endtry
	endif
endfunction
