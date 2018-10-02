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
	let l:systemate = get(g:, 'systemate', {})
	augroup Systemate
	autocmd!

	for [l:style_name, l:style] in items(l:systemate)
		if !has_key(l:style, 'auto_apply')
			"|------------------------------------------------
			"| No auto_apply settings. Wait for manual.
			"|------------------------------------------------
			return
		endif

		let l:autoapply = l:style['auto_apply']

		if has_key(l:autoapply, 'pc_name_match')
		 \ && hostname() !~? l:autoapply['pc_name_match']
			"|------------------------------------------------
			"| We're restricting by pc_name and this is not
			"| the right name. Wait for manual.
			"|------------------------------------------------
			return
		endif

		let l:filetypes = get(l:autoapply, 'for_filetypes', [])

		if empty(l:filetypes)
			let l:filetypes = ['*']
		endif

		for l:ft in l:filetypes
			execute 'autocmd' 'FileType' l:ft 'silent' 'call'
			 \      printf('systemate#ApplyForFiletype("%s", "%s")',
			 \             l:ft,
			 \             l:style_name)

			"|------------------------------------------------
			"| The filetype command won't fire at start of
			"| day, so fire it now if need be.
			"|------------------------------------------------
			if &l:filetype ==# l:ft || l:filetypes == ['*']
				silent call systemate#ApplyForFiletype(&l:filetype, l:style_name)
			endif
		endfor
	endfor

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

