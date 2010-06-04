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

my %result     = ();
my %commands   = ();
my %hostgroups = ();
my %resources  = ();
my @services   = ();

find(\&wanted, "$ENV{PWD}/etc");
sub wanted {
    if (-f and /\.cfg$/) {
        my $file = $File::Find::name;
        local(*DB, $/);
        open (DB, '<', "$file") or die "No puedo abir $file";
        my $slurp = <DB>;
        if ($file =~ /resource.cfg$/) {
            while ($slurp =~ /^\s*?(\$USER\d*\$)\s*=\s*(.*)$/gm) {
                $resources{$1} = $2;
            }
        }
        while ($slurp =~ /^\s*define (\w+)\s*{([^{]+)}/gm) {
            my ($type, $asd)  = ($1, $2);
            my $ref;
            $asd =~ s/#.*$//g;
            while ($asd =~ /^\s+(\S+)\s+(.+?)\s*$/gm) {
                my ($first, $second) = ($1, $2);
                if ($first =~ /^(?:contact_groups|host|host_name|hostgroup|hostgroup_name|members)$/) {
                    $second =~ s/\s//g;
                    $ref->{$first} = [split (",", $second)];
                } else {
                    $ref->{$first} = $second;
                }
            }
            next if exists $ref->{register} and $ref->{register} =~ /0/;
            if ($type eq 'hostgroup') {
                foreach (@{$ref->{hostgroup_name}}) {
                    die if $hostgroups{$_};
                    $hostgroups{$_}{members} = [@{$ref->{members}}];
                    $hostgroups{$_}{alias}   = $ref->{alias};
                }
            }
            if ($type eq 'serviceextinfo') {
                push (@{$ref->{hostgroup_name}}, @{$ref->{hostgroup}}) if $ref->{hostgroup};
                map {$hostgroups{$_}{services}{$ref->{service_description}}{notes_url} = $ref->{notes_url}} @{$ref->{hostgroup_name}};
                map {$result{$_}{services}{$ref->{service_description}}{notes_url} = $ref->{notes_url}} @{$ref->{host_name}};
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
                push (@services, $ref);
            }
        }
    }
}

foreach my $serv (@services) {
    if ($serv->{hostgroup_name}) {
        foreach my $hn (@{$serv->{hostgroup_name}}) {
            foreach (@{$hostgroups{$hn}{members}}) {
                if ($hostgroups{$hn}{services}{$serv->{service_description}}{notes_url}) {
                    $result{$_}{services}{$serv->{service_description}}{notes_url} = $hostgroups{$hn}{services}{$serv->{service_description}}{notes_url};
                }
            }
            push (@{$serv->{host_name}}, @{$hostgroups{$hn}{members}});
        }
    }
    my %hosts = ();
    map {$hosts{$_} = 1} @{$serv->{host_name}};
    @{$serv->{host_name}} = grep { !/^!/ } grep { not $hosts{"!$_"} } keys %hosts;
    print Dumper $serv unless $serv->{check_command};
    my $cmd = $1 if $serv->{check_command} =~ /^([^!]*)(?:|!.*)$/;
    foreach my $hostname (@{$serv->{host_name}}) {
       my $aa = $commands{$cmd};
       next unless defined $aa;
       my @tt = split (/!/, $serv->{check_command});
       $aa =~ s/(\$USER\d*\$)/$resources{$1}/g;
       $aa =~ s/\$HOSTADDRESS\$/$result{$hostname}{address}/g;
       $aa =~ s/\$ARG(\d)\$/$tt[$1]/g;
       $result{$hostname}{services}{$serv->{service_description}}{check_command} = $serv->{check_command};
       $result{$hostname}{services}{$serv->{service_description}}{$cmd} = $commands{$cmd};
       $result{$hostname}{services}{$serv->{service_description}}{CMD}  = $aa;
    }
}

print Dumper %result;
