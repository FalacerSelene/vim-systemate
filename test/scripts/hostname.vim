StartTest hostname
Say 'Test that systemate detects hostnames'

let g:systemate = {}
let g:systemate.host = { 'settings': { 't:foo': 1 } }
let g:systemate_autoapply = { 'host': { 'hostname': hostname() } }

doautocmd SystemateInit VimEnter *

NextTest
Say 'Value of foo - should be autoactivated'
Say get(t:, 'foo', '<UNSET>')
Say 'Check current style name'
AssertE systemate#CurrentStyleName() == 'host'

EndTest
