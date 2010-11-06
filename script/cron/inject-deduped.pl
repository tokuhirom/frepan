#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use JSON::XS;
use XML::Feed;
use XML::Feed::Deduper;
use FrePAN;
use FrePAN::M::Injector;

my $c = FrePAN->bootstrap();
my $url = 'http://friendfeed.com/cpan?format=atom';

&main; exit 0;

sub main {
    my $feed = XML::Feed->parse(URI->new($url))
        or die XML::Feed->errstr;
    for my $entry ($c->feed_deduper->dedup($feed->entries)) {
        my $content = $entry->content;
        my ($name, $version, $url, $path) = _parse_entry($content->body);
        if ($name) {
            FrePAN::M::Injector->inject(
                path     => $path,
                url      => $url,
                name     => $name,
                version  => $version,
                released => $entry->issued->epoch,
            );
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
         # name, version, url, path
        return ($1, $2, $4, $5);
    }

    warn "cannot match!: $body";
    return;
}
