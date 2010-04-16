use Test::Base;

plan tests => 4;

use Object::Container;

{
    package SampleClass;
    use base 'Class::Accessor::Fast';

    __PACKAGE__->mk_accessors(qw/text/);

    sub new {
        my $class = shift;
        my $args  = @_ > 1 ? {@_} : $_;

        $class->SUPER::new($args);
    }
}

my $c = Object::Container->new;

# args
$c->register('SampleClass', text => 'custom args');

isa_ok( $c->get('SampleClass'), 'SampleClass' );
is( $c->get('SampleClass')->text, 'custom args', 'args set ok');

# initializer
$c->register('SampleClass2', sub { SampleClass->new(text => 'custom initializer') });

isa_ok( $c->get('SampleClass2'), 'SampleClass' );
is( $c->get('SampleClass2')->text, 'custom initializer', 'initializer set ok');

