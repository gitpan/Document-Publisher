use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Document::Publisher',
    license             => 'perl',
    dist_author         => 'Robert Krimen <rkrimen@cpan.org>',
    dist_version_from   => 'lib/Document/Publisher.pm',
    build_requires => {
        'Test::More' => 0,
    	map {
            chomp;
            my ($module, $version) = split m/\s+/;
            $version = 0 unless $version;
            ($module => $version)
        } grep { ! m/^\s*#/ } split m/\n/, <<_END_,
Directory::Scratch
_END_
    },
    requires => {
    	map {
            chomp;
            my ($module, $version) = split m/\s+/;
            $version = 0 unless $version;
            ($module => $version)
        } grep { ! m/^\s*#/ } <DATA>,
    },
    create_makefile_pl => 'traditional',
    add_to_cleanup      => [ 'Document-Publisher-*' ],
);

$builder->create_build_script();

__DATA__
File::Path
File::Spec
Getopt::Long
Path::Class
Scalar::Util
Template
Text::Markdown
YAML
