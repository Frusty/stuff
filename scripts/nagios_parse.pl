#!/usr/bin/perl
# Parsea cierta info de un directorio de configuración de nagios en una estructura de datos.
# http://nagios.sourceforge.net/docs/3_0/configobject.html
# http://nagios.sourceforge.net/docs/3_0/objectinheritance.html

use strict;
use warnings;
use Data::Dumper;
use File::Find;

my $cfgdir     = "/opt/local/nagios/etc/";
my %result     = ();
my %commands   = ();
my %hostgroups = ();
my %resources  = ();
my @services   = ();

find(\&wanted, $cfgdir);
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
            my ($type, $data)  = ($1, $2);
            my $ref;
            $data =~ s/#.*$//g;
            while ($data =~ /^\s+(\S+)\s+(.+?)\s*$/gm) {
                my ($first, $second) = ($1, $2);
                next if $first =~ /#/;
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
    my $cmd = "";
    map {$hosts{$_} = 1} @{$serv->{host_name}};
    @{$serv->{host_name}} = grep { !/^!/ } grep { not $hosts{"!$_"} } keys %hosts;
    $serv->{check_command} and $serv->{check_command} =~ /^([^!]*)(?:|!.*)$/ and $cmd=$1;
    foreach my $hostname (@{$serv->{host_name}}) {
        my $cmdstring = $commands{$cmd} or next;
        my @cmdarray = split (/!/, $serv->{check_command});
        $cmdstring =~ s/(\$USER\d*\$)/$resources{$1}/g;
        $cmdstring =~ s/\$HOSTADDRESS\$/$result{$hostname}{address}/g;
	my $count = 0;
	while ($cmdstring =~ /\$ARG(\d)\$/g) { 
		$count++;
		unless (defined $cmdarray[$1]) {
		    print "Problema en el chequeo '$serv->{service_description}' del host $hostname:\n";
		    print "\$ARGV${1}\$ no tiene un valor asociado en la definición del servicio\n";
        	    print "check_command => $cmdstring\n";
        	    print "command_line  => ".join ("|", @cmdarray)."\n\n";
    		    $cmdarray[$1] = "ERROR";
		}
	}
        $cmdstring =~ s/\$ARG(\d)\$/$cmdarray[$1]/g;
        $result{$hostname}{services}{$serv->{service_description}}{check_command} = $serv->{check_command};
        $result{$hostname}{services}{$serv->{service_description}}{$cmd} = $commands{$cmd};
        $result{$hostname}{services}{$serv->{service_description}}{CMD}  = $cmdstring;
    }
}

map {print Dumper $result{lc($_)}} @ARGV or print Dumper %result;
