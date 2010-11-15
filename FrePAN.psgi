use File::Spec;
use File::Basename;
use local::lib File::Spec->catdir(dirname(__FILE__), 'extlib');
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use FrePAN::Web;
use Plack::Builder;
use Plack::App::Directory;
use Plack::App::URLMap;
use Plack::MIME;

delete $Plack::MIME::MIME_TYPES->{$_} for qw/.pl .pm .yml .json/;

builder {
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/static/|/favicon\.ico)},
        root => './htdocs/';

    mount '/' => FrePAN::Web->to_app();
    mount '/src/' =>
      Plack::App::Directory->new( root => './tmp/src/', )->to_app;
};
