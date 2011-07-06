package FrePAN::Web;
use strict;
use warnings;
use parent qw/FrePAN Amon2::Web/;
use Module::Find qw/useall/;

useall 'FrePAN::Web::C';
use FrePAN::M::CPAN;

sub args { shift->{args} }

use Log::Minimal;
use Text::Xslate;
use FrePAN::M::Formatter;
use HTML::Zoom;
{
    my $conf = __PACKAGE__->config->{'Text::Xslate'} || +{};
    my $view = Text::Xslate->new(+{
        'syntax'   => 'TTerse',
        'module'   => [ 'Text::Xslate::Bridge::TT2Like' ],
        'function' => {
            c => sub { Amon2->context() },
            uri_with => sub { Amon2->context()->req->uri_with(@_) },
            uri_for  => sub { Amon2->context()->uri_for(@_) },
            version => sub { @_ == 1 ? $_[0]->VERSION : FrePAN->VERSION }, 
            amon_version => sub { $Amon2::VERSION }, 
            'ref' => sub { ref($_[0]) },
            'i_use_this_filter' => \&FrePAN::M::Formatter::format,
            'int' => sub { int($_[0]) },
            commify => sub {
                local $_ = shift;
                1 while s/((?:\A|[^.0-9])[-+]?\d+)(\d{3})/$1,$2/s;
                return $_;
            },
        },
        path => [File::Spec->catdir(__PACKAGE__->base_dir, 'tmpl')],
        %$conf,
    });
    sub create_view { $view }

    sub render2 {
        my ($self, %args) = @_;
        my $view = $self->create_view();
        my $base = $view->render('include/layout.tx');
        my $zoom = HTML::Zoom->from_html("$base");
        while (my ($selector, $stuff) = each %args) {
            $zoom = $zoom->select($selector)->replace_content(do {
                if (ref $stuff eq 'ARRAY') {
                    HTML::Zoom->from_html($view->render(@$stuff));
                } else {
                    $stuff;
                }
            });
        }
        my $html = $zoom->to_html();

        for my $code ( $self->get_trigger_code('HTML_FILTER') ) {
            $html = $code->( $self, $html );
        }

        $html = $self->encode_html($html);

        return $self->create_response(
            200,
            [
                'Content-Type'   => $self->html_content_type,
                'Content-Length' => length($html)
            ],
            $html,
        );
    }
}

use FrePAN::Web::Dispatcher;
sub dispatch { FrePAN::Web::Dispatcher->dispatch(@_) }

sub show_error {
    my ($c, $msg) = @_;
    return $c->render('/error.tx', {msg => $msg});
}

__PACKAGE__->load_plugins('Web::NoCache');
__PACKAGE__->add_trigger(
    AFTER_DISPATCH => sub {
        my ($c, $res) = @_;
        $res->header('X-Content-Type-Options' => 'nosniff');
    },
);

sub res_404 {
    my ($c) = @_;
    infof("404 : %s", $c->req->path_info);
    return $c->SUPER::res_404();
}

sub redirect_metacpan {
    my ($self, $path) = @_;
    my $uri = URI->new('http://beta.metacpan.org/');
    $uri->path($path);
    return $self->redirect($uri->as_string);
}

1;
