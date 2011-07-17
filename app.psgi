use strict;
use warnings;
use Plack::Builder;
use Plack::App::Directory;
use autodie;

builder {
    enable 'ContentLength';
    enable 'ReverseProxy';
    mount '/feed/index.rss' => sub {
        open my $fh, '<', 'dat/index.rss';
        [200, ['Content-Type' => 'text/xml; charset=utf-8'], $fh];
    };
    mount '/static/' => Plack::App::Directory->new(root => './static/');
    mount '/' => sub {
        open my $fh, '<', 'dat/index.html';
        [200, ['Content-Type' => 'text/html; charset=utf-8'], $fh];
    };
};
