#!/usr/bin/perl -w
# Show current AP/status from a Cisco WLC parsing his summary webpage.

use strict;
use warnings;
use LWP::UserAgent;

my $user      = 'XXXXXXX';
my $pass      = 'XXXXXXX';
my $host      = 'X.X.X.X';
my $total_aps = 24; # Hardware doesn't keep a total including nonworking APs.
my $ua = LWP::UserAgent->new( agent         => 'Mac Safari'
                            , show_progress => 0 # Adds fancy progressbars
                            , timeout       => 5
                            , ssl_opts      => { verify_hostname => 0 } # Skip ssl trust
                            );

sub request ($) {
    my $url = shift || die "No url\n";
    my $req = HTTP::Request->new(GET => $url);
    $req->authorization_basic($user, $pass);
    my $resp = $ua->request($req);
    $resp->is_success ? return $resp->content : print $resp->status_line."\n";
    exit 1 unless $resp->is_success;
}

my $page = &request("https://$host/screens/base/monitor_summary.html");
my $current_clients = my $current_aps = 0;
$current_clients = $1 if $page =~ /current_clients SIZE="\d+" VALUE="(\d+)"/;
$current_aps     = $1 if $page =~ /current_aps SIZE="\d+" MAXLENGTH="\d+" VALUE="(\d+)"/;

print "** $current_aps/$total_aps APs up, $current_clients connected clients.\n";
exit 1 if $current_aps < $total_aps;
