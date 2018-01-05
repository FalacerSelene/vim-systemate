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
"| systemate#ApplyForFiletype(filetype) {{{                                  |
"|===========================================================================|
function! systemate#ApplyForFiletype(filetype) abort
	let l:toapply = <SID>SettingsForFiletype(a:filetype)

	if get(b:, 'systemate_on', 0)
		let b:systemate_on = 1
		let l:current = {}
		for l:item in l:toapply
			if strpart(l:item, 0, 1) == '&'
				let l:current[l:item] = eval(l:item)
			else
				try
					let l:current[l:item] = eval(l:item)
				catch /^E121/
					let l:current[l:item] = '%NULL%'
				endtry
			endif
		endfor
		let b:systemate_save = l:current

		for [l:item, l:value] in items(l:toapply)
			if l:value ==# '%NULL%'
				execute 'unlet!' l:item
			else
				execute 'let' l:item '=' l:value
			endif
		endfor
	else
		let b:systemate_on = 0
		let l:saved = b:systemate_save
		unlet b:systemate_save

		for [l:item, l:value] in items(l:saved)
			if l:value ==# '%NULL%'
				execute 'unlet!' l:item
			else
				execute 'let' l:item '=' l:value
			endif
		endfor
	endif
endfunction
"|===========================================================================|
"| }}}                                                                       |
"|===========================================================================|

"|===========================================================================|
"|                            PRIVATE FUNCTIONS                              |
"|===========================================================================|

"|===========================================================================|
"| s:SettingsForFiletype(filetype) {{{                                       |
"|                                                                           |
"| Returns a list of current settings for all values which would be affected |
"| by activating a style on this filetype.                                   |
"|                                                                           |
"| PARAMS:                                                                   |
"|   1) The filetype to check.                                               |
"|===========================================================================|
function! s:SettingsForFiletype(filetype) abort
	if !has_key(g:, 'systemate')
		return {}
	endif

	let l:settingset = {}
	for [l:_, l:settings] in items(g:systemate)
		for l:v in keys(get(l:settings, 'settings', {}))
			let l:settingset[l:v] = 1
		endfor

		if !has_key(l:settings, 'per_filetype')
			continue
		endif

		for l:v in keys(get(l:settings.per_filetype, a:filetype, {}))
			let l:settingset[l:v] = 1
		endfor
	endfor

	return keys(l:settingset)
endfunction
"|===========================================================================|
"| }}}                                                                       |
"|===========================================================================|

