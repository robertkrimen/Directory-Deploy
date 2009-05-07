package Directory::Deploy::Declare;

use strict;
use warnings;

use Directory::Deploy::Carp;

use Moose();
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    with_caller => [qw/ file dir /],
    also => [qw/ Moose /],
);

sub init_meta {
    shift;
    return Moose->init_meta( base_class => 'Directory::Deploy::Declare::Base', @_ );
}

sub initialize {
    shift;
    my $class = shift;

    return $class->deploy_meta if $class->can( 'deploy_meta' );

    my $deploy_meta = Directory::Deploy::Declare::Meta->new;
    $class->meta->add_method( deploy_meta => sub {
        return $deploy_meta;
    } );

    return $deploy_meta;
}

sub file {
    my $class = shift;
    __PACKAGE__->initialize( $class )->add_entry( file => @_ );
}


sub dir {
    my $class = shift;
    __PACKAGE__->initialize( $class )->add_entry( dir => @_ );
}

1;

package Directory::Deploy::Declare::Meta;

use strict;
use warnings;

use Moose;
use MooseX::AttributeHelpers;

has _entry_list => qw/metaclass Collection::Array is ro isa ArrayRef/, default => sub { [] }, provides => {qw/
    push        _add_entry
    elements    _entries
/};

sub build {
    my $self = shift;
    my $deploy = shift;
    my $given = shift; # Called from BUILD

    for my $entry ($self->_entries) {
        $deploy->add( @$entry );
    }
}

sub add_entry {
    shift->_add_entry( [ @_ ] );
}

1;

package Directory::Deploy::Declare::Base;

use strict;
use warnings;

use Moose;

extends qw/Directory::Deploy/;

sub BUILD {
    my $self = shift;
    $self->BUILD_deploy( @_ );
}

sub BUILD_deploy {
    my $self = shift;
    if (my $method = $self->can( 'deploy_meta' ) ) {
        $method->()->build( $self, @_ );
    }
}

1;
__END__

our $CALLER; # Sub::Exporter doesn't make this available

my $exporter = Sub::Exporter::build_exporter({
    into_level => 1,
    groups => {
        default => \&build_sugar,
    },
});

sub import {
    my $self = shift;
    my $pkg  = caller;

    my @args = grep { !/^-base$/i } @_;

    # just loading the class..
    return if @args == @_;

    do {
        no strict 'refs';
        push @{ $pkg . '::ISA' }, $self;
    };

    local $CALLER = $pkg;

    $exporter->($self, @args);
}

sub build_sugar {
    my ($class, $group, $arg) = @_;

    my $into = $CALLER;

    $class->populate_defaults($arg);

    my $dispatcher = $class->dispatcher_class->new(name => $into);

    my $builder = $class->builder_class->new(
        dispatcher => $dispatcher,
        %$arg,
    );

    return {
        dispatcher    => sub { $builder->dispatcher },
        rewrite       => sub { $builder->rewrite(@_) },
        on            => sub { $builder->on(@_) },
        under         => sub { $builder->under(@_) },
        redispatch_to => sub { $builder->redispatch_to(@_) },
        next_rule     => sub { $builder->next_rule(@_) },
        last_rule     => sub { $builder->last_rule(@_) },

        then  => sub (&) { $builder->then(@_) },
        chain => sub (&) { $builder->chain(@_) },

        # NOTE on shift if $into: if caller is $into, then this function is
        # being used as sugar otherwise, it's probably a method call, so
        # discard the invocant
        dispatch => sub { shift if caller ne $into; $builder->dispatch(@_) },
        run      => sub { shift if caller ne $into; $builder->run(@_) },
    };
}
