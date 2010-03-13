use strict;
use warnings;
use JSON::XS;
use LWP::UserAgent;
use FrePAN;
use FrePAN::DB;

my $url = 'http://friendfeed-api.com/v2/feed/cpan';
get($url);

sub get {
    my $ua = LWP::UserAgent->new();
    my $res = $ua->get($url);
    $res->is_success or die $res->status_line;
    my $data = decode_json($res->content);
    for my $entry (@{$data->{entries}}) {
        my $body = $entry->{body};
        my $entry = parse_entry($body);

        print "# " . $entry->{name} . "\n";
        print encode_json($entry) . "\n\n";
    }
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
