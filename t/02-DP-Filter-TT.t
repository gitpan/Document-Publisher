#!perl -T

use strict;
use warnings;

use Test::More (0 ? (tests => 12) : 'no_plan');

use Document::Publisher::Document;
use Document::Publisher::Filter::TT;
use Directory::Scratch;

my $scratch = new Directory::Scratch;
$scratch->create_tree({
	'a.tt2.txt' => <<_END_
[% BLOCK block %]
This is a block.
[% END %]

[% INCLUDE block %]
This is a.txt
[% INCLUDE block %]

_END_
});
my $dir = $scratch->base;

my $dcmt = new Document::Publisher::Document file => $dir->file('a.tt2.txt');
my $fltr = new Document::Publisher::Filter::TT;
$fltr->run($dcmt);

is(${ $dcmt->content }, <<_END_);



This is a block.

This is a.txt

This is a block.



_END_
