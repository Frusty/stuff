#!/usr/bin/perl

use strict;
use warnings;
use IO::Handle;
use LWP::UserAgent;
use HTTP::Request::Common;

my $initials = 'enter_initials_here';
print "Initials (xxx): " and chomp($initials = <>) while $initials !~ /^[a-z]{3}$/;
my $pass; # = 'enter_password_here';
print 'Password: ' and chomp($pass = <>) while not $pass;
my $project = 'enter_project_here';
print "Project (EXXXXX): " and chomp($project = <>) while $project !~ /^[Ee]\d{5}$/;

my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
my $today = sprintf("%02d/%02d/%04d", $mday, $mon+1, $year+1900);
my $dow = qw(7 1 2 3 4 5 6)[$wday]; # $wday begins with sunday at 0
my $wom = int(($mday+1-$wday)/7);   # Calculate number of full weeks this month
$wom += 1 if $wday < 6;             # +1 if today isn't Saturday

my $ua = LWP::UserAgent->new( agent         => 'Windows IE 6' # ORLY
                            , show_progress => 1
                            , timeout       => 10
                            );

print "Initials:'$initials' Project:'$project' WeekOfMonth:'$wom' DayOfWeek:'$dow' Today:'$today'\n";

my $resp = $ua->request( POST "http://$initials:$pass\@www.xxxxxxxx.xxx/intranet_cs/scripts/setmana2.asp"
                       , [ INSERIR                   => 'Y'
                         , p_inicials                => $initials
                         , setmana                   => $wom
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
