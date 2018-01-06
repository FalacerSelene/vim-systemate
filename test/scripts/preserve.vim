StartTest preserve
Say 'Test that attributes in the DEFAULT are restored'

let g:systemate = {}
let g:systemate.only = { 'settings': { 't:foo': 10 } }

let t:foo = 20

NextTest
Say 'Check values before setting'
call Say(printf('Foo = %s', get(t:, 'foo', '<UNSET>')))
Systemate
call Say(printf('Foo = %s', get(t:, 'foo', '<UNSET>')))
Systemate
call Say(printf('Foo = %s', get(t:, 'foo', '<UNSET>')))

EndTest
