use strict;
use warnings;
use Test::More;

use Carp;
$SIG{__DIE__} = sub { Carp::confess(@_) };

use Object::Container;
my $obj = Object::Container->new;

$obj->autoloader( qr/^Schema::.+/, sub {
    my ($self, $class) = @_;

    my ($table) = $class =~ /^Schema::(.*)/;
    $self->register("Schema::${table}", sub { "Result $table" });
});

ok !$obj->{registered_classes}{'Schema::Foo'}, 'Schema::Foo does not registered';
ok !$obj->{objects}{'Schema::Foo'}, 'Schema::Foo does not initialized';

my $foo = $obj->get('Schema::Foo');
is $foo, 'Result Foo', 'result class ok';

ok $obj->{registered_classes}{'Schema::Foo'}, 'Schema::Foo registered';
ok $obj->{objects}{'Schema::Foo'}, 'Schema::Foo initialized';

done_testing;
