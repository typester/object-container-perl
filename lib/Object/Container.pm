package Object::Container;

use strict;
use warnings;
use parent qw(Class::Accessor::Fast);
use Carp;

our $VERSION = '0.14';

__PACKAGE__->mk_accessors(qw/registered_classes autoloader_rules objects/);

BEGIN {
    our $_HAVE_EAC = 1;
    eval { local $SIG{__DIE__}; require Exporter::AutoClean; };
    if ($@) {
        $_HAVE_EAC = 0;
    }    
}

do {
    my @EXPORTS;

    sub import {
        my ($class, $name) = @_;
        return unless $name;

        my $caller = caller;
        {
            no strict 'refs';
            if ($name =~ /^-base$/i) {
                push @{"${caller}::ISA"}, $class;
                my $r = $class->can('register');
                my $l = $class->can('autoloader');
    
                my %exports = (
                    register   => sub { $r->($caller, @_) },
                    autoloader => sub { $l->($caller, @_) },
                    preload    => sub {
                        $caller->instance->get($_) for @_;
                    },
                    preload_all_except => sub {
                        $caller->instance->load_all_except(@_);
                    },
                    preload_all => sub {
                        $caller->instance->load_all;
                    },
                );
    
                if ($Object::Container::_HAVE_EAC) {
                    Exporter::AutoClean->export( $caller, %exports );
                }
                else {
                    while (my ($name, $fn) = each %exports) {
                        *{"${caller}::${name}"} = $fn;
                    }
                    @EXPORTS = keys %exports;
                }
            }
            else {
                no strict 'refs';
                *{"${caller}::${name}"} = sub {
                    my ($target) = @_;
                    return $target ? $class->get($target) : $class;
                };
            }
        }
    }

    sub unimport {
        my $caller = caller;

        no strict 'refs';
        for my $name (@EXPORTS) {
            delete ${ $caller . '::' }{ $name };
        }

        1; # for EOF
    }
};

my %INSTANCES;
sub instance {
    my $class = shift;
    return $INSTANCES{$class} ||= $class->new;
}

sub has_instance {
    my $class = shift;
    $class = ref $class || $class;
    return $INSTANCES{$class};
};

sub new {
    $_[0]->SUPER::new( +{
        registered_classes => +{},
        autoloader_rules => +[],
        objects => +{},
    } );
}

sub register {
    my ($self, $args, @rest) = @_;
    $self = $self->instance unless ref $self;

    my ($class, $initializer, $is_preload);
    if (defined $args && !ref $args) {
        $class = $args;
        if (@rest == 1 and ref $rest[0] eq 'CODE') {
            $initializer = $rest[0];
        }
        else {
            $initializer = sub {
                $self->ensure_class_loaded($class);
                $class->new(@rest);
            };
        }
    }
    elsif (ref $args eq 'HASH') {
        $class = $args->{class};
        $args->{args} ||= [];
        if (ref $args->{initializer} eq 'CODE') {
            $initializer = $args->{initializer};
        }
        else {
            $initializer = sub {
                $self->ensure_class_loaded($class);
                $class->new(@{$args->{args}});
            };
        }

        $is_preload = 1 if $args->{preload};
    }
    else {
        croak "Usage: $self->register($class || { class => $class ... })";
    }

    $self->registered_classes->{$class} = $initializer;
    $self->get($class) if $is_preload;
    
    return $initializer;
}

sub unregister {
    my ($self, $class) = @_;
    $self = $self->instance unless ref $self;

    delete $self->registered_classes->{$class} and $self->remove($class);
}

sub autoloader {
    my ($self, $rule, $trigger) = @_;
    $self = $self->instance unless ref $self;

    push @{ $self->autoloader_rules }, [$rule, $trigger];
}

sub get {
    my ($self, $class) = @_;
    $self = $self->instance unless ref $self;

    my $obj = $self->objects->{ $class } ||= do {
        my $initializer = $self->registered_classes->{ $class };
        $initializer ? $initializer->($self) : ();
    };

    unless ($obj) {
        # autoloaderer
        if (my ($trigger) = grep { $class =~ /$_->[0]/ } @{ $self->autoloader_rules }) {
            $trigger->[1]->($self, $class);
        }

        $obj = $self->objects->{ $class } ||= do {
            my $initializer = $self->registered_classes->{ $class };
            $initializer ? $initializer->($self) : ();
        };        
    }
        
    $obj or croak qq["$class" is not registered in @{[ ref $self ]}];
}

sub remove {
    my ($self, $class) = @_;
    $self = $self->instance unless ref $self;
    delete $self->objects->{ $class };
}

sub load_all {
    my ($self) = @_;
    $self->load_all_except;
}

sub load_all_except {
    my ($self, @except) = @_;
    $self = $self->instance unless ref $self;

    for my $class (keys %{ $self->registered_classes }) {
        next if grep { $class eq $_ } @except;
        $self->get($class);
    }
}

