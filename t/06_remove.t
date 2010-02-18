use strict;
use warnings;
use Test::More;

use Object::Container;

my $c = Object::Container->new;

$c->register('FileHandle');

is $c->get('FileHandle'), $c->get('FileHandle'), 'save object ok';

my $cached = $c->get('FileHandle');
is $c->remove('FileHandle'), $cached, 'remove return cached object ok';

isnt $c->get('FileHandle'), $cached, 'recreate object after remove ok';

$c->unregister('FileHandle');
my $obj;
{
    local $SIG{__WARN__} = {};
    eval {
        $obj = $c->get('FileHandle');
    };
}
ok !$obj, 'no more avaiable after unregister ok';

done_testing;
