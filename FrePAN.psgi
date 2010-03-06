use FrePAN::Web;
use Plack::Builder;

my $config = do 'config.pl';
builder {
    enable 'Plack::Middleware::Static',
        path => qr{^/static/},
        root => './htdocs/';
    FrePAN::Web->to_app(config => $config);
};
