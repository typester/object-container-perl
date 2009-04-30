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

Object::Container - simple object container

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

This module is a object container interface which supports both OO interface and Singleton interface.

If you want to use one module from several places, you might use L<Class::Singleton> to access the module from any places. But you should subclass each modules to singletonize.

This module provide singleton container instead of module itself, so it is easy to singleton multiple classes.

L<Object::Registrar> is a similar module to this. But Object::Container has also OO interface and supports lazy initializer. (describing below)

=head2 OO and Singleton interfaces

This module provide two interfaces: OO and Singleton.

OO interface is like this:

    my $container = Object::Container->new;

It is normal object oriented interface. And you can use multiple container at the same Time:

    my $container1 = Object::Container->new;
    my $container2 = Object::Container->new;

Singleton is also like this:

    my $container = Object::Container->instance;

instance method always returns singleton object. With this interface, you can 'register' and 'get' method as class method:

    Object::Container->register('WWW::Mechanize');
    my $mech = Object::Container->get('WWW::Mechanize');

When you want use multiple container with Singleton interface, you have to create subclass like this:

    MyContainer1->get('WWW::Mechanize');
    MyContainer2->get('WWW::Mechanize');

=head2 lazy loading and resolve dependencies

The object that is registered by 'register' method is not initialized until calling 'get' method.

    Object::Container->register('WWW::Mechanize', sub { WWW::Mechanize->new }); # doesn't initialize here
    my $mech = Object::Container->get('WWW::Mechanize'); # initialize here

This feature helps you to create less resource and fast runtime script in case of lots of object registered.

And you can resolve dependencies between multiple modules with Singleton interface.

For example:

    Object::Container->register('HTTP::Cookies', sub { HTTP::Cookies->new( file => '/path/to/cookie.dat' ) });
    Object::Container->register('LWP::UserAgent', sub {
        my $cookies = Object::Container->get('HTTP::Cookies');
        LWP::UserAgent->new( cookie_jar => $cookies );
    });

You can resolve dependencies by calling 'get' method in initializer like above.

In that case, only LWP::UserAgent and HTTP::Cookies are initialized.

=head1 METHODS

=head2 register( $class, @args )

=head2 register( $class_or_name, $initialize_code )

Register classes to container.

Most simple usage is:

    Object::Container->register('WWW::Mechanize');

First argument is class name to object. In this case, execute 'WWW::Mechanize->new' when first get method call.

    Object::Container->register('WWW::Mechanize', @args );

is also execute 'WWW::Mechanize->new(@args)'.

If you use different constructor from 'new', want to custom initializer, or want to include dependencies, you can custom initializer to pass a coderef as second argument.

    Object::Container->register('WWW::Mechanize', sub {
        my $mech = WWW::Mechanize->new( stack_depth );
        $mech->agent_alias('Windows IE 6');
        return $mech;
    });

This coderef (initialize) should return object to contain.

With last way you can pass any name to first argument instead of class name.

    Object::Container->register('ua1', sub { LWP::UserAgent->new });
    Object::Container->register('ua2', sub { LWP::UserAgent->new });


=head2 get($class_or_name)

Get the object that registered by 'register' method.

First argument is same as 'register' method.

=head2 ensure_class_loaded($class)

This is utility method that load $class if $class is not loaded.

It's useful when you want include dependency in initializer and want lazy load the modules.

=head1 SEE ALSO

L<Class::Singleton>, L<Object::Registrar>.

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
