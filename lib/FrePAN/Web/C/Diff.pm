package FrePAN::Web::C::Diff;
use strict;
use warnings;
use utf8;
use FrePAN::M::Diff;
use Log::Minimal;
use Text::Xslate qw/mark_raw/;

use Time::HiRes qw/alarm gettimeofday tv_interval/;
sub timeout($&) {
    my ($sec, $code) = @_;
    my $retval;
    my $succeeded = eval {
        local $SIG{ALRM} = sub { die "alarm\n" };
        my $old = alarm($sec);
        my $t1 = [gettimeofday];
        $retval = $code->();
        my $t2 = [gettimeofday];
        alarm $old - tv_interval($t2, $t1);
        1;
    };
    return $retval if $succeeded;
    if ($@ eq "alarm\n") {
        return 0;
    } else {
        die $@; # rethrow
    }
}

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

    # TODO: Do not timeout
    timeout 1, sub {
        my ($added, $removed, $diffs) = FrePAN::M::Diff->diff($old_dist, $new_dist);

        return $c->render2(
            'title' => "diff -u $old_dist $new_dist - FrePAN",
            '#Content' => [
                'diff/show.tx',
                {
                    added    => $added,
                    removed  => $removed,
                    diffs    => $diffs,
                    new_dist => $new_dist,
                    old_dist => $old_dist
                }
            ]
        );
    } or do {
        warnf("diff timeout: %s(%s), %s(%s)", $new_dist->name, $new_dist->dist_id, $old_dist->name, $old_dist->dist_id);
        return $c->show_error("Operation timeout... The distribution has too much files.");
    };
}

1;

