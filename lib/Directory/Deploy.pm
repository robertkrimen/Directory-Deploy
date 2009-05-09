package Directory::Deploy;

use warnings;
use strict;

=head1 NAME

Directory::Deploy -

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

=cut

use Moose;

use Directory::Deploy::Carp;
use Directory::Deploy::Manifest;
use Directory::Deploy::Maker;

use Path::Class();

has manifest => qw/is ro lazy_build 1/, handles => [qw/ add include /];
sub _build_manifest {
    return Directory::Deploy::Manifest->new();
}

has maker => qw/is ro lazy_build 1/;
sub _build_maker {
    my $self = shift;
    return Directory::Deploy::Maker->new( deploy => $self );
}

has base => qw/accessor _base required 1/;
sub base {
    my $self = shift;
    return $self->_base( @_ );
}

sub BUILD {
    my $self = shift;

    $self->_base( Path::Class::Dir->new( $self->_base ) );
}

sub file {
    return shift->base->file( @_ );
}

sub dir {
    return shift->base->subdir( @_ );
}

sub deploy {
    my $self = shift;
    if (! ref $self) { # Invoked as a class method
        my $new_arguments;
        $new_arguments = shift if ref $_[0] eq 'HASH';
        return $self->new( $new_arguments )->deploy( @_ );
    }

    $self->manifest->each( sub {
        my ($entry) = @_;
        $self->maker->make( $entry );
    } );
}

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-directory-deploy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Directory-Deploy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Directory::Deploy


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Directory-Deploy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Directory-Deploy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Directory-Deploy>

=item * Search CPAN

L<http://search.cpan.org/dist/Directory-Deploy/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Directory::Deploy
