use strict;
use warnings;
use Test::More;

use Object::Container 'obj';

obj->register('ZERO', sub { 0 });
obj->register('EMPTY_STRING', sub { '' });

my $obj;

eval {
    $obj = obj->get('ZERO');
};
ok defined $obj, 'return ZERO';

$obj = undef;
eval {
    $obj = obj->get('EMPTY_STRING');
};
ok defined $obj, 'return EMPTY_STRING';


obj->register('UNDEF', sub { undef });
obj->register('EMPTY_LIST', sub { () });


$obj = undef;
eval {
    $obj = obj->get('EMPTY_LIST');
};
ok !$obj, 'return nothing when getting EMPTY_LIST';
like $@, qr/"EMPTY_LIST" is not registered in Object::Container/, 'unknown object error ok';

$obj = undef;
eval {
    $obj = obj->get('UNDEF');
};
ok !$obj, 'return nothing when getting UNDEF';
like $@, qr/"UNDEF" is not registered in Object::Container/, 'unknown object error ok';


done_testing;
