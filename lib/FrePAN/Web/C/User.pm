package FrePAN::Web::C::User;
use strict;
use warnings;
use utf8;
use OAuth::Lite2;
use OAuth::Lite2::Client::WebServer;
use Log::Minimal;
use Amon2::Declare;
use URI::WithBase;
use OAuth::Lite2::Formatter::FormURLEncoded;
use OAuth::Lite2::Formatters;
use Furl;
use JSON qw/decode_json encode_json/;

# login with github's oauth
# https://gist.github.com/419219

{
    package OAuth::Lite2::Formatter::Github;
    use parent qw/OAuth::Lite2::Formatter::FormURLEncoded/;
    sub type { "text/html" }
}

OAuth::Lite2::Formatters->add_formatter(OAuth::Lite2::Formatter::Github->new);

sub _callback_url {
    my ($class, $c) = @_;
    URI::WithBase->new($c->uri_for('/oauth_callback'), $c->req->base)->abs->as_string;
}

{
    my $client;
    sub _client() {
        $client ||= do {
            my $id = c->config->{'OAuth::Lite2'}->{id} // die;
            my $secret = c->config->{'OAuth::Lite2'}->{secret} // die;
            OAuth::Lite2::Client::WebServer->new(
                id            => $id,
                secret        => $secret,
                authorize_uri => q{https://github.com/login/oauth/authorize},
                access_token_uri => q{https://github.com/login/oauth/access_token},
            );
        };
    }
}

sub login {
    my ($class, $c) = @_;

    my $redirect_url = _client->uri_to_redirect(
        redirect_uri => $class->_callback_url($c),
        scope        => q{},
        state        => q{optional_state},
    );
    debugf("redirect to $redirect_url");
    return $c->redirect($redirect_url);
}

sub oauth_callback {
    my ($class, $c) = @_;

    if (my $err = $c->req->param('error')) {
        return $c->show_error($err);
    }
    if ($c->req->raw_body =~ /^error=/) {
        return $c->show_error($c->req->raw_body);
    }
    my $code = $c->req->param('code') // die;
    debugf("code is: $code");
    my $access_token = _get_access_token(
        code         => $code,
        redirect_uri => $class->_callback_url($c),
    ) or return $c->show_error( _client->errstr );

    $c->session->regenerate_session_id(1);

    $c->session->set(
        oauth_info => {
            access_token  => $access_token->access_token,
            expires_at    => time() + ($access_token->expires_in||0),
            refresh_token => $access_token->refresh_token,
        }
    );

    my $res = Furl->new->get('https://github.com/api/v2/json/user/show?access_token=' . $access_token->access_token);
    $res->is_success or die $res->status_line;
    my $data = decode_json($res->content)->{user};
    {
        my $txn = $c->db->txn_scope();
        my $user = $c->db->single(user => {login => $data->{login}}, {for_update => 1});
        unless ($user) {
            $user = $c->db->insert(
                user => {
                    login           => $data->{login},
                    name            => $data->{name},
                    gravatar_id     => $data->{gravatar_id},
                    github_response => encode_json($data)
                },
            );
        }
        $user = $user->refetch;
        $c->session->set(user_id => $user->user_id);
        $txn->commit;
    }

    return $c->redirect('/');
}

sub logout {
    my ($class, $c) = @_;

    $c->session->expire();

    return $c->redirect('/');
}

sub show {
    my ($class, $c) = @_;
    my $user_login = $c->{args}->{user_login} // die;
    my $user = $c->db->single(user => {login => $user_login}) or return $c->res_404();

    my @reviews = $c->db->search('i_use_this', {user_id => $user->user_id});

    return $c->render('user/show.tx', {user => $user, reviews => \@reviews});
}

# hmmm.. github oauth is bit buggy. i need patched version of OAuth::Lite2::Client::WebServer->get_access_token();
use Try::Tiny;
use OAuth::Lite2::Util qw(build_content);
sub _get_access_token {
    my $self = _client();

    my %args = Params::Validate::validate(@_, {
        code         => 1,
        redirect_uri => 1,
        uri          => { optional => 1 },
        # secret_type => { optional => 1 },
        # format      => { optional => 1 },
    });

    unless (exists $args{uri}) {
        $args{uri} = $self->{access_token_uri}
            || Carp::croak "uri not found";
    }

    # $args{format} ||= $self->{format};

    my %params = (
        grant_type    => 'authorization_code',
        client_id     => $self->{id},
        client_secret => $self->{secret},
        code          => $args{code},
        redirect_uri  => $args{redirect_uri},
        # format      => $args{format},
    );

    # $params{secret_type} = $args{secret_type}
    #    if $args{secret_type};

    my $content = build_content(\%params);
    my $headers = HTTP::Headers->new;
    $headers->header("Content-Type" => q{application/x-www-form-urlencoded});
    $headers->header("Content-Length" => bytes::length($content));
    my $req = HTTP::Request->new( POST => $args{uri}, $headers, $content );

    my $res = $self->{agent}->request($req);

    if ($res->content =~ /^error=/) {
        return $self->error($res->content); # XXX
    }

    my ($token, $errmsg);
    try {
        $token = $self->{response_parser}->parse($res);
    } catch {
        critf("Cannot handle oauth response: %s: %s", $_, ddf($res)); # XXX
        $errmsg = "$_";
    };
    return $token || $self->error($errmsg);
}

1;

