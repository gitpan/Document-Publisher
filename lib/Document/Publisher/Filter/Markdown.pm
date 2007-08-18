package Document::Publisher::Filter::Markdown;

use strict;
use warnings;

use Text::Markdown qw/markdown/;
use Carp;

use base qw/Document::Publisher::Filter/;

sub run {
	my $self = shift;
	my $dcmt = shift;

	my $content;
	$content = markdown(${ $dcmt->content }, $self->cnfg);
	$dcmt->content($content);
}

1;
