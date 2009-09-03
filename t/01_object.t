use Test::Base;

plan tests => 4;

use Object::Container;

my $container = Object::Container->new;
ok($container->register('FileHandle'), 'register class ok');
isa_ok($container->get('FileHandle'), 'FileHandle');

{
    my $warning;
    local $SIG{__WARN__} = sub {
        $warning = $_[0];
    };

    ok !$container->get('unknown_object'), 'return nothing when getting unknown object';
    like $warning, qr/"unknown_object" is not registered in Object::Container/, 'unknown object error ok';
}
