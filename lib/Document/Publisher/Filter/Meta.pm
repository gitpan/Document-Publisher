package Document::Publisher::Filter::Meta;

use strict;
use warnings;

use Scalar::Util qw/blessed/;

use base qw/Document::Publisher::Filter/;

sub load {
	shift;
	my @load;
	for my $name (@_) {
		if ($name eq "insert_time") {
			push @load, $name => sub {
				return $_ || shift->file->stat->mtime;
			};
		}
		elsif ($name eq "update_time") {
			push @load, $name => sub {
				return shift->file->stat->mtime;
			};
		}
	}
	return @load;
}

sub run {
	my $self = shift;
	my $dcmt = shift;
	my $cntx = shift;

	my @load;
	my $load = $self->cnfg->{load};
	@load = __PACKAGE__->load(@{ $load }) if $load;

	my $meta = $self->_load($dcmt, $cntx, {}, @load, @_);
 
	$self->persist($dcmt, $meta) if $self->cnfg->{persist};
}

sub _load {
	my $self = shift;
	my $dcmt = shift;
	my $cntx = shift;
	my $meta = shift;

	my $dcmt_meta = $dcmt->meta;

	while (@_) {
		if (ref $_[0] eq 'ARRAY') {
			unshift @_, $self->load(@{ shift() });
			next;
		}
		my $name = shift @_;
		my $cmnd = shift @_;
		my $rslt = $cmnd;
		if (ref $rslt eq 'CODE') {
			local $_ = $meta->{$name};
			$dcmt_meta->{$name} = $meta->{$name} = $rslt->($dcmt, $dcmt_meta, $cntx, $_,
				$meta);
		}
		else {
			$dcmt_meta->{$name} = $meta->{$name} = $rslt;
		}
	}

	return $meta;
}

sub persist {
	die "Don't know how to persist";
}


1;
__END__

use Document::Publisher::Document::Meta::File;
use Path::Class();
use YAML;
use base qw|Class::Accessor|;
use Scalar::Util qw (blessed);
__PACKAGE__->mk_accessors(qw(file path meta));

{ my $meta; sub _meta { return $meta ||= new Document::Publisher::Document::Meta::File } }

sub new {
	my $self = bless {}, shift;
	local %_ = @_;
	my $file = $self->file($_{file});
#	my $path = $self->path($_{path} || Path::Class::file $file->basename);
	my $path = $_{path} || $file->basename;
	$path = Path::Class::file $path unless blessed $path;
	$self->path($path);
	my $insert_time;
	eval {
		$insert_time = _meta->get($file, "insert_time");
	};
	_meta->set($file, insert_time => $insert_time = $file->stat->mtime) unless $insert_time;
	my ($external_meta, $internal_meta, %meta) = ({}, {});
	$external_meta = _meta->_load($file);
	{
		my $content_file = $self->content_file;
		if (! -e $content_file || ($content_file->stat->mtime < $file->stat->mtime)) {
			my @content = $file->slurp;
#			if ($content[0] && $content[0] =~ m/^\s*---\s*\n?$/) {
			if ($content[0] && $content[0] =~ m/^\s*#\s* meta\b$/) {
				my @meta;
				shift @content;
				local $_;
				while ($_ = shift @content) {
					if ($_ && m/^\s*---\s*\n?$/) {
						last;
					}
					push @meta, $_;
				}
				$internal_meta = Load(join '', @meta, "\n") if @meta;
			}
			$self->content_file->openw->print(@content);
		}
	}
	%meta = (%$external_meta, %$internal_meta);
	$meta{update_time} ||= $self->update_time;
	$self->meta(\%meta);
	return $self;
}

sub name {
	my $self = shift;
	return $self->path->basename;
}

sub type {
	my $self = shift;
	my $name = $self->name;
	return $1 if $name =~ m{[.](\w+)$};
	return "plain";
}

sub content_file {
	my $self = shift;
	my $file = $self->file;
	return $file->parent->file(join '.', '', $file->basename, 'content');
}

sub insert_time {
	my $self = shift;
	return _meta->get($self->file, "insert_time");
}

sub update_time {
	my $self = shift;
	return $self->file->stat->mtime;
}

sub content {
	my $self = shift;
	undef local $/;
	return \$self->content_file->slurp;
}

1;
