use strict;
use warnings;
use Test::More;

use Object::Container;

{
    package Foo;
    use base 'Class::Accessor::Fast';

    sub name { 'foo' }

    package Bar;
    use base 'Class::Accessor::Fast';

    sub name { 'bar' }
}


subtest load_all => sub {
    my $c = Object::Container->new;

    $c->register('Foo');
    $c->register('Bar');

    # doesn't load yet
    ok !$c->objects->{'Foo'}, 'Foo is not loaded';
    ok !$c->objects->{'Bar'}, 'Bar is not loaded';

    $c->load_all;

    ok $c->objects->{'Foo'}, 'Foo is loaded';
    ok $c->objects->{'Bar'}, 'Bar is loaded';
};

subtest load_all_except => sub {
    my $c = Object::Container->new;

    $c->register('Foo');
    $c->register('Bar');

    # doesn't load yet
    ok !$c->objects->{'Foo'}, 'Foo is not loaded';
    ok !$c->objects->{'Bar'}, 'Bar is not loaded';

    $c->load_all_except(qw/Bar/);

    ok $c->objects->{'Foo'}, 'Foo is loaded';
    ok !$c->objects->{'Bar'}, 'Bar is not loaded too';
};

done_testing;
