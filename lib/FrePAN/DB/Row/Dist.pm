package FrePAN::DB::Row::Dist;
use strict;
use warnings;
use parent qw/DBIx::Skinny::Row/;
use Amon2::Declare;
use Log::Minimal;

sub files {
    my ($self) = @_;
    c->db->search(file => {dist_id => $self->dist_id});
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

1;
