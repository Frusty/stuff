#!/usr/bin/perl -w
# Downloads stuff from rapidshare urls and/or link lists with checksum check.
# http://images.rapidshare.com/apidoc.txt

use strict;
use warnings;
use LWP::UserAgent;
use LWP::Protocol::https;    # RS requires https for certain transactions.
use HTTP::Request::Common;
use Digest::MD5 qw(md5_hex);
use File::Copy;              # move()
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

print "$0 <rapidshare urls and/or link textfiles>\n" and exit 1 unless $#ARGV == 0;

my @downloads = (); # Array of hashes with the url info.
my $total_size;     # Total size of the remote filename.
my $temp_file;      # Filename of the current download.

sub lwp_callback {
    my ($data, $response, $protocol) = @_;
    print DOWN_FH $data if fileno DOWN_FH;
    my ($got, $total) = (-s $temp_file, $total_size);
    printf("\rDownloading '$temp_file'. Got $got of $total bytes (%.2f%%)", 100*$got/+$total);
}

sub parse_url($) {
    my $url = shift;
    $url =~ s/[\n\r]//g;
    if ($url =~ /files\/(\d+)\/(.+)/) {
        print YELLOW "Adding '$2' ($1)\n";
        push @downloads, { url      => $url
                         , fileid   => $1
                         , filename => $2
                         };
    }
}

sub md5_digest($) {
    my $file = shift;
    open(MD5_FH, $file) or die "Can't open '$file': $!";
    binmode(MD5_FH);
    my $result = Digest::MD5->new->addfile(*MD5_FH)->hexdigest;
    close(MD5_FH);
    return $result;
}

foreach my $arg (@ARGV) {
    if (-r $arg) {
        open(FILE, $arg) or die;
        &parse_url($_) while <FILE>;
        close(FILE);
    } else {
        &parse_url($arg);
    }
}

foreach my $download (@downloads) {
    my $ua = LWP::UserAgent->new;
    if (-r $download->{filename}) {
        print RED "Skipping '$download->{filename}', already on disk.\n";
        next;
    }
    $temp_file = "$download->{filename}.part";
    my $response = $ua->request( POST 'https://api.rapidshare.com/cgi-bin/rsapi.cgi'
                               , [ sub       => 'checkfiles'
                                 , files     => $download->{fileid}
                                 , filenames => $download->{filename}
                                 ]
                               );
    my @reply_fields = split (',', $response->content);
    if ($reply_fields[2] and $reply_fields[4] == 1) {
        $total_size = $reply_fields[2];
    } else {
        my %checkfiles_status = ( 0 => 'File not found'
                                , 1 => 'File OK'
                                , 3 => 'Server down'
                                , 4 => 'File marked as illegal'
                                );
        print RED join(', ', @reply_fields)."\n";
        print RED "Error checking '$download->{filename}': $checkfiles_status{$reply_fields[4]}.\n";
        next;
    }
    $response = $ua->request( POST 'https://api.rapidshare.com/cgi-bin/rsapi.cgi'
                            , [ sub      => 'download'
                              , fileid   => $download->{fileid}
                              , filename => $download->{filename}
                              ]
                            );
    if ( $response->content =~ /DL:([^,]+),(\w+),0,(\w+)/ ) {
        my ($rs_hostname, $dlauth, $md5hex) = ($1, $2, $3);
        open(DOWN_FH, ">", $temp_file) or die $!;
        binmode(DOWN_FH);
        $response = $ua->get( "http://${rs_hostname}/cgi-bin/rsapi.cgi?sub=download&fileid=$download->{fileid}&filename=$download->{filename}&dlauth=$dlauth"
                            , ':content_cb' => \&lwp_callback
                            );
        close(DOWN_FH);
        &lwp_callback; # Make sure we'll update our download status after we close the file handle.
        my $down_digest = uc(&md5_digest($temp_file))." $download->{filename}";
        if ("$md5hex $download->{filename}" eq $down_digest) {
            print GREEN " CHECKSUM OK!\n";
            open(DIGEST_FH, ">", "$download->{filename}.md5") or die $!;
            print DIGEST_FH "$down_digest\n";
            close(DIGEST_FH);
            move($temp_file, $download->{filename});
        } else {
            print BOLD RED " CHECKSUM FAILED!\n";
        }
    }
}
exit 0;
