use strict;
use warnings;
use utf8;

package FrePAN::Web::C::Feed;
use FrePAN;
use autodie;

sub index {
    my $c = shift;
    my $fname = FrePAN->config->{'M::RSSMaker'}->{'path'} // die "Missing configuration for rss file";
    open my $fh, '<', $fname or die "Cannot open rss file: $fname";
    return $c->create_response(
        200,
        [
            'Content-Type'   => 'text/xml;charset=utf-8',
            'Content-Length' => -s $fname
        ],
        $fh
    );
}

1;

