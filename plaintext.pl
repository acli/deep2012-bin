#!/usr/bin/perl
# vi: set sw=4 ai sm:
#
# Very simple/sloppy script to remove HTML tags, for testing purposes only.

use strict;
use integer;
use utf8;

use CGI;

binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $buf = '';
while (<>) {
    $buf .= $_;
}
$buf =~ s/<(?:[^<>""'']|'[^'']*'|"[^""]*")*>//sg;
print $buf;
