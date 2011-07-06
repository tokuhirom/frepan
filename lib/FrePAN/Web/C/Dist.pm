package FrePAN::Web::C::Dist;
use strict;
use warnings;
use String::CamelCase qw/decamelize/;
use JSON::XS qw/decode_json/;
use Smart::Args;
use Log::Minimal;

# show distribution meta data
sub show {
    my ($class, $c, $args) = @_;
    my $author = $args->{author}
        or die;
    my $dist_ver = $args->{dist_ver}
        or die;

    return $c->redirect_metacpan("/release/@{[ uc $author ]}/$dist_ver/");
}

# show pod
sub show_file {
    my ($class, $c, $args) = @_;
    my $author = $args->{author};
    my $dist_ver = $args->{dist_ver};
    my $path = $args->{path};

    return $c->redirect_metacpan("/module/@{[ uc $author ]}/$dist_ver/$path");
}

# other version
sub other_version {
    my ($class, $c) = @_;

    my $dist_id = $c->req->param('dist_id') // die "missing mandatory parameter: dist_id";
    my $dist = $c->db->single(dist => {dist_id => $dist_id}) // return $c->res_404();
    if ($c->req->param('diff')) {
        return $c->redirect('/diff?' . $c->req->env->{QUERY_STRING});
    } else {
        return $c->redirect($dist->relative_url());
    }
}

# /dist/.+/?
sub permalink {
    my ($class, $c) = @_;

    my $dist_name = $c->{args}->{dist_name} // die;
    return $c->redirect_metacpan("/release/$dist_name");
}

1;
