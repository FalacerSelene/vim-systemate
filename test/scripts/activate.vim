StartTest activate
Say 'Test that systemate correctly activates'

let g:systemate = {}
let g:systemate.only = { 'settings': { 't:foo': 1, 't:bar': ['one', 'two'] } }

NextTest
Say 'Value of foo before activating'
Say get(t:, 'foo', '<UNSET>')
Say 'Value of bar'
Say string(get(t:, 'bar', '<UNSET>'))
AssertE empty(systemate#CurrentStyleName())

NextTest
Say 'Activate and check both again'
Systemate
Say get(t:, 'foo', '<UNSET>')
Say string(get(t:, 'bar', '<UNSET>'))
AssertE systemate#CurrentStyleName() == 'only'

NextTest
Say 'Deactive and check last time'
Systemate
Say get(t:, 'foo', '<UNSET>')
Say string(get(t:, 'bar', '<UNSET>'))
AssertE empty(systemate#CurrentStyleName())

EndTest
