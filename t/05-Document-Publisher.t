#!perl -T

use strict;
use warnings;

use Test::More (0 ? (tests => 12) : 'no_plan');

use Document::Publisher;
use Directory::Scratch;

use constant Publisher => "Document::Publisher";

my $src = new Directory::Scratch;
$src->create_tree({
        'a.txt' => 'This is a.txt',
	'b.tt2.html' => <<_END_
[% BLOCK block %]
This is a block.
[% END %]

[% INCLUDE block %]
This is b.tt2.html
[% INCLUDE block %]

_END_
});
my $src_dir = $src->base;

my $dst = new Directory::Scratch;
$dst->create_tree({
});
my $dst_dir = $dst->base;

#is(Publisher->_parse_type(".tt2.html"), "/tt2/html");
#is(Publisher->_parse_type("html"), "/html");
#is(Publisher->_parse_type("alpha:"), "alpha:");
#is(Publisher->_parse_type("beta:.markdown"), "beta:/markdown");

#is(Publisher->_parse_type_from_filename("/a/b/c/d.txt"), "/txt");
#is(Publisher->_parse_type_from_filename("/a/b/c/e"), "/");
#is(Publisher->_parse_type_from_filename("/a/b/c/f.tt2.cfg"), "/tt2/cfg");

my $publisher = Publisher->new([
	qr/\.tt2\.html$/ => [
		'Meta::File' => [qw(insert_time update_time)],
		'TT',
	],
	qr/\.txt$/ => [
	],
	qr/c:.*\.txt$/ => [
	],
]);

$publisher->publish($src_dir->file('a.txt'), $dst_dir->file('a.txt'));
$publisher->publish($src_dir->file('b.tt2.html'), $dst_dir->file('b.tt2.html'));
ok($dst->exists("a.txt"), "a.txt exists");
ok($dst->exists("b.tt2.html"), "b.tt2.html exists");
is($dst->read("b.tt2.html"), <<_END_);



This is a block.

This is b.tt2.html

This is a block.


_END_

Publisher->Publish([
		'--in', $src_dir->file('a.txt')->stringify,
		'--out', $dst_dir->file('b.txt')->stringify,
	], $publisher);
ok($dst->exists("b.txt"), "b.txt exists");

Publisher->Publish([
		'--in', $src_dir->file('b.tt2.html')->stringify,
		'--out', $dst_dir->file('c.txt')->stringify,
		'--pntr', "c:.txt",
	], $publisher);
ok($dst->exists("c.txt"), "c.txt exists");
is($dst->read("c.txt"), <<_END_);
[% BLOCK block %]
This is a block.
[% END %]

[% INCLUDE block %]
This is b.tt2.html
[% INCLUDE block %]

_END_
