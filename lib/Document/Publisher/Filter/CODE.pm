package Document::Publisher::Filter::CODE;

use strict;
use warnings;

use Template;
use Scalar::Util qw/blessed/;
use Carp;

use base qw/Document::Publisher::Filter/;

sub run {
	my $self = shift;
	my $dcmt = shift;
	my $cntx = shift;
	my $code = shift;

	$code->($dcmt, $cntx, @_);
}

1;
