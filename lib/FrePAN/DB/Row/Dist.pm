package FrePAN::DB::Row::Dist;
use strict;
use warnings;
use parent qw/DBIx::Skinny::Row/;
use Amon2::Declare;
use Log::Minimal;
use Smart::Args;
use autodie;

sub files {
    my ($self) = @_;
    c->db->search(file => {dist_id => $self->dist_id});
}

sub delete_files {
    my ($self) = @_;
    c->dbh->do(q{DELETE FROM file WHERE dist_id=?}, {}, $self->dist_id);
}

sub remove_from_fts {
    my ($self) = @_;
    for my $file ($self->files()) {
        c->fts->delete($file->file_id);
    }
}

sub insert_to_fts {
    my ($self) = @_;

    # remove old entries
    {
        my @old_dists = c->db->search(dist => {name => $self->name});
        for my $old_dist (@old_dists) {
            $old_dist->remove_from_fts();
        }
    }

    # insert to fts
    for my $file ($self->files) {
        $file->insert_to_fts() if $file->html();
    }
}

sub archive_path {
    args_pos my $self;

    my $minicpan = c->config->{'M::CPAN'}->{minicpan} // die;

    return File::Spec->catfile(
        $minicpan,
        'authors', 'id',
        $self->path
    );
}

sub delete {
    my $self = shift;

    if (-f $self->archive_path) {
        unlink $self->archive_path();
    }

    $self->remove_from_fts();
    $self->delete_files();

    $self->SUPER::delete();
}

1;
