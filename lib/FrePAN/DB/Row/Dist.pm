package FrePAN::DB::Row::Dist;
use strict;
use warnings;
use parent qw/DBIx::Skinny::Row/;

sub download_url {
    my $self = shift;
    my $base = time() - $self->ctime > 24*60*60 ?
        'http://search.cpan.org/CPAN/authors/id/'
        : 'http://cpan.cpantesters.org/authors/id/';
    return $base . $self->path;
}

1;
