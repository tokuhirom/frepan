package FrePAN::M::CPAN;
use strict;
use warnings;
use Gravatar::URL qw/gravatar_url/;
use DBI;
use Path::Class qw/dir file/;
use Amon2::Declare;
use Log::Minimal;
use Smart::Args;
use CPAN::DistnameInfo;

sub pause_id2gravatar_url {
    my ($self, $pause_id) = @_;
    my $author = c->db->single( meta_author => { pause_id => $pause_id } );
    if ($author) {
        return $self->email2gravatar_url($author->email);
    } else {
        infof("cannot detect author: $pause_id");
        return;
    }
}

sub email2gravatar_url {
    my ($self, $email) = @_;
    return gravatar_url(email => $email, default => 'http://st.pimg.net/tucs/img/who.png');
}

sub minicpan_path {
    c->config->{'M::CPAN'}->{minicpan} // die;
}

sub dist2path {
    my ($class, $distname) = @_;
    my $row = c->db->single(
        meta_packages => {
            dist_name => $distname,
        }
    );
    if ($row) {
        my ($cpanid, $distfile) = split m{/}, $row->path;
        my $minicpan = $class->minicpan_path();
        return File::Spec->catfile(
            $minicpan,
            'authors', 'id',
            substr($cpanid, 0, 1),
            substr($cpanid, 0, 2),
            $cpanid,
            $distfile,
        );
    } else {
        return;
    }
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
