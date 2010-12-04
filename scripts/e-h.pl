#!/usr/bin/perl
# This is a e-hentai web-crawler featuring lots of colors.

use strict;
use WWW::Mechanize;
use HTML::Entities; # For decode_entities
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

my $mech = WWW::Mechanize->new( autocheck => 0 );#, onerror => undef);
$mech->agent_alias( 'Windows IE 6' );
$mech->get('http://forums.e-hentai.org/index.php?');
$mech->field('UserName','xxxxxxx'); # It seems auth users can DL moar stuff.
$mech->field('PassWord','xxxxxxx');
$mech->submit();

foreach my $param (@ARGV) {
    $mech->get($param);
    my $page = $mech->content();
    my $page_img = undef;
    my $dirname = undef;
    my $file = undef;
    my %pages = ();
    my $count = 0;
    my $first_page = 6;

    while ($page =~ /<a href="([^"]+)" onclick="return false">\d+/g) {
        ++$count;
    }

    for (0..($count/2)-1) {
        $pages{$_} = "$param/?p=$_";
    }
    my $total = scalar keys %pages;

    exit 1 unless $total;
    exit 1 if $total < $first_page;

    print BOLD WHITE ($total)." Pages.\n";
    foreach my $current (sort {$a <=> $b} keys %pages)  {
        next if $current < ($first_page-1);
        print BOLD WHITE "$pages{$current}\t($1 de $total)\n";
        $mech->get($pages{$current});
        $page = $mech->content();
        while ($page =~ /href="(http:\/\/g.e-hentai.org\/s\/.+?)"/g) {
            my $url = 0;
            until ($url) {
                $| = 1;  #
                sleep int(rand(3))+3; # We do nothing on 3-6 secs.
                $| = 0;  #
                print BOLD YELLOW "Searching image on $1\n";
                $mech->get($1);
                $page_img = decode_entities($mech->content());
                $page_img =~ /<\/iframe><a href="[^"]+"><img src="([^"]+)" style="[^"]+" \/><\/a><iframe.+?<\/iframe><div>(.+?) ::/;
                $url = $1;
                $file = $2;
            }
            if ($url =~ /509s.gif/) {
                print BOLD RED "Bandwidth exceeded! ($param)\n";
                exit 1;
            }
            print GREEN "Found $url\n";
            if ($page_img =~ /<title>(.*?)<\/title>/ and not defined $dirname) {
                $dirname = $1;
                $dirname =~ s/[\/ ]/_/g;
                print YELLOW "Creating the directory '$ENV{'PWD'}/$dirname'\n";
                chdir $ENV{'PWD'};
                mkdir $dirname;
                chdir $dirname;
            }
            print YELLOW "$file ->";
            if (! -f "$file") {
                for (1..5) {
                    eval {
                        $mech->get( $url, ':content_file' => $file );
                    };
                    last unless $@;
                    print RED "Failed attempt $_ of 5, the error was '$@'. Trying again...\n";
                    $| = 1;  #
                    sleep int(rand(3))+3; # We do nothing on 3-6 secs.
                    $| = 0;  #
                }
                print BOLD BLUE " ", -s $file, " bytes\n";
            } else {
                print BOLD RED " $file already exists, skipping...\n";
            }
        } # while
    } # foreach
} #foreach
print BOLD WHITE "\nOK!\n";
