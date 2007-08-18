package Document::Publisher::Filter::Meta::File;

use strict;
use warnings;

use base qw/Document::Publisher::Filter::Meta/;

sub DEFAULT_CNFG { {
	persist => 1,
} }

{ my $META; sub META { return $META ||= new Document::Publisher::Filter::Meta::File::FileAttributesSimple } }

sub _load {
	my $self = shift;
	my $dcmt = shift;
	my $cntx = shift;
	my $meta = shift;

	eval {
		$meta = META->_load($dcmt->meta_file("meta.yml"));
	};
	$meta = {} if $@;

	return $self->SUPER::_load($dcmt, $cntx, $meta, @_);
}

sub persist {
	my $self = shift;
	my $dcmt = shift;
	my $meta = shift;

	META->_save($dcmt->meta_file("meta.yml"), $meta);
}

1;

package Document::Publisher::Filter::Meta::File::FileAttributesSimple;

use File::Spec;
use File::Path qw/mkpath/;

use base qw/File::Attributes::Simple/;

sub _attribute_file {
    my $self = shift;
    my $file = shift;

    return $file;

#    my $mx = 10;
#    while($mx-- && -l $mx) {
#        $mx = readlink $mx;
#    }

#    
#    my ($volume, $dir, $filename) = File::Spec->splitpath($file);
#    my $meta_dir = File::Spec->catpath($volume, $dir, ".$filename");
#    mkpath $meta_dir unless -d $meta_dir;
#    return File::Spec->catpath($volume, File::Spec->catdir($dir, ".$filename"), "meta.yml");
}

1;
