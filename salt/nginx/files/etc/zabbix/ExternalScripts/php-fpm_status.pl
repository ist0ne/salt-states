#!/usr/bin/perl
#
# Boris HUISGEN <bhuisgen@hbis.fr>

use LWP::UserAgent;

my $URL = "http://127.0.0.1:55888/phpfpm-status";

#
# DO NOT MODIFY AFTER THIS LINE
#

my $ua = LWP::UserAgent->new(timeout => 15);
my $response = $ua->request(HTTP::Request->new('GET', $URL));

my $conn = 0;
my $idle = 0;
my $active = 0;
my $total = 0;
my $maxchildren = 0;

foreach (split(/\n/, $response->content)) {
 $conn = $1 if (/^accepted conn:\s+(\d+)/);
 $idle = $1 if (/^idle processes:\s+(\d+)/);
 $active = $1 if (/^active processes:\s+(\d+)/);
 $total = $1 if (/^total processes:\s+(\d+)/);
 $maxchildren = $1 if (/^max children reached:\s+(\d+)/);
}

print "Accepted conn: $conn\tIdle proc: $idle\tActive proc: $active\tTotal proc: $total\tMax children: $maxchildren\n";
