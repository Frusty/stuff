#!/usr/bin/perl
use strict;
use Net::OpenSSH;

my $ssh = Net::OpenSSH->new('user:password@host');
my ($out, $err) = $ssh->capture2('uname -a');
print "OUT:\n$out\n";
print "ERR:\n$err\n";
