use strict;
use warnings;
use Test::More;
use Test::Requires 'Exporter::AutoClean';

{
    package Foo;
    use base 'Class::Accessor::Fast';

    sub name { 'foo' }

    package Bar;
    use base 'Class::Accessor::Fast';

    sub name { 'bar' }

    package MyContainer;
    use Object::Container '-base';

    register 'Foo';
    register 'Bar';

    preload_all_except qw/Bar/;
}

# doesn't load yet
my $c = MyContainer->instance;

ok $c->objects->{'Foo'}, 'Foo is loaded';
ok !$c->objects->{'Bar'}, 'Bar is not loaded too';

done_testing;
