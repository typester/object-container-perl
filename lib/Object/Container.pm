package Object::Container;
use Any::Moose;

our $VERSION = '0.01';

extends any_moose('::Object'), 'Class::Singleton';

has registered_classes => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has objects => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

no Any::Moose;

# override Class::Singleton initializer
sub _new_instance { shift->new(@_) }

sub register {
    my ($self, $class, @rest) = @_;
    $self = $self->instance unless ref $self;

    my $initializer;
    if (@rest == 1 and ref($rest[0]) eq 'CODE') {
        $initializer = $rest[0];
    }
    else {
        $initializer = sub {
            $self->ensure_class_loaded($class);
            $class->new(@rest);
        };
    }

    $self->registered_classes->{$class} = $initializer;
}

sub get {
    my ($self, $class) = @_;
    $self = $self->instance unless ref $self;
    my $obj = $self->objects->{ $class } ||= $self->registered_classes->{$class}->()
        or die qq["$class" is not registered in @{[ ref $self ]}];
}

sub ensure_class_loaded {
    my ($self, $class) = @_;
    Any::Moose::load_class($class) unless Any::Moose::is_class_loaded($class);
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Object::Container - 

=head1 SYNOPSIS

    use Object::Container;
    
    # initialize container
    my $container = Object::Container->new;
    
    # register class
    $container->register('HTML::TreeBuilder');
    
    # register class with initializer
    $container->register('WWW::Mechanize', sub {
        my $mech = WWW::Mechanize->new( stack_depth => 1 );
        $mech->agent_alias('Windows IE 6');
        return $mech;
    });
    
    # get object
    my $mech = $container->get('WWW::Mechanize');
    
    # also available Singleton interface
    my $container = Object::Container->instance;
    
    # With singleton interface, you can use register/get method as class method
    Object::Container->register('WWW::Mechanize');
    my $mech = Object::Container->get('WWW::Mechanize');

=head1 DESCRIPTION

Stub documentation for this module was created by ExtUtils::ModuleMaker.
It looks like the author of the extension was negligent enough
to leave the stub unedited.

Blah blah blah.

=head1 METHODS

=head2 register( $class, @args )

=head2 register( $class_or_name, $initialize_code )

=head2 get($class_or_name)

=head2 ensure_class_loaded($class)

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2009 KAYAC Inc. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
