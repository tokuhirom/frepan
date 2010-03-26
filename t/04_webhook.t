use strict;
use warnings;
use Test::More;
use Amon::Sense;
use Plack::Test;
use Plack::Util;
use Test::More;
use t::Util;

my $atom = slurp 't/data/atom';

my $app = Plack::Util::load_psgi 'FrePAN.psgi';
test_psgi
    app => $app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(
            POST => 'http://localhost/webhook/friendfeed-cpan',
            [ 'Content-Length' => length($atom) ], $atom
        );
        my $res = $cb->($req);
        is $res->code, 200;
        is $res->content, 'ok';
        diag $res->content if $res->code != 200;
    };

done_testing;
