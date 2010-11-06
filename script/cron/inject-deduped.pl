#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use JSON::XS;
use XML::Feed;
use XML::Feed::Deduper;
use FrePAN;
use FrePAN::M::Injector;
use Web::Scraper;
use Time::Piece;
use CPAN::DistnameInfo;

my $c = FrePAN->bootstrap();
my $ff_url = 'http://friendfeed.com/cpan?format=atom';
my $nntp_url = 'http://www.nntp.perl.org/group/perl.cpan.uploads/';

&main; exit 0;

sub main {
    process_nntp();
    process_ff();
}

sub process_nntp {
    my $time_prefix = do {
        my $time = Time::Piece::gmtime();
        $time -= $time->hour*60*60 + $time->minute*60 + $time->second;
        $time->epoch;
    };
    my $dat = scraper {
        process 'table.article_list tr' => 'entries[]' => scraper {
            process 'a' => 'path' => ['TEXT', sub { s/^CPAN Upload: // }];
            process 'td[width="120"]' => 'time' => ['TEXT', sub { /(\d+):(\d+)/ ? $time_prefix + $1*60*60 + $2*60 : undef }];
        };
    }->scrape(URI->new($nntp_url));
    LOOP: for my $entry (@{$dat->{'entries'}}) {
        next unless $entry->{time};
        my $distnameinfo = CPAN::DistnameInfo->new($entry->{path});
        my $author  = $distnameinfo->cpanid();
        my $version = $distnameinfo->version;
        my $name    = $distnameinfo->dist;

        # check duplication
        my $e = $c->db->single(
            dist => {
                name    => $name,
                version => $version,
                author  => $author,
            }
        );
        next LOOP if $e;

        FrePAN::M::Injector->inject(
            path     => $entry->{path},
            name     => $name,
            version  => $version,
            released => $entry->{time},
            author   => $author,
        );
    }
}

sub process_ff {
    my $feed = XML::Feed->parse(URI->new($ff_url))
        or die XML::Feed->errstr;
    LOOP: for my $entry ($c->feed_deduper->dedup($feed->entries)) {
        my $content = $entry->content;
        my ($name, $version, $url, $path) = _parse_entry($content->body);
        if ($name) {
            my $author = _path2author($path);
            my $entry = $c->db->single(
                dist => {
                    name    => $name,
                    version => $version,
                    author  => $author,
                }
            );
            next LOOP if $entry;

            FrePAN::M::Injector->inject(
                path     => $path,
                name     => $name,
                version  => $version,
                released => $entry->issued->epoch,
            );
        } else {
            warn "cannot parse body: @{[ $content->body ]}";
        }
    }
}

sub _parse_path {
    my $path = shift;
    my ($author) = ($path =~ m{^./../([^/]+)/});
}

sub _path2author {
    my $path = shift;
    my ($author) = ($path =~ m{^./../([^/]+)/});
    die "cannot detect author" unless $author;
    return $author;
}

sub _parse_entry {
    my $body = shift;

    # version number:
    #   1.6.3a
    #   v1.0.3
    #   PNI-Node-Tk 0.02-withoutworldwriteables by Casati Gianluca <-- yes. it's invalid. but, parser should show tolerance.
    #   FusionInventory-Agent 2.1_rc1 by FusionInventory Project
    if ($body =~ m!([\w\-]+) (v?[0-9\._-]*[a-zA-Z0-9]*) by (.+?) - <a.*href="(http:.*?/authors/id/(.*?\.tar\.gz))"!) {
         # name, version, path
        return ($1, $2, $5);
    }

    warn "cannot match!: $body";
    return;
}
