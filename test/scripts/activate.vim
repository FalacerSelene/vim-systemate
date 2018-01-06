StartTest activate
Say 'Test that systemate correctly activates'

let g:systemate = {}
let g:systemate.only = { 'settings': { 't:foo': 1 } }

NextTest
Say 'Value of foo before activating'
Say get(t:, 'foo', '<UNSET>')

NextTest
Say 'Activate and check foo again'
Systemate
Say get(t:, 'foo', '<UNSET>')

NextTest
Say 'Deactive and check last time'
Systemate
Say get(t:, 'foo', '<UNSET>')

EndTest
