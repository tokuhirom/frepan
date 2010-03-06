use strict;
use warnings;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new();

# fetch
my $xml = do {
    my $src = 'http://friendfeed.com/cpan?format=atom';
    my $res = $ua->get($src);
    $res->is_success or die $res->status_line;
    $res->content;
};

# send
{
    my $url = 'http://frepan.64p.org/webhook/friendfeed-cpan';
    my $req = HTTP::Request->new(POST => $url, [], $xml);
    my $res = $ua->request($req);
    $res->is_success or die $res->status_line;
    warn $res->content;
}
