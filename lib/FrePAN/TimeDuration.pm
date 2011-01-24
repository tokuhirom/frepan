use strict;
use warnings;
use utf8;

package FrePAN::TimeDuration;
use parent qw/Exporter/;
use Time::Duration;
use Time::Piece;

our @EXPORT = qw/ago/;

sub ago {
    my ($time) = @_;

    my $now = time();
    my $elapsed = $now-$time;
    if ($elapsed < 24*60*60) {
        return Time::Duration::ago($elapsed, 1);
    } else {
        my $format = '%Y-%m-%d';
        return Time::Piece->new($time)->strftime($format);
    }
}

1;

