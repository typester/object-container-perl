use strict;
use warnings;
use Test::More;

use Object::Container;

ok !Object::Container->has_instance;

my $obj = Object::Container->new;
is_deeply $obj, Object::Container->instance;
is_deeply $obj, Object::Container->has_instance;

done_testing;
