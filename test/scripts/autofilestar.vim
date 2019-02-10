StartTest autofilestar
Say 'Test that systemate correctly auto-activates with star filetype'

let g:systemate = {}
let g:systemate.only = { 'settings': { 't:foo': 1 } }
let g:systemate_autoapply = { 'only': { 'filetypes': ['*'] } }

doautocmd SystemateInit VimEnter *

NextTest
Say 'Value of foo - should be autoactivated'
Say get(t:, 'foo', '<UNSET>')
Say 'Check current style name'
AssertE systemate#CurrentStyleName() == 'only'

NextTest
Say 'Deactive and check again'
Systemate
Say get(t:, 'foo', '<UNSET>')
Say 'Check style name got set'
AssertE empty(systemate#CurrentStyleName())

EndTest