# taken from Mouse
sub _is_class_loaded {
    my $class = shift;

    return 0 if ref($class) || !defined($class) || !length($class);

    # walk the symbol table tree to avoid autovififying
    # \*{${main::}{"Foo::"}{"Bar::"}} == \*main::Foo::Bar::

    my $pack = \%::;
    foreach my $part (split('::', $class)) {
        $part .= '::';
        return 0 if !exists $pack->{$part};

        my $entry = \$pack->{$part};
        return 0 if ref($entry) ne 'GLOB';
        $pack = *{$entry}{HASH};
    }

    return 0 if !%{$pack};

    # check for $VERSION or @ISA
    return 1 if exists $pack->{VERSION}
             && defined *{$pack->{VERSION}}{SCALAR} && defined ${ $pack->{VERSION} };
    return 1 if exists $pack->{ISA}
             && defined *{$pack->{ISA}}{ARRAY} && @{ $pack->{ISA} } != 0;

    # check for any method
    foreach my $name( keys %{$pack} ) {
        my $entry = \$pack->{$name};
        return 1 if ref($entry) ne 'GLOB' || defined *{$entry}{CODE};
    }

    # fail
    return 0;
}


sub _try_load_one_class {
    my $class = shift;

    return '' if _is_class_loaded($class);
    my $klass = $class;
    $klass  =~ s{::}{/}g;
    $klass .= '.pm';

    return do {
        local $@;
        eval { require $klass };
        $@;
    };
}

sub ensure_class_loaded {
    my ($self, $class) = @_;
    my $e = _try_load_one_class($class);
    Carp::confess "Could not load class ($class) because : $e" if $e;

    return $class;
}

1;
__END__

=for stopwords DSL OO runtime singletonize unregister preload

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
    
    # Export singleton interface
    use Object::Container 'container';
    container->register('WWW::Mechanize');
    my $mech = container->get('WWW::Mechanize');
    my $mech = container('WWW::Mechanize'); # save as above
    
    # Subclassing singleton interface
    package MyContainer;
    use Object::Container '-base';
    
    register mech => sub { WWW::Mechanize->new };
    
    # use it
    use MyContainer 'con';
    
    con('mech')->get('http://example.com');

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

=head2 Singleton interface with EXPORT function for lazy people

If you are lazy person, and don't want to write something long code like:

    MyContainer->get('WWW::Mechanize');

This module provide export functions to shorten this.
If you use your container with function name, the function will be exported and act as container:

    use MyContainer 'container';
    
    container->register(...);
    
    container->get(...);
    container(...);             # shortcut to ->get(...);

=head2 Subclassing singleton interface for lazy people

If you are lazy person, and don't want to write something long code in your subclass like:

    __PACKAGE__->register( ... );

Instead of above, this module provide subclassing interface.
To do this, you need to write below code to subclass instead of C<use base>.

    use Object::Container '-base';

And then you can register your object via DSL functions:

    register ua => sub { LWP::UserAgent->new };

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

=head2 new

Create new object.

=head2 instance

Create singleton object and return it.

=head2 register( $class, @args )

=head2 register( $class_or_name, $initialize_code )

=head2 register( { class => $class_or_name ... } )

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

If you want to initialize and register at the same time, the following can.

    Object::Container->register({ class => 'LWP::UserAgent', preload => 1 });

I<initializer> option can be specified.

    Object::Container->register({ class => 'WWW::Mechanize', initializer => sub {
        my $mech = WWW::Mechanize->new( stack_depth );
        $mech->agent_alias('Windows IE 6');
        return $mech;
    }, preload => 1 });

This is the same as written below.

    Object::Container->register('WWW::Mechanize', sub {
        my $mech = WWW::Mechanize->new( stack_depth );
        $mech->agent_alias('Windows IE 6');
        return $mech;
    });
    Object::Container->get('WWW::Mechanize');

If you specify I<args> option is:

    Object::Container->register({ class => 'LWP::UserAgent', args => \@args, preload => 1 });

It is, as you know, the same below.

    Object::Container->register('LWP::UserAgent', @args);
    Object::Container->get('LWP::UserAgent');

=head2 unregister($class_or_name)

Unregister classes from container.

=head2 get($class_or_name)

Get the object that registered by 'register' method.

First argument is same as 'register' method.

=head2 remove($class_or_name)

Remove the cached object that is created at C<get> method above.

Return value is the deleted object if it's exists.

=head2 ensure_class_loaded($class)

This is utility method that load $class if $class is not loaded.

It's useful when you want include dependency in initializer and want lazy load the modules.

=head2 load_all

=head2 load_all_except(@classes_or_names)

This module basically does lazy object initializations, but in some situation, for Copy-On-Write or for runtime speed for example, you might want to preload objects.
For the purpose C<load_all> and C<load_all_except> method are exists.

    Object::Container->load_all;

This method is load all registered object at once.

Also if you have some objects that keeps lazy loading, do like following:

    Object::Container->load_all_except(qw/Foo Bar/);

This means all objects except 'Foo' and 'Bar' are loaded.

=head1 EXPORT FUNCTIONS ON SUBCLASS INTERFACE

Same functions for C<load_all> and C<load_all_except> exists at subclass interface.
Below is list of these functions.

=head2 preload(@classes_or_names)

=head2 preload_all

=head2 preload_all_except

As predictable by name, C<preload_all> is equals to C<load_all> and C<preload_all_except> is equals to <load_all_except>.

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
