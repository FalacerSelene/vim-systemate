StartTest autofiletype
Say 'Test that systemate correctly auto-activates when restricted'

let g:systemate = {}
let g:systemate.only = {}
let g:systemate.only.settings = { 't:foo': 1 }
let g:systemate_autoapply = { 'only': { 'filetypes': ['foo'] } }

doautocmd SystemateInit VimEnter *

NextTest
Say 'Value of foo - should be none'
Say get(t:, 'foo', '<UNSET>')
Say 'Check current style name'
AssertE empty(systemate#CurrentStyleName())

NextTest
Say 'Set filetype, which should trigger the autoapply'
set filetype=foo
Say get(t:, 'foo', '<UNSET>')
Say 'Check style name got set'
AssertE systemate#CurrentStyleName() == 'only'

EndTest
