use Test::Base;

plan tests => 4;

use Object::Container;

my $container = Object::Container->new;
ok($container->register('FileHandle'), 'register class ok');
isa_ok($container->get('FileHandle'), 'FileHandle');

{
    my $obj;
    eval {
        $obj = $container->get('unknown_object');
    };

    ok !$obj, 'return nothing when getting unknown object';
    like $@, qr/"unknown_object" is not registered in Object::Container/, 'unknown object error ok';
}
