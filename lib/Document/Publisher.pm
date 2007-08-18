package Document::Publisher;

use warnings;
use strict;

=head1 NAME

Document::Publisher - Document::Publisher

=head1 VERSION

Version 0.01_02

=cut

our $VERSION = '0.01_02';

=head1 SYNOPSIS

=cut

use Scalar::Util qw (blessed);
use Path::Class;
use Document::Publisher::Document;
use Getopt::Long qw(GetOptions);

use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/recipe/);

sub Publish {
	my $class = shift;
	my $ARGV = shift;
	my $publisher = shift;

	$publisher = __PACKAGE__->new($publisher) if ref $publisher eq 'ARRAY';

	local @ARGV = @$ARGV;
	my ($in, $out, $pntr);
	my $verbose = 0;
	my $debug = 0;
	my $trace = 0;
	my $test = 0;

	$in = shift @ARGV if @ARGV && $ARGV[0] !~ m/^-/;
	$out = shift @ARGV if @ARGV && $ARGV[0] !~ m/^-/;
	$pntr = shift @ARGV if @ARGV && $ARGV[0] !~ m/^-/;
	
	GetOptions(verbose => \$verbose,
		'in=s' => \$in,
		'out=s' => \$out,
		'pntr:s' => \$pntr,
		test => \$test, trace => \$trace, debug => \$debug) or Getopt::Long::HelpMessage(2);
	$trace |= ($debug || $test);

	$publisher->publish($in, $out, $pntr);
}

sub new {
	my $self = bless {}, shift;
	my ($recipe);
	$recipe = shift @_ if ref $_[0] eq 'ARRAY';
	local %_ = @_;
	$recipe ||= $_{recipe};

	my (@recipe, @_recipe);
	@_recipe = @$recipe if $recipe;

	while (@_recipe) {
		my $pntr = shift @_recipe;
		my $filter_lst = shift @_recipe;

		my (@filter_lst, @_filter_lst);
		@_filter_lst = @$filter_lst;
		while (@_filter_lst) {
			my ($filter, $at_);
			$filter = shift @_filter_lst;
			my @at_;
			if (ref $filter eq 'CODE') {
				@at_ = ($filter);
				$filter = "CODE";
			}
			else {
				if (ref $_filter_lst[0] eq 'HASH') {
					@at_ = (shift @_filter_lst);
				}
				else {
					@at_ = @{ shift @_filter_lst || [] };
				}
			}

			if (ref $filter eq '') {
				$filter = "Document::Publisher::Filter::$filter";
				eval "require $filter";
				die $@ if $@;

#				my @cnfg;
#				@cnfg = shift @at_ if ref $at_[0] eq 'HASH';
#				$filter = $filter->new(@cnfg); }

				$filter = $filter->new;
			}

			push @filter_lst, $filter, \@at_;
		}

		push @recipe, $pntr => \@filter_lst;
	}
	$self->recipe(\@recipe);

	return $self;
}

sub publish {
	my $self = shift;
        my $in = shift;
        my $out = shift;
	my $pntr = shift;

	$in = Path::Class::file $in unless blessed $in;
	$out = Path::Class::file $out unless blessed $out;

	my $filter_lst;
	if (ref $pntr eq "ARRAY") {
		my (@filter_lst, @_filter_lst);
		@_filter_lst = @$pntr;
		while (@_filter_lst) {
			my ($filter, $at_);
			$filter = shift @_filter_lst;
			my @at_;
			if (ref $filter eq 'CODE') {
				@at_ = ($filter);
				$filter = "CODE";
			}
			else {
				if (ref $_filter_lst[0] eq 'HASH') {
					@at_ = (shift @_filter_lst);
				}
				else {
					@at_ = @{ shift @_filter_lst || [] };
				}
			}

			if (ref $filter eq '') {
				$filter = "Document::Publisher::Filter::$filter";
				eval "require $filter";
				die $@ if $@;
				$filter = $filter->new;
			}

			push @filter_lst, $filter, \@at_;
		}
		$filter_lst = \@filter_lst;
	}
	else {
		$pntr = $in->stringify unless defined $pntr;

		my @recipe = @{ $self->recipe };
		while (@recipe) {
			my $target_pntr = shift @recipe;

			if (ref $target_pntr eq "Regexp") {
				shift @recipe, next unless $pntr =~ $target_pntr;
			}
			else {
				shift @recipe, next unless $pntr eq $target_pntr;
			}

			$filter_lst = shift @recipe;
			last;
		}
	}

	die "Couldn't find filter list for ($in) ($pntr)" unless $filter_lst;
	
	my $dcmt = new Document::Publisher::Document file => $in;

	my $cntx = { in => $in, out => $out, dcmt => $dcmt, pntr => $pntr, publisher => $self };
        my @filter_lst = @$filter_lst;
	while (@filter_lst) {
		my $filter = shift @filter_lst;
		my $at_ = shift @filter_lst;

		$filter->run($dcmt, $cntx, @$at_);

		last if $cntx->{skip};
	}

        unless ($cntx->{skip}) {
                $dcmt->print($out);
        }
}

1;

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-document-publisher at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Document-Publisher>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Document::Publisher

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Document-Publisher>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Document-Publisher>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Document-Publisher>

=item * Search CPAN

L<http://search.cpan.org/dist/Document-Publisher>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Document::Publisher

__END__

