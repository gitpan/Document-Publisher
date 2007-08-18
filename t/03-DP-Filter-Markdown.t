#!perl -T

use strict;
use warnings;

use Test::More (0 ? (tests => 12) : 'no_plan');

use Document::Publisher::Document;
use Document::Publisher::Filter::Markdown;
use Directory::Scratch;

my $scratch = new Directory::Scratch;
$scratch->create_tree({
	'a.tt2.txt' => <<_END_
This is a.txt

This is some **markdown** text!
_END_
});
my $dir = $scratch->base;

my $dcmt = new Document::Publisher::Document file => $dir->file('a.tt2.txt');
my $fltr = new Document::Publisher::Filter::Markdown;
$fltr->run($dcmt);

is($dcmt->content, <<_END_);
<p>This is a.txt</p>

<p>This is some <strong>markdown</strong> text!</p>
_END_
