#!/usr/bin/perl -w
use strict;
use SNMP;
use Getopt::Long;
use Net::Telnet;
use POSIX qw(strftime);
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

$0 =~ s/.*\///g;
my @cmds = ();
my $file = 0;

GetOptions ( 'command=s' => \@cmds
           , 'file'    => \$file
           );

unless (@ARGV) {
    print <<EOF;
Usage: $0 <host/s> --command <Command to send>
Args:
\t--command, -c\tOptional, can be repeated. Commands to send, use quotes for space-separated arguments.
\t\t\tIf no commands specified, it will use "show config".
\t--file\t\tOptional. Print the command output to a file.
Example: $0 management.jare.es -c "show version" -c "show interface status" -c "show interface trunk"
EOF
exit 1;
}

my %chuis =();
$chuis{'.1.3.6.1.4.1.2467.4.7'}        = {name => 'CSS11501',         user => 'XXXXX', pass => 'XXXXX', runcmd => 'terminal length 65535', defcmd => 'show running-config'};
$chuis{'.1.3.6.1.4.1.9.1.359'}         = {name => 'WS-C2950T-24',     user => 'XXXXX', pass => 'XXXXX', runcmd => 'terminal length 0', enable => 'XXXXX'};
$chuis{'.1.3.6.1.4.1.9.1.559'}         = {name => 'WS-C2950T-48-SI',  user => 'XXXXX', pass => 'XXXXX', runcmd => 'terminal length 0', enable => 'XXXXX'};
$chuis{'.1.3.6.1.4.1.9.1.716'}         = {name => 'WS-C2960-24TT-L',  user => 'XXXXX', pass => 'XXXXX', runcmd => 'terminal length 0', enable => 'XXXXX'};
$chuis{'.1.3.6.1.4.1.9.1.717'}         = {name => 'WS-C2960-48TT-L',  user => 'XXXXX', pass => 'XXXXX', runcmd => 'terminal length 0', enable => 'XXXXX'};
$chuis{'.1.3.6.1.4.1.9.1.696'}         = {name => 'WS-C2960G-24TC-L', user => 'XXXXX', pass => 'XXXXX', runcmd => 'terminal length 0', enable => 'XXXXX'};
$chuis{'.1.3.6.1.4.1.5624.2.2.220'}    = {name => 'C2H124-48',        user => 'XXXXX', pass => 'XXXXX'};
$chuis{'.1.3.6.1.4.1.5624.2.2.286'}    = {name => 'C2H124-48P',       user => 'XXXXX', pass => 'XXXXX'};
$chuis{'.1.3.6.1.4.1.5624.2.1.100'}    = {name => 'B3G124-24',        user => 'XXXXX', pass => 'XXXXX'};
$chuis{'.1.3.6.1.4.1.5624.2.1.53'}     = {name => '7H4382-25',        user => 'XXXXX', pass => 'XXXXX'};
$chuis{'.1.3.6.1.4.1.5624.2.1.59'}     = {name => '1H582-25',         user => 'XXXXX', pass => 'XXXXX',  runcmd => 'set terminal rows disable'};
$chuis{'.1.3.6.1.4.1.5624.2.1.34'}     = {name => '1H582-51',         user => 'XXXXX', pass => 'XXXXX',  runcmd => 'set terminal rows disable'};
$chuis{'.1.3.6.1.4.1.2636.1.1.1.2.31'} = {name => 'ex4200-24p',       user => 'XXXXX', pass => 'XXXXX',  runcmd => 'set cli screen-length 0'};

my @communities = qw/public XXXXX YYYYY/;

sub getSNMP() {
    my $machine   = shift || 'localhost';
    my $community = shift || 'public';
    my $oid       = shift || '.1.3.6.1.2.1.1.2.0';
    my $session   = new SNMP::Session( DestHost    => $machine
                                     , Community   => $community
                                     , Version     => 2
                                     , UseNumeric  => 1
                                     );
    if ($session) {
        my $result = $session->get($oid);
        if ($result) {
            return $result;
        } else {
            print RED "#\tNo SNMP response from '$machine' using '$community'.\n";
            return 0;
        }
    } else {
        print RED "#\tNo SNMP session from '$machine'\n";
        return 0;
    }
}

foreach my $host (@ARGV) {
    my $sysObjectID = 0;
    print BOLD WHITE "#\n#\tTrying '$host'...\n#\n";
    foreach (@communities) {
        $sysObjectID = &getSNMP($host, $_);
            last if $sysObjectID;
    }
    if ($sysObjectID) {
        if ($chuis{$sysObjectID}{name}) {
            print GREEN "#\tHardware: $chuis{$sysObjectID}{name} ($sysObjectID)\n";
        } else {
            print BOLD RED "#\t$sysObjectID no está en el hash:\n";
            foreach my $key (sort keys %chuis) {
                next unless $chuis{$key}{name};
                print GREEN "#\t$chuis{$key}{name}";
                print BOLD GREEN " $key\n";
            }
            next;
        }
    } else {
        print BOLD RED "#\tNo SNMP response from '$host'.\n";
        next;
    }

    my $telnet = new Net::Telnet ( Timeout  => 30
                                 , Errmode  => 'return'
                     , Prompt => '/(?m:.*[\w.-]+\s?(?:\(config[^\)]*\))?\s?[\+\$#>]\s?(?:\(enable\))?\s*$)/'
                                 );
    $telnet->open($host);
    $telnet->login($chuis{$sysObjectID}{user}, $chuis{$sysObjectID}{pass});
    my $prompt = $telnet->last_prompt;

    if ($prompt) {
        print GREEN "#\tStrip Prompt -> '$prompt'\n";
    } else {
        print RED "#\tUnable to get prompt.\n";
        next;
    }

    if ($chuis{$sysObjectID}{enable}) {
        print GREEN "#\tSending enablepass...";
        $telnet->print('enable');
        $telnet->waitfor('/password/i');
        $telnet->cmd($chuis{$sysObjectID}{enable});
        if ($telnet->lastline =~ /denied/i) {
            print BOLD RED " NOK\n#\tSkipping Host '$host'\n";
            next;
        } else {
            print BOLD GREEN " OK\n";
        }
    }

    if ($chuis{$sysObjectID}{runcmd}) {
        print GREEN "#\tSending runcmd '$chuis{$sysObjectID}{runcmd}'\n";
        $telnet->cmd($chuis{$sysObjectID}{runcmd});
    }

    my $defcmd = $chuis{$sysObjectID}{defcmd} || "show config";
    @cmds = ("$defcmd") unless @cmds;
    foreach (@cmds) {
        s/[\n\t\f]+/ /g;
        print CYAN "#\tExecuting '$_' on '$host'\n\n";
        print "${prompt}$_\n";
    my $output = join('', $telnet->cmd("$_"));
        print $output;
        print CYAN "#\tEOF '$_' on '$host'.\n";
    if ($file) {
            my $filename = "${host}-$_-".strftime("%Y%m%d_%H%M%S", localtime);
        $filename =~ s/[^\w:-]/_/g;
            print GREEN "#\tWriting output on '$filename.txt'.\n";
            open(LOG, "> ${filename}.txt") || die "Can't redirect stdout";
            print LOG $output;
            close(LOG);
        }
    }
}
