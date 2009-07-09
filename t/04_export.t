use Test::Base;

plan 'no_plan';

use Object::Container 'obj';

{
    package Foo;
    sub new { bless {}, shift }
    sub hello { 'hello' }
}

Object::Container->register( foo => sub { Foo->new } );

isa_ok( obj('foo'), 'Foo' );
is( obj('foo')->hello, 'hello', 'hello method ok');


