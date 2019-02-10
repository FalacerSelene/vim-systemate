"|===========================================================================|
"|                                                                           |
"|         FILE:  plugin/systemate.vim                                       |
"|                                                                           |
"|  DESCRIPTION:  Manage Company-specific settings.                          |
"|                                                                           |
"|       AUTHOR:  @FalacerSelene                                             |
"|      CONTACT:  < git at falacer-selene dot net >                          |
"|      LICENCE:  See LICENCE.md                                             |
"|      VERSION:  0.1.0                                                      |
"|                                                                           |
"|===========================================================================|

"|===========================================================================|
"|                                  SETUP                                    |
"|===========================================================================|
scriptencoding utf-8

if &compatible || exists('g:loaded_systemate')
	finish
elseif v:version < 704
	echoerr 'Systemate requires vim 7.4 or later!'
endif

let g:loaded_systemate = 1
let g:systemate_version = '0.1.0'
lockvar g:systemate_version

"|===========================================================================|
"|                             USER INTERFACE                                |
"|===========================================================================|

augroup SystemateInit
	autocmd!
	autocmd VimEnter * silent call <SID>InitialiseSystemate()
augroup END

"|===========================================================================|
"|                              USER COMMANDS                                |
"|===========================================================================|
command! -nargs=? -bar Systemate call systemate#SystemateCommand(<q-args>)
command! -nargs=0 -bar SystemateName call <SID>PrintCurrentName()
command! -nargs=0 -bar SystemateSelect call <SID>SystemateSelect()

"|===========================================================================|
"|                                FUNCTIONS                                  |
"|===========================================================================|

"|===========================================================================|
"| s:InitialiseSystemate() {{{                                               |
"|===========================================================================|
function! s:InitialiseSystemate() abort
	if !has_key(g:, 'systemate_autoapply')
		"|------------------------------------------------
		"| Nothing to autoapply, so there is no loading
		"| to do.
		"|------------------------------------------------
		return
	endif

	let l:systemate = get(g:, 'systemate', {})

	let l:auto = items(g:systemate_autoapply)

	"|------------------------------------------------
	"| First, sort the autoapply settings according
	"| to their priority
	"|------------------------------------------------
	function! s:SortAuto(a, b) abort
		let l:aprio = get(a:a[1], 'priority', 0)
		let l:bprio = get(a:b[1], 'priority', 0)

		return l:aprio - l:bprio
	endfunction
	call sort(l:auto, '<SID>SortAuto')
	delfunction s:SortAuto

	"|------------------------------------------------
	"| Then, filter for only ones that fit matching
	"| rules currently in effect.
	"|------------------------------------------------
	function! s:AppliesHere(style)
		let l:rules = a:style[1]
		let l:applies = 1
		if has_key(l:rules, 'hostname')
			if !exists('s:hostname')
				let s:hostname = hostname()
			endif
			if s:hostname !~? l:rules.hostname
				let l:applies = 0
			endif
		endif
		return l:applies
	endfunction
	call filter(l:auto, '<SID>AppliesHere(v:val)')
	delfunction s:AppliesHere

	if empty(l:auto)
		"|------------------------------------------------
		"| There were none left, so no autoapply to do.
		"|------------------------------------------------
		return
	endif

	let [l:style_name, l:rules] = l:auto[0]

	let l:fts = get(l:rules, 'filetypes', ['*'])
	let l:star = index(l:fts, '*') != -1

	augroup Systemate
	autocmd!

	if l:star
		execute 'autocmd' 'FileType' '*' 'silent' 'call'
		 \      printf('systemate#ApplyForFiletype("*", "%s")', l:style_name)
		silent call systemate#ApplyForFiletype('*', l:style_name)
	else
		for l:ft in l:fts
			execute 'autocmd' 'FileType' l:ft 'silent' 'call'
			 \      printf('systemate#ApplyForFiletype("%s", "%s")',
			 \             l:ft,
			 \             l:style_name)
	
			"|------------------------------------------------
			"| The filetype command won't fire at start of
			"| day, so fire it now if need be.
			"|------------------------------------------------
			if &l:filetype ==# l:ft
				silent call systemate#ApplyForFiletype(&l:filetype, l:style_name)
			endif
		endfor
	endif

	augroup END
endfunction
"|===========================================================================|
"| }}}                                                                       |
"|===========================================================================|

"|===========================================================================|
"| s:PrintCurrentName() {{{                                                  |
"|===========================================================================|
function! s:PrintCurrentName() abort
	let l:name = systemate#CurrentStyleName()
	if empty(l:name)
		echo 'Systemate off'
	else
		echo 'Systemate:' l:name
	endif
endfunction
"|===========================================================================|
"| }}}                                                                       |
"|===========================================================================|

"|===========================================================================|
"| s:SystemateSelect() {{{                                                   |
"|===========================================================================|
function! s:SystemateSelect() abort
	let l:style = systemate#StyleSelectionDialogue()
	if !empty(l:style)
		call systemate#ApplyForFiletype(&l:filetype, l:style)
	endif
endfunction
"|===========================================================================|
"| }}}                                                                       |
"|===========================================================================|
