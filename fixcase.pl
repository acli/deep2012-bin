#!/usr/bin/perl
# vi: set sw=4 ai sm:
#
# Attempt to put an all-uppercase DEEP 2012 transcript into mixed case.
# Obviously this involves a huge amount of guesswork.
#
# Fortunately these all-uppercase transcripts follow typewriting conventions,
# so at least we don't have to guess where the end of sentences are.

use strict;
use integer;
use utf8;

use CGI;

sub fix_proper_name ($) {
    my($s) = @_;
    $s = join(' ', map { ucfirst($_) } split(/\s+/, $s));
    $s = join('-', map { ucfirst($_) } split(/-/, $s));
    return $s;
}

sub fixcase ($) {
    my($s) = @_;
    $s =~ s/‑/-/g; # I have no idea what this is
    $s = ucfirst(lc($s));
    $s =~ s/(>>)(\S[^:]*)(:\s*)(\S+)/ $1 . fix_proper_name($2) . $3 . ucfirst($4) /sge;
    $s =~ s/(>>)\s+(\S+)/ $1 . ucfirst($2) /sge;
    $s =~ s/(\s+|^)(?:--|‑‑)(\s+)/\1—\2/sg;
    # Weird transcriptions (or maybe it's because it's all uppercase)
    $s =~ s/\b(i)(?:-|‑)(pad|phone)\b/\1\u\2/sgi;
    # Pretty sure given the context
    $s =~ s/\b(crpd|p\&g)\b/\U\1/gi;
    $s =~ s/\b(room\s\d+)\b/\u\1/g;
    $s =~ s/\b(axel\s+leblois|donovan|d'intino|europe|jutta|mike|(?:north\s+)?america|pina|richard|rich's|toronto|treviranus|walgreen|wal-mart)\b/ fix_proper_name($1) /sge;
    $s =~ s/\b(invite\s+)(rich)\b/ $1 . fix_proper_name($2) /sge;
    $s =~ s/'/’/sg; # Do this last
    # Plain guesses
    $s =~ s/\b(3d|i)\b/\U\1/sg;
    $s =~ s/\b(u\.s\.)/\U\1/sg;
    return $s;
}

binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $sentence = '';
my $buffer = '';

for (my $bom_removed = 0;;) {
    my $s = scalar <>;
last unless defined $s;
    chomp $s;
    if (!$bom_removed && $s =~ /^(?:\xef\xbb\xbf|\x{feff})/) {
	$bom_removed = 1;
	$s = $';
    }

    $buffer .= "\n" if $buffer;
    $buffer .= $s;

    while ($buffer =~ /^((?:(?!\s\s|\s*\n+\s*).)+)(?:\s{2,}|\s*\n+\s*)/s) {
	$buffer = $';
	print fixcase($&);
    }
}
print fixcase($buffer);
print "\n";
