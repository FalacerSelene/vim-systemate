StartTest autofile
Say 'Test that systemate correctly auto-activates'

let g:systemate = {}
let g:systemate.only = { 'settings': { 't:foo': 1 }, 'auto_apply': {} }

doautocmd SystemateInit VimEnter *

NextTest
Say 'Value of foo - should be autoactivated'
Say get(t:, 'foo', '<UNSET>')
Say 'Check current style name'
AssertE empty(systemate#CurrentStyleName())

NextTest
Say 'Deactive and check again'
Systemate
Say get(t:, 'foo', '<UNSET>')
Say 'Check style name got set'
AssertE systemate#CurrentStyleName() == 'only'

EndTest
