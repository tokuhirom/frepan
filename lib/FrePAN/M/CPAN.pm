package FrePAN::M::CPAN;
use strict;
use warnings;
use parent qw/Class::Accessor::Fast/;
use Gravatar::URL qw/gravatar_url/;
use DBI;
use Path::Class qw/dir file/;
use Amon::Declare qw/db logger/;
__PACKAGE__->mk_accessors(qw/minicpan/);

sub new {
    my ($class, $args) = @_;
    bless { minicpan => $args->{minicpan} }, $class;
}

sub pause_id2gravatar_url {
    my ($self, $pause_id) = @_;
    my $author = db->single( meta_author => { pause_id => $pause_id } );
    if ($author) {
        return $self->email2gravatar_url($author->email);
    } else {
        logger->info("cannot detect author: $pause_id");
        return;
    }
}

sub email2gravatar_url {
    my ($self, $email) = @_;
    return gravatar_url(email => $email);
}

sub dist2path {
    my ($self, $distname) = @_;
    my $row = db->single(
        meta_packages => {
            dist_name => $distname,
        }
    );
    if ($row) {
        my ($cpanid, $distfile) = split m{/}, $row->path;
        return File::Spec->catfile(
            $self->{minicpan},
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

1;
