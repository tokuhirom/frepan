#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use FrePAN;
use Log::Minimal;

my $c = FrePAN->bootstrap;

my $sth = $c->db->dbh->prepare(q{SELECT pause_id, dist_name, dist_version FROM meta_uploads where type='backpan'});
$sth->execute();
while (my ($pause_id, $dist_name, $dist_version) = $sth->fetchrow_array) {
    my $dist =
      $c->db->single( dist =>
          { author => $pause_id, name => $dist_name, version => $dist_version }
      );
    if ($dist) {
        infof("removing $pause_id/$dist_name-$dist_version");
        $dist->delete;
    } else {
        # infof("$pause_id/$dist_name-$dist_version is not exists in db");
    }
}

