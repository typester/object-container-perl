use Test::Base;
use Test::Exception;

plan tests => 3;

use Object::Container;

my $container = Object::Container->new;
ok($container->register('FileHandle'), 'register class ok');
isa_ok($container->get('FileHandle'), 'FileHandle');

throws_ok(
    sub { $container->get('unknown_object') },
    qr/"unknown_object" is not registered in Object::Container/,
);
