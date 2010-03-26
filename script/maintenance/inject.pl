use strict;
use warnings;
use JSON::XS;
use LWP::UserAgent;
use FrePAN;
use FrePAN::ConfigLoader;

my $url = 'http://friendfeed-api.com/v2/feed/cpan';

# my $json = get_json();
my $json = '{"version":"2010.06501","url":"http://cpan.cpantesters.org/authors/id/C/CO/CORNELIUS/Vimana-2010.06501.tar.gz","name":"Vimana","path":"C/CO/CORNELIUS/Vimana-2010.06501.tar.gz","released":1268656856}';
# my $json = '{"version":"1.100640","url":"http://search.cpan.org/CPAN/authors/id/J/JQ/JQUELIN/Dist-Zilla-Plugin-AutoPrereq-1.100640.tar.gz","name":"Dist-Zilla-Plugin-AutoPrereq","path":"J/JQ/JQUELIN/Dist-Zilla-Plugin-AutoPrereq-1.100640.tar.gz"}';
print "injecting: $json\n";

my $config = FrePAN::ConfigLoader->load();
my $c = FrePAN->bootstrap(config => $config);
my $sch = $c->get('TheSchwartz::Simple');
use Data::Dumper; warn Dumper($config);
$sch->insert("FrePAN::Worker::ProcessDist", $json) or die $@;
exit;

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

sub get {
    my $ua = LWP::UserAgent->new();
    my $res = $ua->get($url);
    $res->is_success or die $res->status_line;
    my $data = decode_json($res->content);
    my $body = $data->{entries}->[0]->{body};
    my $entry = parse_entry($body);
    return encode_json($entry);
}

