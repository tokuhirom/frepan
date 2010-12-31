package FrePAN::Web::C::Diff;
use strict;
use warnings;
use utf8;
use FrePAN::M::Diff;
use Log::Minimal;
use Text::Xslate qw/mark_raw/;

sub show {
    my ($class, $c) = @_;

    my $dist_id = $c->req->param('dist_id') // die 'missing "dist_id"';
    my $new_dist = $c->db->single(dist => {dist_id => $dist_id}) // die;

    my $old_dist = do {
        if (my $orig_dist_id = $c->req->param('orig_dist_id')) {
            $c->db->single(dist => {dist_id => $orig_dist_id}) // die;
        } else {
            $new_dist->last_release() // return $c->res_404();
        }
    };

    if ($new_dist->version gt $old_dist->version) {
        ($new_dist, $old_dist) = ($old_dist, $new_dist);
    }

    my ($added, $removed, $diffs) = FrePAN::M::Diff->diff($old_dist, $new_dist);

    return $c->render(
        'diff/show.tx',
        {
            added    => $added,
            removed  => $removed,
            diffs    => $diffs,
            new_dist => $new_dist,
            old_dist => $old_dist
        }
    );
}

1;

