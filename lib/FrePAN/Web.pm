package FrePAN::Web;
use strict;
use warnings;
use parent qw/FrePAN Amon2::Web/;
use Module::Find qw/useall/;

useall 'FrePAN::Web::C';
use FrePAN::M::CPAN;

use Tiffany::Text::Xslate;
{
    my $conf = __PACKAGE__->config->{'Text::Xslate'} || +{};
    my $view = Tiffany::Text::Xslate->new(+{
        'syntax'   => 'TTerse',
        'module'   => [ 'Text::Xslate::Bridge::TT2Like' ],
        'function' => {
            c => sub { Amon2->context() },
            uri_with => sub { Amon2->context()->req->uri_with(@_) },
            uri_for  => sub { Amon2->context()->uri_for(@_) },
            version => sub { @_ == 1 ? $_[0]->VERSION : FrePAN->VERSION }, 
            amon_version => sub { $Amon2::VERSION }, 
            email2gravatar_url => sub { FrePAN::M::CPAN->email2gravatar_url(@_) },
            'ref' => sub { ref($_[0]) },
        },
        path => [File::Spec->catdir(__PACKAGE__->base_dir, 'tmpl')],
        %$conf,
    });
    sub create_view { $view }
}

use FrePAN::Web::Dispatcher;
sub dispatch { FrePAN::Web::Dispatcher->dispatch(@_) }

__PACKAGE__->load_plugins('Web::FillInFormLite');
__PACKAGE__->load_plugins('Web::NoCache');

1;
