package FrePAN::M::CPAN;
use strict;
use warnings;
use DBI;
use Path::Class qw/dir file/;
use Amon2::Declare;
use Log::Minimal;
use Smart::Args;
use CPAN::DistnameInfo;

sub minicpan_path {
    c->config->{'M::CPAN'}->{minicpan} // die;
}

sub download_url {
    my ($self, $path, $released) = @_;
    my $base = time() - $released > 24*60*60 ?
        'http://search.cpan.org/CPAN/authors/id/'
        : 'http://cpan.cpantesters.org/authors/id/';
    return $base . $path;
}

# @return instance of FrePAN::DB::Row::Dist
sub dist_from_path {
    args_pos my $self, my $path;

    my $info = CPAN::DistnameInfo->new($path);
    c->db->single(
        dist => {
            author  => $info->cpanid,
            name    => $info->dist,
            version => $info->version,
        },
    );
}

1;
