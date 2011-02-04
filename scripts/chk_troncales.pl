#!/usr/bin/perl -w
use strict;
use Net::Telnet;
use GraphViz;

my %chuis=( '.1.3.6.1.4.1.5624.2.2.220'    => { name   => 'C2H124-48'
                                              , user   => 'admin'
                                              , pass   => 'XXXXX'
                                              , chkcmd => 'ping'
                                              , regexp => 'is alive'
                                              }
          , '.1.3.6.1.4.1.2636.1.1.1.2.31' => { name   => 'ex4200-24p'
                                              , user   => 'admin'
                                              , pass   => 'XXXXX'
                                              , runcmd => 'set cli screen-length 0'
                                              , chkcmd => 'ping routing-instance datos count 1 wait 2'
                                              , regexp => ', 0% packet loss'
                                              }
          );

my %trons=( 'host1' => { IP => '192.168.0.1'
                       , ID => '.1.3.6.1.4.1.5624.2.2.220'
                       }
          , 'host2' => { IP => '192.168.0.2'
                       , ID => '.1.3.6.1.4.1.5624.2.2.220'
                       }
          , 'host3' => { IP => '192.168.0.3'
                       , ID => '.1.3.6.1.4.1.2636.1.1.1.2.31'
                       }
          );

my %vpns=( 666 => { NAME  => 'VLAN 666'
                  , NODES => { 'host1' => '192.168.2.1'
                             , 'host2' => '192.168.2.2'
                             , 'host3' => '192.168.2.3'
                             }
                  }
         , 667 => { NAME  => 'VLAN 667'
                  , NODES => { 'host1' => '192.168.3.7'
                             , 'host2' => '192.168.3.8'
                             }
                  }
         );

my $g = GraphViz->new( name    => 'Troncales'
                     , layout  => 'dot'
                     , node    => { shape     => 'ellipse'
                                  , style     => 'filled'
                                  , fillcolor => 'lightgray'
                                  }
                     , edge    => { color     => 'blue'
                                  }
                     );
my %added=();
foreach my $tron (keys %trons) {
    print "# $tron ($trons{$tron}{IP})\n" unless $ARGV[0];
    my $sysObjectID = 0;

    if (defined $trons{$tron}{ID}) {
        $sysObjectID = $trons{$tron}{ID};
    } else {
        print "#\tEl troncal $tron no tiene ID\n" unless $ARGV[0];
    }

    my $telnet = new Net::Telnet ( Timeout => 10
                                 , Errmode => 'return'
                                 , Prompt  => '/(?m:.*[\w.-]+\s?(?:\(config[^\)]*\))?\s?[\+\$#>]\s?(?:\(enable\))?\s*$)/'
                                 );
    $telnet->open($trons{$tron}{IP});
    if ($telnet->errmsg) {
        print "#\t$telnet->errms\n" unless $ARGV[0];
    }

    $telnet->login($chuis{$sysObjectID}{user}, $chuis{$sysObjectID}{pass});
    unless ($telnet->last_prompt) {
        print "#\tUnable to get prompt.\n" unless $ARGV[0];
    }

    $telnet->cmd($chuis{$sysObjectID}{runcmd}) if ($chuis{$sysObjectID}{runcmd});
    foreach my $vpn (keys %vpns) {
        if ($vpns{$vpn}{NODES}{$tron}) {
            foreach my $node (keys %{$vpns{$vpn}{NODES}}) {
                if ($node ne $tron) {
                    my $srcip = $vpns{$vpn}{NODES}{$tron};
                    my $dstip = $vpns{$vpn}{NODES}{$node};

                    unless (defined $trons{$node}) {
                        print "\tAdded orphan node: ($vpn) $node $dstip\n" unless $ARGV[0];
                        $g->add_node( $dstip
                                    , label   => "$node\n$dstip\n PVID: $vpn"
                                    );
                    }

                    my ($clustyle, $clusfc) = ('dashed', 'black');
                    ($clustyle, $clusfc) = ('filled', 'red') if $telnet->errmsg;
                    $g->add_node( $srcip
                                , label   => "$srcip\n PVID: $vpn"
                                , cluster => { name      => $tron
                                             , fontsize  => 24
                                             , style     => $clustyle
                                             , fillcolor => $clusfc
                                             }
                                );

                    next if defined $added{$vpn}{$dstip}{$srcip};

                    $added{$vpn}{$srcip}{$dstip} = 1;
                    my $ping = join('', $telnet->cmd("$chuis{$sysObjectID}{chkcmd} $dstip"));

                    if ($ping =~ /$chuis{$sysObjectID}{regexp}/sg) {
                        print "\t($vpn) $srcip\t-> $dstip (OK)\n" unless $ARGV[0];
                        $g->add_edge( $srcip => $dstip );
                    } else {
                        print "\t($vpn) $srcip\t-> $dstip (NOK!)\n" unless $ARGV[0];
                        $g->add_edge( $srcip    => $dstip
                                    , label     => "$vpns{$vpn}{NAME}"
                                    , style     => 'bold'
                                    , color     => 'black'
                                    , fontcolor => 'red'
                                    , fontsize  => 18
                                    );
                        $g->add_node( $srcip
                                    , fillcolor => 'red'
                                    );
                        $g->add_node( $dstip
                                    , fillcolor => 'red'
                                    );
                    }
                }
            }
        }
    }
    $telnet->close;
}

my $dir=$ENV{'PWD'};
my $date = scalar localtime();
$dir=$ARGV[0] if ($ARGV[0] and -d $ARGV[0]);

open (FH, ">$dir/troncales.png") || die "Can't redirect stdout";
print FH $g->as_png;
close (FH);

open (FH, ">$dir/index.html") || die "Can't redirect stdout";
print FH <<EOF;
<html>
    <head>
        <title>Troncales $date</title>
        <meta http-equiv="refresh" content=600>
    </head>
    <body>
        <img src="troncales.png" name="troncals">
    </body>
</html>
EOF
close (FH);

`gqview troncales.png&` unless $ARGV[0];

exit 0;
