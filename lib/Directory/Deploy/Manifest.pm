package Directory::Deploy::Manifest;

use Moose;

use Directory::Deploy::Carp;

use Path::Abstract;
use Scalar::Util qw/looks_like_number/;

has _entry_map => qw/is ro required 1/, default => sub { {} };

sub normalize_path {
    my $self = shift;
    my $path = shift;

    croak "Wasn't given a path" unless defined $path;

    $path = Path::Abstract->new( $path );
    s/^\///, s/\/$// for $$path;
    return $path;
}

sub _enter {
    my $self = shift;
    my $entry = shift;
    $self->_entry_map->{$entry->path} = $entry;
    return $entry;
}

sub add {
    my $self = shift;
    croak "Wasn't given anything to add" unless @_;
    my $kind = shift;
    croak "You didn't specify a kind" unless defined $kind;
    
    if ($kind eq 'file') {
        $self->file( @_ );
    }
    elsif ($kind eq 'dir') {
        $self->dir( @_ );
    }
    else {
        croak "Don't understand kind $kind";
    }
}
sub file {
    my $self = shift;
    my %entry;
    if (1 == @_) {
        $entry{path} = shift;
    }
    elsif (2 == @_ && ref $_[1] eq 'SCALAR') {
        $entry{path} = shift;
        $entry{content} = shift;
    }
    elsif (3 == @_) {
        $entry{path} = shift;
        if (ref $_[0] eq 'SCALAR' && $_[1] =~ m/^\d+$/) {
            $entry{content} = shift;
            $entry{mode} = shift;
        }
        elsif (ref $_[1] eq 'SCALAR' && $_[0] =~ m/^\d+$/) {
            $entry{mode} = shift;
            $entry{content} = shift;
        }
    }
    elsif (@_ % 2) {
        $entry{path} = shift;
    }

    my $entry = Directory::Deploy::Manifest::File->new( %entry, @_ );
    $self->_enter( $entry );
    return $entry;
}

sub dir {
    my $self = shift;
    my %entry;
    if (1 == @_) {
        $entry{path} = shift;
    }
    elsif (@_ % 2) {
        $entry{path} = shift;
    }

    my $entry = Directory::Deploy::Manifest::Dir->new( %entry, @_ );
    $self->_enter( $entry );
    return $entry;
}

sub lookup {
    my $self = shift;
    my $path = shift;

    croak "Wasn't given a path" unless defined $path;

    $path = $self->normalize_path( $path );

    return $self->_entry_map->{$path};
}

sub entry {
    return shift->lookup( @_ );
}

sub each {
    my $self = shift;
    my $code = shift;

    for (sort keys %{ $self->_entry_map }) {
        $code->( $self->lookup( $_ ), @_ );
    }
}

#has parser => qw/is ro required 1 isa CodeRef/, default => sub { sub {
#    my $self = shift;
#    chomp;
#    return if m/^\s*$/ || m/^\s*#/;
#    my ($path, $comment) = m/^\s*([^#\s]+)(?:\s*#\s*(.*))?$/;
#    s/^\s*//, s/\s*$// for $path;
#    $self->add(path => $path, comment => $comment);
#} };
#has _entry_list => qw/is ro required 1/, default => sub { {} };

#sub _entry {
#    my $self = shift;
#    return $_[0] if @_ == 1 && blessed $_[0];
#    return Directory::Deploy::Manifest::Om::Manifest::Entry->new(@_);
#}

#sub entry_list {
#    return shift->_entry_list;
#}

#sub entry {
#    my $self = shift;
#    return $self->_entry_list unless @_;
#    my $path = shift;
#    return $self->_entry_list->{$path};
#}

#sub all {
#    my $self = shift;
#    return sort { $a cmp $b } keys %{ $self->_entry_list };
#}

#sub add {
#    my $self = shift;
#    my $entry = $self->_entry(@_);
#    $self->_entry_list->{$entry->path} = $entry;
#}

#sub each {
#    my $self = shift;
#    my $code = shift;

#    for (sort keys %{ $self->_entry_list }) {
#        $code->($self->entry->{$_})
#    }
#}

#sub include {
#    my $self = shift;

#    while (@_) {
#        local $_ = shift;
#        if ($_ =~ m/\n/) {
#            $self->_include_list($_);
#        }
#        else {
#            my $path = $_;
#            my %entry;
#            %entry = %{ shift() } if ref $_[0] eq 'HASH';
#            # FIXME Should we do it this way?
#            my $comment = delete $entry{comment};
#            $self->add(path => $_, comment => $comment, stash => { %entry });
#        }
#    }
#}

#sub _include_list {
#    my $self = shift;
#    my $list = shift;

#    for (split m/\n/, $list) {
#        $self->parser->($self);
#    }
#}

package Directory::Deploy::Manifest::DoesEntry;

use Moose::Role;

requires qw/is_file/;

has mode => qw/is rw isa Maybe[Int]/;
has path => qw/is ro required 1/;
has comment => qw/is rw isa Maybe[Str]/;
has content => qw/is rw/;

sub BUILD {
    my $self = shift;
    $self->{path} = Directory::Deploy::Manifest->normalize_path( $self->path );
}

sub is_dir { return ! shift->is_file }

package Directory::Deploy::Manifest::File;

use Moose;

with qw/Directory::Deploy::Manifest::DoesEntry/;

sub is_file { 1 }

package Directory::Deploy::Manifest::Dir;

use Moose;

with qw/Directory::Deploy::Manifest::DoesEntry/;

sub is_file { 0 }

1;

__END__

use Moose;

has comment => qw/is ro isa Maybe[Str]/;
has stash => qw/is ro required 1 isa HashRef/, default => sub { {} };
has process => qw/is rw isa Maybe[Str|HashRef]/;

sub content {
    return shift->stash->{content};
}

sub copy_into {
    my $self = shift;
    my $hash = shift;
    while (my ($key, $value) = each %{ $self->stash }) {
        $hash->{$key} = $value;
    }
}

1;
