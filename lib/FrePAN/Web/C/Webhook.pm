package FrePAN::Web::C::Webhook;
use Amon::Web::C;
use XML::Feed;
use JSON::XS;
use File::Slurp;

my $VALID_TOKEN = 'c5cedc136feeb7674f96b3d7dcde6361';

sub friendfeed {
    my $mode = param('hub.mode') || '';
    if ($mode eq 'subscribe') {
        # TODO: should verify :P
        my $topic = param('hub.topic');
        my $token = param('hub.verify_token');
        if ($token eq $VALID_TOKEN) {
        # if ($topic =~ m{^http://friendfeed\.com/} && $token eq $VALID_TOKEN) {
            my $challenge = param('hub.challenge');
            warn "OK: $challenge";
            return res(200, [], $challenge);
        } else {
            warn "cannot subscribe: $topic, $token";
            return res(500, [], 'invalid feed');
        }
    } else {
        my $xml = req()->content();
        open my $fh, '>', '/tmp/push.atom' or die $!;
        print $fh $xml;
        close $fh;
        my $feed = XML::Feed->parse(\$xml) or die XML::Feed->errstr;
        for my $entry ($feed->entries) {
            my $content = $entry->content;
            my $info = _parse_entry($content->body);
            c->get('Gearman::Client')->dispatch_background(
                'frepan/add_dist' => encode_json($info),
            ) or die "cannot register job";
        }
        return res(200, [], ['ok']);
    }
}

sub _parse_entry {
    my $body = shift;

    if ($body =~ m!([\w\-]+) ([0-9\._]*) by (.+?) - <a.*href="(http:.*?/authors/id/(.*?\.tar\.gz))"!) {
        return {
            name        => $1,
            version     => $2,
            url         => $4,
            path        => $5,
        };
    }

    warn "cannot match!";
    return;
}

1;
