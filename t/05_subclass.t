use Test::Base;
use FindBin;
use lib "$FindBin::Bin/subclass";
use Test::Requires 'Exporter::AutoClean';

plan tests => 3;

use Foo 'obj';

isa_ok( my $obj = obj('foo_object'), 'FooObject' );
is($obj->{foo}, 'bar', 'object data ok');

isa_ok( $obj = obj('Object::Container'), 'Object::Container' );

