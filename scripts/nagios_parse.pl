#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;
use File::Find;

# command
# contact
# contactgroup
# host
# hostextinfo
# hostgroup
# service
# serviceextinfo
# servicegroup
# timeperiod

my %result = ();
my %commands = ();
my @services = ();

find(\&wanted, "/home/oscar/sandbox/doc/etc");
sub wanted {
    if (-f and /\.cfg$/) {
        my $file = $File::Find::name;
        local(*DB, $/);
        open (DB, '<', "$file") or die "No puedo abir $file";
        my $slurp = <DB>;
        while ($slurp =~ /^define (\w+)\s*{([^{]+)}/gm) {
            my ($type, $asd)  = ($1, $2);
            my $ref;
            $asd =~ s/#.*$//g;
            while ($asd =~ /^\s+(\S+)\s+(.+?)\s*$/gm) {
                my ($first, $second) = ($1, $2);
                if ($first =~ /^(?:contact_groups|host|hostgroup_name|host_name)$/) {
                    next if $second =~ /^!/;
                    $ref->{$first} = [split (",", $second)];
                } else {
                    $ref->{$first} = $second;
                }
            }

            if ($type eq 'serviceextinfo') {
                foreach my $hostname (@{$ref->{host_name}}) {
                    $result{$hostname}{services}{$ref->{service_description}}{notes_url} = $ref->{notes_url};
                }
            }
            if ($type eq 'host') {
                next unless defined ${$ref->{host_name}}[0];
                $result{${$ref->{host_name}}[0]} = { use     => $ref->{use}
                                                   , address => $ref->{address}
                                                   , alias   => $ref->{alias}
                                                   }
            }

            if ($type eq 'command') {
                $commands{$ref->{command_name}} = $ref->{command_line};
            }

            if ($type eq 'service') {
                next unless defined @{$ref->{host_name}} and defined $ref->{service_description};
                push (@services, $ref);
            }
        }
    }
}

foreach my $serv (@services) {
    my $cmd = $1 if $serv->{check_command} =~ /^([^!]*)(?:|!.*)$/;
    foreach my $hostname (@{$serv->{host_name}}) {
       my $aa = $commands{$cmd};
       next unless defined $aa;
       print RED Dumper $serv unless $aa;
       my @tt = split (/!/, $serv->{check_command});
       print $hostname unless $result{$hostname}{address};
       $aa =~ s/\$HOSTADDRESS\$/$result{$hostname}{address}/g;
       $aa =~ s/\$ARG(\d)\$/$tt[$1]/g;
       $result{$hostname}{services}{$serv->{service_description}}{check_command} = $serv->{check_command};
       $result{$hostname}{services}{$serv->{service_description}}{$cmd} = $commands{$cmd};
       $result{$hostname}{services}{$serv->{service_description}}{CMD}  = $aa;
    }
}

$Data::Dumper::Terse = 1;          # don't output names where feasible
#print Dumper %result;
