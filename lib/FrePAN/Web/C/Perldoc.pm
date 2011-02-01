package FrePAN::Web::C::Perldoc;
use strict;
use warnings;
use utf8;
use URI::Escape qw/uri_unescape/;
use FrePAN::M::Perldoc;
use Log::Minimal;

sub redirect {
    my ($class, $c) = @_;
    my $package = uri_unescape($c->req->env->{QUERY_STRING});
    $package =~ s/&.+//; # query is like a 'Perl::Critic&_=1296596694992&slide=1'

    my $url = FrePAN::M::Perldoc->package2url(
        package => $package,
        c       => $c,
    );
    if ($url) {
        return $c->redirect($url);
    } else {
        warnf("package '%s' is not found in frepan", $package);
        return $c->res_404();
    }
}

1;

