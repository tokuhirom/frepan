#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use feature qw(say switch state unicode_strings);
use FrePAN;
use JSON;
use Log::Minimal;

my $c = FrePAN->bootstrap;
my $fts = $c->fts;
my $offset = 0;
my $limit = 100;
while (1) {
    my $res = $fts->furl->get("http://$fts->{host}:$fts->{port}/d/select?table=File&input_type=json&values=[]&output_columns=_key&sortby=_key&limit=$limit&offset=$offset");
    die $res->status_line . "\n\n". $res->content unless $res->is_success;
    my $data = decode_json($res->content);
    $data = $data->[1]->[0];
    shift @$data;
    shift @$data;
    for (@$data) {
        my ($fid) = @$_;
        if ($c->db->single(file => {file_id => $fid})) {
            debugf("skip %s", $fid);
        } else {
            infof("remove %s", $fid);
            $c->fts->delete($fid);
        }
    }
    last unless @$data;
    $offset += $limit;
}

