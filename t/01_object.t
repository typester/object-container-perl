use Test::Base;

plan tests => 2;

use Object::Container;

my $container = Object::Container->new;
ok($container->register('FileHandle'), 'register class ok');
isa_ok($container->get('FileHandle'), 'FileHandle');
