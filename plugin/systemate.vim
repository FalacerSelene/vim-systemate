"|===========================================================================|
"|                                                                           |
"|         FILE:  plugin/systemate.vim                                       |
"|                                                                           |
"|  DESCRIPTION:  Manage Company-specific settings.                          |
"|                                                                           |
"|       AUTHOR:  FalacerSelene                                              |
"|      LICENCE:  Public Domain                                              |
"|     PROVIDES:  :Systemate                                                 |
"|                :IsSystemate                                               |
"|                augroup Systemate                                          |
"|                                                                           |
"|===========================================================================|

"|===========================================================================|
"|                                  SETUP                                    |
"|===========================================================================|
scriptencoding utf-8

if &compatible || exists('g:loaded_systemate')
	finish
endif

let g:loaded_systemate = 1

"|===========================================================================|
"|                             USER INTERFACE                                |
"|===========================================================================|
let s:systemate = {
	\   'auto_apply' : {
	\     'pc_name_match' : 'PC5325',
	\     'for_filetypes' : [
	\       'c',
	\       'cpp',
	\       'perl',
	\       'sh',
	\       'rust',
	\     ],
	\   },
	\   'settings' : {
	\     '&l:expandtab': 1,
	\     '&l:tabstop': 2,
	\     '&l:softtabstop': 2,
	\     '&l:shiftwidth': 2,
	\     '&l:textwidth': 79,
	\     '&l:colorcolumn': 80,
	\     'b:CommentableSubStyle': '%NULL%',
	\     'g:CommentableSubStyle': '%NULL%',
	\     'b:CommentableSubWidth': '%NULL%',
	\     'g:CommentableSubWidth': '%NULL%',
	\   },
	\   'per_filetype' : {
	\     'sh' : {
	\       '&l:tabstop': 4,
	\       '&l:softtabstop': 4,
	\       '&l:shiftwidth': 4,
	\     },
	\     'make' : {
	\       '&l:expandtab' : 0,
	\     },
	\     'rust' : {
	\       '&l:shiftwidth': 4,
	\       '&l:tabstop': 4,
	\       '&l:softtabstop': 4,
	\       '&l:textwidth': 99,
	\       '&l:colorcolumn': 100,
	\     },
	\   },
	\ }

augroup SystemateInit
	autocmd!
	autocmd VimEnter * silent call <SID>InitialiseSystemate()
augroup END

command! -nargs=0 -bar Systemate call <SID>ToggleSystemate()
command! -nargs=0 -bar IsSystemate
	\   if get(b:, 'SystemateStyle', 0)
	\ |   echon "yes"
	\ | else
	\ |   echon "no"
	\ | endif

"|===========================================================================|
"|                                FUNCTIONS                                  |
"|===========================================================================|

"|===========================================================================|
"| s:InitNormalSettings() {{{                                                |
"|===========================================================================|
function! s:InitNormalSettings()
	if !exists('s:normal_settings')
		let s:normal_settings = {}
	endif

	if !exists('s:all_settings')
		let s:all_settings = {}
		for l:it in keys(s:systemate.settings)
			let s:all_settings[l:it] = 1
		endfor
		for [l:_, l:settings] in items(s:systemate.per_filetype)
			for l:it in keys(l:settings)
				let s:all_settings[l:it] = 1
			endfor
		endfor
	endif

	if !has_key(s:normal_settings, &filetype)
		let s:normal_settings[&filetype] = {}
		for l:it in keys(s:all_settings)
			if !exists(l:it)
				let s:normal_settings[&filetype][l:it] = '%NULL%'
			else
				let s:normal_settings[&filetype][l:it] = eval(l:it)
			endif
		endfor
	endif
endfunction
"|===========================================================================|
"| }}}                                                                       |
"|===========================================================================|

"|===========================================================================|
"| s:SetSystemate() {{{                                                     |
"|===========================================================================|
function! s:SetSystemate()
	call <SID>InitNormalSettings()
	echo 'Set Systemate Style'
	let b:SystemateStyle = 1

	"|------------------------------------------------
	"| Make the settings for this filetype
	"|------------------------------------------------
	let l:settings = copy(s:systemate.settings)
	let l:ft = get(s:systemate.per_filetype, &filetype, {})
	call extend(l:settings, l:ft)

	"|------------------------------------------------
	"| Enforce the settings
	"|------------------------------------------------
	for [l:k, l:v] in items(l:settings)
		if l:v ==# '%NULL%'
			if l:k[0] == '&'
				if len(l:k) > 3 && l:k[1] == 'l' && l:k[2] == ':'
					execute 'set' strpart(l:k, 3) . '&'
				else
					execute 'set' strpart(l:k, 1) . '&'
				endif
			else
				execute 'unlet!' l:k
			endif
		else
			execute 'let' l:k '=' l:v
		endif
	endfor
endfunction
"|===========================================================================|
"| }}}                                                                       |
"|===========================================================================|

"|===========================================================================|
"| s:UnsetSystemate() {{{                                                    |
"|===========================================================================|
function! s:UnsetSystemate()
	echo 'Unset Systemate style'
	let b:SystemateStyle = 0
	for [l:k, l:v] in items(get(s:normal_settings, &filetype, {}))
		if type(l:v) == type("") && l:v ==# '%NULL%'
			execute 'unlet!' l:k
		else
			execute 'let' l:k '=' string(l:v)
		endif
	endfor
endfunction
"|===========================================================================|
"| }}}                                                                       |
"|===========================================================================|

"|===========================================================================|
"| s:ToggleSystemate() {{{                                                   |
"|===========================================================================|
function! s:ToggleSystemate()
	call <SID>InitNormalSettings()
	if get(b:, 'SystemateStyle', 0)
		call <SID>UnsetSystemate()
	else
		call <SID>SetSystemate()
	endif
endfunction
"|===========================================================================|
"| }}}                                                                       |
"|===========================================================================|

"|===========================================================================|
"| s:InitialiseSystemate() {{{                                               |
"|===========================================================================|
function! s:InitialiseSystemate()
	if !has_key(s:systemate.auto_apply, 'pc_name_match')
		let l:issystem = 0
	else
		if exists('*systemlist')
			let s:host = systemlist('hostname')[0]
		else
			let s:host = split(system('hostname'), "\n")[0]
		fi
		let l:issystem = s:host =~? s:systemate.auto_apply.pc_name_match
	endif

	if !l:issystem
		return
	endif

	let l:ft = s:systemate.auto_apply.for_filetypes

	augroup Systemate
		autocmd!

	if type(l:ft) == type("") && l:ft ==# '*'
		autocmd BufRead,BufNewFile * silent call <SID>SetSystemate()
	elseif type(l:ft) == type([])
		for l:f in l:ft
			execute 'autocmd FileType' l:f 'silent call <SID>SetSystemate()'
			"|------------------------------------------------
			"| The FileType autocmd won't fire at start of
			"| day (as this plugin is loaded after the
			"| filetype detection is done).
			"|------------------------------------------------
			if &l:filetype ==# l:f
				silent call <SID>SetSystemate()
			endif
		endfor
	endif

	augroup END

endfunction
"|===========================================================================|
"| }}}                                                                       |
"|===========================================================================|
