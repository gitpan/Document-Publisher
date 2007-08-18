package Document::Publisher::Filter::TT;

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
	my $template_context = shift;

	my $engine = $self->cnfg->{engine} || {};
	$engine = new Template($engine) unless blessed $engine && $engine->isa("Template");

	$template_context ||= $self->cnfg->{context} || {};
	$template_context = $template_context->($dcmt, $cntx) if ref $template_context eq "CODE";

	my $error = $self->cnfg->{error} || sub { die shift, "\n" };

	my $content;
	$engine->process($dcmt->content, $template_context, \$content) or $error->($engine->error, $dcmt, $cntx, $engine);
	$dcmt->content(\$content);
}

1;
