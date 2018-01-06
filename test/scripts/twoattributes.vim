StartTest twoattributes
Say 'Test the multiple separate attributes can be used and reset'

let g:systemate = {}
let g:systemate.one = { 'settings': { 't:foo': 4 } }
let g:systemate.two = { 'settings': { 't:bar': 8 } }

function! FooAndBar()
	call Say(printf("Foo = %s, Bar = %s",
	 \              get(t:, 'foo', '<UNSET>'),
	 \              get(t:, 'bar', '<UNSET>')))
endfunction

NextTest
Say 'Check values before setting'
call FooAndBar()

NextTest
Say 'Set style one'
Systemate one
call FooAndBar()
Systemate
call FooAndBar()

NextTest
Say 'Set style two'
Systemate two
call FooAndBar()
Systemate
call FooAndBar()

EndTest
