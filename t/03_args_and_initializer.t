use Test::Base;

plan tests => 4;

use Object::Container;

{
    package SampleClass;
    use Any::Moose;

    has text => (
        is  => 'rw',
        isa => 'Str',
    );
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

