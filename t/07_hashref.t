use strict;
use warnings;
use Test::More;

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
$c->register({ class => 'SampleClass', args => [text => 'costom args'] });

isa_ok( $c->get('SampleClass'), 'SampleClass' );
is( $c->get('SampleClass')->text, 'costom args', 'outer args set ok');

# initializer
$c->register({ class => 'SampleClass2', initializer => sub { SampleClass->new(text => 'custom initializer') } });

isa_ok( $c->get('SampleClass2'), 'SampleClass' );
is( $c->get('SampleClass2')->text, 'custom initializer', 'initializer set ok');

# preload
$c->register({ class => 'SampleClass3', initializer => sub { SampleClass->new(text => 'ploeaded :)') }, preload => 1 });

is( $c->objects->{'SampleClass3'}->text, 'ploeaded :)', 'ploeaded success');

done_testing;
