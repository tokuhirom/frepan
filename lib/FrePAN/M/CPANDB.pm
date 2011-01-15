package FrePAN::M::CPANDB;
use common::sense;
use Amon2::Declare;
use Smart::Args;

# This mehhod checks the $author have a permission to release the $package or not.
# @return 1 if authorized, 0 unauthorized.
sub is_authorized {
    args my $class,
         my $pause_id,
         my $package,
         my $c,
         ;

    my $has_permission = $c->dbh->selectrow_array(q{SELECT COUNT(*) FROM meta_perms WHERE package=? AND pause_id=?}, {}, $package, $pause_id);
    return 1 if $has_permission;

    my $is_registered = $c->dbh->selectrow_array(q{SELECT COUNT(*) FROM meta_perms WHERE package=?}, {}, $package);
    return $is_registered ? 0 : 1;
}

1;
