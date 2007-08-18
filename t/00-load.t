#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Document::Publisher' );
}

diag( "Testing Document::Publisher $Document::Publisher::VERSION, Perl $], $^X" );
