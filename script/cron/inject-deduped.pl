#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use JSON::XS;
use XML::Feed;
use XML::Feed::Deduper;
use FrePAN;
use FrePAN::Worker::ProcessDist;

my $c = FrePAN->bootstrap();
my $url = 'http://friendfeed.com/cpan?format=atom';

&main; exit 0;

sub main {
    my $feed = XML::Feed->parse(URI->new($url))
        or die XML::Feed->errstr;
    for my $entry ($c->feed_deduper->dedup($feed->entries)) {
        my $content = $entry->content;
        my $info = _parse_entry($content->body);
        if ($info) {
            $info->{released} = $entry->issued->epoch;
            FrePAN::Worker::ProcessDist->_work2($info);
        } else {
            warn "cannot parse body: @{[ $content->body ]}";
        }
    }
}

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
