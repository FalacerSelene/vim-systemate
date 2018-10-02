StartTest multistyle
Say 'Test that multiple styles can be used'

let g:systemate = {}
let g:systemate.one = { 'settings': { 't:foo': 1 } }
let g:systemate.two = { 'settings': { 't:foo': 2 } }

NextTest
Say 'Value of foo before activating'
Say get(t:, 'foo', '<UNSET>')
AssertE empty(systemate#CurrentStyleName())

NextTest
Say 'Set style one, and check foo'
Systemate one
Say get(t:, 'foo', '<UNSET>')
AssertE systemate#CurrentStyleName() == 'one'
Systemate
Say get(t:, 'foo', '<UNSET>')
AssertE empty(systemate#CurrentStyleName())

NextTest
Say 'Set style two, and check foo'
Systemate two
Say get(t:, 'foo', '<UNSET>')
AssertE systemate#CurrentStyleName() == 'two'
Systemate
Say get(t:, 'foo', '<UNSET>')
AssertE empty(systemate#CurrentStyleName())

EndTest
