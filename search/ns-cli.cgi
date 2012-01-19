#!/usr/bin/perl -w
#
# ns-cli.cgi -- replace Netscape's "smart search" with stuff we like.
#
# See the file README for instructions on how to use this. (If you don't
# have the file, you can get it from <http://www.lafferty.ca/software/>.)
#
# Thanks to Stefan `Sec` Zehl for the pointer about that NS preference.
#
# SEND ME <rich+nscli@lafferty.ca> YOUR USEFUL SEARCHES! :-)
#
# 2002/08/09 Rich <rich@lafferty.ca>
#   - Fix mozilla instructions again
#   - Rewrite with conf file instead of inline configuration
#   - Add "help me"
#   - More example commands
# 2002/05/16 Rich <rich@lafferty.ca> 
#   - Fix mozilla instructions
#   - More example commands
# 2001/03/19 Rich <rich@lafferty.ca> 
#   - use regex that works!
# 2001/03/19 Rich <rich@lafferty.ca> 
#   - expect 'keyword' or 'kwoff', not just 'kwoff', which means that
#     keywords are turned off.
# 2001/03/19 Rich Lafferty <rich@alcor.concordia.ca> 
#   - first clean version.

use strict;
use CGI qw(:cgi);
use URI::Escape;
use vars qw(%search $allowed);

# We expect ns-cli.conf to be in the current working directory.
# Chane the following line if it isn't.

my $conf = "./ns-cli.conf";

do $conf;

# Allowed hosts
if (defined $allowed and $ENV{REMOTE_ADDR} !~ /$allowed/) {
    print header;
    print "<p>This host is not permitted to access this function.\n";
    exit;
}

my $request = $ENV{QUERY_STRING};
# Uses "keyword" if Internet Keywords is enabled, "kwoff" if they're not.
# Interesting -- if you didn't use nscli, you'd still be sending your
# mistyped URLs to Netscape.
$request =~ s,^keyword/,,;

my $word_delimeter = qr/(?:\s+|\+|%20)/;
my ($func, $words) = split($word_delimeter, $request, 2);
my @words = map { uri_unescape($_) } split($word_delimeter, $words);

show_help() if $func eq 'help';

unless (exists $search{$func}) {
    unshift (@words, $func);
    $func = 'default';
}

if (exists $search{$func}->{SYNONYM}) {
    $func = $search{$func}->{SYNONYM};
}

die "Default action '$func' doesn't exist in \%search\n" 
    unless exists ($search{$func});

my $query = uri_escape (join (" ", @words));
die "No URL listed for $func in $conf\n" unless exists $search{$func}->{URL};
$search{$func}->{URL} =~ s/%%QUERY%%/$query/g;
print redirect($search{$func}->{URL});

sub show_help {
    print <<__HTML__;
Content-Type:text/html

<H2><a href="http://www.lafferty.ca/software/">ns-cli</a>, the Netscape command-line interface</H2>

<H3>Available Commands</H3>
<pre>
__HTML__

    for my $key (sort keys %search) {
        my $text = exists $search{$key}->{SYNONYM} ? "Synonym for <b>$search{$key}->{SYNONYM}</b>" :
	                  $search{$key}->{DESC};
        printf("   %12s   %s\n", $key, $text);
    }

    print <<__HTML__;
<p><small>This is free software with ABSOLUTELY NO WARRANTY. This program is
released under the same terms as Perl itself (specifically, under your
choice of either the GNU Public License version 2, or the Perl
Artistic License). Copyright (c) 2002 Rich Lafferty.</small></p>
__HTML__

    exit;
}


