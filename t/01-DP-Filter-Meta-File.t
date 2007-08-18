#!perl -T

use strict;
use warnings;

use Test::More (0 ? (tests => 12) : 'no_plan');

use Document::Publisher::Document;
use Document::Publisher::Filter::Meta::File;
use Directory::Scratch;

my $scratch = new Directory::Scratch;
$scratch->create_tree({
	'a.txt' => 'This is a.txt',
});
my $dir = $scratch->base;

my $dcmt = new Document::Publisher::Document file => $dir->file('a.txt');
my $fltr = new Document::Publisher::Filter::Meta::File;
$fltr->run($dcmt, undef, [qw(insert_time update_time)]);

ok($scratch->exists(".a.txt"), ".a.txt");
ok($scratch->exists(".a.txt/meta.yml"), ".a.txt/meta.yml");
