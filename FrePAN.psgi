use FrePAN::Web;
use Plack::Builder;
use Plack::App::Directory;
use Plack::App::URLMap;

my $config = do 'config.pl';

builder {
    enable 'Plack::Middleware::Static',
        path => qr{^/static/},
        root => './htdocs/';

    my $map = Plack::App::URLMap->new();
    $map->map('/' => do {
        FrePAN::Web->to_app(config => $config);
    });
    $map->map( '/src/' => do {
        Plack::App::Directory->new( root => './tmp/src/', )->to_app
    });
    $map->to_app;
};
