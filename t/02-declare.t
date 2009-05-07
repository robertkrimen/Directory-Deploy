#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Directory::Scratch;
use Directory::Deploy;

package t::Deploy;

use Directory::Deploy::Declare;

file 'apple', \<<_END_;
Hello, World.
_END_

dir 'banana';

file '/cherry/grape', \<<_END_;
Mmm, fruity.
_END_

dir 'lime//';

no Directory::Deploy::Declare;

1;

package main;

my ($scratch, $deploy, $manifest);

sub test {

    ok( -f $scratch->file( 'apple' ) );
    ok( -s _ );
    is( $scratch->read( 'apple' )."\n", <<_END_ );
Hello, World.
_END_

    ok( -d $scratch->dir( 'banana' ) );

    ok( -f $scratch->file( 'cherry/grape' ) );
    ok( -s _ );
    is( $scratch->read( 'cherry/grape' )."\n", <<_END_ );
Mmm, fruity.
_END_

    ok( -d $scratch->dir( 'lime' ) );
}

{
    $scratch = Directory::Scratch->new;
    $deploy = t::Deploy->new( base => $scratch->base );

    $deploy->deploy;

    ok( $deploy->manifest->entry( 'apple' ) );

    test;
}

{
    $scratch = Directory::Scratch->new;
    t::Deploy->deploy( { base => $scratch->base } );

    test;
}

1;
