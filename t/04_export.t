use Test::Base;

plan 'no_plan';

use Object::Container 'obj';

{
    package Foo;
    sub new { bless {}, shift }
    sub hello { 'hello' }
}

obj->register( foo => sub { Foo->new } );

isa_ok( obj('foo'), 'Foo' );
isa_ok( obj->get('foo'), 'Foo' );
is( obj('foo')->hello, 'hello', 'hello method ok');
is( obj->get('foo')->hello, 'hello', 'hello method ok');


