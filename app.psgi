use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use FrePAN::Web;
use Plack::Builder;
use Plack::App::Directory;
use Plack::App::URLMap;
use Plack::MIME;
use FrePAN::API;
use Plack::App::File;

delete $Plack::MIME::MIME_TYPES->{$_} for qw/.pl .pm .yml .json/;

builder {
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/static/|/favicon\.ico|/robots\.txt)},
        root => './';
    enable 'Plack::Middleware::ReverseProxy';

    mount '/' => FrePAN::Web->to_app();
    mount '/api/' => FrePAN::API->to_app();
    mount '/docs/' => Plack::App::Directory->new(root => 'apidocs/build/html/')->to_app;
};
