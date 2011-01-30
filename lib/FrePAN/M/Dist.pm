use strict;
use warnings;
use utf8;

package FrePAN::M::Dist;
use Smart::Args;
use Amon2::Declare;

sub get_latest_version {
    args my $class,
         my $name,
         ;
    my $c = c();

    my ($latest) = reverse sort {
        eval { version->parse($a) || 0 } <=> eval { version->parse($b) || 0 }
      } map { @$_ } @{
        $c->dbh->selectall_arrayref( q{SELECT version FROM dist WHERE name=?},
            {}, $name )
      };
    return $latest;
}

1;

