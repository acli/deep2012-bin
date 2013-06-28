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
    # escaped
    my($s, $narration_mode) = @_;
    $s = CGI::escapeHTML($s);
    $s =~ s/\&gt;/>/g;

    # Attempt to mark up inaudibles and such
    # Note use of i. em is wrong in this context.
    my $tag = $narration_mode? 'div': 'span';
    my $spacing = $narration_mode? "\n\n": '';
    $s =~ s {(\[)\s*(applause|inaudible)\s*(\])}
	    {<$tag class=narration>$spacing\1<i>\2<\/i>\3$spacing<\/$tag>}i;
    return $s;
}

sub end_monolog () {
    print "\n</div>" if defined $monolog;
    undef $monolog;
}

sub new_monolog ($;$) {
    my($utterance, $speaker) = @_;
    my $prev_speaker = $monolog;
    end_monolog if defined $monolog;
    my $tag = defined $speaker? "$speaker:": '';
    printf("<div class=monolog>\n\n>>%s %s\n",
	    escape($tag), escape($utterance));
    if (defined $speaker) {
	$monolog = $speaker;
    } else {
	$monolog = defined $prev_speaker? $prev_speaker: 0;
    }
}

for (my $bom_removed = 0;;) {
    my $s = scalar <>;
last unless defined $s;
    chomp $s;
    if (!$bom_removed && $s =~ /^\xef\xbb\xbf/) {
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
