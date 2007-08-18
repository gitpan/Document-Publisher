package Document::Publisher::Filter;

use strict;
use warnings;

use Scalar::Util qw/blessed/;

use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/cnfg/);

sub DEFAULT_CNFG {}

sub new {
	my $self = bless {}, shift;
	my $cnfg = shift if ref $_[0] eq 'HASH';
	$cnfg ||= {};

	if (my $default_cnfg = $self->DEFAULT_CNFG) {
		while (my ($name, $value) = each %$default_cnfg) {
			$cnfg->{$name} = $value unless exists $cnfg->{$name};
		}
	}

	$self->cnfg($cnfg);

	return $self;
}

sub run {
	die "Don't know what to do"
}

1;
