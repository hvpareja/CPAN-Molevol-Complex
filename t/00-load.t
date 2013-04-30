#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Coevolution::Compcoe' ) || print "Bail out!\n";
}

diag( "Testing Coevolution::Compcoe $Coevolution::Compcoe::VERSION, Perl $], $^X" );
