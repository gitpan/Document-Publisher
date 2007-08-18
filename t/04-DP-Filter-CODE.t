#!perl -T

use strict;
use warnings;

use Test::More (0 ? (tests => 12) : 'no_plan');

use Document::Publisher::Document;
use Document::Publisher::Filter::CODE;
use Directory::Scratch;

my $scratch = new Directory::Scratch;
$scratch->create_tree({
	'a.txt' => 'This is a.txt',
});
my $dir = $scratch->base;

my $dcmt = new Document::Publisher::Document file => $dir->file('a.txt');
my $fltr = new Document::Publisher::Filter::CODE;
my $code = sub {
        my $dcmt = shift;
        $dcmt->meta->{a} = 1;
};
$fltr->run($dcmt, undef, $code);

is($dcmt->meta->{a}, 1);
