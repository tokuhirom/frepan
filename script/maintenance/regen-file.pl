#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use FrePAN;
use FrePAN::M::Injector;
use Log::Minimal;

my $c = FrePAN->bootstrap();

my $iter = $c->db->search('dist' => {}, {order_by => {dist_id => 'DESC'}});
while (my $dist = $iter->next) {
    my $dir = $dist->extracted_dir();
    unless (-d $dir) {
        warnf "Missing directory: $dir";
        next;
    }

    infof("regen: " . $dist->path);

    my $meta = FrePAN::M::Injector->load_meta(
        dir => $dir
    );
    FrePAN::M::Injector->insert_files(
        meta => $meta,
        dist => $dist,
        dir  => $dist->extracted_dir(),
        c    => $c,
    );
}

