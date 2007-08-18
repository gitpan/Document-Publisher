package Document::Publisher::Document;

use strict;
use warnings;

use Scalar::Util qw/blessed/;
use File::Spec();
use Path::Class();

use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/file meta _meta_dir _content/);

sub new {
	my $self = bless {}, shift;
	local %_ = @_;
	my $file = $self->file(Path::Class::file $_{file});
	my $meta = $self->meta($_{meta} || {});
    	my ($volume, $dir, $filename) = File::Spec->splitpath($file);
	my $meta_dir = File::Spec->catpath($volume, $dir, ".$filename");
	$self->_meta_dir(Path::Class::dir $meta_dir);
	return $self;
}

sub content {
	my $self = shift;
	return $self->_content(@_) if @_;
	return $self->_content if $self->{got_content};
	$self->{got_content} = 1;
	undef local $/;
    return $self->_content(\$self->file->slurp);
}

sub meta_dir {
    my $self = shift;
	
	my $meta_dir = $self->_meta_dir->subdir(@_);
	$meta_dir->mkpath unless -d $meta_dir;
	return $meta_dir;
}

sub meta_file {
	my $self = shift;
	my $meta_file = $self->_meta_dir->file(@_);
	$meta_file->parent->mkpath unless -d $meta_file->parent;
	return $meta_file;
}

sub print {
	my $self = shift;
	my $out = shift || \*STDOUT;
	$out = $out->openw if blessed $out && $out->isa('Path::Class::File');
	$out->print(${ $self->content });
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
