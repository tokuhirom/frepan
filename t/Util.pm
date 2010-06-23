use 5.013002;

package t::Util {
    use DBI;

    sub slurp { open my $fh, '<', $_[0] or die "cannot open file $_[0]"; do { local $/; <$fh> } }

    $ENV{PLACK_ENV} = 'test';

    # initialize database

    my $dbh = DBI->connect('dbi:mysql:mysql_read_default_file=/etc/my.cnf;mysql_multi_statements=1', 'root', '');

    my $app_schema = slurp 'sql/my.sql';
    $dbh->do(q{DROP DATABASE IF EXISTS test_FrePAN;});
    $dbh->do(q{CREATE DATABASE test_FrePAN;});
    $dbh->do(q{USE test_FrePAN;});
    $dbh->do($app_schema);

    my $sch_schema = slurp 'sql/schwartz.sql';
    $dbh->do(q{DROP DATABASE IF EXISTS test_FrePAN_sch;});
    $dbh->do(q{CREATE DATABASE test_FrePAN_sch;});
    $dbh->do(q{USE test_FrePAN_sch;});
    $dbh->do($sch_schema);

}
