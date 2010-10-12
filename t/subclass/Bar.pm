package Bar;
use strict;
use warnings;
use Object::Container '-base';

register foo_object => sub { bless { foo => 'bar' }, 'FooObject' };
register 'Object::Container';

no Object::Container;
