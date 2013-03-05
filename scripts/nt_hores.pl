#!/usr/bin/perl

use strict;
use warnings;
use IO::Handle;
use LWP::UserAgent;
use URI::Escape;
use HTTP::Request::Common;

my $initials;
print "Initials (xxx): " and chomp($initials = <>) while $initials !~ /^[a-z]{3}$/;
my $pass; # = 'enter_password_here';
$pass = uri_escape($pass);
print 'Password: ' and chomp($pass = <>) while not $pass;
my $project; # = 'enter_project_here';
print "Project (EXXXXX): " and chomp($project = <>) while $project !~ /^[Ee]\d{5}$/;

my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
my $today = sprintf("%02d/%02d/%04d", $mday, $mon+1, $year+1900);
my $dow = qw(7 1 2 3 4 5 6)[$wday]; # $wday begins with sunday at 0
my $woy = int($yday / 7) + 1; # WeekOfYear

my $ua = LWP::UserAgent->new( agent         => 'Windows IE 6' # ORLY
                            , show_progress => 1
                            , timeout       => 10
                            );

print "Initials:'$initials' Project:'$project' WeekOfYear:'$woy' DayOfWeek:'$dow' Today:'$today'\n";
my $resp = $ua->request( POST "http://$initials:$pass\@www.xxxxxxx.net/intranet_cs/scripts/setmana2.asp"
                       , [ INSERIR                   => 'Y'
                         , p_inicials                => $initials
                         , setmana                   => $woy
                         , ann                       => $year+1900
                         , "cmbDia_$dow"             => $today
                         , "c_exe$dow"               => $project
                         , "c_hores_${dow}_$dow"     => '08:00'
                         , "c_horesFact_${dow}_$dow" => '08:00'
                         , "DescripcioTasca$dow"     => $initials
                         , num_files                 => 7
                         ]
                       );

$resp->is_success ? exit 0 : print $resp->headers_as_string."\n";
