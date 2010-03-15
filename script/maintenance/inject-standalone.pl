use strict;
use warnings;
use JSON::XS;
use LWP::UserAgent;
use FrePAN;
use FrePAN::DB;
use FrePAN::Worker;
use FrePAN::Worker::ProcessDist;
$FrePAN::Worker::ProcessDist::DEBUG=1;

my $url = 'http://friendfeed-api.com/v2/feed/cpan';
# my $json = '{"version":"2010.06501","url":"http://cpan.cpantesters.org/authors/id/C/CO/CORNELIUS/Vimana-2010.06501.tar.gz","name":"Vimana","path":"C/CO/CORNELIUS/Vimana-2010.06501.tar.gz"}';
# my $json = '{"version":"1.100640","url":"http://search.cpan.org/CPAN/authors/id/J/JQ/JQUELIN/Dist-Zilla-Plugin-AutoPrereq-1.100640.tar.gz","name":"Dist-Zilla-Plugin-AutoPrereq","path":"J/JQ/JQUELIN/Dist-Zilla-Plugin-AutoPrereq-1.100640.tar.gz"}';
# my $json = '{"version":"0.34","url":"http://cpan.cpantesters.org/authors/id/N/NI/NINE/Inline-Python-0.34.tar.gz","name":"Inline-Python","path":"N/NI/NINE/Inline-Python-0.34.tar.gz"}';
my $json = '{"version":"3.10_53","url":"http://cpan.cpantesters.org/authors/id/T/TI/TIMB/Devel-NYTProf-3.10_53.tar.gz","name":"Devel-NYTProf","path":"T/TI/TIMB/Devel-NYTProf-3.10_53.tar.gz","released":1268656856}';

my $config = do 'config.pl';
my $c = FrePAN->bootstrap(config => $config);

$FrePAN::Worker::VERBOSE = 1;
# my $json = get($url);
print "injecting: $json\n";
FrePAN::Worker::ProcessDist->run(
    decode_json($json)
);

exit;

sub get {
    my $ua = LWP::UserAgent->new();
    my $res = $ua->get($url);
    $res->is_success or die $res->status_line;
    my $data = decode_json($res->content);
    my $body = $data->{entries}->[0]->{body};
    my $entry = parse_entry($body);
    return encode_json($entry);
}

sub parse_entry {
    my $body = shift;

    if ($body =~ m!^([\w\-]+) ([0-9\._]*) by (.+?) - <a.*href="(http:.*?/authors/id/(.*?\.tar\.gz))"!) {
        return {
            name    => $1,
            version => $2,
            url     => $4,
            path    => $5,
        };
    }

    return;
}
