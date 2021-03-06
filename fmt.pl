#!/usr/bin/perl
# vi: set sw=4 ai sm:
#
# Reformats a DEEP 2012 transcript, in plain text format, to something that
# resembles some sort of preliminary HTML code that can be posted into a
# WordPress site and tweaked.

use strict;
use integer;
use utf8;

use CGI;

use vars qw( $monolog );

sub escape ($;$) {
    # Escape the HTML, except that in WordPress > doesn’t really need to be
    # escaped and neither does & unless it forms a valid SGML entity
    my($s, $narration_mode) = @_;
    $s = CGI::escapeHTML($s);
    $s =~ s/\&gt;/>/g;
    $s =~ s/(?!\&amp;(?:\S+);)\&amp;/\&/g;

    # Attempt to mark up inaudibles and such
    # Note use of i. em is wrong in this context.
    my $tag = $narration_mode? 'div': 'span';
    my $spacing = $narration_mode? "\n\n": '';
    $s =~ s {(\[)\s*(applause|inaudible|cannot understand speaker|not able to hear video)\s*(\])}
	    {<$tag class=narration>$spacing\1<i>\2<\/i>\3$spacing<\/$tag>}i;
    return $s;
}

sub end_monolog () {
    print "\n</div>" if defined $monolog;
    undef $monolog;
}

sub new_monolog ($;$) {
    my($utterance, $speaker) = @_;
    end_monolog if defined $monolog;
    if (defined $speaker) {
	printf("<div class=monolog>\n\n>><span class=speaker>%s</span>: %s\n",
		escape($speaker), escape($utterance));
	$monolog = $speaker;
    } else {
	printf("<div class=monolog>\n\n>> %s\n",
		escape($utterance));
	$monolog = 0;
    }
}

sub start_boilerplate () {
    print <<EOT;
<article class=transcript>
<section class=setdown id=intro>
</section>
<section class=main-speaker id=speech>
EOT
}

sub end_boilerplate () {
    print <<EOT;
</section>
<section id=qa>
</section>
</article>
EOT
}

binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

start_boilerplate;

for (my $bom_removed = 0;;) {
    my $s = scalar <>;
last unless defined $s;
    chomp $s;
    if (!$bom_removed && $s =~ /^(?:\xef\xbb\xbf|\x{feff})/) {
	$bom_removed = 1;
	$s = $';
    }
    if ($s =~ /^\s*>>(\S[^:]*)\s*:\s*(.*)$/) {		# identified speaker
	my($speaker, $utterance) = ($1, $2);
	new_monolog($utterance, $speaker);
    } elsif ($s =~ /^\s*>>\s+(.*)$/) {			# unidentified speaker
	my($utterance) = ($1);
	new_monolog($utterance);
    } elsif ($s =~ /^\s*\[\s*[^\[\]]+\s*\]\s*$/) {	# sounds
	end_monolog;
	printf "%s\n", escape($s, 1);
    } else {
	printf "\n%s\n", escape($s);
    }
}
end_monolog;
end_boilerplate;
