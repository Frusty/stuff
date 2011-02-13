#!/usr/bin/perl
# Query http a nagios a servicios con problemas.
# Se puede consultar un host concreto pasándolo como argumento.

use strict;
use warnings;
use LWP::UserAgent;
use HTML::Entities;  # decode_entities
use Term::ANSIColor;

my $nagios   = "http://127.0.0.1/nagios";
my $username = "";
my $password = "";

my %colors = ( OK       => 'green'
             , WARNING  => 'bright_yellow'
             , UNKNOWN  => 'bright_magenta' # ANSI hates orange.
             , CRITICAL => 'bright_red'
             );
my $colorkeys = join("|", keys %colors);

sub httpget($$$) {
    my ($url, $user, $pass) = @_;
    my $ua = LWP::UserAgent->new;
    $ua->agent('Ozzy Osbourne 6.66'); # Era necesario.
    my $req = HTTP::Request->new(GET => $url);
    $pass and $req->authorization_basic($user, $pass);
    my $res = $ua->request($req);
    $res->is_success ? return $res->decoded_content : return $res->status_line
}

sub swrite {
    my $format = shift;
    $^A = "";                  # El acumulador ha de estar vacío en cada iteración.
    formline($format,@_);      # http://perldoc.perl.org/functions/formline.html
    $^A =~ s/^[\s+\|]+\n+//mg; # Eliminamos líneas sin infomación.
    return $^A;
}

$ARGV[0] and $ARGV[0] =~ s/\W//g;                   # Sanitizamos 1er argumento si existe.
my $host = $ARGV[0] || "all&servicestatustypes=28"; # No he mirado el resto de servicestatustypes.

my $page = decode_entities(&httpget("$nagios/cgi-bin/status.cgi?host=$host", $username, $password));
die "$page\n" if $page =~ /^\d{3}/;

$page =~ s/<td><\/td>/^/ig; # No me interesa tener celdas vacías...
$page =~ s/<[^>]+?>//g;     # para no cargármelas aquí.
$page =~ s/^\s*\n+//mg;     # Fuera whitelines.

my $firstloop = 0; # Para mostrar el header una vez.
while ($page =~ /([^\n]+)\n([^\n]+)\n((?:$colorkeys))\n([^\n]+)\n([^\n]+)\n(\d+\/\d+)\n([^\n]+)\n/gs) {
    my ($one, $two, $three, $four, $five, $six, $seven) = ($1, $2, $3, $4, $5, $6, $7);
    not $firstloop++ and print colored (<<'__EOF__', 'green');
Host              Service                  Since             Nº    Description
                |---------------------------------------------------------------------------------------|
__EOF__
    my $output = swrite(<<'__EOF__', $one, $two, $five, $six, $seven);
^<<<<<<<<<<<<<< | ^<<<<<<<<<<<<<<<<<<<<< | ^>>>>>>>>>>>>>> | ^>> | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | ~~
                |---------------------------------------------------------------------------------------|
__EOF__
    print colored ($output, $colors{$3});
}
exit 0;
