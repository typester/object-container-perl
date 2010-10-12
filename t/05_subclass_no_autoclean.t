use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/no_clean";
use lib "$FindBin::Bin/subclass";

use Foo 'obj';

isa_ok( my $obj = obj('foo_object'), 'FooObject' );
is($obj->{foo}, 'bar', 'object data ok');
isa_ok( $obj = obj('Object::Container'), 'Object::Container' );

# obj->register == Foo::register because this is in no clean state
is obj->can('register'), Foo->can('register'), 'obj->register == Foo::register ok';
isnt obj->can('register'), Object::Container->can('register'), 'obj->register != Object::Container::register ok';;


use Bar 'obj_clean';



done_testing;