sub _parse_type {
	shift;
	my $_type = shift;

	my ($namespace, $type);
	if ($_type =~ m/:/) {
		($namespace, $type) = split m/:/, $_type, 2;
	}
	else {
		($namespace, $type) = ('', $_type);
	}

	$type =~ tr/\./\//;
	$type = "/$type" unless $type =~ m/^\//;

	die "Don't understand type ($namespace:$type)" if $type =~ m/\/\//;
	die "Don't understand type ($namespace:$type)" if $type !~ m/^[\/\w]+$/;
	die "Don't understand type ($namespace:$type)" if $namespace !~ m/^[\w]*$/;

	$type = "$namespace:$type";
	$type =~ s/^:// and return $type;
	$type =~ s/:\/$/:/ and return $type;
	return $type;
}

sub TYPE_PTTN_LST {
	return [ 
		qr/(\.tt2\.[\w]+)$/,
		qr/(\.[\w]+)$/,
	]
}

sub _parse_type_from_filename {
	shift;
	my $file = shift;
	my $type_pttn_lst = shift || TYPE_PTTN_LST;
	for my $type_pttn (@$type_pttn_lst) {
		return __PACKAGE__->_parse_type($1) if $file =~ m/$type_pttn/;
	}
	return __PACKAGE__->_parse_type('');
}

sub _parse_pntr {
	shift;
	my $pntr = shift;
	return $pntr if $pntr =~ m/=$/;
	return __PACKAGE__->_parse_type($pntr);
}

sub new {
	my $self = bless {}, shift;
	local %_ = @_;
	my $filter_cnfg = $_{filter_cnfg} || [];
	my $type_pttn_lst = $_{type_pttn_lst} || [];

	$self->type_pttn_lst([ @$type_pttn_lst, @{ TYPE_PTTN_LST() } ]);

	my (@filter_cnfg, @_filter_cnfg);
	@_filter_cnfg = @$filter_cnfg;

	while (@_filter_cnfg) {
		my $pntr = shift @_filter_cnfg;
		my $filter_lst = shift @_filter_cnfg;

		$pntr = __PACKAGE__->_parse_pntr($pntr) unless ref $pntr eq 'Regex';

		my (@filter_lst, @_filter_lst);
		@_filter_lst = @$filter_lst;
		while (@_filter_lst) {
			my ($filter, $at_);
			$filter = shift @_filter_lst;
			my @at_;
			if (ref $filter eq 'CODE') {
				@at_ = { code => $filter };
				$filter = "CODE";
			}
			else {
				if (ref $_filter_lst[0] eq 'HASH') {
					@at_ = (shift @_filter_lst);
				}
				else {
					@at_ = @{ shift @_filter_lst || [] };
				}
			}

			if (ref $filter eq '') {
				$filter = "Document::Publisher::Filter::$filter";
				eval "require $filter";
				die $@ if $@;
				my @cnfg;
				@cnfg = shift @at_ if ref $at_[0] eq 'HASH';
				$filter = $filter->new(@cnfg); }

			push @filter_lst, $filter, \@at_;
		}

		push @filter_cnfg, $pntr => \@filter_lst;
	}
	$self->filter_cnfg(\@filter_cnfg);

	return $self;
}

sub publish {
	my $self = shift;
        my $in = shift;
        my $out = shift;
	my $type = shift;

	$in = Path::Class::file $in unless blessed $in;
	$out = Path::Class::file $out unless blessed $out;

	my $dcmt = new Document::Publisher::Document file => $in;

	$type = __PACKAGE__->_parse_type_from_filename($in, $self->type_pttn_lst) unless $type;
	my $pntr = __PACKAGE__->_parse_pntr($type);

	my @filter_cnfg = @{ $self->filter_cnfg };
	my $filter_lst;
	while (@filter_cnfg) {
		my $filter_pntr = shift @filter_cnfg;

		if (ref $filter_pntr eq "Regex") {
			next unless $pntr =~ $filter_pntr;
		}
		else {
			next unless $pntr eq $filter_pntr;
		}

		$filter_lst = shift @filter_cnfg;
		last;
	}

	die "Couldn't find filter list for ($in) ($type) ($pntr)" unless $filter_lst;
	
	my $cntx = { in => $in, out => $out, dcmt => $dcmt, type => $type, pntr => $pntr, publisher => $self };
        my @filter_lst = @$filter_lst;
	while (@filter_lst) {
		my $filter = shift @filter_lst;
		my $at_ = shift @filter_lst;

		$filter->run($dcmt, $cntx, @$at_);

		last if $cntx->{skip};
	}

        unless ($cntx->{skip}) {
                $dcmt->print($out);
        }
}

#sub publish {
#        my $self = shift;
#        my $in = shift;
#        my $out = shift;

#        my $dcmt = new Document::Publisher::Document file => $in;
#        my $cntx = { dcmt => $dcmt, in => $in, out => $out, publisher => $self };

#        my @filter_lst = @{ $self->filter };
#        while (@filter_lst) {
#                my ($filter, $at_);
#                $filter = shift;
#                if (ref $filter eq 'CODE') {
#                        $at_ = [ code => $filter ];
#                        $filter = "CODE";
#                }
#                else {
#                        $at_ = shift || [];
#                }
#                if (ref $filter eq '') {
#                        $filter = "Document::Publisher::Filter::$filter"
#                        eval "require $class";
#                        die $@ if $@;
#                        my @cnfg;
#                        @cnfg = @{ shift @$at_ } if ref $at_->[0] eq 'HASH';
#                        $filter = $filter->new(@cnfg);
#                }

#                $filter->run($dcmt, $cntx, @$at_);

#                last if $self->skip;
#        }

#        unless ($self->skip) {
#                $dcmt->print($out);
#        }
#}

=pod

'.tt2.markdown' => [
	'$meta',
	'Meta::File' => [ { persist => 0 }, [qw(insert_time update_time)] ],
	'TT' => [ template => { sjd } ],
	'Markdown' => undef,
]

'.html' => [
]
	
=cut
1;
