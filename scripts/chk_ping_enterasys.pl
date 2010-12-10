#!/usr/bin/perl -w
use strict;
use Net::Telnet;
use Getopt::Long;
use Data::Dumper;

$0 =~ s/.*\///g;
my $ips = undef;
GetOptions ('ips=s' => \$ips);

unless (@ARGV and $ips) {
    print <<EOF;
Usage: $0 <switch> --ips <hosts>
args:
\t<switch>\tDevice to interrogate, any extra host specified as an argument will also be queried.
\t--ips, -i\tA single or a comma-separated list of <hosts> to ping.
Example:
\t$0 ent1 ent2 -i 192.168.221.1,192.168.221.2,192.168.221.3
EOF
exit 1;
}

sub check_ip_host(@) {
    my $validip = "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\$";
    my $validhost = "^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])\$";
    @_ ? my @badhosts = grep { $_ !~ /(?:$validip|$validhost)/ } @_ : print "Empty array!\n";
    exit 1 unless @_;
    @badhosts ? print join(", ", @badhosts)." IP o Hostname inválido/s.\n" : return 0;
    exit 1 if @badhosts;
}

&check_ip_host(@ARGV);
my @iplist = split (",", $ips);
&check_ip_host(@iplist);

foreach my $switch (@ARGV) {
    my $telnet = new Net::Telnet ( Timeout  => 5
                             , Errmode  => 'return'
                             , Prompt   => '/.*\(rw\)->/i'
                             );
    $telnet->open($switch);
    $telnet->login('XXXXX', 'XXXXXXX');
    $telnet->cmd('router');
    foreach (@iplist) {
        my $ping = join('', $telnet->cmd("ping $_"));
        $ping =~ /is alive/ ? print "$switch -> $_ (OK)\n" : print "$switch -> $_ (NOK!)\n";
    }
    $telnet->close;
}
exit 0;
