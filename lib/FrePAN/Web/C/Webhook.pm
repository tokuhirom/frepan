package FrePAN::Web::C::Webhook;
use strict;
use warnings;
use XML::Feed;
use JSON::XS;
use File::Slurp;

my $VALID_TOKEN = 'c5cedc136feeb7674f96b3d7dcde6361';

sub friendfeed {
    my ($class, $c) = @_;
    my $mode = $c->req->param('hub.mode') || '';
    if ($mode eq 'subscribe') {
        # TODO: should verify :P
        my $topic = $c->req->param('hub.topic');
        my $token = $c->req->param('hub.verify_token');
        if ($token eq $VALID_TOKEN) {
        # if ($topic =~ m{^http://friendfeed\.com/} && $token eq $VALID_TOKEN) {
            my $challenge = $c->req->param('hub.challenge');
            warn "OK: $challenge";
            return res(200, [], $challenge);
        } else {
            warn "cannot subscribe: $topic, $token";
            return res(500, [], 'invalid feed');
        }
    } else {
        my $xml = $c->req->content();
        my $feed = XML::Feed->parse(\$xml) or die XML::Feed->errstr;
        for my $entry ($feed->entries) {
            my $content = $entry->content;
            my $info = _parse_entry($content->body);
            $info->{released} = $entry->issued->epoch;
            if ($info) {
                $c->create_schwartz_simple->insert(
                    'FrePAN::Worker::ProcessDist' => encode_json($info),
                ) or die "cannot register job: $@";
            } else {
                warn "cannot parse body: @{[ $content->body ]}";
            }
        }
        return $c->create_response(200, [], ['ok']);
    }
}
*post_friendfeed = *friendfeed;

sub _parse_entry {
    my $body = shift;

    # version number:
    #   1.6.3a
    #   v1.0.3
    #   PNI-Node-Tk 0.02-withoutworldwriteables by Casati Gianluca <-- yes. it's invalid. but, parser should show tolerance.
    #   FusionInventory-Agent 2.1_rc1 by FusionInventory Project
    if ($body =~ m!([\w\-]+) (v?[0-9\._-]*[a-zA-Z0-9]*) by (.+?) - <a.*href="(http:.*?/authors/id/(.*?\.tar\.gz))"!) {
        return {
            name        => $1,
            version     => $2,
            url         => $4,
            path        => $5,
        };
    }

    warn "cannot match!: $body";
    return;
}

1;
