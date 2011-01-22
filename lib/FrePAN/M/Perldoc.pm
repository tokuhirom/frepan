use strict;
use warnings;
use utf8;

package FrePAN::M::Perldoc;
use Smart::Args;

sub lookup {
    args my $class,
         my $c,
         my $package,
         ;

    my ($author, $name, $version, $path) = $c->dbh->selectrow_array(q{SELECT dist.author, dist.name, dist.version, file.path FROM file INNER JOIN dist ON (file.dist_id = dist.dist_id) WHERE package=? ORDER BY file.dist_id DESC LIMIT 1}, {}, $package);
    if (defined $author) {
        return "http://@{[ $c->web_host ]}/~$author/$name-$version/$path";
    } else {
        return;
    }
}

1;

