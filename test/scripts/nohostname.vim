StartTest nohostname
Say 'Test that systemate does not react to other hostnames'

let g:systemate = {}
let g:systemate.host = { 'settings': { 't:foo': 1 } }
let g:systemate_autoapply = { 'host': { 'hostname': printf("not%s", hostname()) } }

doautocmd SystemateInit VimEnter *

NextTest
Say 'Value of foo - should not be set'
Say get(t:, 'foo', '<UNSET>')
Say 'Check current style name'
AssertE empty(systemate#CurrentStyleName())

EndTest
