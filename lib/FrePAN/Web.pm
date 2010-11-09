package FrePAN::Web;
use strict;
use warnings;
use parent qw/FrePAN Amon2::Web/;
use Module::Find qw/useall/;

useall 'FrePAN::Web::C';
use FrePAN::M::CPAN;

__PACKAGE__->add_config(
    'Text::Xslate' => {
        'syntax'   => 'TTerse',
        'module'   => [ 'Text::Xslate::Bridge::TT2Like' ],
        'function' => {
            c => sub { Amon2->context() },
            uri_with => sub { Amon2->context()->req->uri_with(@_) },
            uri_for  => sub { Amon2->context()->uri_for(@_) },
            version => sub { @_ == 1 ? $_[0]->VERSION : FrePAN->VERSION }, 
            amon_version => sub { $Amon2::VERSION }, 
            email2gravatar_url => sub { FrePAN::M::CPAN->email2gravatar_url(@_) },
            'lc' => sub { scalar(lc($_[0])) },
            has_item => sub { defined $_[0]->{$_[1]} },
            'ref' => sub { ref($_[0]) },
        },
    }
);

use Tiffany::Text::Xslate;
my $view = Tiffany::Text::Xslate->new(__PACKAGE__->config->{'Text::Xslate'});
sub create_view { $view }

use FrePAN::Web::Dispatcher;
sub dispatch { FrePAN::Web::Dispatcher->dispatch(@_) }

__PACKAGE__->load_plugins('Web::FillInFormLite');
__PACKAGE__->load_plugins('Web::NoCache');

1;
